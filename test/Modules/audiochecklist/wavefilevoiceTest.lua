describe("WaveFileVoice", function()
    local waveFileVoice
    local utils
    local audio
    local sound
    local soundLookup
    local randomResult

    local function createVoice()
        return waveFileVoice:new("Patrick", "challenges", "responses")
    end

    local function createSound()
        return sound:new(0, 0)
    end

    setup(function()
        stub.new(math, "random", function() return randomResult end)

        _G.DIRECTORY_SEPARATOR = "/"

        waveFileVoice = require "audiochecklist.wavefilevoice"
        utils = require "audiochecklist.utils"
        audio = require "audiochecklist.audio"
        sound = require "audiochecklist.sound"

        stub.new(utils, "logError")
        stub.new(utils, "fileExists", true)
    end)

    teardown(function()
        math.random:revert()
        utils.logError:revert()
        utils.fileExists:revert()

        waveFileVoice = nil
        utils = nil
        audio = nil
        sound = nil

        _G.DIRECTORY_SEPARATOR = nil
    end)

    before_each(function()
        soundLookup = {}
        randomResult = 1
        stub.new(audio, "loadSoundFile", function(filePath) return soundLookup[filePath] end)
        stub.new(audio, "releaseSound", function(sound) end)
    end)

    after_each(function()
        audio.loadSoundFile:revert()
        audio.releaseSound:revert()
        soundLookup = nil
        randomResult = 1
    end)

    it("should initialize a new voice", function()
        local voice = createVoice()

        assert.are.equal("Patrick", voice:getName())
        assert.is_true(voice:isFinished())
    end)

    it("should throw an error if not initialized correctly", function()
        assert.has_error(function() waveFileVoice:new(nil, nil, nil) end, "name must be a string")
        assert.has_error(function() waveFileVoice:new(0, nil, nil) end, "name must be a string")
        assert.has_error(function() waveFileVoice:new("", 0, nil) end, "challengeFilesDirectoryPath must be a string")
        assert.has_error(function() waveFileVoice:new("", "", nil) end, "challengeFilesDirectoryPath must not be empty")
        assert.has_error(function() waveFileVoice:new("", nil, 0) end, "responseFilesDirectoryPath must be a string")
        assert.has_error(function() waveFileVoice:new("", nil, "") end, "responseFilesDirectoryPath must not be empty")
    end)

    it("should throw an error if challenge sound files are added but the challenge directory is not set", function()
        local voice = waveFileVoice:new("Patrick", nil, "responses")
        assert.has_error(function() voice:addChallengeSoundFile("1", "Challenge.wav") end, "Challenge files directory was not set")
    end)

    it("should throw an error if response sound files are added but the response directory is not set", function()
        local voice = waveFileVoice:new("Patrick", "challenges", nil)
        assert.has_error(function() voice:addResponseSoundFile("One", "Response.wav") end, "Response files directory was not set")
    end)

    it("should throw an error if fail sound files are added but the response directory is not set", function()
        local voice = waveFileVoice:new("Patrick", "challenges", nil)
        assert.has_error(function() voice:addFailSoundFile("Fail.wav") end, "Response files directory was not set")
    end)

    it("should load the challenge sounds when activated", function()
        soundLookup["challenges/Challenge1.wav"] = createSound()
        soundLookup["challenges/Challenge2.wav"] = createSound()
        soundLookup["responses/Response.wav"] = createSound()
        soundLookup["responses/Fail.wav"] = createSound()

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:addResponseSoundFile("One", "Response.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called_with("challenges/Challenge1.wav")
        assert.stub(audio.loadSoundFile).was.called_with("challenges/Challenge2.wav")
        assert.stub(audio.loadSoundFile).was.called(2)
    end)

    it("should only load existing challenge sounds when activated", function()
        stub(utils, "fileExists", function(path) return not string.find(path, "NotExisting") end)

        finally(function()
            utils.fileExists:revert()
        end)

        soundLookup["challenges/Challenge.wav"] = createSound()

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge.wav")
        voice:addChallengeSoundFile("2", "NotExisting.wav")

        voice:activateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called_with("challenges/Challenge.wav")
        assert.stub(audio.loadSoundFile).was.called(1)
    end)

    it("should load the challenge sounds only once when activated multiple times", function()
        soundLookup["challenges/Challenge.wav"] = createSound()

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()
        voice:activateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called(1)
    end)

    it("should not throw an error if there are no challenge sounds to load", function()
        local voice = createVoice()

        voice:activateChallengeSounds()

        assert.stub(audio.loadSoundFile).was_not_called()
    end)

    it("should load the response and fail sounds when activated", function()
        soundLookup["challenges/Challenge1.wav"] = createSound()
        soundLookup["challenges/Challenge2.wav"] = createSound()
        soundLookup["responses/Response1.wav"] = createSound()
        soundLookup["responses/Response2.wav"] = createSound()
        soundLookup["responses/Fail1.wav"] = createSound()
        soundLookup["responses/Fail2.wav"] = createSound()

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:addResponseSoundFile("One", "Response1.wav")
        voice:addResponseSoundFile("Two", "Response2.wav")

        voice:addFailSoundFile("Fail1.wav")
        voice:addFailSoundFile("Fail2.wav")

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called_with("responses/Response1.wav")
        assert.stub(audio.loadSoundFile).was.called_with("responses/Response2.wav")
        assert.stub(audio.loadSoundFile).was.called_with("responses/Fail1.wav")
        assert.stub(audio.loadSoundFile).was.called_with("responses/Fail2.wav")
        assert.stub(audio.loadSoundFile).was.called(4)
    end)

    it("should only load existing response and fail sounds when activated", function()
        stub(utils, "fileExists", function(path) return not string.find(path, "NotExisting") end)

        finally(function()
            utils.fileExists:revert()
        end)

        soundLookup["responses/Response.wav"] = createSound()
        soundLookup["responses/Fail.wav"] = createSound()

        local voice = createVoice()

        voice:addResponseSoundFile("One", "Response.wav")
        voice:addResponseSoundFile("Two", "NotExisting.wav")

        voice:addFailSoundFile("Fail.wav")
        voice:addFailSoundFile("NotExisting.wav")

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called_with("responses/Response.wav")
        assert.stub(audio.loadSoundFile).was.called_with("responses/Fail.wav")
        assert.stub(audio.loadSoundFile).was.called(2)
    end)

    it("should load the response and fail sounds only once when activated multiple times", function()
        soundLookup["responses/Response.wav"] = createSound()
        soundLookup["responses/Fail.wav"] = createSound()

        local voice = createVoice()

        voice:addResponseSoundFile("One", "Response.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()
        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(2)
    end)

    it("should not throw an error if there are no response sounds to load", function()
        soundLookup["responses/Fail.wav"] = createSound()

        local voice = createVoice()

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(1)
    end)

    it("should not throw an error if there are no fail sounds to load", function()
        soundLookup["responses/Response.wav"] = createSound()

        local voice = createVoice()

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(1)
    end)

    it("should not throw an error if there are no response sounds and no fail sounds to load", function()
        local voice = createVoice()

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was_not_called()
    end)

    it("should release all loaded challenge sounds when deactivated", function()
        local challengeSound1 = createSound()
        local challengeSound2 = createSound()
        local responseSound = createSound()
        local failSound = createSound()

        soundLookup["challenges/Challenge1.wav"] = challengeSound1
        soundLookup["challenges/Challenge2.wav"] = challengeSound2
        soundLookup["responses/Response.wav"] = responseSound
        soundLookup["responses/Fail.wav"] = failSound

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:addResponseSoundFile("One", "Response.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateChallengeSounds()
        voice:deactivateChallengeSounds()

        assert.stub(audio.releaseSound).was.called_with(challengeSound1)
        assert.stub(audio.releaseSound).was.called_with(challengeSound2)
        assert.stub(audio.releaseSound).was.called(2)
    end)

    it("should load and release all challenge sounds again when activated and deactivated again", function()
        soundLookup["challenges/Challenge1.wav"] = createSound()
        soundLookup["challenges/Challenge2.wav"] = createSound()

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:activateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called(2)
        assert.stub(audio.releaseSound).was.called(0)

        voice:deactivateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called(2)
        assert.stub(audio.releaseSound).was.called(2)

        voice:activateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called(4)
        assert.stub(audio.releaseSound).was.called(2)

        voice:deactivateChallengeSounds()

        assert.stub(audio.loadSoundFile).was.called(4)
        assert.stub(audio.releaseSound).was.called(4)
    end)

    it("should not throw an error if there are no challenge sounds to release", function()
        local voice = createVoice()

        voice:activateChallengeSounds()
        voice:deactivateChallengeSounds()

        assert.stub(audio.releaseSound).was_not_called()
    end)

    it("should release all loaded response and fail sounds when deactivated", function()
        local challengeSound = createSound()
        local responseSound1 = createSound()
        local responseSound2 = createSound()
        local failSound1 = createSound()
        local failSound2 = createSound()

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Response1.wav"] = responseSound1
        soundLookup["responses/Response2.wav"] = responseSound2
        soundLookup["responses/Fail1.wav"] = failSound1
        soundLookup["responses/Fail2.wav"] = failSound2

        local voice = createVoice()

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:addResponseSoundFile("One", "Response1.wav")
        voice:addResponseSoundFile("Two", "Response2.wav")

        voice:addFailSoundFile("Fail1.wav")
        voice:addFailSoundFile("Fail2.wav")

        voice:activateResponseSounds()
        voice:deactivateResponseSounds()

        assert.stub(audio.releaseSound).was.called_with(responseSound1)
        assert.stub(audio.releaseSound).was.called_with(responseSound2)
        assert.stub(audio.releaseSound).was.called_with(failSound1)
        assert.stub(audio.releaseSound).was.called_with(failSound2)
        assert.stub(audio.releaseSound).was.called(4)
    end)

    it("should load and release all release and fail sounds again when activated and deactivated again", function()
        soundLookup["responses/Response.wav"] = createSound()
        soundLookup["responses/Fail.wav"] = createSound()

        local voice = createVoice()

        voice:addResponseSoundFile("One", "Response.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(2)
        assert.stub(audio.releaseSound).was.called(0)

        voice:deactivateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(2)
        assert.stub(audio.releaseSound).was.called(2)

        voice:activateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(4)
        assert.stub(audio.releaseSound).was.called(2)

        voice:deactivateResponseSounds()

        assert.stub(audio.loadSoundFile).was.called(4)
        assert.stub(audio.releaseSound).was.called(4)
    end)

    it("should not throw an error if there are no response sounds to release", function()
        soundLookup["responses/Fail.wav"] = createSound()

        local voice = createVoice()

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()
        voice:deactivateResponseSounds()

        assert.stub(audio.releaseSound).was.called(1)
    end)

    it("should not throw an error if there are no fail sounds to release", function()
        soundLookup["responses/Response.wav"] = createSound()

        local voice = createVoice()

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()
        voice:deactivateResponseSounds()

        assert.stub(audio.releaseSound).was.called(1)
    end)

    it("should not throw an error if there are no response and fail sounds to release", function()
        local voice = createVoice()

        voice:activateResponseSounds()
        voice:deactivateResponseSounds()

        assert.stub(audio.releaseSound).was_not_called()
    end)

    it("should not throw an error if the voice if the voice is deactivated but was not activated", function()
        local voice = createVoice()

        voice:deactivateChallengeSounds()
        voice:deactivateResponseSounds()

        assert.stub(audio.releaseSound).was_not_called()
    end)

    it("should play the correct challenge sound", function()
        local voice = createVoice()
        local challengeSound1 = createSound()
        local challengeSound2 = createSound()

        stub.new(challengeSound1, "play")
        stub.new(challengeSound2, "play")

        soundLookup["challenges/Challenge1.wav"] = challengeSound1
        soundLookup["challenges/Challenge2.wav"] = challengeSound2

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:activateChallengeSounds()

        voice:playChallengeSound("2")

        assert.stub(challengeSound1.play).was_not_called()
        assert.stub(challengeSound2.play).was.called(1)
    end)

    it("should play the correct challenge sound if there is a response sound with the same key", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local responseSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(responseSound, "play")

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Response.wav"] = responseSound

        voice:addChallengeSoundFile("One", "Challenge.wav")
        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateChallengeSounds()

        voice:playChallengeSound("One")

        assert.stub(challengeSound.play).was.called(1)
        assert.stub(responseSound.play).was_not_called()
    end)

    it("should restart the active challenge sound when played again", function()
        local voice = createVoice()
        local challengeSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "stop")

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()

        voice:playChallengeSound("1")
        voice:playChallengeSound("1")

        assert.stub(challengeSound.play).was.called(2)
        assert.stub(challengeSound.stop).was.called(1)
    end)

    it("should stop any active challenge sound when playing a new challenge sound", function()
        local voice = createVoice()
        local challengeSound1 = createSound()
        local challengeSound2 = createSound()

        stub.new(challengeSound1, "play")
        stub.new(challengeSound1, "stop")
        stub.new(challengeSound2, "play")
        stub.new(challengeSound2, "stop")

        soundLookup["challenges/Challenge1.wav"] = challengeSound1
        soundLookup["challenges/Challenge2.wav"] = challengeSound2

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:activateChallengeSounds()

        voice:playChallengeSound("1")
        voice:playChallengeSound("2")

        assert.stub(challengeSound1.play).was.called(1)
        assert.stub(challengeSound2.play).was.called(1)
        assert.stub(challengeSound1.stop).was.called(1)
        assert.stub(challengeSound2.stop).was_not_called()
    end)

    it("should stop any active response sound when playing a new challenge sound", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local responseSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "stop")
        stub.new(responseSound, "play")
        stub.new(responseSound, "stop")

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Response.wav"] = responseSound

        voice:addChallengeSoundFile("1", "Challenge.wav")
        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateChallengeSounds()
        voice:activateResponseSounds()

        voice:playResponseSound("One")
        voice:playChallengeSound("1")

        assert.stub(challengeSound.play).was.called(1)
        assert.stub(responseSound.stop).was.called(1)
    end)

    it("should stop any active fail sound when playing a new challenge sound", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local failSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "stop")
        stub.new(failSound, "play")
        stub.new(failSound, "stop")

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Fail.wav"] = failSound

        voice:addChallengeSoundFile("1", "Challenge.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateChallengeSounds()
        voice:activateResponseSounds()

        voice:playFailSound()
        voice:playChallengeSound("1")

        assert.stub(challengeSound.play).was.called(1)
        assert.stub(failSound.stop).was.called(1)
    end)

    it("should play the correct response sound", function()
        local voice = createVoice()
        local responseSound1 = createSound()
        local responseSound2 = createSound()

        stub.new(responseSound1, "play")
        stub.new(responseSound2, "play")

        soundLookup["responses/Response1.wav"] = responseSound1
        soundLookup["responses/Response2.wav"] = responseSound2

        voice:addResponseSoundFile("One", "Response1.wav")
        voice:addResponseSoundFile("Two", "Response2.wav")

        voice:activateResponseSounds()

        voice:playResponseSound("Two")

        assert.stub(responseSound1.play).was_not_called()
        assert.stub(responseSound2.play).was.called(1)
    end)

    it("should play the correct response sound if there is a challenge sound with the same key", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local responseSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(responseSound, "play")

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Response.wav"] = responseSound

        voice:addChallengeSoundFile("One", "Challenge.wav")
        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateChallengeSounds()
        voice:activateResponseSounds()

        voice:playResponseSound("One")

        assert.stub(challengeSound.play).was_not_called()
        assert.stub(responseSound.play).was.called(1)
    end)

    it("should restart the active response sound when played again", function()
        local voice = createVoice()
        local responseSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "stop")

        soundLookup["responses/Response.wav"] = responseSound

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()

        voice:playResponseSound("One")
        voice:playResponseSound("One")

        assert.stub(responseSound.play).was.called(2)
        assert.stub(responseSound.stop).was.called(1)
    end)

    it("should stop any active challenge sound when playing a new response sound", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local responseSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "stop")
        stub.new(responseSound, "play")
        stub.new(responseSound, "stop")

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Response.wav"] = responseSound

        voice:addChallengeSoundFile("1", "Challenge.wav")
        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateChallengeSounds()
        voice:activateResponseSounds()

        voice:playChallengeSound("1")
        voice:playResponseSound("One")

        assert.stub(challengeSound.stop).was.called(1)
        assert.stub(responseSound.play).was.called(1)
    end)

    it("should stop any active response sound when playing a new response sound", function()
        local voice = createVoice()
        local responseSound1 = createSound()
        local responseSound2 = createSound()

        stub.new(responseSound1, "play")
        stub.new(responseSound1, "stop")
        stub.new(responseSound2, "play")
        stub.new(responseSound2, "stop")

        soundLookup["responses/Response1.wav"] = responseSound1
        soundLookup["responses/Response2.wav"] = responseSound2

        voice:addResponseSoundFile("One", "Response1.wav")
        voice:addResponseSoundFile("Two", "Response2.wav")

        voice:activateResponseSounds()

        voice:playResponseSound("One")
        voice:playResponseSound("Two")

        assert.stub(responseSound1.play).was.called(1)
        assert.stub(responseSound2.play).was.called(1)
        assert.stub(responseSound1.stop).was.called(1)
        assert.stub(responseSound2.stop).was_not_called()
    end)

    it("should stop any active fail sound when playing a new response sound", function()
        local voice = createVoice()
        local responseSound = createSound()
        local failSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "stop")
        stub.new(failSound, "play")
        stub.new(failSound, "stop")

        soundLookup["responses/Response.wav"] = responseSound
        soundLookup["responses/Fail.wav"] = failSound

        voice:addResponseSoundFile("1", "Response.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()

        voice:playFailSound()
        voice:playResponseSound("1")

        assert.stub(responseSound.play).was.called(1)
        assert.stub(failSound.stop).was.called(1)
    end)

    it("should play a random fail sound", function()
        local voice = createVoice()
        local failSound1 = createSound()
        local failSound2 = createSound()

        stub.new(failSound1, "play")
        stub.new(failSound2, "play")

        soundLookup["responses/Fail1.wav"] = failSound1
        soundLookup["responses/Fail2.wav"] = failSound2

        voice:addFailSoundFile("Fail1.wav")
        voice:addFailSoundFile("Fail2.wav")

        voice:activateResponseSounds()

        randomResult = 2
        voice:playFailSound()

        assert.stub(failSound1.play).was_not_called()
        assert.stub(failSound2.play).was.called(1)
    end)

    it("should restart the active fail sound when played again", function()
        local voice = createVoice()
        local failSound = createSound()

        stub.new(failSound, "play")
        stub.new(failSound, "stop")

        soundLookup["responses/Fail.wav"] = failSound

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()

        voice:playFailSound()
        voice:playFailSound()

        assert.stub(failSound.play).was.called(2)
        assert.stub(failSound.stop).was.called(1)
    end)

    it("should stop any active challenge sound when playing a new fail sound", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local failSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "stop")
        stub.new(failSound, "play")
        stub.new(failSound, "stop")

        soundLookup["challenges/Challenge.wav"] = challengeSound
        soundLookup["responses/Fail.wav"] = failSound

        voice:addChallengeSoundFile("1", "Challenge.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateChallengeSounds()
        voice:activateResponseSounds()

        voice:playChallengeSound("1")
        voice:playFailSound()

        assert.stub(challengeSound.stop).was.called(1)
        assert.stub(failSound.play).was.called(1)
    end)

    it("should stop any active response sound when playing a new fail sound", function()
        local voice = createVoice()
        local responseSound = createSound()
        local failSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "stop")
        stub.new(failSound, "play")
        stub.new(failSound, "stop")

        soundLookup["responses/Response.wav"] = responseSound
        soundLookup["responses/Fail.wav"] = failSound

        voice:addResponseSoundFile("One", "Response.wav")
        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()

        voice:playResponseSound("One")
        voice:playFailSound()

        assert.stub(responseSound.play).was.called(1)
        assert.stub(failSound.play).was.called(1)
        assert.stub(responseSound.stop).was.called(1)
        assert.stub(failSound.stop).was_not_called()
    end)

    it("should stop any active fail sound when playing a new fail sound", function()
        local voice = createVoice()
        local failSound1 = createSound()
        local failSound2 = createSound()

        stub.new(failSound1, "play")
        stub.new(failSound1, "stop")
        stub.new(failSound2, "play")
        stub.new(failSound2, "stop")

        soundLookup["responses/Fail1.wav"] = failSound1
        soundLookup["responses/Fail2.wav"] = failSound2

        voice:addFailSoundFile("Fail1.wav")
        voice:addFailSoundFile("Fail2.wav")

        voice:activateResponseSounds()

        voice:playFailSound()

        randomResult = 2
        voice:playFailSound()

        assert.stub(failSound1.stop).was.called(1)
        assert.stub(failSound2.play).was.called(1)
    end)

    it("should throw an error if the key for a sound is invalid", function()
        local voice = createVoice()
        assert.has_error(function() voice:playChallengeSound(nil) end, "key must be a string")
        assert.has_error(function() voice:playChallengeSound(0) end, "key must be a string")
        assert.has_error(function() voice:playResponseSound(nil) end, "key must be a string")
        assert.has_error(function() voice:playResponseSound(0) end, "key must be a string")
    end)

    it("should throw an error if a sound is played and the voice is not activated", function()
        local voice = createVoice()
        assert.has_error(function() voice:playChallengeSound("") end, "voice 'Patrick' was not activated for the challenges")
        assert.has_error(function() voice:playResponseSound("") end, "voice 'Patrick' was not activated for the responses")
        assert.has_error(function() voice:playFailSound() end, "voice 'Patrick' was not activated for the responses")
    end)

    it("should pause and resume the active challenge sound", function()
        local voice = createVoice()
        local challengeSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "pause")

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()
        voice:playChallengeSound("1")
        voice:pause()

        assert.stub(challengeSound.play).was.called(1)
        assert.stub(challengeSound.pause).was.called(1)

        voice:resume()

        assert.stub(challengeSound.play).was.called(2)
    end)

    it("should not pause the active challenge sound multiple times", function()
        local voice = createVoice()
        local challengeSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "pause")

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()
        voice:playChallengeSound("1")
        voice:pause()
        voice:pause()

        assert.stub(challengeSound.pause).was.called(1)
    end)

    it("should not resume the active challenge sound multiple times", function()
        local voice = createVoice()
        local challengeSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "pause")

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()
        voice:playChallengeSound("1")
        voice:pause()
        voice:resume()
        voice:resume()

        assert.stub(challengeSound.play).was.called(2)
    end)

    it("should reset the pause when playing a challenge voice", function()
        local voice = createVoice()
        local challengeSound1 = createSound()
        local challengeSound2 = createSound()

        stub.new(challengeSound1, "stop")
        stub.new(challengeSound1, "play")
        stub.new(challengeSound1, "pause")
        stub.new(challengeSound2, "play")

        soundLookup["challenges/Challenge1.wav"] = challengeSound1
        soundLookup["challenges/Challenge2.wav"] = challengeSound2

        voice:addChallengeSoundFile("1", "Challenge1.wav")
        voice:addChallengeSoundFile("2", "Challenge2.wav")

        voice:activateChallengeSounds()
        voice:playChallengeSound("1")
        voice:pause()
        voice:playChallengeSound("2")

        assert.stub(challengeSound2.play).was.called(1)
    end)

    it("should pause and resume the active response sound", function()
        local voice = createVoice()
        local responseSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "pause")

        soundLookup["responses/Response.wav"] = responseSound

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()
        voice:playResponseSound("One")
        voice:pause()

        assert.stub(responseSound.play).was.called(1)
        assert.stub(responseSound.pause).was.called(1)

        voice:resume()

        assert.stub(responseSound.play).was.called(2)
    end)

    it("should not pause the active response sound multiple times", function()
        local voice = createVoice()
        local responseSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "pause")

        soundLookup["responses/Response.wav"] = responseSound

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()
        voice:playResponseSound("One")
        voice:pause()
        voice:pause()

        assert.stub(responseSound.pause).was.called(1)
    end)

    it("should not resume the active response sound multiple times", function()
        local voice = createVoice()
        local responseSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "pause")

        soundLookup["responses/Response.wav"] = responseSound

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()
        voice:playResponseSound("One")
        voice:pause()
        voice:resume()
        voice:resume()

        assert.stub(responseSound.play).was.called(2)
    end)

    it("should reset the pause when playing a response voice", function()
        local voice = createVoice()
        local responseSound1 = createSound()
        local responseSound2 = createSound()

        stub.new(responseSound1, "stop")
        stub.new(responseSound1, "play")
        stub.new(responseSound1, "pause")
        stub.new(responseSound2, "play")

        soundLookup["responses/Response1.wav"] = responseSound1
        soundLookup["responses/Response2.wav"] = responseSound2

        voice:addResponseSoundFile("1", "Response1.wav")
        voice:addResponseSoundFile("2", "Response2.wav")

        voice:activateResponseSounds()
        voice:playResponseSound("1")
        voice:pause()
        voice:playResponseSound("2")

        assert.stub(responseSound2.play).was.called(1)
    end)

    it("should pause and resume the active fail sound", function()
        local voice = createVoice()
        local failSound = createSound()

        stub.new(failSound, "play")
        stub.new(failSound, "pause")

        soundLookup["responses/Fail.wav"] = failSound

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()
        voice:playFailSound()
        voice:pause()

        assert.stub(failSound.play).was.called(1)
        assert.stub(failSound.pause).was.called(1)

        voice:resume()

        assert.stub(failSound.play).was.called(2)
    end)

    it("should not pause the active fail sound multiple times", function()
        local voice = createVoice()
        local failSound = createSound()

        stub.new(failSound, "play")
        stub.new(failSound, "pause")

        soundLookup["responses/Fail.wav"] = failSound

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()
        voice:playFailSound()
        voice:pause()
        voice:pause()

        assert.stub(failSound.pause).was.called(1)
    end)

    it("should not resume the active fail sound multiple times", function()
        local voice = createVoice()
        local failSound = createSound()

        stub.new(failSound, "play")
        stub.new(failSound, "pause")

        soundLookup["responses/Fail.wav"] = failSound

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()
        voice:playFailSound()
        voice:pause()
        voice:resume()
        voice:resume()

        assert.stub(failSound.play).was.called(2)
    end)

    it("should reset the pause when playing a fail voice", function()
        local voice = createVoice()
        local failSound1 = createSound()
        local failSound2 = createSound()

        stub.new(failSound1, "stop")
        stub.new(failSound1, "play")
        stub.new(failSound1, "pause")
        stub.new(failSound2, "play")

        soundLookup["responses/Fail1.wav"] = failSound1
        soundLookup["responses/Fail2.wav"] = failSound2

        voice:addFailSoundFile("Fail1.wav")
        voice:addFailSoundFile("Fail2.wav")

        voice:activateResponseSounds()
        voice:playFailSound()
        voice:pause()
        randomResult = 2
        voice:playFailSound()

        assert.stub(failSound2.play).was.called(1)
    end)

    it("should not restart the active sound when resumed while the voice was not paused", function()
        local voice = createVoice()
        local challengeSound = createSound()

        stub.new(challengeSound, "stop")
        stub.new(challengeSound, "play")
        stub.new(challengeSound, "pause")

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()
        voice:playChallengeSound("1")
        voice:resume()

        assert.stub(challengeSound.play).was.called(1)
        assert.stub(challengeSound.stop).was_not_called()
    end)

    it("should not throw an error if the voice is paused when there is no active challenge sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:pause()
    end)

    it("should not throw an error if the voice is paused when there is no active response sound", function()
        local voice = createVoice()
        voice:activateResponseSounds()
        voice:pause()
    end)

    it("should not throw an error if the voice is paused when there is no active challenge or response sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:activateResponseSounds()
        voice:pause()
    end)

    it("should not throw an error if the voice is resumed when there is no active challenge sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:resume()
    end)

    it("should not throw an error if the voice is resumed when there is no active response sound", function()
        local voice = createVoice()
        voice:activateResponseSounds()
        voice:resume()
    end)

    it("should not throw an error if the voice is resumed when there is no active challenge or response sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:activateResponseSounds()
        voice:resume()
    end)

    it("should throw an error if the voice is paused or resumed when the voice is not activated", function()
        local voice = createVoice()
        assert.has_error(function() voice:pause() end, "voice 'Patrick' was not activated")
        assert.has_error(function() voice:resume() end, "voice 'Patrick' was not activated")
    end)

    it("should stop the active challenge sound", function()
        local voice = createVoice()
        local challengeSound = createSound()

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "stop")

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")

        voice:activateChallengeSounds()
        voice:playChallengeSound("1")
        voice:stop()

        assert.stub(challengeSound.stop).was.called(1)
    end)

    it("should stop the active response sound", function()
        local voice = createVoice()
        local responseSound = createSound()

        stub.new(responseSound, "play")
        stub.new(responseSound, "stop")

        soundLookup["responses/Response.wav"] = responseSound

        voice:addResponseSoundFile("One", "Response.wav")

        voice:activateResponseSounds()
        voice:playResponseSound("One")
        voice:stop()

        assert.stub(responseSound.stop).was.called(1)
    end)

    it("should stop the active fail sound", function()
        local voice = createVoice()
        local failSound = createSound()

        stub.new(failSound, "play")
        stub.new(failSound, "stop")

        soundLookup["responses/Fail.wav"] = failSound

        voice:addFailSoundFile("Fail.wav")

        voice:activateResponseSounds()
        voice:playFailSound()
        voice:stop()

        assert.stub(failSound.stop).was.called(1)
    end)

    it("should not throw an error if the voice is stopped when there is no active challenge sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:stop()
    end)

    it("should not throw an error if the voice is stopped when there is no active response sound", function()
        local voice = createVoice()
        voice:activateResponseSounds()
        voice:stop()
    end)

    it("should not throw an error if the voice is stopped when there is no active challenge or response sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:activateResponseSounds()
        voice:stop()
    end)

    it("should throw an error if the voice is stopped when the voice is not activated", function()
        local voice = createVoice()
        assert.has_error(function() voice:stop() end, "voice 'Patrick' was not activated")
    end)

    it("should report finished if there is no active challenge sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        assert.is_true(voice:isFinished())
    end)

    it("should report finished if there is no active response sound", function()
        local voice = createVoice()
        voice:activateResponseSounds()
        assert.is_true(voice:isFinished())
    end)

    it("should report finished if there is no active challenge or response sound", function()
        local voice = createVoice()
        voice:activateChallengeSounds()
        voice:activateResponseSounds()
        assert.is_true(voice:isFinished())
    end)

    it("should report finished if the voice is not activated", function()
        local voice = createVoice()
        assert.is_true(voice:isFinished())
    end)

    it("should only report finished if the active challenge sound is finished", function()
        local voice = createVoice()
        local challengeSound = createSound()
        local finished = true

        stub.new(challengeSound, "play")
        stub.new(challengeSound, "isFinished", function() return finished end)

        soundLookup["challenges/Challenge.wav"] = challengeSound

        voice:addChallengeSoundFile("1", "Challenge.wav")
        voice:activateChallengeSounds()
        voice:playChallengeSound("1")

        assert.is_true(voice:isFinished())

        finished = false

        assert.is_false(voice:isFinished())
    end)

    it("should only report finished if the active response sound is finished", function()
        local voice = createVoice()
        local responseSound = createSound()
        local finished = true

        stub.new(responseSound, "play")
        stub.new(responseSound, "isFinished", function() return finished end)

        soundLookup["responses/Response.wav"] = responseSound

        voice:addResponseSoundFile("One", "Response.wav")
        voice:activateResponseSounds()
        voice:playResponseSound("One")

        assert.is_true(voice:isFinished())

        finished = false

        assert.is_false(voice:isFinished())
    end)
end)
