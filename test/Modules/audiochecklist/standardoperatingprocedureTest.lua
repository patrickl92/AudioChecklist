describe("StandardOperatingProcedure", function()
    local standardOperatingProcedure
    local voice
    local checklist

    local function createSOP()
        return standardOperatingProcedure:new("My SOP")
    end

    setup(function()
        standardOperatingProcedure = require "audiochecklist.standardoperatingprocedure"
        voice = require "audiochecklist.voice"
        checklist = require "audiochecklist.checklist"
    end)

    teardown(function()
        standardOperatingProcedure = nil
        voice = nil
        checklist = nil
    end)

    it("should initialize a new SOP", function()
        local sop = createSOP()

        assert.are.equal("My SOP", sop:getName())
        assert.are.equal(0, #sop:getAirplanes())
        assert.are.equal(0, #sop:getChallengeVoices())
        assert.is_nil(sop:getActiveChallengeVoice())
        assert.are.equal(0, #sop:getResponseVoices())
        assert.is_nil(sop:getActiveResponseVoice())
        assert.are.equal(0, #sop:getAllChecklists())
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should thrown an error if the name is invalid", function()
        assert.has_error(function() standardOperatingProcedure:new(nil) end, "name must be a string")
        assert.has_error(function() standardOperatingProcedure:new(0) end, "name must be a string")
    end)

    it("should add the airplanes", function()
        local sop = createSOP()
        sop:addAirplane("B738")
        sop:addAirplane("B736")

        local airplanes = sop:getAirplanes()
        assert.are.equal(2, #airplanes)
        assert.are.equal("B738", airplanes[1])
        assert.are.equal("B736", airplanes[2])
    end)

    it("should throw an error if the airplane is invalid", function()
        local sop = createSOP()
        assert.has_error(function() sop:addAirplane(nil) end, "planeIcao must be a string")
        assert.has_error(function() sop:addAirplane(0) end, "planeIcao must be a string")
    end)

    it("should add the challenge voices and set the first added voice as the active challenge voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")
        local voice2 = voice:new("Voice2")

        sop:addChallengeVoice(voice1)
        sop:addChallengeVoice(voice2)

        local voices = sop:getChallengeVoices()
        assert.are.equal(2, #voices)
        assert.are.equal(voice1, voices[1])
        assert.are.equal(voice2, voices[2])
        assert.are.equal(voice1, sop:getActiveChallengeVoice())
    end)

    it("should throw an error if the challenge voice is invalid", function()
        local sop = createSOP()
        assert.has_error(function() sop:addChallengeVoice(nil) end, "voice must not be nil")
    end)

    it("should set the active challenge voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")
        local voice2 = voice:new("Voice2")

        sop:addChallengeVoice(voice1)
        sop:addChallengeVoice(voice2)
        sop:setActiveChallengeVoice(voice2)

        assert.are.equal(voice2, sop:getActiveChallengeVoice())
    end)

    it("should accept nil as the active challenge voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")

        sop:addChallengeVoice(voice1)
        sop:setActiveChallengeVoice(nil)

        assert.is_nil(sop:getActiveChallengeVoice())
    end)

    it("should throw an error if a voice is which does not belong to the SOP set as the active challenge voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")

        assert.has_error(function() sop:setActiveChallengeVoice(voice1) end, "voice is not in the list of challenge voices")
    end)

    it("should add the response voices and set the first added voice as the active response voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")
        local voice2 = voice:new("Voice2")

        sop:addResponseVoice(voice1)
        sop:addResponseVoice(voice2)

        local voices = sop:getResponseVoices()
        assert.are.equal(2, #voices)
        assert.are.equal(voice1, voices[1])
        assert.are.equal(voice2, voices[2])
        assert.are.equal(voice1, sop:getActiveResponseVoice())
    end)

    it("should throw an error if the response voice is invalid", function()
        local sop = createSOP()
        assert.has_error(function() sop:addResponseVoice(nil) end, "voice must not be nil")
    end)

    it("should set the active response voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")
        local voice2 = voice:new("Voice2")

        sop:addResponseVoice(voice1)
        sop:addResponseVoice(voice2)
        sop:setActiveResponseVoice(voice2)

        assert.are.equal(voice2, sop:getActiveResponseVoice())
    end)

    it("should accept nil as the active response voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")

        sop:addResponseVoice(voice1)
        sop:setActiveResponseVoice(nil)

        assert.is_nil(sop:getActiveResponseVoice())
    end)

    it("should throw an error if a voice which does not belong to the SOP is set as the active response voice", function()
        local sop = createSOP()
        local voice1 = voice:new("Voice1")

        assert.has_error(function() sop:setActiveResponseVoice(voice1) end, "voice is not in the list of response voices")
    end)

    it("should add the checklists", function()
        local sop = createSOP()
        local checklist1 = checklist:new("Checklist 1")
        local checklist2 = checklist:new("Checklist 2")

        sop:addChecklist(checklist1)
        sop:addChecklist(checklist2)

        local checklists = sop:getAllChecklists()
        assert.are.equal(2, #checklists)
        assert.are.equal(checklist1, checklists[1])
        assert.are.equal(checklist2, checklists[2])
        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should throw an error if the checklist is invalid", function()
        local sop = createSOP()
        assert.has_error(function() sop:addChecklist(nil) end, "checklist must not be nil")
    end)

    it("should set the active checklist", function()
        local sop = createSOP()
        local checklist = checklist:new("Checklist 1")

        sop:addChecklist(checklist)
        sop:setActiveChecklist(checklist)

        assert.are.equal(checklist, sop:getActiveChecklist())
    end)

    it("should accept nil as the active checklist", function()
        local sop = createSOP()
        local checklist = checklist:new("Checklist 1")

        sop:addChecklist(checklist)
        sop:setActiveChecklist(checklist)
        sop:setActiveChecklist(nil)

        assert.is_nil(sop:getActiveChecklist())
    end)

    it("should throw an error if a checklist which does not belong to the SOP is set as the active checklist", function()
        local sop = createSOP()
        local checklist = checklist:new("Checklist 1")

        assert.has_error(function() sop:setActiveChecklist(checklist) end, "checklist does not belong to the SOP")
    end)

    it("should reset itself and all checklists", function()
        local sop = createSOP()
        local checklist1 = checklist:new("Checklist 1")
        local checklist2 = checklist:new("Checklist 2")

        sop:addChecklist(checklist1)
        sop:addChecklist(checklist2)
        sop:setActiveChecklist(checklist1)

        stub.new(checklist1, "reset")
        stub.new(checklist2, "reset")

        sop:reset()

        assert.is_nil(sop:getActiveChecklist())
        assert.stub(checklist1.reset).was.called(1)
        assert.stub(checklist2.reset).was.called(1)
    end)

    it("should execute the activated callbacks", function()
        local sop = createSOP()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sop:addActivatedCallback(function() callbackSpy1() end)
        sop:addActivatedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sop:onActivated()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the deactivated callbacks", function()
        local sop = createSOP()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sop:addDeactivatedCallback(function() callbackSpy1() end)
        sop:addDeactivatedCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sop:onDeactivated()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the do_often callbacks", function()
        local sop = createSOP()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sop:addDoOftenCallback(function() callbackSpy1() end)
        sop:addDoOftenCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sop:doOften()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should execute the do_every_frame callbacks", function()
        local sop = createSOP()
        local callbackSpy1 = spy.new(function() end)
        local callbackSpy2 = spy.new(function() end)

        sop:addDoEveryFrameCallback(function() callbackSpy1() end)
        sop:addDoEveryFrameCallback(function() callbackSpy2() end)

        assert.spy(callbackSpy1).was_not_called()
        assert.spy(callbackSpy2).was_not_called()

        sop:doEveryFrame()

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy2).was.called(1)
    end)

    it("should not throw an error if there are no callbacks", function()
        local sop = createSOP()

        sop:onActivated()
        sop:onDeactivated()
        sop:doOften()
        sop:doEveryFrame()
    end)

    it("should throw an error if an invalid callback is added", function()
        local sop = createSOP()

        assert.has_error(function() sop:addActivatedCallback(nil) end, "callback must be a function")
        assert.has_error(function() sop:addActivatedCallback(0) end, "callback must be a function")

        assert.has_error(function() sop:addDeactivatedCallback(nil) end, "callback must be a function")
        assert.has_error(function() sop:addDeactivatedCallback(0) end, "callback must be a function")

        assert.has_error(function() sop:addDoOftenCallback(nil) end, "callback must be a function")
        assert.has_error(function() sop:addDoOftenCallback(0) end, "callback must be a function")

        assert.has_error(function() sop:addDoEveryFrameCallback(nil) end, "callback must be a function")
        assert.has_error(function() sop:addDoEveryFrameCallback(0) end, "callback must be a function")
    end)
end)