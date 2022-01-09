--- Provides functions to play a loaded sound.
-- A sound can be started, paused and resumed. It also provides information if the sound has finished playing.
-- @classmod sound
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local sound = {}

local utils = require "audiochecklist.utils"

--- Creates a new sound.
-- @tparam number soundTableEntry The reference to the entry in the FlyWithLua sound table.
-- @tparam number duration The duration of the sound.
-- @treturn sound The created sound.
function sound:new(soundTableEntry, duration)
    utils.verifyType("soundTableEntry", soundTableEntry, "number")
    utils.verifyType("duration", duration, "number")

    sound.__index = sound

    local obj = {}
    setmetatable(obj, sound)

    obj.soundTableEntry = soundTableEntry
    obj.duration = duration
    obj.endTime = 0
    obj.pauseStartTime = 0

    return obj
end

--- Plays or resumes the sound.
function sound:play()
    if self.pauseStartTime == 0 then
        -- If the sound is already playing then it is restarted
        self:stop()

        -- Start playing the sound
        play_sound(self.soundTableEntry)
        self.endTime = os.time() + self.duration
    else
        -- Resume the sound
        play_sound(self.soundTableEntry)

        -- Recalculate the new end time
        local pauseDuration = os.time() - self.pauseStartTime
        self.endTime = self.endTime + pauseDuration
        self.pauseStartTime = 0
    end
end

--- Pauses the sound.
-- The sound is not paused if the sound has already been paused, has not been started or has finished playing.
function sound:pause()
    if self.pauseStartTime == 0 and not self:isFinished() then
        pause_sound(self.soundTableEntry)
        self.pauseStartTime = os.time()
    end
end

-- Stops playing the sound.
-- This function also resets the pause of the sound.
function sound:stop()
    stop_sound(self.soundTableEntry)
    self.endTime = 0
    self.pauseStartTime = 0
end

--- Checks whether the sound has finished playing.
-- @treturn bool <code>True</code> if the sound has not bee started, is currently paused or has finished playing, otherwise <code>false</code>.
function sound:isFinished()
    return self.endTime == 0 or (os.time() > self.endTime and self.pauseStartTime == 0)
end

--- Gets the reference to the entry in the FlyWithLua sound table.
-- @treturn number The reference to the sound table entry.
function sound:getSoundTableEntry()
    return self.soundTableEntry
end

return sound
