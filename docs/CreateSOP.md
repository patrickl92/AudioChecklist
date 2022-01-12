# How to create a standard operating procedure
## Definitions

* **Standard operating procedure (SOP)**: Contains a set of checklists and voices
* **Checklist**: Contains a set of checklist items
* **Checklist item**: Provides a challenge and response text, as well as keys for the challenge and response sounds
* **Voice**: Responsible for playing audio files based on the provided sound keys

Check out the [LDoc](https://patrickl92.github.io/AudioChecklist/ldoc/) page for the provided classes.

## First step

Create a `.lua` file (e.g. `MySOP.lua`) in the `<X-Plane 11>/Resources/plugins/FlyWithLua/Scripts` folder. This file is loaded automatically when an aircraft is loaded in X-Plane. Add the code which is required for your SOP in this file.

You may want to install the [DataRefTool](https://github.com/leecbaker/datareftool) to find out the required DataRefs for your checklists.

## Standard operating procedure

The user needs to select a SOP in order to use this extensions. It is possible to have multiple SOPs installed, each one with its own set of checklists and voices.

A SOP needs to have a name and at least one supported airplane set. If no airplane is set on the SOP, then it is not available to the user.

```lua
-- Load the SOP module
local standardOperatingProcedure = require "audiochecklist.standardoperatingprocedure"

-- Create a new SOP with the name "My first SOP"
local mySOP = standardOperatingProcedure:new("My first SOP")

-- Add the ICAO code of the supported airplanes (at least one)
mySOP:addAirplane("B738")
```

## Checklist

An SOP consists of multiple checklists. If a SOP is selected by the user, all checklists of that SOP are listed and can be executed.

A checklist needs a display title and a set of checklist items, which are executed in the order in which they were added to the checklist. You can add as many checklists as you need to your SOP.

```lua
-- Load the checklist module
local checklist = require "audiochecklist.checklist"

-- Create a new checklist with the title "PREFLIGHT"
-- The title should be upper case, so it has the same appearance as the existing SOPs
local preflightChecklist = checklist:new("PREFLIGHT")

-- Add the checklist to the SOP
mySOP:addChecklist(preflightChecklist)
```

## Sound mapping

Before explaining the checklist item, you should know how the sound mapping works. Each checklist item needs to define at least a challenge sound, which is played when the item is executed. Response sounds are also required, but there is one exception where it can be ommitted (see [soundChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/soundChecklistItem.html)).

The checklist items do not play the sounds by themself, but use a voice to play a required sound. Sounds are mapped using unique string keys, which allows to use different audio sources, even in the same SOP.

The AudioChecklist ships with only one voice implementation, which uses WAVE files to play sounds. For this type of voice, the sound keys need to be mapped to audio files. If a checklist items is executed, the sound key is passed to the active voice, which looks up the mapped audio file for that key and starts playing it.

```lua
-- Load the waveFileVoice module
local waveFileVoice = require "audiochecklist.wavefilevoice"

-- Let's imagine we have a checklist item which defines the challenge key 'Battery' and the response key 'On'
-- Create a voice which uses WAVE files to play sounds
local voice = waveFileVoice:new("Voice name", "path/to/challenge/files", "path/to/response/files")

-- Map the sound keys to an audio file
-- Make sure you use the correct mapping function for the challenges and responses
voice:addChallengeSoundFile("Battery", "Item_Battery.wav")
voice:addResponseSoundFile("On", "Response_On.wav")

-- Note: The following lines are only here to show how the voices are used
-- Playing sounds is handled by the framework, so you don't need to play any sounds yourself

-- Play the file "path/to/audio/files/Item_Battery.wav"
voice:playChallengeSound("Item_Start")

-- Play the file "path/to/response/files/Response_On.wav"
voice:playResponseSound("On")
```

## Voice

A voice plays audio based on the provided sound keys. A voice can either provide only challenge sounds or response sounds, or both.

```lua
-- Load the waveFileVoice module
local waveFileVoice = require "audiochecklist.wavefilevoice"

-- Create a voice which only supports challenges
local challengeVoice = waveFileVoice:new("The challenge voice", "path/to/challenges", nil)

-- Create a voice which only supports responses and failures
local responseVoice = waveFileVoice:new("The response voice", nil, "path/to/responses")

-- Create a voice which supports challenges, responses and failures
local challengeAndResponseVoice = waveFileVoice:new("Third voice", "other/challenge/files", "other/response/files")

-- Map the sound keys to an audio file
challengeVoice:addChallengeSoundFile("Battery", "Item_Battery.wav")
responseVoice:addResponseSoundFile("On", "Response_On.wav")
challengeAndResponseVoice:addChallengeSoundFile("Battery", "Item_Battery.wav")
challengeAndResponseVoice:addResponseSoundFile("On", "Response_On.wav")

-- Add the voices to the SOP
mySOP:addChallengeVoice(challengeVoice)
mySOP:addResponseVoice(responseVoice)
mySOP:addChallengeVoice(challengeAndResponseVoice)
mySOP:addResponseVoice(challengeAndResponseVoice)
```

A SOP needs at least one challenge voice and one response voice (which can be the same object). If the SOP contains multiple voices, then the user can select the challenge and response voice he wants to use.

If you want something else than WAVE files as an audio source, then you can easily implement your own audio source (e.g. create the sounds using a text-to-speech engine). All you need to do is to create a class which derives from the base [voice](https://patrickl92.github.io/AudioChecklist/ldoc/classes/voice.html) class and implement its methods. Once created, just add it to the SOP:

```lua
local voice = myAwesomeVoice:new("Voice name")

mySOP:addChallengeVoice(voice)
mySOP:addResponseVoice(voice)
```

## Checklist items

A checklist should contain at least one checklist item. The framework ships with different types of checklist items. In the following code samples, the sound key mapping of the voice is ommitted to focus on each checklist item.

The [utils](https://patrickl92.github.io/AudioChecklist/ldoc/modules/utils.html) module provides useful functions to access DataRefs in X-Plane, which are used in the code samples below. To use it, it needs to be loaded once:

```lua
-- Load the utils module
local utils = require "audiochecklist.utils"
```

### Sound item

The [soundChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/soundChecklistItem.html) plays a single sound and completes after the sound has been played. It can be used to mark the start and the end of a checklist.

```lua
-- Load the soundChecklistItem module
local soundChecklistItem = require "audiochecklist.soundchecklistitem"

-- Create the item and add it to the checklist
preflightChecklist:addItem(soundChecklistItem:new("Preflight_Start"))
```

### Automatic item

The [automaticChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/automaticChecklistItem.html) uses a callback function to check whether a specific condition is met. It requires a challenge and response text as well as a key for the challenge sound. This checklist item uses the response text as the key for the response sound.

If the callback function indicates that the condition is not met, then a fail sound is played and the checklist execution waits until the condition is met or the checklist item is skipped.

```lua
-- Load the automaticChecklistItem module
local automaticChecklistItem = require "audiochecklist.automaticchecklistitem"

function checkIsBatteryOn()
  return utils.readDataRefFloat("laminar/B738/electric/battery_pos") == 1
end

-- Create the item and add it to the checklist
-- The key for the response sound in this example is "ON"
preflightChecklist:addItem(automaticChecklistItem:new("BATTERY", "ON", "Preflight_Battery", checkIsBatteryOn))
```

You can also use this checklist item to finish items automatically (e.g. if the condition does not make sense in the simulator)

```lua
-- Plays the challenge and response sound and continues automatically
preflightChecklist:addItem(automaticChecklistItem:new("GEAR PINS", "REMOVED", "Preflight_Battery", function() return true end))
```

### Automatic item with dynamic response

Some items requires the response to be different based on the current state of the aircraft (e.g. Flaps setting or Anti-Ice). The [automaticDynamicResponseChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/automaticDynamicResponseChecklistItem.html) extends the [automaticChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/automaticChecklistItem.html) by a callback which provides the response sound key to use when the checklist item has met its condition.

```lua
-- Load the automaticDynamicResponseChecklistItem module
local automaticDynamicResponseChecklistItem = require "audiochecklist.automaticdynamicresponsechecklistitem"

function checkIsAntiIceValid()
  return utils.readDataRefFloat("laminar/B738/ice/eng1_heat_pos") == utils.readDataRefFloat("laminar/B738/ice/eng2_heat_pos")
end

local function getResponseAntiIce()
  if utils.readDataRefFloat("laminar/B738/ice/eng1_heat_pos") == 1 then
    return "ON"
  end

  return "OFF"
end

-- Create the item and add it to the checklist
-- The condition is met if both anti-ice switches have the same state
-- The response is based on the state of the anti-ice switches (either "ON" or "OFF")
preflightChecklist:addItem(automaticDynamicResponseChecklistItem:new("ANTI-ICE", "__", "Preflight_AntiIce", getResponseAntiIce, checkIsAntiIceValid))
```

### Manual item

The [manualChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/manualChecklistItem.html) needs to be set to completed by the user. It requires a challenge and response text as well as a key for the challenge sound. This checklist item uses the response text as the key for the response sound.

The checklist execution waits until the user has set this item to completed.

```lua
-- Load the manualChecklistItem module
local manualChecklistItem = require "audiochecklist.manualchecklistitem"

-- Create the item and add it to the checklist
-- The key for the response sound in this example is "ON"
preflightChecklist:addItem(automaticChecklistItem:new("FLIGHT INSTRUMENTS", "CHECKED", "Preflight_FlightInstruments"))
```

### Manual item with dynamic response

Some items requires the response to be different from the displayed response text (e.g. Fuel). The [manualDynamicResponseChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/manualDynamicResponseChecklistItem.html) extends the [manualChecklistItem](https://patrickl92.github.io/AudioChecklist/ldoc/classes/manualChecklistItem.html) by a callback which provides the response sound key to use when the user sets the item to completed.

```lua
-- Load the manualDynamicResponseChecklistItem module
local manualDynamicResponseChecklistItem = require "audiochecklist.manualdynamicresponsechecklistitem"

-- Create the item and add it to the checklist
-- The text "__ REQ, __ ONBOARD" will be display in the checklist window, but once completed the response "CHECKED" is played
preflightChecklist:addItem(manualDynamicResponseChecklistItem:new("FUEL", "__ REQ, __ ONBOARD", "Preflight__Fuel", function() return "CHECKED" end))
```

## Checking conditions frequently

Some checklist items may require an action to be performed before the checklist item is actually executed (e.g. checking the oxygen). FlyWithLua offers functions to execute code in different intervals. However, the provided code is executed always, despite your SOP not being active. To prevent this, you can add callbacks to your SOP which are only executed if your SOP is active.

```lua
local oxygenChecked = false

-- Gets called every second
local function updateDataRefVariablesOften()
  -- read values which are not changed often (e.g. engines are running)
end

-- Gets called every frame
local function updateDataRefVariablesEveryFrame()
  if not oxygenChecked and (utils.readDataRefFloat("laminar/B738/push_button/oxy_test_cpt_pos") == 1) then
    -- The oxygon check has been performed
    oxygenChecked = true
  end
end

-- Set the callbacks for the updates
mySOP:addDoOftenCallback(updateDataRefVariablesOften)
mySOP:addDoEveryFrameCallback(updateDataRefVariablesEveryFrame)

-- The checklist item just returns the state of the local variable
-- This allows the oxygen check to be performed any time prior the exection of the checklist item
preflightChecklist:addItem(automaticChecklistItem:new("OXYGEN", "TESTED, 100%", "Preflight_Oxygen", function() return oxygenChecked end))
```

## Registering the SOP

Once the setup of your SOP is done, it needs to be registered to be detected by the framework.

```lua
-- Load the sopRegister module
local sopRegister = require "audiochecklist.sopregister"

-- Register the SOP
sopRegister.addSOP(mySOP)
```
