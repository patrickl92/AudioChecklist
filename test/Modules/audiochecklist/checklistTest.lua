describe("Checklist", function()
    local checklist
    local checklistItem

    local function createChecklist()
        return checklist:new("My checklist")
    end

    setup(function()
        checklist = require "audiochecklist.checklist"
        checklistItem = require "audiochecklist.checklistitem"
    end)

    teardown(function()
        checklist = nil
        checklistItem = nil
    end)

    it("should initialize a new checklist", function()
        local checklist = createChecklist()

        assert.are.equal("My checklist", checklist:getTitle())
        assert.are.equal(checklist.stateNotStarted, checklist:getState())
        assert.are.equal(0, #checklist:getAllItems())
        assert.is_nil(checklist:getActiveItem())
    end)

    it("should thrown an error if the title is invalid", function()
        assert.has_error(function() checklist:new(nil) end, "title must be a string")
        assert.has_error(function() checklist:new(0) end, "title must be a string")
    end)

    it("should set its state", function()
        local checklist = createChecklist()

        checklist:setState(checklist.stateInProgress)
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        checklist:setState(42)
        assert.are.equal(42, checklist:getState())
    end)

    it("should throw an error if an invalid state is set", function()
        local checklist = createChecklist()
        assert.has_error(function() checklist:setState(nil) end, "state must be a number")
        assert.has_error(function() checklist:setState("") end, "state must be a number")
    end)

    it("should add the checklist items and set the first added item as the active item", function()
        local checklist = createChecklist()
        local checklistItem1 = checklistItem:new()
        local checklistItem2 = checklistItem:new()

        checklist:addItem(checklistItem1)
        checklist:addItem(checklistItem2)

        local checklistItems = checklist:getAllItems()
        assert.are.equal(2, #checklistItems)
        assert.are.equal(checklistItem1, checklistItems[1])
        assert.are.equal(checklistItem2, checklistItems[2])
        assert.are.equal(checklistItem1, checklist:getActiveItem())
    end)

    it("should set the active item by its number", function()
        local checklist = createChecklist()
        local checklistItem1 = checklistItem:new()
        local checklistItem2 = checklistItem:new()

        checklist:addItem(checklistItem1)
        checklist:addItem(checklistItem2)
        checklist:setActiveItemNumber(2)

        assert.are.equal(checklistItem2, checklist:getActiveItem())
    end)

    it("should throw an error if the active item number is invalid", function()
        local checklist = createChecklist()
        local checklistItem1 = checklistItem:new()
        local checklistItem2 = checklistItem:new()

        checklist:addItem(checklistItem1)
        checklist:addItem(checklistItem2)

        assert.has_error(function() checklist:setActiveItemNumber(nil) end, "itemNumber must be a number")
        assert.has_error(function() checklist:setActiveItemNumber("") end, "itemNumber must be a number")
        assert.has_error(function() checklist:setActiveItemNumber(0) end, "itemNumber must point to an existing item")
        assert.has_error(function() checklist:setActiveItemNumber(3) end, "itemNumber must point to an existing item")
    end)

    it("should set the next item", function()
        local checklist = createChecklist()
        local checklistItem1 = checklistItem:new()
        local checklistItem2 = checklistItem:new()

        checklist:addItem(checklistItem1)
        checklist:addItem(checklistItem2)

        assert.is_true(checklist:hasNextItem())

        checklist:setNextItemActive()

        assert.are.equal(checklistItem2, checklist:getActiveItem())
        assert.is_false(checklist:hasNextItem())

        assert.has_error(function() checklist:setNextItemActive() end, "The active item is the last item")
    end)

    it("should reset itself and all checklist items", function()
        local checklist = createChecklist()
        local checklistItem1 = checklistItem:new()
        local checklistItem2 = checklistItem:new()

        checklist:addItem(checklistItem1)
        checklist:addItem(checklistItem2)
        checklist:setState(checklist.stateInProgress)
        checklist:setActiveItemNumber(2)

        stub.new(checklistItem1, "reset")
        stub.new(checklistItem2, "reset")

        checklist:reset()

        assert.are.equal(checklist.stateNotStarted, checklist:getState())
        assert.are.equal(checklistItem1, checklist:getActiveItem())
        assert.stub(checklistItem1.reset).was.called(1)
        assert.stub(checklistItem2.reset).was.called(1)
    end)

    it("should execute the started callbacks", function()
        local checklist = createChecklist()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklist:addStartedCallback(function() callbackSpy1() end)
        checklist:addStartedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        checklist:onStarted()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the cancelled callbacks", function()
        local checklist = createChecklist()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklist:addCancelledCallback(function() callbackSpy1() end)
        checklist:addCancelledCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        checklist:onCancelled()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the completed callbacks", function()
        local checklist = createChecklist()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklist:addCompletedCallback(function() callbackSpy1() end)
        checklist:addCompletedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        checklist:onCompleted()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should not throw an error if there are no callbacks", function()
        local checklist = createChecklist()

        checklist:onStarted()
        checklist:onCancelled()
        checklist:onCompleted()
    end)

    it("should throw an error if an invalid callback is added", function()
        local checklist = createChecklist()

        assert.has_error(function() checklist:addStartedCallback(nil) end, "callback must be a function")
        assert.has_error(function() checklist:addStartedCallback(0) end, "callback must be a function")

        assert.has_error(function() checklist:addCancelledCallback(nil) end, "callback must be a function")
        assert.has_error(function() checklist:addCancelledCallback(0) end, "callback must be a function")

        assert.has_error(function() checklist:addCompletedCallback(nil) end, "callback must be a function")
        assert.has_error(function() checklist:addCompletedCallback(0) end, "callback must be a function")
    end)
end)