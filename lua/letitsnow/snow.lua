local M = {}

local end_command_str = "End"
local SNOWPILE_MAX = 8
local ns_id = vim.api.nvim_create_namespace("snow")
local stop = true

local function _clear_snow(buf)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(buf, ns_id, mark[1])
	end
end

local function _end_hygge(buf)
	vim.api.nvim_buf_del_user_command(buf, end_command_str)

	stop = true
end

local function _make_grid(height, width)
	local grid = {}

	for i = 1, height do
		grid[i] = {}
		for j = 1, width do
			grid[i][j] = 0
		end
	end

	return grid
end

local function _is_floating(buf, row, col, grid)
	if row == vim.api.nvim_buf_line_count(buf) then
		return false
	end
	if row + 1 < #grid then
		if grid[row + 1][col] == SNOWPILE_MAX then
			return false
		end
		local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, true)[1]
		if col < #line and line[col] ~= " " then
			return false
		end
	end
	return true
end

local function _show_snowflake(buf, row, col)
	vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
		virt_text = { { "❄" } },
		virt_text_win_col = col,
	})
end

local size_to_snowpile = {
	[1] = "\u{2581}",
	[2] = "\u{2582}",
	[3] = "\u{2583}",
	[4] = "\u{2584}",
	[5] = "\u{2585}",
	[6] = "\u{2586}",
	[7] = "\u{2587}",
	[8] = "\u{2588}",
}

local function _show_snowpile(buf, row, col, size)
	local icon = size_to_snowpile[size]

	vim.api.nvim_buf_set_extmark(buf, ns_id, row, col, {
		virt_text = { { icon } },
		virt_text_pos = "overlay",
	})
end

local function _show_snow(buf, row, col, grid)
	local size = grid[row][col]

	if size == 1 and _is_floating(buf, row, col, grid) then
		_show_snowflake(buf, row, col)
	else
		_show_snowpile(buf, row, col, size)
	end
end

local function _show_snow_debug(buf, row, col, grid)
	vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
		virt_text = { { tostring(grid[row][col]) } },
		virt_text_win_col = col,
	})
end

local function _show_grid(buf, grid)
	for row = 1, #grid do
		for col = 1, #grid[row] do
			-- _show_snow_debug(buf, row, col, grid)
			if grid[row][col] == 0 then
				goto continue
			end
			_show_snow(buf, row, col, grid)
			::continue::
		end
	end
end

local function _obstructed(row, col, lines)
	return not (row >= 0 and row < #lines and col >= 0 and (col >= #lines[row] or lines[row][col] == " "))
end

local function _inside_grid(row, col, grid)
	return row >= 0 and row < #grid and col >= 0 and col < #grid[row]
end

local function _update_snowflake(row, col, old_grid, new_grid, lines)
	local height = #new_grid

	local below = nil
	local below_a = nil
	local below_b = nil
	local below_c = nil
	local below_d = nil

	-- Check straight down
	if row + 1 < height and (col < #lines[row + 1] or lines[row + 1][col] == " ") then
		below = old_grid[row + 1][col]
	end

	local d = 1
	if math.random() < 0.5 then
		d = -1
	end

	-- Check 1 down 1 sideways
	if
		_inside_grid(row + 1, col + d, new_grid)
		and not _obstructed(row + 1, col, lines)
		and not _obstructed(row + 1, col + d, lines)
	then
		below_a = old_grid[row + 1][col + d]
	end
	if
		_inside_grid(row + 1, col - d, new_grid)
		and not _obstructed(row + 1, col, lines)
		and not _obstructed(row + 1, col - d, lines)
	then
		below_b = old_grid[row + 1][col - d]
	end

	-- Check 1 down 2 sideways
	if
		_inside_grid(row + 1, col + 2 * d, new_grid)
		and not _obstructed(row + 1, col, lines)
		and not _obstructed(row + 1, col + 2 * d, lines)
	then
		below_c = old_grid[row + 1][col + 2 * d]
	end
	if
		_inside_grid(row + 1, col - 2 * d, new_grid)
		and not _obstructed(row + 1, col, lines)
		and not _obstructed(row + 1, col - 2 * d, lines)
	then
		below_d = old_grid[row + 1][col - 2 * d]
	end

	-- Actually move snow (if possible)
	local moved = false
	-- Straight down
	if below ~= nil and below < SNOWPILE_MAX then
		new_grid[row + 1][col] = new_grid[row + 1][col] + 1
		moved = true
	elseif below_a ~= nil and below_a < SNOWPILE_MAX then
		new_grid[row + 1][col + d] = new_grid[row + 1][col + d] + 1
		moved = true
	elseif below_b ~= nil and below_b < SNOWPILE_MAX then
		new_grid[row + 1][col - d] = new_grid[row + 1][col - d] + 1
		moved = true
	elseif below_c ~= nil and below_c < SNOWPILE_MAX then
		new_grid[row + 1][col + 2 * d] = new_grid[row + 1][col + 2 * d] + 1
		moved = true
	elseif below_d ~= nil and below_d < SNOWPILE_MAX then
		new_grid[row + 1][col - 2 * d] = new_grid[row + 1][col - 2 * d] + 1
		moved = true
	else
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col]
	end

	if moved ~= nil and moved then
		new_grid[row][col] = old_grid[row][col] - 1
	end
end

local function _update_snowpile(row, col, old_grid, new_grid, lines)
	local d = 1
	if math.random() < 0.5 then
		d = -1
	end
	if
		_inside_grid(row, col + d, new_grid)
		and old_grid[row][col + d] <= old_grid[row][col] - 3
		and not _obstructed(row, col + d, lines)
	then
		new_grid[row][col + d] = new_grid[row][col + d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
	elseif
		_inside_grid(row, col - d, new_grid)
		and old_grid[row][col - d] <= old_grid[row][col] - 3
		and not _obstructed(row, col - d, lines)
	then
		new_grid[row][col - d] = new_grid[row][col - d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
	else
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col]
	end
end

local function _update_grid(win, buf, old_grid)
	local height = vim.api.nvim_buf_line_count(buf)
	local width = vim.api.nvim_win_get_width(win)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, height, true)

	local new_grid = _make_grid(height, width)

	-- Spawn new snowflake
	-- WARN: This should maybe be += 1?
	new_grid[1][math.random(0, width - 1)] = 1

	-- Update positions of snow
	for row = 1, height do
		if row >= #old_grid then
			goto continue_outer
		end
		for col = 1, width do
			if col >= #old_grid[row] or old_grid[row][col] == 0 then
				goto continue_inner
			end
			if _is_floating(buf, row, col, old_grid) then
				_update_snowflake(row, col, old_grid, new_grid, lines)
			else
				_update_snowpile(row, col, old_grid, new_grid, lines)
			end
			::continue_inner::
		end
		::continue_outer::
	end

	return new_grid
end

local function _main_loop(win, buf, grid)
	grid = _update_grid(win, buf, grid)

	_clear_snow(buf)

	_show_grid(buf, grid)

	if not stop then
		vim.defer_fn(function()
			_main_loop(win, buf, grid)
		end, 500)
	else
		_clear_snow(buf)
	end
end

M._let_it_snow = function()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()

	local height = vim.api.nvim_buf_line_count(buf)
	local width = vim.api.nvim_win_get_width(win)
	local initial_grid = _make_grid(height, width)

	vim.api.nvim_buf_create_user_command(buf, end_command_str, function()
		_end_hygge(buf)
	end, {})

	stop = false

	vim.defer_fn(function()
		_main_loop(win, buf, initial_grid)
	end, 500)
end

return M
