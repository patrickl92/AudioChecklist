local utils = require "audiochecklist.utils"
local sopRegister = require "audiochecklist.sopregister"
local sopExecutor = require "audiochecklist.sopexecutor"
local checklist = require "audiochecklist.checklist"
local checklistItem = require "audiochecklist.checklistitem"
local preferences = require "audiochecklist.preferences"

local initialized = false

-- Define the colors used in the UI
local checklistStateColors = {}
checklistStateColors[checklist.stateNotStarted] = 0xFFFFFFFF
checklistStateColors[checklist.stateInProgress] = 0xFFFFFFFF
checklistStateColors[checklist.stateCompleted] = 0xFF267F00

local itemStateColors = {}
itemStateColors[checklistItem.stateNotStarted] = 0xFFFFFFFF
itemStateColors[checklistItem.stateInProgress] = 0xFFFFFFFF
itemStateColors[checklistItem.stateSuccess] = 0xFF267F00
itemStateColors[checklistItem.stateFailed] = 0xFF0000FF
itemStateColors[checklistItem.stateDoneManually] = 0xFF267F00

local buttonColorGreen = 0xFF267F00
local buttonColorGreenHovered = 0xFF08AD00
local buttonColorGreenActive = 0xFF079600
local buttonColorDefaultDisabled = 0x806F4624
local buttonColorGreenDisabled = 0x80267F00

-- Define the variables used for displaying the preferences window
local preferencesWindow = nil

-- Define the variables used for displaying the checklist window
local checklistWindowOpen = false
local checklistWindow = nil
local checklistWindowSizeValid = false
local checklistWindowShowsScrollBar = false
local checklistWindowPoppedOut = false
local lastChecklistWindowPosition = nil
local lineLength = 45

local activeChecklistDisplayText = ""
local checklistItemsDisplayItems = {}

local allSOPs = nil
local filteredSOPs = nil
local supportedPlanes = nil
local selectedPlaneIndex = 1
local selectedSOPIndex = 1

local lastRenderedSOP = nil
local lastRenderedChecklist = nil

--- Updates the list of filtered SOPs based on the selected plane.
local function updateFilteredSOPs()
	filteredSOPs = {}

	if supportedPlanes[selectedPlaneIndex] then
		local selectedPlane = supportedPlanes[selectedPlaneIndex]
		local planeKey = preferences.escapeString(selectedPlane)
		local lastUsedSopName = preferences.get("LastUsedSOP_" .. planeKey)

		for _, sop in ipairs(allSOPs) do
			for _, plane in ipairs(sop:getAirplanes()) do
				if plane == selectedPlane then
					table.insert(filteredSOPs, sop)

					if lastUsedSopName == sop:getName() then
						-- Select the last used SOP
						selectedSOPIndex = #filteredSOPs
					end

					local sopKey = preferences.escapeString(sop:getName())
					local lastUsedChallengeVoiceName = preferences.get("LastUsedChallengeVoice_" .. planeKey .. "_" .. sopKey)
					local lastUsedResponseVoiceName = preferences.get("LastUsedResponseVoice_" .. planeKey .. "_" .. sopKey)

					for _, voice in ipairs(sop:getChallengeVoices()) do
						if lastUsedChallengeVoiceName == voice:getName() then
							-- Activate the last used challenge voice
							sop:setActiveChallengeVoice(voice)
							break
						end
					end

					for _, voice in ipairs(sop:getResponseVoices()) do
						if lastUsedResponseVoiceName == voice:getName() then
							-- Activate the last used response voice
							sop:setActiveResponseVoice(voice)
							break
						end
					end

					break
				end
			end
		end
	end
end

