local M = {}

-- TODO: Add default settings

local commands = {
	{
		name = "LetItSnow",
		desc = "Let It Snow",
		func = "let_it_snow",
	},
}

M._create_commands = function()
	local let_it_snow = require("let-it-snow")
	for _, cmd in ipairs(commands) do
		vim.api.nvim_create_user_command(cmd.name, function()
			let_it_snow[cmd.func]()
		end, { desc = cmd.desc })
	end
end

return M
