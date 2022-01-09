--- Acts as an interface for a checklist item implementation.
-- A checklist item can have a challenge and resposne text, which are displayed in the UI. These are optional, however if the checklist item has a response, the challenge and response texts are required.
--
-- The challenge and response sounds are referenced by a key. The challenge sound key is required for each checklist item. The response sound key is only required if the checklist item provides a response text.
--
-- If a checklist item does not have a response, it is not displayed in the UI. Instead, only the challenge sound is played and then it is completed automatically.
--
-- A checklist item can either evaluate itself if its conditions are met or it can indicate that it needs to be completed manually (e.g. by the user or by some external trigger).
--
-- Callbacks can be added to react to the checklist item getting started, failed and completed.
-- @classmod checklistItem
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local checklistItem = {
    stateNotStarted = 0,
    stateInProgress = 1,
    stateSuccess = 2,
    stateFailed = 3,
    stateDoneManually = 4
}

local utils = require "audiochecklist.utils"

--- Executes an array of callbacks.
-- @tparam tab callbacks The callbacks array to execute.
local function executeCallbacks(callbacks)
    for _, callback in ipairs(callbacks) do
        callback()
    end
end

--- Creates a new checklist item.
-- @treturn checklistItem The created checklist item.
function checklistItem:new()
    checklistItem.__index = checklistItem

    local obj = {}
    setmetatable(obj, checklistItem)

    obj.state = checklistItem.stateNotStarted
    obj.startedCallbacks = {}
    obj.failedCallbacks = {}
    obj.completedCallbacks = {}

    return obj
end

--- Gets the challenge text of the checklist item.
-- This function can be implemented in a derived checklist item class.
-- @treturn ?string Always <code>nil</code>.
function checklistItem:getChallengeText()
    return nil
end

--- Gets the response text of the checklist item.
-- This function can be implemented in a derived checklist item class.
-- @treturn ?string Always <code>nil</code>.
function checklistItem:getResponseText()
    return nil
end

--- Gets the key of the challenge sound.
-- This function can be implemented in a derived checklist item class.
-- @treturn ?string Always <code>nil</code>.
function checklistItem:getChallengeKey()
    return nil
end

--- Gets the key of the response sound.
-- This function can be implemented in a derived checklist item class.
-- @treturn ?string Always <code>nil</code>.
function checklistItem:getResponseKey()
    return nil
end

--- Checks whether the checklist item has a response
-- This function can be implemented in a derived checklist item class.
-- @treturn bool Always <code>false</code>.
function checklistItem:hasResponse()
    return false
end

--- Checks whether the checklist item needs to be completed manually.
-- This function can be implemented in a derived checklist item class.
-- @treturn bool Always <code>false</code>.
function checklistItem:isManualItem()
    return false
end

--- Checks whether the conditions of the checklist items are met.
-- This function can be implemented in a derived checklist item class.
-- @treturn bool Always <code>true</code>.
function checklistItem:evaluate()
    return true
end

--- Sets the state of the checklist item.
-- @tparam number state The new state.
function checklistItem:setState(state)
    utils.verifyType("state", state, "number")
    self.state = state
end

--- Gets the current state of the checklist item.
-- @treturn number The current state.
function checklistItem:getState()
    return self.state
end

--- Resets the state of the checklist item.
function checklistItem:reset()
    self:setState(checklistItem.stateNotStarted)
end

--- Adds a callback which is executed if the checklist item is started.
-- @tparam func callback The callback to add.
-- @usage myChecklistItem:addStartedCallback(function() end)
function checklistItem:addStartedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.startedCallbacks, callback)
end

--- Adds a callback which is executed if the checklist item has failed.
-- @tparam func callback The callback to add.
-- @usage myChecklistItem:addFailedCallback(function() end)
function checklistItem:addFailedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.failedCallbacks, callback)
end

--- Adds a callback which is executed if the checklist item is completed.
-- @tparam func callback The callback to add.
-- @usage myChecklistItem:addCompletedCallback(function() end)
function checklistItem:addCompletedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.completedCallbacks, callback)
end

--- Executes the started callbacks.
function checklistItem:onStarted()
    executeCallbacks(self.startedCallbacks)
end

--- Executes the failed callbacks.
function checklistItem:onFailed()
    executeCallbacks(self.failedCallbacks)
end

--- Executes the completed callbacks.
function checklistItem:onCompleted()
    executeCallbacks(self.completedCallbacks)
end

return checklistItem