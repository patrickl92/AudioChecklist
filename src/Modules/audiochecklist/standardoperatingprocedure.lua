--- Represents a standard operating procedure (SOP).
-- Each SOP contains an array of airplane ICAO codes, an array of challenge and response voices, an array of checklists and an active checklist.
-- The airplace ICAO codes indicates the airplances the SOP is intended for.
-- The challenge and response voices allow an alternate immersion of the SOP.
-- The active checklist indicates the currently executed checklist.
--
-- A SOP can have callbacks for the do_often and do_every_frame functions of the FlyWithLua framework. The callbacks are executed accordingly.
--
-- Callbacks can be added to react to the SOP getting activated and deactivated.
-- @classmod standardOperatingProcedure
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local standardOperatingProcedure = {}

local utils = require "audiochecklist.utils"

--- Executes an array of callbacks.
-- @tparam tab callbacks The callbacks array to execute.
local function executeCallbacks(callbacks)
    for _, callback in ipairs(callbacks) do
        callback()
    end
end

--- Creates a new standard operating procedure.
-- @tparam string name The name of the SOP.
-- @treturn standardOperatingProcedure The created SOP.
function standardOperatingProcedure:new(name)
    utils.verifyType("name", name, "string")

    standardOperatingProcedure.__index = standardOperatingProcedure

    local obj = {}
    setmetatable(obj, standardOperatingProcedure)

    obj.name = name
    obj.airplanes = {}
    obj.challengeVoices = {}
    obj.responseVoices = {}
    obj.checklists = {}
    obj.activatedCallbacks = {}
    obj.deactivatedCallbacks = {}
    obj.doOftenCallbacks = {}
    obj.doEveryFrameCallbacks = {}

    return obj
end

--- Gets the name of the SOP.
-- @treturn string The name of the SOP.
function standardOperatingProcedure:getName()
    return self.name
end

--- Adds an ICAO code to the array of supported airplanes.
-- @tparam string planeIcao The ICAO code to add.
function standardOperatingProcedure:addAirplane(planeIcao)
    utils.verifyType("planeIcao", planeIcao, "string")
    table.insert(self.airplanes, planeIcao)
end

--- Gets the ICAO codes of the supported airplanes.
-- @treturn tab An array which contains the ICAO codes of the supported airplances.
function standardOperatingProcedure:getAirplanes()
    return self.airplanes
end

--- Adds a voice to the list of challenge voices.
-- The first added voice is automatically set as the active challenge voice.
-- @tparam voice voice The voice to add.
function standardOperatingProcedure:addChallengeVoice(voice)
    utils.verifyNotNil("voice", voice)

    table.insert(self.challengeVoices, voice)

    if not self.activeChallengeVoice then
        self.activeChallengeVoice = voice
    end
end

--- Gets the challenge voices of the SOP.
-- @treturn tab An array which contains the challenge voices.
function standardOperatingProcedure:getChallengeVoices()
    return self.challengeVoices
end

--- Sets the active challenge voice of the SOP.
-- The voice must have been added to the challenge voices.
-- @tparam ?voice voice The new active challenge voice. Can be <code>nil</code>.
-- @raise An error is thrown if the voice is not in the list of challenge voices.
function standardOperatingProcedure:setActiveChallengeVoice(voice)
    if voice and not utils.arrayContains(self.challengeVoices, voice) then
        error("voice is not in the list of challenge voices")
    end

    self.activeChallengeVoice = voice
end

--- Gets the active challenge voice of the SOP.
-- @treturn ?voice The active challenge voice of the SOP.
function standardOperatingProcedure:getActiveChallengeVoice()
    return self.activeChallengeVoice
end

--- Adds a voice to the list of response voices.
-- The first added voice is automatically set as the active response voice.
-- @tparam voice voice The voice to add.
function standardOperatingProcedure:addResponseVoice(voice)
    utils.verifyNotNil("voice", voice)

    table.insert(self.responseVoices, voice)

    if not self.activeResponseVoice then
        self.activeResponseVoice = voice
    end
