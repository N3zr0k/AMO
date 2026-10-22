# AMO - Ammunition Management Organizer

Ammo helper for hunters in WoW Forever (interface 16001). Works on its own, no other addon needed.

## Contents

* [Features](#features)
* [Options](#options)
* [Commands](#commands)
* [Installation](#installation)
* [Credits](#credits)
* [License](#license)

## Features

* Warns when the quiver is about to run empty (estimated from your use in combat, from a chosen number of filled quiver slots) and urgently when only a few rounds are left.
* Warns before a dungeon if there is too little ammo.
* Messages with a saying per race.
* Tooltip on ammo, quiver and ammo pouch: supply per kind, rounds per minute (average and last fight), time until empty.
* Optionally equips the best usable ammo automatically (when a stack is empty, the next weaker one follows; not in combat).
* At a vendor, asks whether the quiver should be refilled with the strongest usable ammo.
* The whole addon can be switched off; for other classes it does nothing.

## Options

Game options, category **AMO**. All values can be set with sliders and toggles. Settings are stored in `AMODB`.

## Commands

* `/amo` opens the options.
* `/amo debug [on|off]` switches debug mode. Debug messages appear only in the BugLab console; without BugLab there are none.
* `/amo equip` shows what the ammo equip would do right now.

## Installation

Copy the `AMO` folder into `Interface/AddOns`.

## Credits

Ace3 libraries (LibStub, CallbackHandler, AceAddon, AceEvent, AceDB, AceLocale, AceGUI, AceConfig). Moved here from Glimpse: Classes.

## License

MIT, see `LICENSE`.
