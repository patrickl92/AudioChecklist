--- Contains the logic for executing a checklist.
-- A SOP needs to be set in order to execute a checklist. Any checklist of the active SOP can be started or stopped at any time.
-- The state of the active checklist and its checklist items is updated during execution. All the required sounds are played using the active voices of the SOP.
-- Execution of a checklist can be paused and resumed.
--
-- The update function needs to be called regularly to continue the execution of the current checklist.
--
-- Callbacks can be added to react to SOPs getting activated and deactivated, checklists being started, cancelled and completed and checklist items getting started, failed and completed.
-- @module sopExecutor
-- @author Patrick Lang
-- @copyright 2022 Patrick Lang
local sopExecutor = {
    executionModeDefault = 0,
    executionModeAutoDone = 1,
    executionModeManual = 2
}

local utils = require "audiochecklist.utils"
local audio = require "audiochecklist.audio"

local paused = false
local pauseStartTime = 0

local executionMode = sopExecutor.executionModeDefault

local activeSOP = nil
local challengeVoice = nil
local responseVoice = nil
local activeVoice = nil

local voiceVolume = 1

local responseDelay = 0.3
local nextChecklistItemDelay = 0.3
local responseDelayFinishedTime = 0
local nextChecklistItemDelayFinishedTime = 0

local sopActivatedCallbacks = {}
local sopDeactivatedCallbacks = {}
local checklistStartedCallbacks = {}
local checklistCancelledCallbacks = {}
local checklistCompletedCallbacks = {}
local checklistItemStartedCallbacks = {}
local checklistItemFailedCallbacks = {}
local checklistItemCompletedCallbacks = {}

--- Executes each callback and passes the provided parameters.
-- @tparam tab callbacks The callbacks array.
-- @param ... The parameters for the callback.
local function executeCallbacks(callbacks, ...)
    for _, callback in ipairs(callbacks) do
        callback(...)
    end
end

--- Activates the specified voice.
-- The previous active voice is stopped.
-- @tparam voice voice The voice to activate.
local function activateVoice(voice)
    if activeVoice then
        activeVoice:stop()
    end

    activeVoice = voice
end

--- Starts playing the challenge sound for the given checklist item.
-- @tparam checklistItem checklistItem The checklist item.
local function playChallenge(checklistItem)
    local key = checklistItem:getChallengeKey()

    utils.logDebug("SopExecutor", "Playing challenge sound '" .. key .. "'")

    activateVoice(challengeVoice)
    challengeVoice:playChallengeSound(key)
end

--- Starts playing the response sound for the given checklist item.
-- @tparam checklistItem checklistItem The checklist item.
local function playResponse(checklistItem)
    local key = checklistItem:getResponseKey()

    utils.logDebug("SopExecutor", "Playing response sound '" .. key .. "'")

    activateVoice(responseVoice)
    responseVoice:playResponseSound(key)
end

--- Starts playing a random fail sound.
local function playFailResponse()
    utils.logDebug("SopExecutor", "Playing random fail sound")

    activateVoice(responseVoice)
    responseVoice:playFailSound()
end

--- Sets the execution mode.
--
-- Supported modes:
--
-- 0: Default execution mode. Automatic checks are performed and manual checklist items needs to be completed manually.
-- 1: Auto Done. Automatic checks are performed and manual checklist items are automatically completed.
-- 2: Manual. No automatic checks are performed and each checklist item needs to be completed manually. Also does not play any response sound.
-- @tparam mode number The new execution mode.
function sopExecutor.setExecutionMode(mode)
    utils.verifyType("mode", mode, "number")

    if mode ~= sopExecutor.executionModeDefault and mode ~= sopExecutor.executionModeAutoDone and mode ~= sopExecutor.executionModeManual then
        error("Invalid execution mode: " .. tostring(mode))
    end

    utils.logInfo("SopExecutor", "Setting execution mode to " .. tostring(mode))
    executionMode = mode
end

