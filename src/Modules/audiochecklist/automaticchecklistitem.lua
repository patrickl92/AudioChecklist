--- Implemention of a checklist item which evaluates whether its conditions are met.
-- It uses a callback for the evaluation so that it can be utilized for different cases. The checklist item is completed automatically if the conditions are met.
-- @classmod automaticChecklistItem
-- @see checklistItem
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local automaticChecklistItem = {}

local checklistItem = require "audiochecklist.checklistitem"
local utils = require "audiochecklist.utils"

--- Creates a checklist item, which will be completed automatically if the conditions are met.
-- @tparam string challengeText The challenge text of the checklist item.
-- @tparam string responseText The response text of the checklist item, which is also used as the key of the response sound.
-- @tparam string challengeKey The key of the challenge sound..
-- @tparam func evaluateFunction The function to evaluate whether the conditions for the checklist item are met. If the function returns any value other than <code>true</code>, the conditions are considered as not met.
-- @treturn automaticChecklistItem The created checklist item.
function automaticChecklistItem:new(challengeText, responseText, challengeKey, evaluateFunction)
    utils.verifyType("challengeText", challengeText, "string")
    utils.verifyType("responseText", responseText, "string")
    utils.verifyType("challengeKey", challengeKey, "string")
    utils.verifyType("evaluateFunction", evaluateFunction, "function")

    automaticChecklistItem.__index = automaticChecklistItem
    setmetatable(automaticChecklistItem, {
        __index = checklistItem
    })

    local obj = checklistItem:new()
    setmetatable(obj, automaticChecklistItem)

    obj.challengeText = challengeText
    obj.responseText = responseText
    obj.challengeKey = challengeKey
    obj.evaluateFunction = evaluateFunction

    return obj
end

--- Gets the challenge text of the checklist item.
-- @treturn string The challenge text of the checklist item.
function automaticChecklistItem:getChallengeText()
    return self.challengeText
end

--- Gets the response text of the checklist item.
-- @treturn string The response text of the checklist item.
function automaticChecklistItem:getResponseText()
    return self.responseText
end

--- Gets the key of the challenge sound.
-- @treturn string The key of the challenge sound.
function automaticChecklistItem:getChallengeKey()
    return self.challengeKey
end

--- Gets the key of the response sound.
-- The response text is used as the key of the response sound.
-- @treturn string The response text of the response sound.
function automaticChecklistItem:getResponseKey()
    return self.responseText
end

--- Checks whether the checklist item has a response.
-- @treturn bool Always <code>true</code>.
function automaticChecklistItem:hasResponse()
    return true
end

--- Checks whether the conditions of the checklist items are met.
-- @treturn bool <code>True</code> if the evaluation callback returns <code>true</code>, otherwise <code>false</code>.
function automaticChecklistItem:evaluate()
    return self.evaluateFunction() == true
end

return automaticChecklistItem
