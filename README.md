# AudioChecklist for X-Plane

[![test](https://github.com/patrickl92/AudioChecklist/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/patrickl92/AudioChecklist/actions/workflows/test.yml) [![generate-ldoc](https://github.com/patrickl92/AudioChecklist/actions/workflows/ldoc.yml/badge.svg?branch=main)](https://github.com/patrickl92/AudioChecklist/actions/workflows/ldoc.yml)

This is a framework for executing checklists in X-Plane, which features:
* Different sets of checklists for each aircraft
* Automatic check of the aircraft state for each checklist item
* Audio playback for the challenges and responses of a checklist

## Installation

* Install FlyWithLua: https://forums.x-plane.org/index.php?/files/file/38445-flywithlua-ng-next-generation-edition-for-x-plane-11-win-lin-mac/
* Download [latest release](https://github.com/patrickl92/AudioChecklist/releases) (e.g. AudioChecklist_v1.0.0.zip) and unzip the file
  * Copy the content from `Modules` to `<X-Plane 11>/Resources/plugins/FlyWithLua/Modules`
  * Copy the content from `Scripts` to `<X-Plane 11>/Resources/plugins/FlyWithLua/Scripts`

## Usage

Check out the [usage description](docs/Usage.md) for a detailed overview.

Take a look at the [preview video](https://patrickl92.github.io/AudioChecklist/Preview.mp4) to see how it looks like.

The framework itself does not contain any checklists. The available checklists can be downloaded from the [SOP github repository](https://github.com/patrickl92/AudioChecklistSOPs)

If you want to create your own checklists, follow this [guide](docs/CreateSOP.md).