--- Gets the current execution mode.
-- @treturn number The current execution mode.
function sopExecutor.getExecutionMode()
    return executionMode
end

--- Sets the active standard operating procedure.
-- This deactivates the previously active standard operating procedure.
-- @tparam ?standardOperatingProcedure sop The standard operating procedure to activate. Can be <code>nil</code>.
-- @raise An error is thrown if the standard operating procedure has no active challenge voice or no active response voice set.
function sopExecutor.setActiveSOP(sop)
    sopExecutor.stopChecklist()

    if activeSOP then
        utils.logInfo("SopExecutor", "Deactivating SOP '" .. activeSOP:getName() .. "'")

        challengeVoice:deactivateChallengeSounds()
        responseVoice:deactivateResponseSounds()
        activeSOP:reset()
        activeSOP:onDeactivated()
        executeCallbacks(sopDeactivatedCallbacks, activeSOP)

        challengeVoice = nil
        responseVoice = nil
    end

    activeSOP = sop

    if activeSOP then
        utils.logInfo("SopExecutor", "Activating SOP '" .. activeSOP:getName() .. "'")

        -- Reset the SOP to ensure a correct state
        activeSOP:reset()

        challengeVoice = activeSOP:getActiveChallengeVoice()
        responseVoice = activeSOP:getActiveResponseVoice()

        if not challengeVoice then
            activeSOP = nil
            error("SOP does not have an active challenge voice set")
        end

        if not responseVoice then
            activeSOP = nil
            error("SOP does not have an active response voice set")
        end

        utils.logInfo("SopExecutor", "Challenge voice: '" .. challengeVoice:getName() .. "'")
        utils.logInfo("SopExecutor", "Response voice: '" .. responseVoice:getName() .. "'")

        challengeVoice:setVolume(voiceVolume)
        responseVoice:setVolume(voiceVolume)

        challengeVoice:activateChallengeSounds()
        responseVoice:activateResponseSounds()
        activeSOP:onActivated()
        executeCallbacks(sopActivatedCallbacks, activeSOP)
    end
end

--- Gets the active standard operating procedure.
-- @treturn ?standardOperatingProcedure The active standard operating procedure.
function sopExecutor.getActiveSOP()
    return activeSOP
end

--- Starts the execution of a checklist.
-- The checklist must be part of the active SOP.
-- If there has already been a checklist started, then the previous execution is stopped.
-- @tparam checklist checklist The checklist to execute.
-- @raise An error is thrown if there is no active SOP or the checklist does not belong to the active SOP.
function sopExecutor.startChecklist(checklist)
    if not activeSOP then error("There is no active standard operating procedure") end
    utils.verifyNotNil("checklist", checklist)
    if not utils.arrayContains(activeSOP:getAllChecklists(), checklist) then error("Active standard operating procecure does not contain the given checklist") end

    sopExecutor.stopChecklist()

    utils.logDebug("SopExecutor", "Starting execution of checklist '" .. checklist:getTitle() .. "'")

    activeSOP:setActiveChecklist(checklist)
    checklist:reset()
    checklist:setState(checklist.stateInProgress)
    checklist:onStarted()
    executeCallbacks(checklistStartedCallbacks, checklist, activeSOP)
end

--- Stops the execution of the active checklist.
-- It also resets the pause of the active checklist.
-- This function does nothing if no checklist has been started.
function sopExecutor.stopChecklist()
    paused = false
    activeVoice = nil

    if activeSOP then
        local checklist = activeSOP:getActiveChecklist()
        if checklist then
            utils.logDebug("SopExecutor", "Stopping execution of checklist '" .. checklist:getTitle() .. "'")

            checklist:reset()

            activeSOP:setActiveChecklist(nil)
            challengeVoice:stop()
            responseVoice:stop()

            checklist:onCancelled()
            executeCallbacks(checklistCancelledCallbacks, checklist, activeSOP)
        end
    end
end

