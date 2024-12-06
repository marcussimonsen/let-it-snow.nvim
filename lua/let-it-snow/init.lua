local settings = require("let-it-snow.settings")
local snow = require("let-it-snow.snow")

local M = {}

M.setup = function(opts)
	settings._update_settings(opts)
	if settings.settings.create_highlight_groups then
		settings._create_hl_groups()
	end
	settings._create_commands()
end

M.let_it_snow = function()
	local buf = vim.api.nvim_get_current_buf()
	if snow.running[buf] then
		snow.stop_snow(buf)
	else
		snow._let_it_snow()
	end
end

M.stop_snow = function()
	local buf = vim.api.nvim_get_current_buf()
	if snow.running[buf] then
		snow._stop_snow(buf)
	end
end

M.stop_snow_all = function()
	for buf in pairs(snow.running) do
		snow._stop_snow(buf)
	end
end

M.is_running_in_buf = function(buf)
	return snow.running[buf] ~= nil
end

M.is_running = function()
	local buf = vim.api.nvim_get_current_buf()
	return M.is_running_in_buf(buf)
end

return M
