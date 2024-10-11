local M = {}

local commands = {
	{
		name = "LetItSnow",
		desc = "Let It Snow",
		func = "let_it_snow",
	},
}

M._create_commands = function()
	local letitsnow = require("letitsnow")
	for _, cmd in ipairs(commands) do
		vim.api.nvim_create_user_command(cmd.name, function()
			letitsnow[cmd.func]()
		end, { desc = cmd.desc })
	end
end

return M