--- Executes the <code>do_often</code> callback of the active SOP.
-- This function does nothing if no SOP has been activated.
function sopExecutor.doOften()
    if activeSOP then
        activeSOP:doOften()
    end
end

--- Executes the <code>do_every_frame</code> callback of the active SOP.
-- This function does nothing if no SOP has been activated.
function sopExecutor.doEveryFrame()
    if activeSOP then
        activeSOP:doEveryFrame()
    end
end

--- Executes the active SOP and its checklist.
-- This function needs to be called regularly in order to execute the checklist.
-- This function does nothing if no SOP has been activated, no checklist has been started or the execution is paused.
function sopExecutor.update()
    if paused or not activeSOP then
        return
    end

    local checklist = activeSOP:getActiveChecklist()
    if not checklist then
        return
    end

    local checklistItem = checklist:getActiveItem()
    if not checklistItem then
        return
    end

	if utils.getTime() < nextChecklistItemDelayFinishedTime then
		-- Wait for the delay between the checklist items to finish
		return
	end

    nextChecklistItemDelayFinishedTime = 0

    if checklistItem:getState() == checklistItem.stateNotStarted then
        utils.logDebug("SopExecutor", "Starting execution of checklist item '" .. (checklistItem:getChallengeText() or "<nil>") .. "'")

        -- Set the state of the checklist item to InProgress and play its challenge sound
        checklistItem:setState(checklistItem.stateInProgress)
        checklistItem:onStarted()
        executeCallbacks(checklistItemStartedCallbacks, checklistItem, checklist, activeSOP)
        playChallenge(checklistItem)
    end

    -- Wait for the currently played sound to finish
    if not activeVoice or activeVoice:isFinished() then
		if activeVoice and checklistItem:getState() ~= checklistItem.stateSuccess and checklistItem:hasResponse() and responseDelay > 0 then
			-- Sound has been finished and checklist item has a response
			responseDelayFinishedTime = utils.getTime() + responseDelay
		end

		activeVoice = nil

        if checklistItem:getState() ~= checklistItem.stateSuccess and utils.getTime() >= responseDelayFinishedTime then
            responseDelayFinishedTime = 0

            if not checklistItem:hasResponse() then
                utils.logDebug("SopExecutor", "Checklist item does not have a response, setting it to completed")

                -- Checklist item does not have a response, so only set it to completed
                checklistItem:setState(checklistItem.stateSuccess)
                checklistItem:onCompleted()
                executeCallbacks(checklistItemCompletedCallbacks, checklistItem, checklist, activeSOP)
            elseif checklistItem:getState() == checklistItem.stateDoneManually then
                utils.logDebug("SopExecutor", "Checklist item has been completed manually, setting it to completed")

                -- Checklist item was completed manually, so update its state and play the response sound
                checklistItem:setState(checklistItem.stateSuccess)
                checklistItem:onCompleted()
                executeCallbacks(checklistItemCompletedCallbacks, checklistItem, checklist, activeSOP)
                playResponse(checklistItem)
            elseif not checklistItem:isManualItem() and executionMode ~= sopExecutor.executionModeManual then
                if checklistItem:evaluate() then
                    utils.logDebug("SopExecutor", "Conditions of the checklist item are met, setting it to completed")

                    -- The conditions of the checklist items are met, so set it to completed and play the response sound
                    checklistItem:setState(checklistItem.stateSuccess)
                    checklistItem:onCompleted()
                    executeCallbacks(checklistItemCompletedCallbacks, checklistItem, checklist, activeSOP)
                    playResponse(checklistItem)
                elseif checklistItem:getState() ~= checklistItem.stateFailed then
                    utils.logDebug("SopExecutor", "Conditions of the checklist item are not met, setting it to failed")

                    -- The conditions of the checklist items are not met, so set it to failed and play a random fail sound
                    checklistItem:setState(checklistItem.stateFailed)
                    checklistItem:onFailed()
                    executeCallbacks(checklistItemFailedCallbacks, checklistItem, checklist, activeSOP)
                    playFailResponse()
                end
            elseif executionMode == sopExecutor.executionModeAutoDone then
                utils.logDebug("SopExecutor", "Automatic completion of manual checklist items is enabled, setting it to completed")

                -- Automatic completion of manual checklist items is enabled, so set it to completed and play the response sound
                checklistItem:setState(checklistItem.stateSuccess)
                checklistItem:onCompleted()
                executeCallbacks(checklistItemCompletedCallbacks, checklistItem, checklist, activeSOP)
                playResponse(checklistItem)
            end
        end

        if not activeVoice and checklistItem:getState() == checklistItem.stateSuccess then
            utils.logDebug("SopExecutor", "Execution of checklist item '" .. (checklistItem:getChallengeText() or "<nil>") .. "' completed")

            -- No new sound (e.g. the response to the checklist item) has been started and the checklist item has been completed
            if checklist:hasNextItem() then
                -- Move to the next checklist item if there is one
                checklist:setNextItemActive()

                if nextChecklistItemDelay > 0 then
				    nextChecklistItemDelayFinishedTime = utils.getTime() + nextChecklistItemDelay
                end
            else
                -- Checklist has been completed
                checklist:setState(checklist.stateCompleted)
                checklist:onCompleted()
                executeCallbacks(checklistCompletedCallbacks, checklist, activeSOP)
                activeSOP:setActiveChecklist(nil)
            end
        end
    end
