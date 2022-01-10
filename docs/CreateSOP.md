# How to create a standard operating procedure
## Definitions

* **Standard operating procedure (SOP)**: Contains a set of checklists and voices
* **Checklist**: Contains a set of checklist items
* **Checklist item**: Provides a challenge and response text, as well as keys for the challenge and response sounds
* **Voice**: Responsible for playing audio files based on the provided sound keys

Check out the [LDoc](https://patrickl92.github.io/AudioChecklist/ldoc/) page for the provided classes.

## Standard operating procedure

The user needs to select a SOP in order to use this extensions. It is possible to have multiple SOPs installed, each one with its own set of checklists and voices.

A SOP needs to have a name and at least one supported airplane set. If no airplane is set on the SOP, then it is not available to the user.

```
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

```
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

```
-- Let's imagine we have a checklist item which defines the challenge key 'Battery' and the response key 'On'
-- Create a voice which uses WAVE files to play sounds
local voice = waveFileVoice:new("Voice name", "path/to/challenge/files", "path/to/response/files")

-- Map the sound keys to an audio file
-- Make sure you use the correct mapping function for the challenges and responses
voice:addChallengeSoundFile("Battery", "Item_Battery.wav")
voice:addResponseSoundFile("On", "Response_On.wav")

-- Play the file "path/to/audio/files/Item_Battery.wav"
voice:playChallengeSound("Item_Start")

-- Play the file "path/to/response/files/Response_On.wav"
voice:playResponseSound("On")
```

## Voice

A voice plays audio based on the provided sound keys. A voice can either provide only challenge sounds or response sounds, or both.

You can easily implement your own audio sources (e.g. create the sounds using a text-to-speech engine). All you need to do is to create a class which derives from the base [voice](https://patrickl92.github.io/AudioChecklist/ldoc/classes/voice.html) class and implement its methods. Once created, just add it to the SOP:

```
local voice = myAwesomeVoice:new("Voice name")

mySOP:addChallengeVoice(voice)
mySOP:addResponseVoice(voice)
```
