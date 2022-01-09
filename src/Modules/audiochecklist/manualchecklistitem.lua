--- Implemention of a checklist item which needs to be competed manually.
-- @classmod manualChecklistItem
-- @see checklistItem
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local manualChecklistItem = {}

local checklistItem = require "audiochecklist.checklistitem"
local utils = require "audiochecklist.utils"

--- Creates a checklist item, which needs to be set to completed manually.
-- @tparam string challengeText The challenge text of the checklist item.
-- @tparam string responseText The response text of the checklist item, which is also used as the key of the response sound.
-- @tparam string challengeKey The key of the challenge sound.
-- @treturn manualChecklistItem The created checklist item.
function manualChecklistItem:new(challengeText, responseText, challengeKey)
    utils.verifyType("challengeText", challengeText, "string")
    utils.verifyType("responseText", responseText, "string")
    utils.verifyType("challengeKey", challengeKey, "string")

    manualChecklistItem.__index = manualChecklistItem
    setmetatable(manualChecklistItem, {
        __index = checklistItem
    })

    local obj = checklistItem:new()
    setmetatable(obj, manualChecklistItem)

    obj.challengeText = challengeText
    obj.responseText = responseText
    obj.challengeKey = challengeKey

    return obj
end

--- Gets the challenge text of the checklist item.
-- @treturn string The challenge text of the checklist item.
function manualChecklistItem:getChallengeText()
    return self.challengeText
end

--- Gets the response text of the checklist item.
-- @treturn string The response text of the checklist item.
function manualChecklistItem:getResponseText()
    return self.responseText
end

--- Gets the key of the challenge sound.
-- @treturn string The key of the challenge sound.
function manualChecklistItem:getChallengeKey()
    return self.challengeKey
end

--- Gets the key of the response sound.
-- The response text is used as the key of the response sound.
-- @treturn string The response text of the response sound.
function manualChecklistItem:getResponseKey()
    return self.responseText
end

--- Checks whether the checklist item has a response.
-- @treturn bool Always <code>true</code>.
function manualChecklistItem:hasResponse()
    return true
end

--- Checks whether the checklist item needs to be completed manually.
-- @treturn bool Always <code>true</code>.
function manualChecklistItem:isManualItem()
    return true
end

return manualChecklistItem