--- Initializes the local variables.
local function initialize()
	allSOPs = sopRegister.getAllSOPs()
	supportedPlanes = {}
	local addedPlanes = {}

	table.insert(supportedPlanes, PLANE_ICAO)
	addedPlanes[PLANE_ICAO] = true

	for _, sop in ipairs(allSOPs) do
		for _, plane in ipairs(sop:getAirplanes()) do
			if not addedPlanes[plane] then
				table.insert(supportedPlanes, plane)
				addedPlanes[plane] = true
			end
		end
	end

	table.sort(allSOPs, function (left, right) return left:getName() < right:getName() end)
	table.sort(supportedPlanes)

	for i, plane in ipairs(supportedPlanes) do
		if plane == PLANE_ICAO then
			selectedPlaneIndex = i
			break
		end
	end

	updateFilteredSOPs()
end

--- Initializes the display items for the checklist items.
-- This is an optimization to not have to rebuild the displayed text in every render call.
-- @tparam checklist checklist The checklist which contains the items to initialize.
local function setChecklistItemsDisplayItems(checklist)
	checklistItemsDisplayItems = {}

	if not checklist then
		return
	end

	-- Build the display text of the checklist (will look like '===== Title =====')
	local checklistTitle = checklist:getTitle()
	local checklistDisplayTextTable = {}
	local requiredEqualSigns = lineLength - string.len(checklistTitle) - 2

	for i=0,math.floor((requiredEqualSigns / 2) + 0.5) - 1,1 do
		checklistDisplayTextTable[#checklistDisplayTextTable + 1] = "="
	end

	checklistDisplayTextTable[#checklistDisplayTextTable + 1] = " "
	checklistDisplayTextTable[#checklistDisplayTextTable + 1] = checklistTitle
	checklistDisplayTextTable[#checklistDisplayTextTable + 1] = " "

	for i=0,(requiredEqualSigns / 2) - 1,1 do
		checklistDisplayTextTable[#checklistDisplayTextTable + 1] = "="
	end

	activeChecklistDisplayText = table.concat(checklistDisplayTextTable)

	for _, checklistItem in ipairs(checklist:getAllItems()) do
		if checklistItem:hasResponse() then
			local challengeText = checklistItem:getChallengeText()
			local responseText = checklistItem:getResponseText()

			-- Build the display text of the checklist item (will look like 'Challenge.......Response')
			local displayTextTable = {}
			local requiredDots = lineLength - string.len(challengeText) - string.len(responseText)

			displayTextTable[#displayTextTable + 1] = challengeText

			for i=0,requiredDots-1,1 do
				displayTextTable[#displayTextTable + 1] = "."
			end

			displayTextTable[#displayTextTable + 1] = responseText

			table.insert(checklistItemsDisplayItems, {
				checklistItem = checklistItem,
				displayText = table.concat(displayTextTable)
			})
		end
	end
end

--- Triggers a resize of the checklist window.
local function invalidateChecklistWindowSize()
	checklistWindowSizeValid = false
end

--- Updates the size of the checklist window based on the current checklist.
local function updateChecklistWindowSize()
	if checklistWindow == nil then
		return
	end

    utils.logDebug("Main", "Updating checklist window size")

	local checklistWindowLeft, checklistWindowTop, checklistWindowRight, checklistWindowBottom = float_wnd_get_geometry(checklistWindow)
	local xPlaneWindowLeft, xPlaneWindowTop, xPlaneWindowRight, xPlaneWindowBottom = XPLMGetScreenBoundsGlobal()

	-- Used a fixed default with, because it does not work to calculate the current width if the window is popped out
	local requiredWidth = 332
	local requiredHeight = checklistWindowTop - checklistWindowBottom
	local maxHeight = xPlaneWindowTop - xPlaneWindowBottom - 100

	-- Calculate the required height based on the content
	local activeSOP = sopExecutor.getActiveSOP()
	if activeSOP then
		local activeChecklist = activeSOP:getActiveChecklist()
		if activeChecklist then
			-- Checklist execution window
			requiredHeight = 22 * #checklistItemsDisplayItems + 69
		else
			-- Checklist selection window
			requiredHeight = 39 * #(activeSOP:getAllChecklists()) + 16
		end
	else
		-- SOP selection window
		requiredHeight = 200
	end

	if requiredHeight > maxHeight then
		-- Limit the maximum height based on the size of the X-Plane window
		requiredHeight = maxHeight

		if checklistWindowShowsScrollBar ~= true then
			-- Extend the width for the scroll bar
			requiredWidth = requiredWidth + 10
			checklistWindowShowsScrollBar = true
		end
	elseif checklistWindowShowsScrollBar == true then
		-- Remove the extra width for the scroll bar
		requiredWidth = requiredWidth - 10
		checklistWindowShowsScrollBar = false
	end

    local left = checklistWindowLeft
    local top = checklistWindowTop
    local right = checklistWindowLeft + requiredWidth
    local bottom = checklistWindowTop - requiredHeight

	-- Update the size of the window and prevent resizing
	float_wnd_set_geometry(checklistWindow, left, top, right, bottom)
	float_wnd_set_resizing_limits(checklistWindow, requiredWidth, requiredHeight, requiredWidth, requiredHeight)

    utils.logDebug("Main", "Checklist window location: Left: " .. tostring(left) .. "; Top: " .. tostring(top) .. "; Right: " .. tostring(right) .. "; Bottom: " .. tostring(bottom))
end

--- Renders the menu for selecting a standard operating procedure.
local function renderSopMenu()
	local selectedPlane = ""
	local selectedSOPName = ""
	local selectedChallengeVoiceName = ""
	local selectedResponseVoiceName = ""
	local selectedSOP = filteredSOPs[selectedSOPIndex]
	local startButtonDisabled = false

	if supportedPlanes[selectedPlaneIndex] then
		selectedPlane = supportedPlanes[selectedPlaneIndex]
	end

	if selectedSOP then
		selectedSOPName = selectedSOP:getName()

		local activeChallengeVoice = selectedSOP:getActiveChallengeVoice()
		local activeRepsonseVoice = selectedSOP:getActiveResponseVoice()

		if activeChallengeVoice then
			selectedChallengeVoiceName = activeChallengeVoice:getName()
		end

		if activeRepsonseVoice then
			selectedResponseVoiceName = activeRepsonseVoice:getName()
		end
	end

	if selectedResponseVoiceName == "" or selectedChallengeVoiceName == "" then
		-- Do not allow starting a SOP if it has no active response or challenge voices set
		startButtonDisabled = true
	end

	imgui.SetCursorPosY(15)

	-- ##################################
	-- Plane selection
	-- ##################################

	imgui.TextUnformatted("1. Select plane:")
	imgui.SameLine()
	imgui.SetCursorPosX(133)
	imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
	imgui.PushItemWidth(190)

	if imgui.BeginCombo("plane", selectedPlane) then
		for i, plane in ipairs(supportedPlanes) do
			if imgui.Selectable(plane, selectedPlaneIndex == i) then
				selectedPlaneIndex = i
				selectedSOPIndex = 1
				updateFilteredSOPs()
			end
		end

		imgui.EndCombo()
	end

	imgui.PopItemWidth()
	imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)

	-- ##################################
	-- SOP selection
	-- ##################################

	imgui.TextUnformatted("2. Select SOP:")
	imgui.SameLine()
	imgui.SetCursorPosX(133)
	imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
	imgui.PushItemWidth(190)

	if imgui.BeginCombo("sop", selectedSOPName) then
		for i, sop in ipairs(filteredSOPs) do
			if imgui.Selectable(sop:getName(), selectedSOPIndex == i) then
				selectedSOPIndex = i
			end
		end

		imgui.EndCombo()
	end

	imgui.PopItemWidth()
	imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)

	-- ##################################
	-- Voice selection (Pilot flying)
	-- ##################################

	imgui.TextUnformatted("3. Select pilots:")
	imgui.SetCursorPosX(100)
	imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)
	imgui.TextUnformatted("PF:")
	imgui.SameLine()
	imgui.SetCursorPosX(133)
	imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
	imgui.PushItemWidth(190)

	if imgui.BeginCombo("pf", selectedResponseVoiceName) then
		if selectedSOP then
			for _, voice in ipairs(selectedSOP:getResponseVoices()) do
				if imgui.Selectable(voice:getName(), voice == selectedSOP:getActiveResponseVoice()) then
					selectedSOP:setActiveResponseVoice(voice)
				end
			end
		end

		imgui.EndCombo()
	end

	imgui.PopItemWidth()

	-- ##################################
	-- Voice selection (Pilot monitoring)
	-- ##################################

	imgui.SetCursorPosX(100)
	imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)
	imgui.TextUnformatted("PM:")
	imgui.SameLine()
	imgui.SetCursorPosX(133)
	imgui.SetCursorPosY(imgui.GetCursorPosY() - 3)
	imgui.PushItemWidth(190)

	if imgui.BeginCombo("pm", selectedChallengeVoiceName) then
		if selectedSOP then
			for _, voice in ipairs(selectedSOP:getChallengeVoices()) do
				if imgui.Selectable(voice:getName(), voice == selectedSOP:getActiveChallengeVoice()) then
					selectedSOP:setActiveChallengeVoice(voice)
				end
			end
		end

		imgui.EndCombo()
	end

	imgui.PopItemWidth()

	-- ##################################
	-- Start button
	-- ##################################

	imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)

	if startButtonDisabled then
		imgui.PushStyleColor(imgui.constant.Col.Button, buttonColorDefaultDisabled)
		imgui.PushStyleColor(imgui.constant.Col.ButtonHovered, buttonColorDefaultDisabled)
		imgui.PushStyleColor(imgui.constant.Col.ButtonActive, buttonColorDefaultDisabled)
	end

	if imgui.Button("Start", 315, 25) then
		if not startButtonDisabled then
			-- Save the selected SOP and voices in the preferences
			local planeKey = preferences.escapeString(selectedPlane)
			local sopKey = preferences.escapeString(selectedSOP:getName())

			preferences.set("LastUsedSOP_" .. planeKey, selectedSOP:getName())
			preferences.set("LastUsedChallengeVoice_" .. planeKey .. "_" .. sopKey, selectedChallengeVoiceName)
			preferences.set("LastUsedResponseVoice_" .. planeKey .. "_" .. sopKey, selectedResponseVoiceName)

			-- Start the selected SOP by setting it active in the SOP executor
			sopExecutor.setActiveSOP(selectedSOP)
		end
	end

	if startButtonDisabled then
		imgui.PopStyleColor(3)
	end
end

--- Renders the menu for selecting a checklist to execute.
-- A button is displayed for each checklist. The content of the button is the title of the checklist. Clicking a button will start the execution of the checklist.
local function renderChecklistMenu(sop)
	imgui.SetCursorPosY(5)

	for _, checklist in ipairs(sop:getAllChecklists()) do
		imgui.SetCursorPosX(10)
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 10)

		local popStyles = false

		if checklist:getState() == checklist.stateCompleted then
			-- Checklist has already been completed, so change its color to green
			imgui.PushStyleColor(imgui.constant.Col.Button, buttonColorGreen)
			imgui.PushStyleColor(imgui.constant.Col.ButtonHovered, buttonColorGreenHovered)
			imgui.PushStyleColor(imgui.constant.Col.ButtonActive, buttonColorGreenActive)
			popStyles = true
		end

		if imgui.Button(checklist:getTitle(), 310, 25) then
			-- Clicking the button starts the execution of the checklist
			sopExecutor.startChecklist(checklist)
		end

		if popStyles == true then
			imgui.PopStyleColor(3)
		end
	end
end

--- Renders the given checklist.
-- @tparam checklist checklist The checklist to render.
local function renderChecklist(checklist)
	imgui.SetCursorPosX(10)
	imgui.SetCursorPosY(10)

	-- ##################################
	-- Top button bar
	-- ##################################

	if imgui.Button("Back", 70, 25) then
		-- Clicking the button stops the execution of the checklist
		sopExecutor.stopChecklist()
	end

	imgui.SameLine()
	imgui.SetCursorPosX(130)

	local checklistPaused = sopExecutor.isPaused()
	if checklistPaused then
		-- The current checklist execution is paused, so show a button to resume the execution
		if imgui.Button("Resume", 70, 25) then
			sopExecutor.resume()
		end
	else
		-- The current checklist execution is not paused, so show a button to pause the execution
		if imgui.Button("Pause", 70, 25) then
			sopExecutor.pause()
		end
	end

	local activeChecklistItem = checklist:getActiveItem()
	if activeChecklistItem and activeChecklistItem:hasResponse() then
		imgui.SameLine()
		imgui.SetCursorPosX(250)

		if checklistPaused then
			-- If the execution of the current checklist is paused, then render the "Done"/"Skip" button as disabled
			imgui.PushStyleColor(imgui.constant.Col.Button, buttonColorDefaultDisabled)
			imgui.PushStyleColor(imgui.constant.Col.ButtonHovered, buttonColorDefaultDisabled)
			imgui.PushStyleColor(imgui.constant.Col.ButtonActive, buttonColorDefaultDisabled)
		end

		if activeChecklistItem:isManualItem() then
			-- The checklist item needs to be completed manually, so provide a button to complete it
			if checklistPaused then
				-- Use the green disabled color for the "Done" button
				imgui.PopStyleColor(3)
				imgui.PushStyleColor(imgui.constant.Col.Button, buttonColorGreenDisabled)
				imgui.PushStyleColor(imgui.constant.Col.ButtonHovered, buttonColorGreenDisabled)
				imgui.PushStyleColor(imgui.constant.Col.ButtonActive, buttonColorGreenDisabled)
			else
				imgui.PushStyleColor(imgui.constant.Col.Button, buttonColorGreen)
				imgui.PushStyleColor(imgui.constant.Col.ButtonHovered, buttonColorGreenHovered)
				imgui.PushStyleColor(imgui.constant.Col.ButtonActive, buttonColorGreenActive)
			end

			if imgui.Button("Done", 70, 25) then
				-- Ignore the button click if the execution of the current checklist is paused
				if not checklistPaused then
					sopExecutor.setCurrentChecklistItemDone()
				end
			end

			if checklistPaused == false then
				imgui.PopStyleColor(3)
			end
		else
			-- The checklist item checks itself whether it is completed, so provide a button to skip it
			if imgui.Button("Skip", 70, 25) then
				-- Ignore the button click if the execution of the current checklist is paused
				if not checklistPaused then
					sopExecutor.setCurrentChecklistItemDone()
				end
			end
		end

		if checklistPaused then
			imgui.PopStyleColor(3)
		end
	end

	-- ##################################
	-- Checklist title and items
	-- ##################################

	imgui.SetCursorPosX(10)
	imgui.SetCursorPosY(50)

	-- Render the title of the checklist
	imgui.PushStyleColor(imgui.constant.Col.Text, checklistStateColors[checklist:getState()])
	imgui.TextUnformatted(activeChecklistDisplayText)
	imgui.PopStyleColor()

	imgui.SetCursorPosY(65)

	for _, displayItem in ipairs(checklistItemsDisplayItems) do
		-- Render each checklist item
		imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)
		imgui.PushStyleColor(imgui.constant.Col.Text, itemStateColors[displayItem.checklistItem:getState()])

		imgui.TextUnformatted(displayItem.displayText)

		imgui.PopStyleColor()
	end
end

--- Callback function to render the content of the preferences window.
function AudioChecklist_preferencesWindowOnRender()
	imgui.SetCursorPosX(10)
	imgui.SetCursorPosY(10)

	local autoDoneChanged, autoDoneValue = imgui.Checkbox("Enable Auto Done", sopExecutor.autoDoneEnabled())
	if autoDoneChanged then
		if autoDoneValue then
			sopExecutor.enableAutoDone()
			preferences.set("AutoDoneEnabled", "1")
		else
			sopExecutor.disableAutoDone()
			preferences.set("AutoDoneEnabled", "0")
		end
	end

	imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)

	local responseDelayChanged, responseDelayValue = imgui.SliderFloat("Response Delay", sopExecutor.getResponseDelay(), 0, 1, "%.1f seconds")
	if responseDelayChanged then
		sopExecutor.setResponseDelay(responseDelayValue)
		preferences.set("ResponseDelay", tostring(responseDelayValue))
	end

	local nextChecklistItemDelayChanged, nextChecklistItemDelayValue = imgui.SliderFloat("Next Item Delay", sopExecutor.getNextChecklistItemDelay(), 0, 1, "%.1f seconds")
	if nextChecklistItemDelayChanged then
		sopExecutor.setNextChecklistItemDelay(nextChecklistItemDelayValue)
		preferences.set("NextItemDelay", tostring(nextChecklistItemDelayValue))
	end

	imgui.SetCursorPosY(imgui.GetCursorPosY() + 5)

	local volumeChanged, volumeValue = imgui.SliderFloat("Volume", sopExecutor.getVoiceVolume() * 100, 10, 100, "%10.0f %%")
	if volumeChanged then
		sopExecutor.setVoiceVolume(volumeValue / 100)
		preferences.set("VoiceVolume", tostring(volumeValue / 100))
	end
