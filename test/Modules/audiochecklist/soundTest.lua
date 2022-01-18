describe("Sound", function()
    local sound
    local utils
    local currentTime

    local function createSound()
        return sound:new(1, 0.5)
    end

    setup(function()
        sound = require "audiochecklist.sound"
        utils = require "audiochecklist.utils"

        _G.set_sound_gain = function(soundTableEntry, volume) end
        _G.play_sound = function(soundTableEntry) end
        _G.pause_sound = function(soundTableEntry) end
        _G.stop_sound = function(soundTableEntry) end

        stub.new(utils, "getTime", function() return currentTime end)
    end)

    teardown(function()
        sound = nil
        utils = nil
    end)

    before_each(function()
        currentTime = 100
    end)

    after_each(function()
        currentTime = 0
    end)

    it("should initialize a new sound", function()
        local sound = createSound()

        assert.are.equal(1, sound:getSoundTableEntry())
        assert.is_true(sound:isFinished())
    end)

    it("should set the volume", function()
        local sound = createSound()
        local volumeSpy = spy.on(_G, "set_sound_gain")

        sound:setVolume(0.5)

        assert.spy(volumeSpy).was.called(1)
        assert.spy(volumeSpy).was.called_with(1, 0.5)
    end)

    it("should throw an error if the volume is invalid", function()
        local sound = createSound()
        assert.has_error(function() sound:setVolume(nil) end, "volume must be a number")
        assert.has_error(function() sound:setVolume("0.5") end, "volume must be a number")
    end)

    it("should play the sound", function()
        local sound = createSound()
        local playSpy = spy.on(_G, "play_sound")
        local stopSpy = spy.on(_G, "stop_sound")

        sound:play()

        assert.spy(stopSpy).was.called(1)
        assert.spy(stopSpy).was.called_with(1)

        assert.spy(playSpy).was.called(1)
        assert.spy(playSpy).was.called_with(1)
    end)

    it("should stop the sound", function()
        local sound = createSound()
        local stopSpy = spy.on(_G, "stop_sound")

        sound:play()
        sound:stop()

        assert.spy(stopSpy).was.called(2)
        assert.spy(stopSpy).was.called_with(1)
    end)

    it("should stop the sound, even if it was not started", function()
        local sound = createSound()
        local stopSpy = spy.on(_G, "stop_sound")

        sound:stop()

        assert.spy(stopSpy).was.called(1)
        assert.spy(stopSpy).was.called_with(1)
    end)

    it("should pause the sound", function()
        local sound = createSound()
        local pauseSpy = spy.on(_G, "pause_sound")

        sound:play()
        sound:pause()

        assert.spy(pauseSpy).was.called(1)
        assert.spy(pauseSpy).was.called_with(1)
    end)

    it("should not pause the sound if the sound was not started", function()
        local sound = createSound()
        local pauseSpy = spy.on(_G, "pause_sound")

        sound:pause()

        assert.spy(pauseSpy).was_not_called()
    end)

    it("should not pause the sound multiple times", function()
        local sound = createSound()
        local pauseSpy = spy.on(_G, "pause_sound")

        sound:play()
        sound:pause()
        sound:pause()

        assert.spy(pauseSpy).was.called(1)
    end)

    it("should resume the sound if it was paused", function()
        local sound = createSound()
        local playSpy = spy.on(_G, "play_sound")
        local stopSpy = spy.on(_G, "stop_sound")

        sound:play()
        sound:pause()
        sound:play()

        assert.spy(stopSpy).was.called(1)
        assert.spy(stopSpy).was.called_with(1)

        assert.spy(playSpy).was.called(2)
        assert.spy(playSpy).was.called_with(1)
    end)

    it("should report if the sound has been finished", function()
        local sound = createSound()

        sound:play()

        assert.is_false(sound:isFinished())

        -- Simulate 1 second
        currentTime = currentTime + 1

        assert.is_true(sound:isFinished())
    end)

    it("should be finished if the sound is stopped", function()
        local sound = createSound()

        sound:play()

        assert.is_false(sound:isFinished())

        sound:stop()

        assert.is_true(sound:isFinished())
    end)

    it("should not be finished if the sound is paused", function()
        local sound = createSound()

        sound:play()
        sound:pause()

        assert.is_false(sound:isFinished())

        -- Simulate 5 seconds
        currentTime = currentTime + 5

        assert.is_false(sound:isFinished())

        sound:play()

        assert.is_false(sound:isFinished())

        -- Simulate 1 second
        currentTime = currentTime + 1

        assert.is_true(sound:isFinished())
    end)
end)