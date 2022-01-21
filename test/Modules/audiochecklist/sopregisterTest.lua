insulate("SOPRegister", function()
    local sopRegister
    local utils
    local standardOperatingProcedure

    setup(function()
        sopRegister = require "audiochecklist.sopregister"
        utils = require "audiochecklist.utils"
        standardOperatingProcedure = require "audiochecklist.standardoperatingprocedure"

        stub.new(utils, "logInfo")
    end)

    teardown(function()
        sopRegister = nil
        standardOperatingProcedure = nil
    end)

    it("should add the given SOPs", function()
        local sop1 = standardOperatingProcedure:new("First SOP")
        local sop2 = standardOperatingProcedure:new("Second SOP")

        sopRegister.addSOP(sop1)
        sopRegister.addSOP(sop2)

        local allSOPs = sopRegister.getAllSOPs()
        assert.are.equal(2, #allSOPs)
        assert.are.equal(sop1, allSOPs[1])
        assert.are.equal(sop2, allSOPs[2])
    end)

    it("should thrown an error if the given SOP is invalid", function()
        assert.has_error(function() sopRegister.addSOP(nil) end, "sop must not be nil")
    end)
end)

insulate("SOPRegister", function()
    local sopRegister
    local utils
    local standardOperatingProcedure

    setup(function()
        sopRegister = require "audiochecklist.sopregister"
        utils = require "audiochecklist.utils"
        standardOperatingProcedure = require "audiochecklist.standardoperatingprocedure"

        stub.new(utils, "logInfo")
    end)

    teardown(function()
        sopRegister = nil
        standardOperatingProcedure = nil
    end)

    it("should execute the callbacks if a SOP is added", function()
        local sop1 = standardOperatingProcedure:new("First SOP")
        local sop2 = standardOperatingProcedure:new("Second SOP")
        local callbackSpy1 = spy.new(function(sop) end)
        local callbackSpy2 = spy.new(function(sop) end)

        sopRegister.addAddedCallback(function(sop) callbackSpy1(sop) end)
        sopRegister.addAddedCallback(function(sop) callbackSpy2(sop) end)

        sopRegister.addSOP(sop1)

        assert.spy(callbackSpy1).was.called(1)
        assert.spy(callbackSpy1).was.called_with(sop1)
        assert.spy(callbackSpy2).was.called(1)
        assert.spy(callbackSpy2).was.called_with(sop1)

        sopRegister.addSOP(sop2)

        assert.spy(callbackSpy1).was.called(2)
        assert.spy(callbackSpy1).was.called_with(sop2)
        assert.spy(callbackSpy2).was.called(2)
        assert.spy(callbackSpy2).was.called_with(sop2)
    end)

    it("should thrown an error if the given callback is invalid", function()
        assert.has_error(function()  sopRegister.addAddedCallback(nil) end, "callback must be a function")
        assert.has_error(function()  sopRegister.addAddedCallback(0) end, "callback must be a function")
    end)
end)