end

--- Callback function to render the content of the checklist window.
function AudioChecklist_checklistWindowOnRender()
	checklistWindowOpen = true
	checklistWindowPoppedOut = float_wnd_is_popped(checklistWindow)

	local activeSOP = sopExecutor.getActiveSOP()
	local activeChecklist = nil

	if activeSOP then
		activeChecklist = activeSOP:getActiveChecklist()
	end

	if lastRenderedSOP ~= activeSOP then
		lastRenderedSOP = activeSOP
		invalidateChecklistWindowSize()
	end

	if lastRenderedChecklist ~= activeChecklist then
		lastRenderedChecklist = activeChecklist
		invalidateChecklistWindowSize()
		setChecklistItemsDisplayItems(activeChecklist)
	end

	if checklistWindowSizeValid ~= true then
		updateChecklistWindowSize()
		checklistWindowSizeValid = true
	end

	if activeSOP then
		local activeChecklist = activeSOP:getActiveChecklist()
		if activeChecklist then
			renderChecklist(activeChecklist)
		else
			renderChecklistMenu(activeSOP)
		end
	else
		renderSopMenu()
	end
end

--- Callback function to reset the variables for the preferences window.
function AudioChecklist_preferencesWindowOnClosed()
    utils.logDebug("Main", "Preferences window closed")
	preferencesWindow = nil
