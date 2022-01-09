describe("ManualDynamicResponseChecklistItem", function()
    local manualDynamicResponseChecklistItem

    local function createItem()
        return manualDynamicResponseChecklistItem:new("Challenge Text", "Response Text", "Challenge Key", function() return "Response Key" end)
    end

    setup(function()
        manualDynamicResponseChecklistItem = require "audiochecklist.manualdynamicresponsechecklistitem"
    end)

    teardown(function()
        manualDynamicResponseChecklistItem = nil
    end)

    it("should initialize a new checklist", function()
        local checklistItem = createItem()

        assert.are.equal("Challenge Text", checklistItem:getChallengeText())
        assert.are.equal("Response Text", checklistItem:getResponseText())
        assert.are.equal("Challenge Key", checklistItem:getChallengeKey())
        assert.are.equal("Response Key", checklistItem:getResponseKey())
        assert.is_true(checklistItem:hasResponse())
        assert.is_true(checklistItem:isManualItem())
        assert.is_true(checklistItem:evaluate())
        assert.are.equal(manualDynamicResponseChecklistItem.stateNotStarted, checklistItem:getState())
    end)

    it("should throw an error if not initialized correctly", function()
        local checklistItem = createItem()

        assert.has_error(function() checklistItem:new(nil, "", "", function() return "" end) end, "challengeText must be a string")
        assert.has_error(function() checklistItem:new(0, "", "", function() return "" end) end, "challengeText must be a string")
        assert.has_error(function() checklistItem:new("", nil, "", function() return "" end) end, "responseText must be a string")
        assert.has_error(function() checklistItem:new("", 0, "", function() return "" end) end, "responseText must be a string")
        assert.has_error(function() checklistItem:new("", "", nil, function() return "" end) end, "challengeKey must be a string")
        assert.has_error(function() checklistItem:new("", "", 0, function() return "" end) end, "challengeKey must be a string")
        assert.has_error(function() checklistItem:new("", "", "", nil) end, "responseKeyFunction must be a function")
        assert.has_error(function() checklistItem:new("", "", "", "") end, "responseKeyFunction must be a function")
    end)

    it("should return the response key based on the response key function", function()
        local returnValue
        local checklistItem = manualDynamicResponseChecklistItem:new("Challenge Text", "Response Text", "Challenge Key", function() return returnValue end)

        returnValue = "Key1"
        assert.are.equal("Key1", checklistItem:getResponseKey())

        returnValue = "Key2"
        assert.are.equal("Key2", checklistItem:getResponseKey())

        returnValue = nil
        assert.is_nil(checklistItem:getResponseKey())

        returnValue = true
        assert.is_true(checklistItem:getResponseKey())
    end)

    it("should set its state", function()
        local checklistItem = createItem()

        checklistItem:setState(manualDynamicResponseChecklistItem.stateInProgress)
        assert.are.equal(manualDynamicResponseChecklistItem.stateInProgress, checklistItem:getState())

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

        checklistItem:setState(manualDynamicResponseChecklistItem.stateInProgress)
        checklistItem:reset(42)

        assert.are.equal(manualDynamicResponseChecklistItem.stateNotStarted, checklistItem:getState())
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