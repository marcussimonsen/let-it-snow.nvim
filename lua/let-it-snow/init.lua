local settings = require("let-it-snow.settings")
local snow = require("let-it-snow.snow")

local M = {}

-- TODO: Add setting for delay between updates
-- TODO: Add settings for chars used to display snow
M.setup = function (opts)
    settings._create_commands()
end

M.let_it_snow = function ()
    snow._let_it_snow()
end

return M