end

--- Gets the response voices of the SOP.
-- @treturn tab An array which contains the response voices.
function standardOperatingProcedure:getResponseVoices()
    return self.responseVoices
end

--- Sets the active response voice of the SOP.
-- The voice must have been added to the response voices.
-- @tparam ?voice voice The new active response voice. Can be <code>nil</code>.
-- @raise An error is thrown if the voice is not in the list of response voices.
function standardOperatingProcedure:setActiveResponseVoice(voice)
    if voice and not utils.arrayContains(self.responseVoices, voice) then
        error("voice is not in the list of response voices")
    end

    self.activeResponseVoice = voice
end

--- Gets the active response voice of the SOP.
-- @treturn ?voice The active response voice of the SOP.
function standardOperatingProcedure:getActiveResponseVoice()
    return self.activeResponseVoice
end

--- Adds a checklist to the SOP.
-- @tparam checklist checklist The checklist to add.
function standardOperatingProcedure:addChecklist(checklist)
    utils.verifyNotNil("checklist", checklist)
    table.insert(self.checklists, checklist)
end

--- Returns all checklists of the SOP.
-- @treturn tab An array which contains all checklists.
function standardOperatingProcedure:getAllChecklists()
    return self.checklists
end

--- Sets the active checklist of the SOP.
-- The checklist must have been added to the SOP.
-- @tparam ?checklist checklist The new active checklist. Can be <code>nil</code>.
-- @raise An error is thrown if the checklist does not belong to the SOP.
function standardOperatingProcedure:setActiveChecklist(checklist)
    if checklist and not utils.arrayContains(self.checklists, checklist) then
        error("checklist does not belong to the SOP")
    end

    self.activeChecklist = checklist
end

--- Gets the active checklist of the SOP.
-- @treturn ?checklist The active checklist.
function standardOperatingProcedure:getActiveChecklist()
    return self.activeChecklist
end

--- Resets the state of all checklist and their checklist items.
-- Also sets the active checklist to <code>nil</code>.
function standardOperatingProcedure:reset()
    self:setActiveChecklist(nil)

    for _, checklist in ipairs(self.checklists) do
        checklist:reset()
    end
end

--- Adds a callback which is executed if the SOP is activated.
-- @tparam func callback The callback to add.
-- @usage mySOP:addActivatedCallback(function() end)
function standardOperatingProcedure:addActivatedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.activatedCallbacks, callback)
end

--- Adds a callback which is executed if the SOP is deactivated.
-- @tparam func callback The callback to add.
-- @usage mySOP:addDeactivatedCallback(function() end)
function standardOperatingProcedure:addDeactivatedCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.deactivatedCallbacks, callback)
end

--- Executes the activated callbacks.
function standardOperatingProcedure:onActivated()
    executeCallbacks(self.activatedCallbacks)
end

--- Executes the deactivated callbacks.
function standardOperatingProcedure:onDeactivated()
    executeCallbacks(self.deactivatedCallbacks)
end

--- Adds a callback for the <code>do_often</code> function.
-- @tparam func callback The callback to add.
-- @usage mySOP:addDoOftenCallback(function() end)
function standardOperatingProcedure:addDoOftenCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.doOftenCallbacks, callback)
end

--- Adds a callback for the <code>do_every_frame</code> function.
-- @tparam func callback The callback to add.
-- @usage mySOP:addDoEveryFrameCallback(function() end)
function standardOperatingProcedure:addDoEveryFrameCallback(callback)
    utils.verifyType("callback", callback, "function")
    table.insert(self.doEveryFrameCallbacks, callback)
end

--- Executes the callbacks for the <code>do_often</code> function.
function standardOperatingProcedure:doOften()
    executeCallbacks(self.doOftenCallbacks)
end

--- Executes the callbacks for the <code>do_every_frame</code> function.
function standardOperatingProcedure:doEveryFrame()
    executeCallbacks(self.doEveryFrameCallbacks)
end

return standardOperatingProcedure
