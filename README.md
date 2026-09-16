# EllesmereUI Simple Nameplates

A deliberately simple alternative nameplate-color module for **EllesmereUI**.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but replaces the confusing assortment of nameplate colors with four easy-to-understand colors:

| Color      | Meaning                                  |
| ---------- | ---------------------------------------- |
| **Green**  | Friendly — you cannot fight them         |
| **Yellow** | Neutral — attackable, but non-aggressive |
| **Orange** | Hostile — not currently attacking you    |
| **Red**    | Attacking you — you have aggro           |

That's it.

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

## Changelog

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
