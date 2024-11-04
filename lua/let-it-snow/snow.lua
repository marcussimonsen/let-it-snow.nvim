local M = {}

local end_command_str = "End"
local SNOWPILE_MAX = 8
local MAX_SPAWN_ATTEMPTS = 500
local ns_id = vim.api.nvim_create_namespace("snow")
local stop = true

local function clear_snow(buf)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(buf, ns_id, mark[1])
	end
end

local function end_hygge(buf)
	vim.api.nvim_buf_del_user_command(buf, end_command_str)

	stop = true
end

local function make_grid(height, width)
	local grid = {}

	for i = 0, height do
		grid[i] = {}
		for j = 0, width do
			grid[i][j] = 0
		end
	end

	return grid
end

local function inside_grid(row, col, grid)
	return row >= 0 and row < #grid and col >= 0 and col < #grid[row]
end

local function obstructed(row, col, lines, grid)
	-- `lines` is 1-based, so check char in lines at row + 1 (uppermost line)
	local char_obstructed = (col < #lines[row + 1] and lines[row + 1]:sub(col + 1, col + 1) ~= " ")
	local snowpile_obstructed = grid[row][col] == SNOWPILE_MAX
	return char_obstructed or snowpile_obstructed
end

local function is_floating(row, col, grid, lines)
	if row >= #lines - 1 then
		return false
	end
	return not obstructed(row + 1, col, lines, grid)
end

local function show_snowflake(buf, row, col)
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

local function show_snowpile(buf, row, col, size)
	assert(
		size <= SNOWPILE_MAX,
		string.format("Exceeded max snowpile size (%d) at in buf %s: %d, %d", size, buf, row, col)
	)
	local icon = size_to_snowpile[size]

	vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
		virt_text = { { icon } },
		virt_text_win_col = col,
	})
end

local function show_snow(buf, row, col, grid, lines)
	local size = grid[row][col]

	if size == 1 and is_floating(row, col, grid, lines) then
		show_snowflake(buf, row, col)
	else
		show_snowpile(buf, row, col, size)
	end
end

local function show_snow_debug(buf, row, col, grid)
	vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
		virt_text = { { tostring(grid[row][col]) } },
		virt_text_win_col = col,
	})
end

local function show_debug_obstructed(buf, grid, lines)
	for row = 0, #grid - 1 do
		for col = 0, #grid[row] do
			if obstructed(row, col, lines, grid) then
				vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
					virt_text = { { "\u{2588}" } },
					virt_text_win_col = col,
				})
			end
		end
	end
end

local function show_grid(buf, grid, lines)
	for row = 0, #grid do
		for col = 0, #grid[row] do
			if grid[row][col] == 0 then
				goto continue
			end
			show_snow(buf, row, col, grid, lines)
			::continue::
		end
	end
end

local function spawn_snowflake(grid, lines)
	local x = nil
	local attempts = 0
	while x == nil or obstructed(0, x, lines, grid) do
		if attempts >= MAX_SPAWN_ATTEMPTS then
			vim.notify(
				("Warning: Exceeded %d attempts in spawning a snowflake!\nStopping..."):format(MAX_SPAWN_ATTEMPTS),
				vim.log.levels.WARN
			)
			return
		end
		x = math.random(0, #grid[0] - 1)
		attempts = attempts + 1
	end
	grid[0][x] = grid[0][x] + 1
end

local function update_snowflake(row, col, old_grid, new_grid)
	-- Snow always fall - by definition
	-- Move 1 snow to cell below
	new_grid[row + 1][col] = new_grid[row + 1][col] + 1
	-- Keep rest of snow
	new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
end

local function update_snowpile(row, col, old_grid, new_grid, lines)
	local d = 1
	if math.random() < 0.5 then
		d = -1
	end
	if
		inside_grid(row, col + d, new_grid)
		and old_grid[row][col + d] <= old_grid[row][col] - 3
		and not obstructed(row, col + d, lines, new_grid)
	then
		new_grid[row][col + d] = new_grid[row][col + d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
	elseif
		inside_grid(row, col - d, new_grid)
		and old_grid[row][col - d] <= old_grid[row][col] - 3
		and not obstructed(row, col - d, lines, new_grid)
	then
		new_grid[row][col - d] = new_grid[row][col - d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
	elseif inside_grid(row, col, new_grid) and not obstructed(row, col, lines, new_grid) then
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col]
	end
end

local function update_grid(win, buf, old_grid, lines)
	local height = vim.api.nvim_buf_line_count(buf)
	local width = vim.api.nvim_win_get_width(win)

	local new_grid = make_grid(height, width)

	-- Update positions of snow
	for row = 0, height do
		if row >= #old_grid then
			break
		end
		for col = 0, width do
			if col >= #old_grid[row] or old_grid[row][col] == 0 then
				goto continue_inner
			end
			if is_floating(row, col, old_grid, lines) then
				update_snowflake(row, col, old_grid, new_grid)
			else
				update_snowpile(row, col, old_grid, new_grid, lines)
			end
			::continue_inner::
		end
	end

	spawn_snowflake(new_grid, lines)

	return new_grid
end

local function get_lines(buf)
	local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, true)
	local tabwidth = vim.o.tabstop

	local tab_replacement = (" "):rep(tabwidth)

	for row = 1, #lines do
		lines[row] = lines[row]:gsub("\t", tab_replacement)
	end

	return lines
end

local function main_loop(win, buf, grid)
	local lines = get_lines(buf)
	grid = update_grid(win, buf, grid, lines)

	clear_snow(buf)

	show_grid(buf, grid, lines)

	-- TODO: Delay with desired - time_to_update_grid
	if not stop then
		vim.defer_fn(function()
			main_loop(win, buf, grid)
		end, 500)
	else
		clear_snow(buf)
	end
end

M._let_it_snow = function()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()

	local height = vim.api.nvim_buf_line_count(buf)
	local width = vim.api.nvim_win_get_width(win)
	local initial_grid = make_grid(height, width)

	vim.api.nvim_buf_create_user_command(buf, end_command_str, function()
		end_hygge(buf)
	end, {})

	stop = false

	vim.defer_fn(function()
		main_loop(win, buf, initial_grid)
	end, 0)
end

return M
