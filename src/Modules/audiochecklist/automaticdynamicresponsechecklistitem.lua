--- Inherits from the automaticChecklistItem class and provides a dynamic key for the response sound.
-- It uses a callback to get the actual key for the response sound.
-- @classmod automaticDynamicResponseChecklistItem
-- @see automaticChecklistItem
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local automaticDynamicResponseChecklistItem = {}

local automaticChecklistItem = require "audiochecklist.automaticchecklistitem"
local utils = require "audiochecklist.utils"

--- Creates a checklist item, which will be completed automatically if the conditions are met.
-- @tparam string challengeText The challenge text of the checklist item.
-- @tparam string responseText The response text of the checklist item.
-- @tparam string challengeKey The key of the challenge sound.
-- @tparam func responseKeyFunction The function to get the key of the response sound to use.
-- @tparam func evaluateFunction The function to evaluate whether the conditions for the checklist item are met. If the function returns any value other than <code>true</code>, the conditions are considered as not met.
-- @treturn automaticDynamicResponseChecklistItem The created checklist item.
function automaticDynamicResponseChecklistItem:new(challengeText, responseText, challengeKey, responseKeyFunction, evaluateFunction)
    utils.verifyType("responseKeyFunction", responseKeyFunction, "function")

    automaticDynamicResponseChecklistItem.__index = automaticDynamicResponseChecklistItem
    setmetatable(automaticDynamicResponseChecklistItem, {
        __index = automaticChecklistItem
    })

    local obj = automaticChecklistItem:new(challengeText, responseText, challengeKey, evaluateFunction)
    setmetatable(obj, automaticDynamicResponseChecklistItem)

    obj.responseKeyFunction = responseKeyFunction

    return obj
end

--- Gets the key of the response sound.
-- @treturn ?string The key of the response sound.
function automaticDynamicResponseChecklistItem:getResponseKey()
    return self.responseKeyFunction()
end

return automaticDynamicResponseChecklistItem