end

--- Pauses the execution of a checklist.
-- This function does nothing if no checklist has been started.
function sopExecutor.pause()
    if not paused and activeSOP and activeSOP:getActiveChecklist() then
        utils.logInfo("SopExecutor", "Pausing checklist execution")

        paused = true
        pauseStartTime = utils.getTime()

        if activeVoice then
            activeVoice:pause()
        end
    end
end

--- Resumes the execution of a checklist.
-- This function does nothing if the execution is not paused.
function sopExecutor.resume()
    if paused then
        utils.logInfo("SopExecutor", "Resuming checklist execution")

        paused = false

        -- Apply the pause duration to the delays
        local pauseDuration = utils.getTime() - pauseStartTime;
        if responseDelayFinishedTime > 0 then
            responseDelayFinishedTime = responseDelayFinishedTime + pauseDuration
        end

        if nextChecklistItemDelayFinishedTime > 0 then
            nextChecklistItemDelayFinishedTime = nextChecklistItemDelayFinishedTime + pauseDuration
        end

        if activeVoice then
            activeVoice:resume()
        end
    end
end

--- Checks whether execution of the checklist is currently paused.
-- @treturn bool <code>True</code> if the execution is paused, otherwise <code>false</code>.
function sopExecutor.isPaused()
    return paused
end

--- Sets the current checklist item to manually done.
-- This function does nothing if there is no checklist item active.
-- It can be used to complete the manual checklist items or to skip failed automatic checklist items.
function sopExecutor.setCurrentChecklistItemDone()
    if activeSOP then
        local checklist = activeSOP:getActiveChecklist()
        if checklist then
            local checklistItem = checklist:getActiveItem()
            if checklistItem:getState() ~= checklistItem.stateSuccess then
                utils.logDebug("SopExecutor", "Setting checklist item '" .. (checklistItem:getChallengeText() or "<nil>") .. "' to done manually")
                checklistItem:setState(checklistItem.stateDoneManually)
            end
        end
    end
end

--- Sets the delay for playing the response sound.
-- This also delays the evaluation of the checklist item.
-- @tparam number delay The delay to use in seconds. Must be greater or equal to zero.
function sopExecutor.setResponseDelay(delay)
	utils.verifyType("delay", delay, "number")
	if delay < 0 then error ("Delay must be greater or equal to zero") end

    utils.logDebug("SopExecutor", "Set response delay: " .. tostring(delay))
	responseDelay = delay
end

--- Gets the delay for playing the response sound.
-- @treturn number The currently used delay.
function sopExecutor.getResponseDelay()
	return responseDelay
