--- Implementation of a voice which uses WAVE files as an audio source.
-- The sound files have to be mapped to the challenge and response sound keys of the checklist items.
-- @classmod waveFileVoice
-- @see voice
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local waveFileVoice = {}

local voice = require "audiochecklist.voice"
local audio = require "audiochecklist.audio"
local utils = require "audiochecklist.utils"

--- Verifies if a voice was activated.
-- @tparam voice voice The voice.
-- @raise An error is thrown if neither the challenges nor the responses of the voice were activated.
local function verifyActivated(voice)
    if not voice.challengesInitialized and not voice.responsesInitialized then
        error("voice '" .. voice:getName() .. "' was not activated")
    end
end

--- Verifies if a voice was activated for the challenges.
-- @tparam voice voice The voice.
-- @raise An error is thrown if the voice was not activated for the challenges.
local function verifyChallengesActivated(voice)
    if not voice.challengesInitialized then
        error("voice '" .. voice:getName() .. "' was not activated for the challenges")
    end
end

--- Verifies if a voice was activated for the responses.
-- @tparam voice voice The voice.
-- @raise An error is thrown if the voice was not activated for the responses.
local function verifyResponsesActivated(voice)
    if not voice.responsesInitialized then
        error("voice '" .. voice:getName() .. "' was not activated for the responses")
    end
end

--- Starts playing a sound.
-- @tparam voice voice The voice which contains the sound
-- @tparam sound sound The sound to start
local function playSound(voice, sound)
    voice:stop()

    voice.activeSound = sound
    sound:play()
end

--- Creates a new voice.
-- @tparam string name The name of the voice
-- @tparam string challengeFilesDirectoryPath The path to the directory which contains the challenge sound files. Must not be empty. If this parameter is <code>nil</code>, then no challenge sound files can be added.
-- @tparam string responseFilesDirectoryPath The path to the directory which contains the response and fail sound files. Must not be empty. If this parameter is <code>nil</code>, then no response or fail sound files can be added.
-- @treturn waveFileVoice The created voice
function waveFileVoice:new(name, challengeFilesDirectoryPath, responseFilesDirectoryPath)
    if challengeFilesDirectoryPath ~= nil then
        utils.verifyType("challengeFilesDirectoryPath", challengeFilesDirectoryPath, "string")

        if string.len(challengeFilesDirectoryPath) == 0 then
            error("challengeFilesDirectoryPath must not be empty")
        end
    end

    if responseFilesDirectoryPath ~= nil then
        utils.verifyType("responseFilesDirectoryPath", responseFilesDirectoryPath, "string")

        if string.len(responseFilesDirectoryPath) == 0 then
            error("responseFilesDirectoryPath must not be empty")
        end
    end

    waveFileVoice.__index = waveFileVoice
    setmetatable(waveFileVoice, {
        __index = voice
    })

    local obj = voice:new(name)
    setmetatable(obj, waveFileVoice)

    obj.challengeFilesDirectoryPath = challengeFilesDirectoryPath
    obj.responseFilesDirectoryPath = responseFilesDirectoryPath

    obj.challengesInitialized = false
    obj.responsesInitialized = false

    obj.challengeSoundFiles = {}
    obj.responseSoundFiles = {}
    obj.failSoundFiles = {}

    obj.challengeSounds = {}
    obj.responseSounds = {}
    obj.failSounds = {}

    return obj
end

--- Sets the volume of the voice.
-- A value of 1 means 100% (full volume), a value of 0.5 means 50% (half the volume).
-- This function should be implemented in a derived voice class.
-- @tparam numer volume The volume to use.
function waveFileVoice:setVolume(volume)
    utils.verifyType("volume", volume, "number")

    self.volume = volume

    if self.challengesInitialized then
        for _, sound in pairs(self.challengeSounds) do
            sound:setVolume(volume)
        end
    end

    if self.responsesInitialized then
        for _, sound in pairs(self.responseSounds) do
            sound:setVolume(volume)
        end

        for _, sound in pairs(self.failSounds) do
            sound:setVolume(volume)
        end
    end
end

--- Gets called when the voice is selected for providing the audio output for the challenges.
-- Can be used to initialize the voice. This function does nothing in this implementation.
function waveFileVoice:activateChallengeSounds()
    if self.challengesInitialized then
        return
    end

    for key, soundFileName in pairs(self.challengeSoundFiles) do
        local fullPath = self.challengeFilesDirectoryPath .. DIRECTORY_SEPARATOR .. soundFileName

        if utils.fileExists(fullPath) then
            local sound = audio.loadSoundFile(fullPath)

            if self.volume then
                sound:setVolume(self.volume)
            end

            self.challengeSounds[key] = sound
        else
            utils.logError("WaveFileVoice", "The file '" .. fullPath .. "' does not exist")
        end
    end

    self.challengesInitialized = true
end

--- Gets called when the voice is selected for providing the audio output for the responses and failures.
-- Can be used to initialize the voice. This function does nothing in this implementation.
function waveFileVoice:activateResponseSounds()
    if self.responsesInitialized then
        return
    end

    for key, soundFileName in pairs(self.responseSoundFiles) do
        local fullPath = self.responseFilesDirectoryPath .. DIRECTORY_SEPARATOR .. soundFileName

        if utils.fileExists(fullPath) then
            local sound = audio.loadSoundFile(fullPath)

            if self.volume then
                sound:setVolume(self.volume)
            end

            self.responseSounds[key] = sound
        else
            utils.logError("WaveFileVoice", "The file '" .. fullPath .. "' does not exist")
        end
    end

    for _, soundFileName in pairs(self.failSoundFiles) do
        local fullPath = self.responseFilesDirectoryPath .. DIRECTORY_SEPARATOR .. soundFileName

        if utils.fileExists(fullPath) then
            local sound = audio.loadSoundFile(fullPath)

            if self.volume then
                sound:setVolume(self.volume)
            end

            table.insert(self.failSounds, sound)
        else
            utils.logError("WaveFileVoice", "The file '" .. fullPath .. "' does not exist")
        end
    end

    self.responsesInitialized = true
