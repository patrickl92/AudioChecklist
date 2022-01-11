describe("SOPExecutor",function()
    local sopExecutor
    local utils
    local standardOperatingProcedure
    local checklist
    local checklistItem
    local voice
    local challengeVoice
    local responseVoice
    local challengeVoiceFinished
    local responseVoiceFinished

    local function createSOP()
        local sop = standardOperatingProcedure:new("Test SOP")
        local activeChecklist = nil

        stub.new(sop, "onActivated")
        stub.new(sop, "onDeactivated")
        stub.new(sop, "reset")
        stub.new(sop, "getActiveChallengeVoice", challengeVoice)
        stub.new(sop, "getActiveResponseVoice", responseVoice)
        stub.new(sop, "setActiveChecklist", function(_, checklist) activeChecklist = checklist end)
        stub.new(sop, "getActiveChecklist", function() return activeChecklist end)
        stub.new(sop, "doOften")
        stub.new(sop, "doEveryFrame")

        return sop
    end

    local function createChecklist()
        local checklist = checklist:new("Test Checklist")
        local state = checklist:getState()

        stub.new(checklist, "reset")
        stub.new(checklist, "setState", function(_, newState) state = newState end)
        stub.new(checklist, "getState", function() return state end)
        stub.new(checklist, "onStarted")
        stub.new(checklist, "onCancelled")
        stub.new(checklist, "onCompleted")

        return checklist
    end

    local function createChecklistItem()
        local checklistItem = checklistItem:new()
        local state = checklistItem:getState()

        stub.new(checklistItem, "reset")
        stub.new(checklistItem, "setState", function(_, newState) state = newState end)
        stub.new(checklistItem, "getState", function() return state end)
        stub.new(checklistItem, "evaluate", true)
        stub.new(checklistItem, "isManualItem", false)
        stub.new(checklistItem, "onStarted")
        stub.new(checklistItem, "onFailed")
        stub.new(checklistItem, "onCompleted")

        return checklistItem
    end

    local function createSoundChecklistItem()
        local checklistItem = createChecklistItem()

        stub.new(checklistItem, "getChallengeKey", "TheChallengeKey")
        stub.new(checklistItem, "hasResponse", false)

        return checklistItem
    end

    local function createAutomaticChecklistItem()
        local checklistItem = createChecklistItem()

        stub.new(checklistItem, "getChallengeKey", "TheChallengeKey")
        stub.new(checklistItem, "getResponseKey", "TheResponseKey")
        stub.new(checklistItem, "hasResponse", true)

        return checklistItem
    end

    local function createManualChecklistItem()
        local checklistItem = createChecklistItem()

        stub.new(checklistItem, "getChallengeKey", "TheChallengeKey")
        stub.new(checklistItem, "getResponseKey", "TheResponseKey")
        stub.new(checklistItem, "hasResponse", true)
        stub.new(checklistItem, "isManualItem", true)

        return checklistItem
    end

    local function createChallengeVoice()
        local voice = voice:new("TestChallengeVoice")

        stub.new(voice, "activateChallengeSounds")
        stub.new(voice, "deactivateChallengeSounds")
        stub.new(voice, "activateResponseSounds", function() error("Should not call activateResponseSounds on challenge voice") end)
        stub.new(voice, "deactivateResponseSounds", function() error("Should not call deactivateResponseSounds on challenge voice") end)
        stub.new(voice, "playChallengeSound")
        stub.new(voice, "playResponseSound", function() error("Should not call playResponseSound on challenge voice") end)
        stub.new(voice, "playFailSound", function() error("Should not call playFailSound on challenge voice") end)
        stub.new(voice, "pause")
        stub.new(voice, "resume")
        stub.new(voice, "stop")
        stub.new(voice, "isFinished", true)

        return voice
    end

    local function createResponseVoice()
        local voice = voice:new("TestResponseVoice")

        stub.new(voice, "activateChallengeSounds", function() error("Should not call activateChallengeSounds on response voice") end)
        stub.new(voice, "deactivateChallengeSounds", function() error("Should not call deactivateChallengeSounds on response voice") end)
        stub.new(voice, "activateResponseSounds")
        stub.new(voice, "deactivateResponseSounds")
        stub.new(voice, "playChallengeSound", function() error("Should not call playChallengeSound on response voice") end)
        stub.new(voice, "playResponseSound")
        stub.new(voice, "playFailSound")
        stub.new(voice, "pause")
        stub.new(voice, "resume")
        stub.new(voice, "stop")
        stub.new(voice, "isFinished", true)

        return voice
    end

    setup(function()
        sopExecutor = require "audiochecklist.sopexecutor"
        utils = require "audiochecklist.utils"
        standardOperatingProcedure = require "audiochecklist.standardoperatingprocedure"
        checklist = require "audiochecklist.checklist"
        checklistItem = require "audiochecklist.checklistitem"
        voice = require "audiochecklist.voice"

        stub.new(utils, "logDebug")
    end)

    teardown(function()
        sopExecutor = nil
        utils = nil
        standardOperatingProcedure = nil
        checklist = nil
        checklistItem = nil
        voice = nil
    end)

    before_each(function()
        challengeVoiceFinished = true
        responseVoiceFinished = true

        challengeVoice = createChallengeVoice()
        responseVoice = createResponseVoice()

        stub.new(challengeVoice, "playChallengeSound", function() challengeVoiceFinished = false end)
        stub.new(challengeVoice, "isFinished", function() return challengeVoiceFinished end)
        stub.new(responseVoice, "playResponseSound", function() responseVoiceFinished = false end)
        stub.new(responseVoice, "playFailSound", function() responseVoiceFinished = false end)
        stub.new(responseVoice, "isFinished", function() return responseVoiceFinished end)
    end)

    after_each(function()
        challengeVoiceFinished = false
        responseVoiceFinished = false
        challengeVoice = nil
        responseVoice = nil

        sopExecutor.setActiveSOP(nil)
    end)

    it("should activate and deactivate the SOP", function()
        local sop = createSOP()

        sopExecutor.setActiveSOP(sop)

        assert.stub(sop.reset).was.called(1)
        assert.stub(sop.onActivated).was.called(1)
        assert.stub(challengeVoice.activateChallengeSounds).was.called(1)
        assert.stub(responseVoice.activateResponseSounds).was.called(1)

        assert.stub(sop.onDeactivated).was_not_called()
        assert.stub(challengeVoice.deactivateChallengeSounds).was_not_called()
        assert.stub(responseVoice.deactivateResponseSounds).was_not_called()

        sopExecutor.setActiveSOP(nil)

        assert.stub(sop.reset).was.called(2)
        assert.stub(sop.onDeactivated).was.called(1)
        assert.stub(challengeVoice.deactivateChallengeSounds).was.called(1)
        assert.stub(responseVoice.deactivateResponseSounds).was.called(1)
    end)

    it("should switch between SOPs", function()
        local sop1 = createSOP()
        local sop2 = createSOP()

        local challengeVoice2 = createChallengeVoice()
        local responseVoice2 = createResponseVoice()

        stub.new(sop2, "getActiveChallengeVoice", challengeVoice2)
        stub.new(sop2, "getActiveResponseVoice", responseVoice2)

        sopExecutor.setActiveSOP(sop1)

        assert.stub(sop1.reset).was.called(1)
        assert.stub(sop1.onActivated).was.called(1)
        assert.stub(challengeVoice.activateChallengeSounds).was.called(1)
        assert.stub(responseVoice.activateResponseSounds).was.called(1)

        sopExecutor.setActiveSOP(sop2)

        assert.stub(sop1.reset).was.called(2)
        assert.stub(sop1.onDeactivated).was.called(1)
        assert.stub(challengeVoice.deactivateChallengeSounds).was.called(1)
        assert.stub(responseVoice.deactivateResponseSounds).was.called(1)

        assert.stub(sop2.reset).was.called(1)
        assert.stub(sop2.onActivated).was.called(1)
        assert.stub(challengeVoice2.activateChallengeSounds).was.called(1)
        assert.stub(responseVoice2.activateResponseSounds).was.called(1)

        sopExecutor.setActiveSOP(nil)

        assert.stub(sop2.reset).was.called(2)
        assert.stub(sop2.onDeactivated).was.called(1)
        assert.stub(challengeVoice2.deactivateChallengeSounds).was.called(1)
        assert.stub(responseVoice2.deactivateResponseSounds).was.called(1)
    end)

    it("should not throw an error if nil is passed when no SOP is active", function()
        sopExecutor.setActiveSOP(nil)
    end)

    it("should throw an error if the SOP does not have an active challenge voice", function()
        local sop = createSOP()
        stub.new(sop, "getActiveChallengeVoice", nil)
        assert.has_error(function() sopExecutor.setActiveSOP(sop) end, "SOP does not have an active challenge voice set")
    end)

    it("should throw an error if the SOP does not have an active response voice", function()
        local sop = createSOP()
        stub.new(sop, "getActiveResponseVoice", nil)
        assert.has_error(function() sopExecutor.setActiveSOP(sop) end, "SOP does not have an active response voice set")
    end)

    it("should return the active SOP", function()
        local sop = createSOP()
        sopExecutor.setActiveSOP(sop)

        assert.are.equal(sop, sopExecutor.getActiveSOP())

        sopExecutor.setActiveSOP(nil)

        assert.is_nil(sopExecutor.getActiveSOP())
    end)

    it("should start a checklist", function()
        local sop = createSOP()
        local checklist = createChecklist()

        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        assert.stub(sop.setActiveChecklist).was.called(1)
        assert.stub(sop.setActiveChecklist).was.called_with(sop, checklist)
        assert.stub(checklist.reset).was.called(1)
        assert.stub(checklist.setState).was.called(1)
        assert.stub(checklist.setState).was.called_with(checklist, checklist.stateInProgress)
        assert.stub(checklist.onStarted).was.called(1)
    end)

    it("should throw an error if a checklist is started and no SOP is active", function()
        local checklist = createChecklist()
        assert.has_error(function() sopExecutor.startChecklist(checklist) end, "There is no active standard operating procedure")
    end)

    it("should throw an error if an invalid checklist is started", function()
        local sop = createSOP()
        local checklist = createChecklist()

        sopExecutor.setActiveSOP(sop)

        assert.has_error(function() sopExecutor.startChecklist(nil) end, "checklist must not be nil")
        assert.has_error(function() sopExecutor.startChecklist(checklist) end, "Active standard operating procecure does not contain the given checklist")
    end)

    it("should stop the active checklist", function()
        local sop = createSOP()
        local checklist = createChecklist()

        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)
        sopExecutor.stopChecklist()

        assert.stub(sop.setActiveChecklist).was.called(2)
        assert.stub(sop.setActiveChecklist).was.called_with(sop, nil)
        assert.stub(checklist.reset).was.called(2)
        assert.stub(checklist.onCancelled).was.called(1)
        assert.stub(challengeVoice.stop).was.called(1)
        assert.stub(responseVoice.stop).was.called(1)
    end)

    it("should not throw an error if a checklist is stopped and no SOP is active", function()
        sopExecutor.stopChecklist()
    end)

    it("should not throw an error if a checklist is stopped and no checklist is active", function()
        local sop = createSOP()
        sopExecutor.setActiveSOP(sop)
        sopExecutor.stopChecklist()
    end)

    it("should execute the do_often callback of the active SOP", function()
        local sop = createSOP()
        sopExecutor.setActiveSOP(sop)

        sopExecutor.doOften()
        sopExecutor.doOften()
        sopExecutor.doOften()

        assert.stub(sop.doOften).was.called(3)
    end)

    it("should not throw an error if the do_often callback is executed and no SOP is active", function()
        sopExecutor.doOften()
    end)

    it("should execute the do_every_frame callback of the active SOP", function()
        local sop = createSOP()
        sopExecutor.setActiveSOP(sop)

        sopExecutor.doEveryFrame()
        sopExecutor.doEveryFrame()
        sopExecutor.doEveryFrame()

        assert.stub(sop.doEveryFrame).was.called(3)
    end)

    it("should not throw an error if the do_every_frame callback is executed and no SOP is active", function()
        sopExecutor.doEveryFrame()
    end)

    it("should start the execution of a checklist item", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createChecklistItem()

        stub.new(checklistItem, "getChallengeKey", "TheChallengeKey")
        stub.new(checklistItem, "getResponseKey", "TheResponseKey")
        stub.new(checklistItem, "hasResponse", true)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        assert.are.equal(checklistItem, checklist:getActiveItem())
        assert.are.equal(checklistItem.stateNotStarted, checklistItem:getState())
        assert.stub(checklistItem.onStarted).was_not_called()
        assert.stub(challengeVoice.playChallengeSound).was_not_called()

        -- Multiple update calls must not update the checklist item if a voice is still active
        sopExecutor.update()
        sopExecutor.update()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onStarted).was.called(1)
        assert.stub(challengeVoice.playChallengeSound).was.called_with(challengeVoice, "TheChallengeKey")
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())
    end)

    it("should not throw an error if the execution is updated and no SOP is active", function()
        sopExecutor.update()
    end)

    it("should not throw an error if the execution is updated and no checklist is active", function()
        local sop = createSOP()
        sopExecutor.setActiveSOP(sop)
        sopExecutor.update()
    end)

    it("should not throw an error if the execution is updated and no checklist item is active", function()
        local sop = createSOP()
        local checklist = createChecklist()

        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)
        sopExecutor.update()
    end)

    it("should execute a checklist item without response", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createSoundChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should not update a checklist item without response while the challenge sound is active", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createSoundChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_no_called()

        sopExecutor.update()
        sopExecutor.update()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_no_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should not evualuate the conditions of an automatic checklist item while the challenge sound is active", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        sopExecutor.update()
        sopExecutor.update()

        assert.stub(checklistItem.evaluate).was_not_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.stub(checklistItem.evaluate).was.called(1)
    end)

    it("should execute an automatic checklist item whose conditions are met", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute an automatic checklist item whose conditions are not met initially", function()
        local evaluateResult = false
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        stub.new(checklistItem, "evaluate", function() return evaluateResult end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        evaluateResult = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute an automatic checklist item whose conditions are met while the fail sound is active", function()
        local evaluateResult = false
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        stub.new(checklistItem, "evaluate", function() return evaluateResult end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        evaluateResult = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute an automatic checklist item which is skipped before the conditions are evaluated", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        sopExecutor.setCurrentChecklistItemDone()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateDoneManually, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was_not_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(checklistItem.evaluate).was_not_called()
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute an automatic checklist item which is skipped after the conditions were not met and the fail sound is finished", function()
        local evaluateResult = false
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        stub.new(checklistItem, "evaluate", function() return evaluateResult end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        sopExecutor.setCurrentChecklistItemDone()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute an automatic checklist item which is skipped after the conditions were not met and the fail sound is not finished", function()
        local evaluateResult = false
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        stub.new(checklistItem, "evaluate", function() return evaluateResult end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        sopExecutor.setCurrentChecklistItemDone()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateDoneManually, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(checklistItem.onFailed).was.called(1)
        assert.stub(responseVoice.playResponseSound).was_not_called()
        assert.stub(responseVoice.playFailSound).was.called(1)

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute a manual checklist item", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createManualChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()

        sopExecutor.setCurrentChecklistItemDone()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.stub(responseVoice.playFailSound).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should not update a manual checklist item while the challenge sound is active", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createManualChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()

        sopExecutor.setCurrentChecklistItemDone()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateDoneManually, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.stub(responseVoice.playFailSound).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should complete a manual checklist item automatically if enabled", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createManualChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.enableAutoDone()
        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()

        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.stub(responseVoice.playFailSound).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should not complete a manual checklist item automatically if disabled", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createManualChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.enableAutoDone()
        sopExecutor.disableAutoDone()
        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was_not_called()
        assert.stub(responseVoice.playResponseSound).was_not_called()

        sopExecutor.setCurrentChecklistItemDone()
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.stub(responseVoice.playFailSound).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should execute a checklist with multiple items", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem1 = createSoundChecklistItem()
        local checklistItem2 = createAutomaticChecklistItem()
        local checklistItem3 = createSoundChecklistItem()

        checklist:addItem(checklistItem1)
        checklist:addItem(checklistItem2)
        checklist:addItem(checklistItem3)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()

        assert.stub(checklistItem1.onStarted).was.called(1)
        assert.stub(checklistItem2.onStarted).was_not_called()
        assert.stub(checklistItem3.onStarted).was_not_called()
        assert.are.equal(checklistItem1, checklist:getActiveItem())

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem1:getState())
        assert.are.equal(checklistItem.stateNotStarted, checklistItem2:getState())
        assert.are.equal(checklistItem.stateNotStarted, checklistItem3:getState())
        assert.stub(checklistItem1.onCompleted).was.called(1)
        assert.stub(checklistItem2.onCompleted).was_not_called()
        assert.stub(checklistItem3.onCompleted).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())
        assert.are.equal(checklistItem2, checklist:getActiveItem())

        sopExecutor.update()

        assert.stub(checklistItem1.onStarted).was.called(1)
        assert.stub(checklistItem2.onStarted).was.called(1)
        assert.stub(checklistItem3.onStarted).was_not_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem1:getState())
        assert.are.equal(checklistItem.stateSuccess, checklistItem2:getState())
        assert.are.equal(checklistItem.stateNotStarted, checklistItem3:getState())
        assert.are.equal(checklistItem2, checklist:getActiveItem())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem1:getState())
        assert.are.equal(checklistItem.stateSuccess, checklistItem2:getState())
        assert.are.equal(checklistItem.stateNotStarted, checklistItem3:getState())
        assert.stub(checklistItem1.onCompleted).was.called(1)
        assert.stub(checklistItem2.onCompleted).was.called(1)
        assert.stub(checklistItem3.onCompleted).was_not_called()
        assert.are.equal(checklist.stateInProgress, checklist:getState())
        assert.are.equal(checklistItem3, checklist:getActiveItem())

        sopExecutor.update()

        assert.stub(checklistItem1.onStarted).was.called(1)
        assert.stub(checklistItem2.onStarted).was.called(1)
        assert.stub(checklistItem3.onStarted).was.called(1)
        assert.are.equal(checklistItem3, checklist:getActiveItem())

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem1:getState())
        assert.are.equal(checklistItem.stateSuccess, checklistItem2:getState())
        assert.are.equal(checklistItem.stateSuccess, checklistItem3:getState())
        assert.stub(checklistItem1.onCompleted).was.called(1)
        assert.stub(checklistItem2.onCompleted).was.called(1)
        assert.stub(checklistItem3.onCompleted).was.called(1)
        assert.are.equal(checklist.stateCompleted, checklist:getState())
        assert.are.equal(checklistItem3, checklist:getActiveItem())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should stop the execution of a checklist", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.stopChecklist()
        sopExecutor.update()

        assert.are_not_equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(responseVoice.playResponseSound).was_not_called(1)
        assert.stub(responseVoice.playFailSound).was_not_called(1)
        assert.are_not_equal(checklist.stateCompleted, checklist:getState())
    end)

    it("should pause and resume the execution of the checklist item if the challenge voice is active", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        sopExecutor.pause()

        assert.stub(challengeVoice.pause).was.called(1)
        assert.stub(responseVoice.pause).was_not_called()

        challengeVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.evaluate).was_not_called()

        sopExecutor.resume()

        assert.are.equal(checklistItem.stateInProgress, checklistItem:getState())
        assert.stub(checklistItem.evaluate).was_not_called()
        assert.stub(challengeVoice.resume).was.called(1)
        assert.stub(responseVoice.resume).was_not_called()

        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.stub(checklistItem.onCompleted).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called(1)
        assert.stub(responseVoice.playResponseSound).was.called_with(responseVoice, "TheResponseKey")
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
    end)

    it("should pause and resume the execution of the checklist item if the response voice is active", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()

        sopExecutor.pause()

        assert.stub(challengeVoice.pause).was_not_called()
        assert.stub(responseVoice.pause).was.called(1)

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateInProgress, checklist:getState())

        sopExecutor.resume()

        assert.are.equal(checklist.stateInProgress, checklist:getState())
        assert.stub(challengeVoice.resume).was_not_called()
        assert.stub(responseVoice.resume).was.called(1)

        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
    end)

    it("should pause and resume the execution of the checklist item if an automatic checklist item waits for its conditions to be met", function()
        local evaluateResult = false
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()

        stub.new(checklistItem, "evaluate", function() return evaluateResult end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true
        sopExecutor.update()
        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())

        sopExecutor.pause()
        evaluateResult = true
        sopExecutor.update()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.stub(challengeVoice.pause).was_not_called()
        assert.stub(responseVoice.pause).was_not_called()

        sopExecutor.resume()

        assert.are.equal(checklistItem.stateFailed, checklistItem:getState())
        assert.are.equal(checklist.stateInProgress, checklist:getState())
        assert.stub(challengeVoice.resume).was_not_called()
        assert.stub(responseVoice.resume).was_not_called()

        sopExecutor.update()

        assert.are.equal(checklistItem.stateSuccess, checklistItem:getState())
        assert.are.equal(checklist.stateInProgress, checklist:getState())

        responseVoiceFinished = true
        sopExecutor.update()

        assert.are.equal(checklist.stateCompleted, checklist:getState())
    end)

    it("should not pause the execution if no SOP is active", function()
        sopExecutor.pause()

        assert.is_false(sopExecutor.isPaused())
    end)

    it("should not pause the execution if no checklist is active", function()
        local sop = createSOP()
        sopExecutor.setActiveSOP(sop)
        sopExecutor.pause()

        assert.is_false(sopExecutor.isPaused())
    end)

    it("should not throw an error if the execution is resumed but it was not paused", function()
        sopExecutor.resume()
    end)

    it("should execute the SOP activated callbacks", function()
        local sop = createSOP()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sopExecutor.addSOPActivatedCallback(function(sop) callbackSpy1(sop) end)
        sopExecutor.addSOPActivatedCallback(function(sop) callbackSpy2(sop) end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.setActiveSOP(sop)

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(sop)
    end)

    it("should execute the SOP deactivated callbacks", function()
        local sop = createSOP()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sopExecutor.addSOPDeactivatedCallback(function(sop) callbackSpy1(sop) end)
        sopExecutor.addSOPDeactivatedCallback(function(sop) callbackSpy2(sop) end)

        sopExecutor.setActiveSOP(sop)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.setActiveSOP(nil)

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(sop)
    end)

    it("should execute the checklist started callbacks", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sop:addChecklist(checklist)

        sopExecutor.addChecklistStartedCallback(function(checklist, sop) callbackSpy1(checklist, sop) end)
        sopExecutor.addChecklistStartedCallback(function(checklist, sop) callbackSpy2(checklist, sop) end)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(checklist, sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(checklist, sop)
    end)

    it("should execute the checklist cancelled callbacks", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sop:addChecklist(checklist)

        sopExecutor.addChecklistCancelledCallback(function(checklist, sop) callbackSpy1(checklist, sop) end)
        sopExecutor.addChecklistCancelledCallback(function(checklist, sop) callbackSpy2(checklist, sop) end)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.stopChecklist()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(checklist, sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(checklist, sop)
    end)

    it("should execute the checklist completed callbacks", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createSoundChecklistItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.addChecklistCompletedCallback(function(checklist, sop) callbackSpy1(checklist, sop) end)
        sopExecutor.addChecklistCompletedCallback(function(checklist, sop) callbackSpy2(checklist, sop) end)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)
        sopExecutor.update()
        challengeVoiceFinished = true

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.update()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(checklist, sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(checklist, sop)
    end)

    it("should execute the checklist item started callbacks", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.addChecklistItemStartedCallback(function(checklistItem, checklist, sop) callbackSpy1(checklistItem, checklist, sop) end)
        sopExecutor.addChecklistItemStartedCallback(function(checklistItem, checklist, sop) callbackSpy2(checklistItem, checklist, sop) end)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.update()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(checklistItem, checklist, sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(checklistItem, checklist, sop)
    end)

    it("should execute the checklist item failed callbacks", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        stub.new(checklistItem, "evaluate", false)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.addChecklistItemFailedCallback(function(checklistItem, checklist, sop) callbackSpy1(checklistItem, checklist, sop) end)
        sopExecutor.addChecklistItemFailedCallback(function(checklistItem, checklist, sop) callbackSpy2(checklistItem, checklist, sop) end)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.update()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(checklistItem, checklist, sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(checklistItem, checklist, sop)
    end)

    it("should execute the checklist item completed callbacks", function()
        local sop = createSOP()
        local checklist = createChecklist()
        local checklistItem = createAutomaticChecklistItem()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        stub.new(checklistItem, "evaluate", true)

        checklist:addItem(checklistItem)
        sop:addChecklist(checklist)

        sopExecutor.addChecklistItemCompletedCallback(function(checklistItem, checklist, sop) callbackSpy1(checklistItem, checklist, sop) end)
        sopExecutor.addChecklistItemCompletedCallback(function(checklistItem, checklist, sop) callbackSpy2(checklistItem, checklist, sop) end)

        sopExecutor.setActiveSOP(sop)
        sopExecutor.startChecklist(checklist)

        sopExecutor.update()
        challengeVoiceFinished = true

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sopExecutor.update()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(checklistItem, checklist, sop)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(checklistItem, checklist, sop)
    end)
end)