end

--- Shows the preferences window if it is not already visible.
function AudioChecklist_showPreferencesWindow()
	if preferencesWindow == nil then
        utils.logDebug("Main", "Creating preferences window")

		local windowWidth = 356
		local windowHeight = 118

		-- Create the window
		preferencesWindow = float_wnd_create(windowWidth, windowHeight, 1, true)

		-- Set the window title
		float_wnd_set_title(preferencesWindow, "Audio Checklist - Preferences")

		-- Set the callback functions
		float_wnd_set_onclose(preferencesWindow, "AudioChecklist_preferencesWindowOnClosed")
		float_wnd_set_imgui_builder(preferencesWindow, "AudioChecklist_preferencesWindowOnRender")

		-- Prevent resizing
		float_wnd_set_resizing_limits(preferencesWindow, windowWidth, windowHeight, windowWidth, windowHeight)

		-- Center window on screen
		local xPlaneWindowLeft, xPlaneWindowTop, xPlaneWindowRight, xPlaneWindowBottom = XPLMGetScreenBoundsGlobal()
		local screenWidth = xPlaneWindowRight - xPlaneWindowLeft
		local sceenHeight = xPlaneWindowTop - xPlaneWindowBottom

        local left = xPlaneWindowLeft + (screenWidth - windowWidth) / 2
        local top = xPlaneWindowBottom + (sceenHeight - windowHeight) / 2
        local right = xPlaneWindowLeft + (screenWidth + windowWidth) / 2
        local bottom = xPlaneWindowBottom + (sceenHeight + windowHeight) / 2

		float_wnd_set_geometry(preferencesWindow, left, top, right, bottom)

        utils.logDebug("Main", "Preferences window location: Left: " .. tostring(left) .. "; Top: " .. tostring(top) .. "; Right: " .. tostring(right) .. "; Bottom: " .. tostring(bottom))
	end
