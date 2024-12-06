local M = {}

local DEFAULT_SETTINGS = {
	---@type integer Delay between updates
	delay = 500,
	---@type string Single character used to represent snowflakes
	snowflake_char = "\u{2744}",
	---@type string[] Array of single character used to represent snow (in order of least to most)
	snowpile_chars = {
		[1] = "\u{2581}",
		[2] = "\u{2582}",
		[3] = "\u{2583}",
		[4] = "\u{2584}",
		[5] = "\u{2585}",
		[6] = "\u{2586}",
		[7] = "\u{2587}",
		[8] = "\u{2588}",
	},
	---@type integer Max attempts at spawning a snowfile
	max_spawn_attempts = 500,
	---@type boolean Whether to create highlight groups or not
	create_highlight_groups = true,
	---@type string Name of namespace to use for extmarks (you probably don't need to change this)
	namespace = "let-it-snow",
	---@type string Name of highlight group to use for snowflakes
	highlight_group_name_snowflake = "snowflake",
	---@type string Name of highlight group to use for snowpiles
	highlight_group_name_snowpile = "snowpile",
}

M.settings = DEFAULT_SETTINGS

local COMMANDS = {
	{
		name = "LetItSnow",
		desc = "Let It Snow",
		func = "let_it_snow",
	},
	{
		name = "LetItSnowStop",
		desc = "Stop Snow",
		func = "stop_snow",
	},
	{
		name = "LetItSnowStopAll",
		desc = "Stop snow in all buffers",
		func = "stop_snow_all",
	},
}

M._create_commands = function()
	local let_it_snow = require("let-it-snow.init")
	for _, cmd in ipairs(COMMANDS) do
		vim.api.nvim_create_user_command(cmd.name, function()
			let_it_snow[cmd.func]()
		end, { desc = cmd.desc })
	end
end

M._create_hl_groups = function()
	vim.api.nvim_set_hl(0, M.settings.highlight_group_name_snowflake, { fg = "#ffffff" })
	vim.api.nvim_set_hl(0, M.settings.highlight_group_name_snowpile, { fg = "#ffffff" })
end

M._update_settings = function(opts)
	opts = opts or {}

	for setting, value in pairs(opts) do
		M.settings[setting] = value
	end
end

return M
