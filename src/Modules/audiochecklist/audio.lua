--- Provides functions to load WAVE files.
-- The module creates sound instances which can be used to control the loaded audio file.
-- The sound instances can be released again, to allow the memory to be reused if new audio files are loaded.
-- @module audio
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local audio = {}

local utils = require "audiochecklist.utils"
local sound = require "audiochecklist.sound"

local releasedSoundTableEntries = {}

--- Helper function to convert a string representation of a binary number into a number.
-- @tparam string str The string representation.
-- @treturn number The converted number.
local function binToNumber(str)
    return string.byte(str, 1) + string.byte(str, 2) * 256 + string.byte(str, 3) * 65536 + string.byte(str, 4) * 16777216
end

--- Gets the duration of a WAV file.
-- Source: https://forums.x-plane.org/index.php?/forums/topic/183135-get-wav-file-duration-using-flywithlua/.
-- @tparam string filePath The path to the sound file.
-- @treturn number The duration of the sound file in seconds.
local function getWaveFileDuration(filePath)
    local file = io.open(filePath, "rb")
    local d = 0
    local size = 0
    local byteRate = 0
    -- file could not be opened?
    if not file then
        return 0
    end
    -- unknown format? (Should always start with "RIFF")
    if file:read(4) ~= "RIFF" then
        file:close()
        return 0
    end
    -- next 4 bytes should be the total length (in bytes)
    size = binToNumber(file:read(4))
    -- next 4 bytes must always be "WAVE", otherwise unknown format
    if file:read(4) ~= "WAVE" then
        file:close()
        return 0
    end
    -- next 4 bytes must always be "fmt ", otherwise unknown format
    if file:read(4) ~= "fmt " then
        file:close()
        return 0
    end
    -- skip next 12 bytes
    file:read(12)
    -- next 4 bytes should be the byte rate (how many bytes per second)
    byteRate = binToNumber(file:read(4))
    file:close()
    -- take total length minus length of header and divide it by bytes/second --> return length in seconds
    return (size - 42) / byteRate
end

--- Loads a sound from a file.
-- @tparam string filePath The path to the sound file.
-- @treturn sound The loaded sound.
function audio.loadSoundFile(filePath)
    utils.verifyType("filePath", filePath, "string")

    if not utils.fileExists(filePath) then
        error("The file '" .. filePath .. "' does not exist")
    end

    local duration = getWaveFileDuration(filePath)
    if duration == 0 then
        utils.logError("Audio", "Duration of sound file '" .. filePath .. "' could not be determined")
    end

    local soundTableEntry = table.remove(releasedSoundTableEntries)

    if not soundTableEntry then
        utils.logDebug("Audio", "Loading sound file '" .. filePath .. "'")
        soundTableEntry = load_WAV_file(filePath)
    else
        -- Reuse the memory by replacing the previous loaded sound
        utils.logDebug("Audio", "Loading sound file '" .. filePath .. "' (reusing released FlyWithLua sound table entry " .. tostring(soundTableEntry) .. ")")
        replace_WAV_file(soundTableEntry, filePath)
    end

    return sound:new(soundTableEntry, duration)
end

--- Allows the memory of a sound to be reused by a new sound.
-- Using the sound after it has been released can lead to a wrong sound file being played.
-- @tparam sound sound The sound to release.
function audio.releaseSound(sound)
    utils.verifyNotNil("sound", sound)
    table.insert(releasedSoundTableEntries, sound:getSoundTableEntry())
end

return audio