end

--- Callback function to reset the variables for the checklist window.
function AudioChecklist_checklistWindowOnClosed()
    utils.logDebug("Main", "Checklist window closed")

	if checklistWindowPoppedOut ~= true then
		-- Store the current location of the window
		local left, top, right, bottom = float_wnd_get_geometry(checklistWindow)
		lastChecklistWindowPosition = {
			Left = left,
			Top = top,
			Right = right,
			Bottom = bottom
		}
	end

	checklistWindow = nil
	checklistWindowOpen = false
	checklistWindowShowsScrollBar = false
	checklistWindowPoppedOut = false
end

--- Shows the checklist window if it is not already visible.
function AudioChecklist_showChecklistWindow()
	-- Initialize all variables if the window is opened the first time
	if not initialized then
		initialize()
		initialized = true
	end

	if checklistWindow == nil then
        utils.logDebug("Main", "Creating checklist window")

		local windowWidth = 332
		local windowHeight = 110

		-- Create the window
		checklistWindow = float_wnd_create(windowWidth, windowHeight, 1, true)

		-- Set the window title
		float_wnd_set_title(checklistWindow, "Audio Checklist")

		-- Set the callback functions
		float_wnd_set_onclose(checklistWindow, "AudioChecklist_checklistWindowOnClosed")
		float_wnd_set_imgui_builder(checklistWindow, "AudioChecklist_checklistWindowOnRender")

		if lastChecklistWindowPosition ~= nil then
			local checklistWindowLeft = lastChecklistWindowPosition["Left"]
			local checklistWindowTop = lastChecklistWindowPosition["Top"]
			local checklistWindowRight = lastChecklistWindowPosition["Right"]
			local checklistWindowBottom = lastChecklistWindowPosition["Bottom"]

			float_wnd_set_geometry(checklistWindow, checklistWindowLeft, checklistWindowTop, checklistWindowRight, checklistWindowBottom)
			lastChecklistWindowPosition = nil
		else
			local monitors = XPLMGetAllMonitorBoundsGlobal()
			if #monitors > 0 then
				local mainMonitor = monitors[1]
				local checklistWindowLeft = mainMonitor.inLeft + 100
				local checklistWindowTop = mainMonitor.inTop - 100
				local checklistWindowRight = checklistWindowLeft + windowWidth
				local checklistWindowBottom = checklistWindowTop - windowHeight

				float_wnd_set_geometry(checklistWindow, checklistWindowLeft, checklistWindowTop, checklistWindowRight, checklistWindowBottom)
			end
		end

        local left, top, right, bottom = float_wnd_get_geometry(checklistWindow)
        utils.logDebug("Main", "Checklist window location: Left: " .. tostring(left) .. "; Top: " .. tostring(top) .. "; Right: " .. tostring(right) .. "; Bottom: " .. tostring(bottom))

		invalidateChecklistWindowSize()
	end
