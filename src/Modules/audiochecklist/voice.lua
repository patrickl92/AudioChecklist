--- Acts as an interface for a voice implementation.
-- A voice is responsible for playing a specified challenge or response sound based on the provided key.
-- It may can be paused, resumed and stopped.
-- @classmod voice
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local voice = {}

local utils = require "audiochecklist.utils"

--- Creates a new voice.
-- @tparam string name The name of the voice.
-- @treturn voice The created voice
function voice:new(name)
    utils.verifyType("name", name, "string")

    voice.__index = voice

    local obj = {}
    setmetatable(obj, voice)

    obj.name = name

    return obj
end

--- Gets the name of the voice.
-- @treturn string The name of the voice.
function voice:getName()
    return self.name
end

--- Sets the volume of the voice.
-- A value of 1 means 100% (full volume), a value of 0.5 means 50% (half the volume).
-- This function should be implemented in a derived voice class.
-- @tparam numer volume The volume to use.
function voice:setVolume(volume)
end

--- Gets called when the voice is selected for providing the audio output for the challenges.
-- Can be used to initialize the voice. This function does nothing in this implementation.
function voice:activateChallengeSounds()
end

--- Gets called when the voice is selected for providing the audio output for the responses and failures.
-- Can be used to initialize the voice. This function does nothing in this implementation.
function voice:activateResponseSounds()
end

--- Gets called when the voice is no longer an active audio provider for the challenges.
-- Can be used to release any resources. This function does nothing in this implementation.
function voice:deactivateChallengeSounds()
end

--- Gets called when the voice is no longer an active audio provider for the responses and failures.
-- Can be used to release any resources. This function does nothing in this implementation.
function voice:deactivateResponseSounds()
end

--- Starts playing the challenge sound with the specified key.
-- This function should be implemented in a derived voice class.
-- @tparam string key The key of the challenge sound
function voice:playChallengeSound(key)
end

--- Starts playing the response sound with the specified key.
-- This function should be implemented in a derived voice class.
-- @tparam string key The key of the response sound
function voice:playResponseSound(key)
end

--- Starts playing a fail sound.
-- This function should be implemented in a derived voice class.
function voice:playFailSound()
end

--- Pauses the active sound.
-- This function should be implemented in a derived voice class.
function voice:pause()
end

--- Resumes the active sound.
-- This function should be implemented in a derived voice class.
function voice:resume()
end

--- Stops playing the active sound.
-- This function should be implemented in a derived voice class.
function voice:stop()
end

--- Checks whether the active sound has finished playing.
-- This function should be implemented in a derived voice class.
-- @treturn bool Always <code>true</code>.
function voice:isFinished()
    return true
end

return voice
