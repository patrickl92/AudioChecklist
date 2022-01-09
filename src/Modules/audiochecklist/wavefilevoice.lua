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

local function verifyActivated(voice)
    if not voice.initialized then
        error("voice '" .. voice:getName() .. "' was not activated")
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
-- @tparam string challengeFilesDirectoryPath The path to the directory which contains the challenge sound files. If this parameter is an empty string, then no challenge sound files can be added.
-- @tparam string responseFilesDirectoryPath The path to the directory which contains the response and fail sound files. If this parameter is an empty string, then no response or fail sound files can be added.
-- @treturn waveFileVoice The created voice
function waveFileVoice:new(name, challengeFilesDirectoryPath, responseFilesDirectoryPath)
    utils.verifyType("challengeFilesDirectoryPath", challengeFilesDirectoryPath, "string")
    utils.verifyType("responseFilesDirectoryPath", responseFilesDirectoryPath, "string")

    waveFileVoice.__index = waveFileVoice
    setmetatable(waveFileVoice, {
        __index = voice
    })

    local obj = voice:new(name)
    setmetatable(obj, waveFileVoice)

    obj.challengeFilesDirectoryPath = challengeFilesDirectoryPath
    obj.responseFilesDirectoryPath = responseFilesDirectoryPath
    obj.initialized = false

    obj.challengeSoundFiles = {}
    obj.responseSoundFiles = {}
    obj.failSoundFiles = {}

    obj.challengeSounds = {}
    obj.responseSounds = {}
    obj.failSounds = {}

    return obj
end

--- Gets called when the voice is selected for providing the audio output.
-- Loads all audio files into the FlyWithLua sound table.
function waveFileVoice:onActivated()
    if self.initialized then
        return
    end

    for key, soundFileName in pairs(self.challengeSoundFiles) do
        local fullPath = self.challengeFilesDirectoryPath .. DIRECTORY_SEPARATOR .. soundFileName

        if utils.fileExists(fullPath) then
            self.challengeSounds[key] = audio.loadSoundFile(fullPath)
        else
            utils.logError("WaveFileVoice", "The file '" .. fullPath .. "' does not exist")
        end
    end

    for key, soundFileName in pairs(self.responseSoundFiles) do
        local fullPath = self.responseFilesDirectoryPath .. DIRECTORY_SEPARATOR .. soundFileName

        if utils.fileExists(fullPath) then
            self.responseSounds[key] = audio.loadSoundFile(fullPath)
        else
            utils.logError("WaveFileVoice", "The file '" .. fullPath .. "' does not exist")
        end
    end

    for _, soundFileName in pairs(self.failSoundFiles) do
        local fullPath = self.responseFilesDirectoryPath .. DIRECTORY_SEPARATOR .. soundFileName

        if utils.fileExists(fullPath) then
            table.insert(self.failSounds, audio.loadSoundFile(fullPath))
        else
            utils.logError("WaveFileVoice", "The file '" .. fullPath .. "' does not exist")
        end
    end

    self.initialized = true
end

--- Gets called when the voice is no longer an active audio provider.
-- Releases all loaded audio files.
function waveFileVoice:onDeactivated()
    if not self.initialized then
        return
    end

    self:stop()

    -- Release the loaded sounds and remove all references
    for key, _ in pairs(self.challengeSounds) do
        audio.releaseSound(self.challengeSounds[key])
        self.challengeSounds[key] = nil
    end

    for key, _ in pairs(self.responseSounds) do
        audio.releaseSound(self.responseSounds[key])
        self.responseSounds[key] = nil
    end

    for key, _ in pairs(self.failSounds) do
        audio.releaseSound(self.failSounds[key])
        self.failSounds[key] = nil
    end

    self.initialized = false
end

--- Starts playing the challenge sound with the specified key.
-- If the voice is currently paused, then the pause is reset.
-- If the key is not mapped to a sound file, then no sound is played.
-- @tparam string key The key of the challenge sound.
-- @raise An error is thrown if the voice was not activated.
function waveFileVoice:playChallengeSound(key)
    utils.verifyType("key", key, "string")
    verifyActivated(self)

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
    verifyActivated(self)

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
    verifyActivated(self)

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

    if self.challengeFilesDirectoryPath == "" then
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

    if self.responseFilesDirectoryPath == "" then
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

    if self.responseFilesDirectoryPath == "" then
        error("Response files directory was not set")
    end

    table.insert(self.failSoundFiles, soundFileName)
end

return waveFileVoice
