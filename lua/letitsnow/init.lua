local settings = require("letitsnow.settings")
local snow = require("letitsnow.snow")

local M = {}

M.setup = function (opts)
    settings._create_commands()
end

M.let_it_snow = function ()
    snow._let_it_snow()
end

return M
