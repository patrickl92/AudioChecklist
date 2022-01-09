--- Implemention of a checklist item which only provides a challenge sound.
-- It can be used to play a sound that indicates the start or the end of a checklist.
-- @classmod soundChecklistItem
-- @see checklistItem
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local soundChecklistItem = {}

local checklistItem = require "audiochecklist.checklistitem"
local utils = require "audiochecklist.utils"

--- Creates a hidden checklist item, which will be completed auotmatically after the sound file has been played.
-- @tparam string challengeKey The key of the challenge sound.
-- @treturn soundChecklistItem The created checklist item.
function soundChecklistItem:new(challengeKey)
    utils.verifyType("challengeKey", challengeKey, "string")

    soundChecklistItem.__index = soundChecklistItem
    setmetatable(soundChecklistItem, {
        __index = checklistItem
    })

    local obj = checklistItem:new()
    setmetatable(obj, soundChecklistItem)

    obj.challengeKey = challengeKey

    return obj
end

--- Gets the key of the challenge sound.
-- @treturn string The key of the challenge sound.
function soundChecklistItem:getChallengeKey()
    return self.challengeKey
end

--- Checks whether the conditions of the checklist items are met.
-- @treturn bool Always <code>true</code>.
function soundChecklistItem:evaluate()
    return true
end

return soundChecklistItem
