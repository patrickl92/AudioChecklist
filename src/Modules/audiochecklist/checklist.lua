--- Represents a checklist.
-- Each checklist contains an array of checklist items and an active checklist item. The active checklist item indicates the currently executed checklist item.
--
-- Callbacks can be added to react to the checklist getting started, stopped and completed.
-- @classmod checklist
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local checklist = {
    stateNotStarted = 0,
    stateInProgress = 1,
    stateCompleted = 2
}

local utils = require "audiochecklist.utils"

--- Executes an array of callbacks.
-- @tparam tab callbacks The callbacks array to execute.
local function executeCallbacks(callbacks)
    for _, callback in ipairs(callbacks) do
        callback()
    end
end

--- Creates a new checklist.
-- @tparam string title The title of the checklist.
-- @treturn checklist The created checklist.
function checklist:new(title)
    utils.verifyType("title", title, "string")

    checklist.__index = checklist

    local obj = {}
    setmetatable(obj, checklist)

    obj.title = title
    obj.state = checklist.stateNotStarted
    obj.items = {}
    obj.activeItemNumber = 1
    obj.startedCallbacks = {}
    obj.cancelledCallbacks = {}
    obj.completedCallbacks = {}

    return obj
end

--- Gets the title of the checklist.
-- @treturn string The title of the checklist.
function checklist:getTitle()
    return self.title
end

--- Sets the state of the checklist.
-- @tparam number state The new state.
function checklist:setState(state)
    utils.verifyType("state", state, "number")
    self.state = state
end

--- Gets the current state of the checklist.
-- @treturn number state The state of the checklist.
function checklist:getState()
    return self.state
end

--- Adds an item to the checklist.
-- @tparam checklistItem checklistItem The item to add.
function checklist:addItem(checklistItem)
    utils.verifyNotNil("checklistItem", checklistItem)
    table.insert(self.items, checklistItem)
end

--- Gets all items of the checklist.
-- @treturn tab An array which contains all checklist items.
function checklist:getAllItems()
    return self.items
end

--- Gets the active checklist item.
-- @treturn ?checklistItem The active checklist item.
function checklist:getActiveItem()
    return self.items[self.activeItemNumber]
end

--- Sets the active checklist item number.
-- @tparam number itemNumber The new active checklist item number.
-- @raise An error is thrown if the itemNumber does not point to an existing item.
function checklist:setActiveItemNumber(itemNumber)
    utils.verifyType("itemNumber", itemNumber, "number")

    if itemNumber < 1 or itemNumber > #self.items then
        error("itemNumber must point to an existing item")
    end

    self.activeItemNumber = itemNumber
end

--- Checks whether there is another checklist item after the active checklist item.
-- @treturn bool <code>True</code> if there are still checklist items left, otherwise <code>false</code>.
function checklist:hasNextItem()
    return self.activeItemNumber < #self.items
end

--- Activates the next checklist item.
-- If there is no checklist item after the current active checklist item, then the active checklist item becomes <code>nil</code>.
-- @raise An error is thrown if the active item is the last item
function checklist:setNextItemActive()
    if not self:hasNextItem() then
        error("The active item is the last item")
    end

    self.activeItemNumber = self.activeItemNumber + 1
end

--- Resets the state of the checklist and its checklist items.
-- The active checklist item is set to the first checklist item.
function checklist:reset()
    self:setState(checklist.stateNotStarted)
    self:setActiveItemNumber(1)

    for _, checklistItem in ipairs(self.items) do
        checklistItem:reset()
    end
end

--- Adds a callback which is executed if the checklist is started.
-- @tparam func callback The callback to add.
-- @usage myChecklist:addStartedCallback(function() end)
function checklist:addStartedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.startedCallbacks, callback)
end

--- Adds a callback which is executed if the checklist is cancelled.
-- @tparam func callback The callback to add.
-- @usage myChecklist:addCancelledCallback(function() end)
function checklist:addCancelledCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.cancelledCallbacks, callback)
end

--- Adds a callback which is executed if the checklist is completed.
-- @tparam func callback The callback to add.
-- @usage myChecklist:addCompletedCallback(function() end)
function checklist:addCompletedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.completedCallbacks, callback)
end

--- Executes the started callbacks.
function checklist:onStarted()
    executeCallbacks(self.startedCallbacks)
end

--- Executes the cancelled callbacks.
function checklist:onCancelled()
    executeCallbacks(self.cancelledCallbacks)
end

--- Executes the completed callbacks.
function checklist:onCompleted()
    executeCallbacks(self.completedCallbacks)
end

return checklist