end

--- Sets the delay for the execution of the next checklist item.
-- @tparam number delay The delay to use in seconds. Must be greater or equal to zero.
function sopExecutor.setNextChecklistItemDelay(delay)
	utils.verifyType("delay", delay, "number")
	if delay < 0 then error ("Delay must be greater or equal to zero") end

    utils.logDebug("SopExecutor", "Set response delay: " .. tostring(delay))
	nextChecklistItemDelay = delay
end

--- Gets the delay for the execution of the next checklist item.
-- @treturn number The currently used delay.
function sopExecutor.getNextChecklistItemDelay()
	return nextChecklistItemDelay
end

--- Sets the volume of the challenge and response voices.
-- A value of 1 means 100% (full volume), a value of 0.5 means 50% (half the volume).
-- @tparam numer volume The volume to use.
function sopExecutor.setVoiceVolume(volume)
    utils.verifyType("volume", volume, "number")
	if volume <= 0 then error ("Volume must be greater than zero") end

    utils.logDebug("SopExecutor", "Set volume: " .. tostring(volume))
    voiceVolume = volume

    if challengeVoice then
        challengeVoice:setVolume(voiceVolume)
    end

    if responseVoice then
        responseVoice:setVolume(voiceVolume)
    end
end

--- Gets the volume of the challenge and response voices.
-- A value of 1 means 100% (full volume), a value of 0.5 means 50% (half the volume).
-- @treturn number The currently used volume.
function sopExecutor.getVoiceVolume()
	return voiceVolume
end

--- Adds a callback which is executed if a SOP is activated.
-- The activated SOP is passed as parameter to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addSOPActivatedCallback(function(sop) end)
function sopExecutor.addSOPActivatedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(sopActivatedCallbacks, callback)
end

--- Adds a callback which is executed if a SOP is deactivated.
-- The SOP is passed as parameter to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addSOPDeactivatedCallback(function(sop) end)
function sopExecutor.addSOPDeactivatedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(sopDeactivatedCallbacks, callback)
end

--- Adds a callback which is executed if a checklist is started.
-- The started checklist and the active SOP are passed as parameters to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addChecklistStartedCallback(function(checklist, sop) end)
function sopExecutor.addChecklistStartedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(checklistStartedCallbacks, callback)
end

--- Adds a callback which is executed if a checklist is cancelled.
-- The cancelled checklist and the active SOP are passed as parameters to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addChecklistCancelledCallback(function(checklist, sop) end)
function sopExecutor.addChecklistCancelledCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(checklistCancelledCallbacks, callback)
end

--- Adds a callback which is executed if a checklist is completed.
-- The completed checklist and the active SOP are passed as parameters to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addChecklistCompletedCallback(function(checklist, sop) end)
function sopExecutor.addChecklistCompletedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(checklistCompletedCallbacks, callback)
end

--- Adds a callback which is executed if a checklist item is started.
-- The started checklist item, its checklist and the active SOP are passed as parameters to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addChecklistItemStartedCallback(function(checklistItem, checklist, sop) end)
function sopExecutor.addChecklistItemStartedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(checklistItemStartedCallbacks, callback)
end

--- Adds a callback which is executed if a checklist item has failed.
-- The failed checklist item, its checklist and the active SOP are passed as parameters to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addChecklistItemFailedCallback(function(checklistItem, checklist, sop) end)
function sopExecutor.addChecklistItemFailedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(checklistItemFailedCallbacks, callback)
end

--- Adds a callback which is executed if a checklist item is completed.
-- The completed checklist item, its checklist and the active SOP are passed as parameters to the callback.
-- @tparam func callback The callback to add.
-- @usage sopExecutor.addChecklistItemCompletedCallback(function(checklistItem, checklist, sop) end)
function sopExecutor.addChecklistItemCompletedCallback(callback)
    utils.verifyType("callback", callback, "function")
	table.insert(checklistItemCompletedCallbacks, callback)
end

return sopExecutor
