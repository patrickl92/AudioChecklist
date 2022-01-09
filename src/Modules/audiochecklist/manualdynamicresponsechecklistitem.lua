--- Inherits from the manualChecklistItem class and provides a dynamic key for the response sound.
-- It uses a callback to get the actual key for the response sound.
-- @classmod manualDynamicResponseChecklistItem
-- @see manualChecklistItem
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local manualDynamicResponseChecklistItem = {}

local manualChecklistItem = require "audiochecklist.manualchecklistitem"
local utils = require "audiochecklist.utils"

--- Creates a checklist item, which needs to be set to completed manually.
-- @tparam string challengeText The challenge text of the checklist item.
-- @tparam string responseText The response text of the checklist item.
-- @tparam string challengeKey The key of the challenge sound.
-- @tparam func responseKeyFunction The function to get the key of the response sound to use.
-- @treturn manualDynamicResponseChecklistItem The created checklist item.
function manualDynamicResponseChecklistItem:new(challengeText, responseText, challengeKey, responseKeyFunction)
    utils.verifyType("responseKeyFunction", responseKeyFunction, "function")

    manualDynamicResponseChecklistItem.__index = manualDynamicResponseChecklistItem
    setmetatable(manualDynamicResponseChecklistItem, {
        __index = manualChecklistItem
    })

    local obj = manualChecklistItem:new(challengeText, responseText, challengeKey)
    setmetatable(obj, manualDynamicResponseChecklistItem)

    obj.responseKeyFunction = responseKeyFunction

    return obj
end

--- Gets the key of the response sound.
-- @treturn ?string The key of the response sound.
function manualDynamicResponseChecklistItem:getResponseKey()
    return self.responseKeyFunction()
end

return manualDynamicResponseChecklistItem