end

--- Hides the checklist window if it is visible.
function AudioChecklist_hideChecklistWindow()
    if checklistWindow ~= nil then
        float_wnd_destroy(checklistWindow)
    end
end

--- Toggles the visibility of the checklist window.
function AudioChecklist_toggleChecklistWindow()
	if checklistWindowOpen ~= true then
		AudioChecklist_showChecklistWindow()
	else
		AudioChecklist_hideChecklistWindow()
	end
end

--- Calls the doOften function of the SOP executor.
function AudioChecklist_doOften()
	sopExecutor.doOften()
end

--- Calls the doEveryFrame function of the SOP executor.
function AudioChecklist_doEveryFrame()
	sopExecutor.doEveryFrame()
end

--- Executes the active checklist.
function AudioChecklist_updateChecklist()
	sopExecutor.update()
end

--- Toggles between pause and resume of the current checklist item.
function AudioChecklist_toggleChecklistPauseResume()
	if sopExecutor.isPaused() then
		sopExecutor.resume()
	else
		sopExecutor.pause()
	end
end

--- Sets the current checklist item to manually done.
function AudioChecklist_setCurrentChecklistItemDone()
	if not sopExecutor.isPaused() then
		sopExecutor.setCurrentChecklistItemDone()
	end
end

--- Resets the active SOP.
-- This allows to select another SOP or different voices.
function AudioChecklist_resetSOP()
	sopExecutor.setActiveSOP(nil)