end

--- Gets called when the voice is no longer an active audio provider for the challenges.
-- Can be used to release any resources. This function does nothing in this implementation.
function waveFileVoice:deactivateChallengeSounds()
    if not self.challengesInitialized then
        return
    end

    -- Release the loaded sounds and remove all references
    for key, _ in pairs(self.challengeSounds) do
        audio.releaseSound(self.challengeSounds[key])
        self.challengeSounds[key] = nil
    end

    self.challengesInitialized = false
end

--- Gets called when the voice is no longer an active audio provider for the responses and failures.
-- Can be used to release any resources. This function does nothing in this implementation.
function waveFileVoice:deactivateResponseSounds()
    if not self.responsesInitialized then
        return
    end

    -- Release the loaded sounds and remove all references
    for key, _ in pairs(self.responseSounds) do
        audio.releaseSound(self.responseSounds[key])
        self.responseSounds[key] = nil
    end

    for key, _ in pairs(self.failSounds) do
        audio.releaseSound(self.failSounds[key])
        self.failSounds[key] = nil
    end

    self.responsesInitialized = false
end

--- Starts playing the challenge sound with the specified key.
-- If the voice is currently paused, then the pause is reset.
-- If the key is not mapped to a sound file, then no sound is played.
-- @tparam string key The key of the challenge sound.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:playChallengeSound(key)
    utils.verifyType("key", key, "string")
    verifyChallengesActivated(self)

    local sound = self.challengeSounds[key]
    if not sound then
        utils.logError("Voice", "No challenge sound for key '" .. key .. "'")
        return
    end

    playSound(self, sound)
end

--- Starts playing the response sound with the specified key.
-- If the voice is currently paused, then the pause is reset.
-- If the key is not mapped to a sound file, then no sound is played.
-- @tparam string key The key of the response sound.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:playResponseSound(key)
    utils.verifyType("key", key, "string")
    verifyResponsesActivated(self)

    local sound = self.responseSounds[key]
    if not sound then
        utils.logError("Voice", "No response sound for key '" .. key .. "'")
        return
    end

    playSound(self, sound)
end

--- Starts playing a random fail sound
-- If the voice is currently paused, then the pause is reset.
-- If the voice does not contain a fail sound, then no sound is played.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:playFailSound()
    verifyResponsesActivated(self)

    if #self.failSounds > 0 then
        playSound(self, self.failSounds[math.random(#self.failSounds)])
    end
end

--- Pauses the active sound.
-- If there is no active sound or the voice is already paused, then this method does nothing.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:pause()
    verifyActivated(self)

    if not self.paused and self.activeSound then
        self.paused = true
        self.activeSound:pause()
    end
end

--- Resumes the active sound.
-- If there is no active sound or the voice is not paused, then this method does nothing.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:resume()
    verifyActivated(self)

    if self.paused and self.activeSound then
        self.paused = false
        self.activeSound:play()
    end
end

--- Stops playing the active sound.
-- If the voice is currently paused, then the pause is reset.
-- If there is no active sound, then this method does nothing.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:stop()
    verifyActivated(self)

    if self.activeSound then
        self.activeSound:stop()
        self.activeSound = nil
    end

    self.paused = false
end

--- Checks whether the active sound has finished playing.
-- @treturn bool <code>True</code> if there is no active sound or the active sound has finished playing, otherwise <code>false</code>.
function waveFileVoice:isFinished()
    if self.activeSound then
        return self.activeSound:isFinished()
    end

    return true
end

--- Maps a sound file to a challenge sound key.
-- The sound cannot be used until the voice has been activated after the sound has been added.
-- @tparam string key The challenge sound key.
-- @tparam string soundFileName The name of the sound file.
-- @raise An error is thrown if the path to the directory which contains the challenge sound files was not set.
function waveFileVoice:addChallengeSoundFile(key, soundFileName)
    utils.verifyType("key", key, "string")
    utils.verifyType("soundFileName", soundFileName, "string")

    if not self.challengeFilesDirectoryPath then
        error("Challenge files directory was not set")
    end

    self.challengeSoundFiles[key] = soundFileName
end

--- Maps a sound file to a response sound key.
-- The sound cannot be used until the voice has been activated after the sound has been added.
-- @tparam string key The challenge sound key.
-- @tparam string soundFileName The name of the sound file.
-- @raise An error is thrown if the path to the directory which contains the response and fail sound files was not set.
function waveFileVoice:addResponseSoundFile(key, soundFileName)
    utils.verifyType("key", key, "string")
    utils.verifyType("soundFileName", soundFileName, "string")

    if not self.responseFilesDirectoryPath then
        error("Response files directory was not set")
    end

    self.responseSoundFiles[key] = soundFileName
end

--- Adds a sound file to the list of fail sounds.
-- The sound cannot be used until the voice has been activated after the sound has been added.
-- @tparam string soundFileName The name of the sound file.
-- @raise An error is thrown if the path to the directory which contains the response and fail sound files was not set.
function waveFileVoice:addFailSoundFile(soundFileName)
    utils.verifyType("soundFileName", soundFileName, "string")

    if not self.responseFilesDirectoryPath then
        error("Response files directory was not set")
    end

    table.insert(self.failSoundFiles, soundFileName)
end

return waveFileVoice
