describe("Audio", function()
    local audio
    local utils
    local loadedFilesCount

    local function round(num)
        local mult = 100
        return math.floor(num * mult + 0.5) / mult
    end

    setup(function()
        _G.load_WAV_file = function(path)
            loadedFilesCount = loadedFilesCount + 1
            return loadedFilesCount
        end

        _G.replace_WAV_file = function(soundTableEntry, path)
        end

        audio = require "audiochecklist.audio"
        utils = require "audiochecklist.utils"

        stub.new(utils, "logDebug")
        stub.new(utils, "logError")
    end)

    teardown(function()
        utils.logDebug:revert()
        utils.logError:revert()

        audio = nil
        utils = nil
    end)

    before_each(function()
        loadedFilesCount = 0
    end)

    after_each(function()
        loadedFilesCount = 0
    end)

    it("should load a WAVE file", function()
        local sound = audio.loadSoundFile("files/Checked.wav")
        assert.is_not_nil(sound)
        assert.are.equal(1, sound:getSoundTableEntry())
        assert.are.equal(0.4, round(sound.duration))
    end)

    it("should load multiple WAVE files", function()
        local sound1 = audio.loadSoundFile("files/Checked.wav")
        local sound2 = audio.loadSoundFile("files/On.wav")
        assert.is_not_nil(sound1)
        assert.is_not_nil(sound2)
        assert.are.equal(1, sound1:getSoundTableEntry())
        assert.are.equal(2, sound2:getSoundTableEntry())
    end)

    it("should load the same WAVE file multiple times", function()
        local sound1 = audio.loadSoundFile("files/Checked.wav")
        local sound2 = audio.loadSoundFile("files/Checked.wav")
        assert.is_not_nil(sound1)
        assert.is_not_nil(sound2)
        assert.are.equal(1, sound1:getSoundTableEntry())
        assert.are.equal(2, sound2:getSoundTableEntry())
    end)

    it("should throw an error if the file does not exist", function()
        assert.has_error(function() audio.loadSoundFile("files/NotExistingFile.wav") end, "The file 'files/NotExistingFile.wav' does not exist")
    end)

    it("should throw an error if the file path is invalid", function()
        assert.has_error(function() audio.loadSoundFile(nil) end, "filePath must be a string")
        assert.has_error(function() audio.loadSoundFile(0) end, "filePath must be a string")
    end)

    it("should reuse the memory of released sounds", function()
        local sound1 = audio.loadSoundFile("files/Checked.wav")
        audio.releaseSound(sound1)
        local sound2 = audio.loadSoundFile("files/On.wav")
        local sound3 = audio.loadSoundFile("files/On.wav")
        assert.is_not_nil(sound2)
        assert.is_not_nil(sound3)
        assert.are.equal(1, sound2:getSoundTableEntry())
        assert.are.equal(2, sound3:getSoundTableEntry())
    end)

    it("should throw an error if no sound to release is provided", function()
        assert.has_error(function() audio.releaseSound(nil) end, "sound must not be nil")
    end)
end)
