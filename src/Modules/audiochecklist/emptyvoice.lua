--- Implementation of a voice which does not play any sound.
-- @classmod emptyvoice
-- @see voice
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local emptyvoice = {}

local voice = require "audiochecklist.voice"

--- Creates a new voice.
-- @tparam string name The name of the voice.
-- @treturn emptyvoice The created voice
function emptyvoice:new(name)
    emptyvoice.__index = emptyvoice
    setmetatable(emptyvoice, {
        __index = voice
    })

    local obj = voice:new(name)
    setmetatable(obj, emptyvoice)

    return obj
end

return emptyvoice
