describe("EmptyVoice", function()
    local emptyVoice

    local function createVoice()
        return emptyVoice:new("Patrick")
    end

    setup(function()
        emptyVoice = require "audiochecklist.emptyVoice"
    end)

    teardown(function()
        emptyVoice = nil
    end)

    it("should initialize a new voice", function()
        local voice = createVoice()

        assert.are.equal("Patrick", voice:getName())
        assert.is_true(voice:isFinished())
    end)

    it("should throw an error if the name is invalid", function()
        assert.has_error(function() emptyVoice:new(nil) end, "name must be a string")
        assert.has_error(function() emptyVoice:new(0) end, "name must be a string")
    end)

    it("should not throw any error in the default implementations", function()
        local voice = createVoice()

        voice:setVolume(1)
        voice:activateChallengeSounds()
        voice:activateResponseSounds()
        voice:deactivateChallengeSounds()
        voice:deactivateResponseSounds()
        voice:playChallengeSound(nil)
        voice:playResponseSound(nil)
        voice:playFailSound()
        voice:pause()
        voice:resume()
        voice:stop()
    end)
end)
