describe("ChecklistItem", function()
    local checklistItem

    local function createItem()
        return checklistItem:new()
    end

    setup(function()
        checklistItem = require "audiochecklist.checklistitem"
    end)

    teardown(function()
        checklistItem = nil
    end)

    it("should initialize a new checklist", function()
        local checklistItem = createItem()

        assert.is_nil(checklistItem:getChallengeText())
        assert.is_nil(checklistItem:getResponseText())
        assert.is_nil(checklistItem:getChallengeKey())
        assert.is_nil(checklistItem:getResponseKey())
        assert.is_false(checklistItem:hasResponse())
        assert.is_false(checklistItem:isManualItem())
        assert.is_true(checklistItem:evaluate())
        assert.are.equal(checklistItem.stateNotStarted, checklistItem:getState())
    end)

    it("should set its state", function()
        local checklistItem = createItem()

        checklistItem:setState(checklistItem.stateInProgress)
        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())

        checklistItem:setState(42)
        assert.are.equal(42, checklistItem:getState())
    end)

    it("should throw an error if an invalid state is set", function()
        local checklistItem = createItem()
        assert.has_error(function() checklistItem:setState(nil) end, "state must be a number")
        assert.has_error(function() checklistItem:setState("") end, "state must be a number")
    end)

    it("should reset its state", function()
        local checklistItem = createItem()

        checklistItem:setState(checklistItem.stateInProgress)
        checklistItem:reset(42)

        assert.are.equal(checklistItem.stateNotStarted, checklistItem:getState())
    end)

    it("should execute the started callbacks", function()
        local checklistItem = createItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklistItem:addStartedCallback(function() callbackSpy1() end)
        checklistItem:addStartedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        checklistItem:onStarted()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the failed callbacks", function()
        local checklistItem = createItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklistItem:addFailedCallback(function() callbackSpy1() end)
        checklistItem:addFailedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        checklistItem:onFailed()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the completed callbacks", function()
        local checklistItem = createItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklistItem:addCompletedCallback(function() callbackSpy1() end)
        checklistItem:addCompletedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        checklistItem:onCompleted()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should not throw an error if there are no callbacks", function()
        local checklistItem = createItem()

        checklistItem:onStarted()
        checklistItem:onFailed()
        checklistItem:onCompleted()
    end)

    it("should throw an error if an invalid callback is added", function()
        local checklistItem = createItem()

        assert.has_error(function() checklistItem:addStartedCallback(nil) end, "callback must be a function")
        assert.has_error(function() checklistItem:addStartedCallback(0) end, "callback must be a function")

        assert.has_error(function() checklistItem:addFailedCallback(nil) end, "callback must be a function")
        assert.has_error(function() checklistItem:addFailedCallback(0) end, "callback must be a function")

        assert.has_error(function() checklistItem:addCompletedCallback(nil) end, "callback must be a function")
        assert.has_error(function() checklistItem:addCompletedCallback(0) end, "callback must be a function")
    end)
end)