end

--- Enables the logging of debug messages.
function AudioChecklist_enableDebugLogging()
	utils.enableDebugLogging()
end

--- Disables the logging of debug messages.
function AudioChecklist_disableDebugLogging()
	utils.disableDebugLogging()
end

--- Saves the preferences.
function AudioChecklist_savePreferences()
	preferences.save(SCRIPT_DIRECTORY .. "AudioChecklist.prefs")
end

--- Removes all preferences.
function AudioChecklist_clearPreferences()
	preferences.clear()
end

-- Load the preferences
preferences.load(SCRIPT_DIRECTORY .. "AudioChecklist.prefs")

-- Save the prefernces on exit
do_on_exit("AudioChecklist_savePreferences()")

-- Set the callback functions
do_every_frame("AudioChecklist_updateChecklist()")
do_often("AudioChecklist_doOften()")
do_every_frame("AudioChecklist_doEveryFrame()")

-- Check whether automatic completion of checklist items which requires a manual check should be enabled
if preferences.get("AutoDoneEnabled", "0") == "1" then
	sopExecutor.enableAutoDone()
end

-- Set the configured delays
sopExecutor.setResponseDelay(tonumber(preferences.get("ResponseDelay", "0.3")))
sopExecutor.setNextChecklistItemDelay(tonumber(preferences.get("NextItemDelay", "0.3")))
sopExecutor.setVoiceVolume(tonumber(preferences.get("VoiceVolume", "1")))

-- Add the provided macros and commands
add_macro("Audio Checklist: Show Window", "AudioChecklist_showChecklistWindow()")
add_macro("Audio Checklist: Switch SOP", "AudioChecklist_resetSOP()")
add_macro("Audio Checklist: Preferences", "AudioChecklist_showPreferencesWindow()")

-- Only for debugging
--add_macro("Audio Checklist: Clear Preferences", "AudioChecklist_clearPreferences()")
add_macro("Audio Checklist: Enable Debug Logging", "AudioChecklist_enableDebugLogging()", "AudioChecklist_disableDebugLogging()", "deactivate")

create_command("FlyWithLua/AudioChecklist/ToggleChecklistWindow", "Open/Close checklist window", "AudioChecklist_toggleChecklistWindow()", "", "")
create_command("FlyWithLua/AudioChecklist/TogglePauseResume", "Pause/Resume checklist", "AudioChecklist_toggleChecklistPauseResume()", "", "")
create_command("FlyWithLua/AudioChecklist/SetCurrentChecklistItemDone", "Skip/Done checklist item", "AudioChecklist_setCurrentChecklistItemDone()", "", "")