# EllesmereUI Simple Nameplates

A deliberately simple alternative nameplate-color module for **EllesmereUI**.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| Unit state | Default color | Meaning |
| --- | --- | --- |
| Friendly NPC | Green | You cannot fight them |
| Unfriendly NPC | Yellow | Attackable, but non-aggressive |
| Hostile NPC | Orange | Will attack, but is not attacking your group |
| Attacking NPC | Red | Attacking you, a pet, or a group member |
| Friendly PC | Light blue | Same faction |
| Unfriendly PC | Periwinkle | Opposite faction, but not PvP-enabled |
| Hostile PC | Purple | PvP-enabled opposite-faction player |
| Attacking PC | Magenta | Hostile player targeting or generating threat on your group |

## How It Works

Simple Nameplates does **not** draw replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for health depletion, casting, channels, target treatment, classification, and other standard nameplate behavior.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

## What's Displayed

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Normal Blizzard target treatment
* Threat percentage at the right side of the health bar when Midnight exposes a non-secret threat percentage

## Color Settings

Open **Options → AddOns → EllesmereUI Simple Nameplates**, or type `/esnp`, to customize all eight colors. Changes apply immediately and are saved between sessions. The panel also includes a **Reset Colors** button.

## Installation

1. Exit World of Warcraft.
2. Extract `EllesmereUISimpleNameplates` into `_retail_/Interface/AddOns/`.
3. Disable **EllesmereUI Nameplates** in the AddOns list.
4. Enable **EllesmereUI Simple Nameplates** and **EllesmereUI**.
5. Log in.

## EllesmereUI Nameplates Conflict

**EllesmereUI Nameplates and EllesmereUI Simple Nameplates should not be enabled at the same time.**

If the standard EllesmereUI Nameplates addon is enabled, Simple Nameplates displays a startup warning with a **Disable & Reload** button.

## Midnight and Secret Values

World of Warcraft: Midnight may mark some threat information as secret.

Simple Nameplates does not attempt to inspect secret values. Threat percentage is displayed only when WoW allows the value to be read.

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so the attacking-PC color is best effort: it is used when WoW reports threat or when the hostile player is targeting you, your pet, or a member of your group.

## Changelog

### 0.3.0

* Added separate colors for four NPC states and four player-character states.
* Added a standard WoW AddOns settings panel with eight color pickers and a reset button.
* Added `/esnp` to open the color settings directly.
* Added safe Midnight handling for restricted PvP and unit-comparison values.
* Player-controlled pets, guardians, minions, and vehicles use the player color language.

### 0.2.0

* Removed the custom overlay nameplate that caused duplicate nameplates.
* Reworked Simple Nameplates to recolor Blizzard's existing nameplates instead.
* Preserved Blizzard health depletion and cast/channel bars.
* Simplified reaction and threat coloring to green, yellow, orange, and red.
* Retained the startup conflict warning for EllesmereUI Nameplates.

### 0.1.1

* Added a startup conflict warning for EllesmereUI Nameplates.

### 0.1.0

* Initial test implementation.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))
Licensed under the GNU General Public License v3.0 (GPL-3.0):
https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
