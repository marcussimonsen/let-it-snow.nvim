local settings = require("let-it-snow.settings")

local M = {}

local ns_id = vim.api.nvim_create_namespace(settings.settings.namespace)

-- TODO: This doesn't seem to belong here
local end_command_str = "EndHygge"

M.running = {}

local function clear_snow(buf)
	local marks = vim.api.nvim_buf_get_extmarks(buf, ns_id, 0, -1, {})
	for _, mark in ipairs(marks) do
		vim.api.nvim_buf_del_extmark(buf, ns_id, mark[1])
	end
end

local function table_empty(t)
	for _, _ in pairs(t) do
		return false
	end
	return true
end

M.end_hygge = function(buf)
	M.running[buf] = nil

	if table_empty(M.running) then
		vim.api.nvim_buf_del_user_command(buf, end_command_str)
	end
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
	local snowpile_obstructed = grid[row][col] == #settings.settings.snowpile_chars
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
		virt_text = { { settings.settings.snowflake_char, settings.settings.highlight_group_name_snowflake } },
		virt_text_win_col = col,
	})
end

local function show_snowpile(buf, row, col, size)
	assert(
		size <= #settings.settings.snowpile_chars,
		string.format("Exceeded max snowpile size (%d) at in buf %s: %d, %d", size, buf, row, col)
	)
	local icon = settings.settings.snowpile_chars[size]

	vim.api.nvim_buf_set_extmark(buf, ns_id, row, 0, {
		virt_text = { { icon, settings.settings.highlight_group_name_snowpile } },
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
    local height = math.min(#grid, #lines)

	for row = 0, height do
		for col = 0, #grid[row] do
			if grid[row][col] == 0 then
				goto continue
			end
			show_snow(buf, row, col, grid, lines)
			::continue::
		end
	end
end

local function spawn_snowflake_on_line(row, grid, lines)
	local x = nil
	local attempts = 0
	while x == nil or obstructed(row, x, lines, grid) do
		if attempts >= settings.settings.max_spawn_attempts then
			vim.notify(
				("Warning: Exceeded %d attempts in spawning a snowflake!\nStopping..."):format(
					settings.settings.max_spawn_attempts
				),
				vim.log.levels.WARN
			)
			return
		end
		x = math.random(0, #grid[0] - 1)
		attempts = attempts + 1
	end
	grid[row][x] = grid[row][x] + 1
end

local function spawn_snowflake(grid, lines)
	spawn_snowflake_on_line(0, grid, lines)
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
	if -- Fall 1 down 1 to the side
		inside_grid(row + 1, col + d, new_grid)
		and old_grid[row + 1][col + d] <= old_grid[row][col] - 2
		and not obstructed(row, col + d, lines, new_grid)
		and not obstructed(row + 1, col + d, lines, new_grid)
	then
		new_grid[row + 1][col + d] = new_grid[row + 1][col + d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
	elseif -- Other side
		inside_grid(row + 1, col - d, new_grid)
		and old_grid[row + 1][col - d] <= old_grid[row][col] - 2
		and not obstructed(row, col - d, lines, new_grid)
		and not obstructed(row + 1, col - d, lines, new_grid)
	then
		new_grid[row + 1][col - d] = new_grid[row + 1][col - d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
		-- FIX: Don't fall sideways when in pile and can't fall diagonal
	elseif -- Fall 1 to the side
		inside_grid(row, col + d, new_grid)
		and old_grid[row][col + d] <= old_grid[row][col] - 3
		and not obstructed(row, col + d, lines, new_grid)
	then
		new_grid[row][col + d] = new_grid[row][col + d] + 1
		new_grid[row][col] = new_grid[row][col] + old_grid[row][col] - 1
	elseif -- Other side
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
	local start = os.clock() * 1000
	local lines = get_lines(buf)

	clear_snow(buf)
	show_grid(buf, grid, lines)

	grid = update_grid(win, buf, grid, lines)

	local wait_time = math.max(0, settings.settings.delay - (os.clock() * 1000 - start))

	if M.running[buf] then
		vim.defer_fn(function()
			main_loop(win, buf, grid)
		end, wait_time)
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
	local lines = get_lines(buf)

	-- Fill initial_grid with snow
	for row = 0, height - 1 do
		spawn_snowflake_on_line(row, initial_grid, lines)
	end

	vim.api.nvim_buf_create_user_command(buf, end_command_str, function()
		M.end_hygge(buf)
	end, {})

	M.running[buf] = true

	vim.defer_fn(function()
		main_loop(win, buf, initial_grid)
	end, 0)
end

return M
