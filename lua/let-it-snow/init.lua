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
		vim.notify(("Already snowing in buffer %d"):format(buf), vim.log.levels.WARN)
		return
	end
	snow._let_it_snow()
end

return M
