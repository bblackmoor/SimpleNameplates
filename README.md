# Simple Nameplates

A deliberately simple standalone nameplate-color addon for World of Warcraft.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| Unit state | Default color | Meaning |
| --- | --- | --- |
| Friendly NPC | Light blue | You cannot fight them |
| Unfriendly NPC | Yellow | Attackable, but non-aggressive |
| Hostile NPC | Orange | Will attack, but is not attacking you or one of your controlled units |
| Attacking NPC | Red | Attacking you, your pet, guardian, or minion |
| Friendly PC | Green | Same faction, including your pets, guardians, and minions |
| Unfriendly PC | Yellow | Opposite faction, but neither side can attack; name only |
| Attackable PC | Yellow | Either side can attack, but the player is not attacking you or one of your controlled units |
| Attacking PC | Red | Player targeting or generating threat on you or one of your controlled units |

## How It Works

Simple Nameplates does **not** draw replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for health depletion, casting, channels, target treatment, classification, and other standard nameplate behavior.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

## What's Displayed

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Normal Blizzard target treatment
* Optional threat percentage at the right side of the health bar when Midnight exposes a non-secret threat percentage
* Optional same-color glow around PC health bars

## Color Settings

Open **Options → AddOns → Simple Nameplates → Colors**, or type `/snp`, to customize all eight colors. Each row identifies whether its color appears on the name or health bar and has its own reset button. Changes apply immediately and are saved between sessions. The panel also includes **Reset Colors**, a master styling switch, and an optional **Glow PC health bars** setting, disabled by default. Name-only PCs cannot glow because they have no visible health bar.

Units without health bars display their relationship color on the name. When a health bar is present, the name remains white for contrast and the bar carries the relationship color.

## Text Settings

Open **Options → AddOns → Simple Nameplates → Text**, or type `/snp text`, to choose:

* The unit-name font.
* A separate threat-percentage font.
* Whether names appear above or inside visible health bars.
* Whether available threat percentages are displayed.

Both fonts default to WoW's built-in **Arial Narrow** with a normal outline. Other standard Blizzard fonts are available without an external font library. Inside-bar names automatically shrink to fit the existing bar; the bar itself is not resized. Friendly and unattackable name-only plates are unaffected by the placement setting.

## TRP3 Integration

Open **Options → AddOns → Simple Nameplates → TRP3**, or type `/snp trp3`. The page begins with **Display TRP3 profile information**, which is disabled by default.

When enabled, Simple Nameplates can use a character's TRP3 roleplaying full name, put the short title before the name, show the full title on a separate line above the name, and mark out-of-character profiles. If the OOC option is enabled, `[OOC]` replaces the short title; IC profiles receive no marker. Full titles always remain outside the health bar, even when the name itself is inside it.

Each field has its own toggle. The normal WoW name is used whenever a cached TRP3 profile or selected field is unavailable. `TRP3.lua` keeps the optional profile access isolated, and Simple Nameplates continues to work normally without TRP3.

## About

The main **Simple Nameplates** AddOns page is an About screen showing the addon version, author, category, license, source repository, and slash commands. The displayed version is read directly from the addon's `.toc` metadata so it cannot drift from the installed release. Click the source URL to open a copy-ready dialog.

Type `/snp debug` with a unit targeted to report its detected type, reaction, faction, attackability, PvP and threat information, resulting state, display treatment, and color. Restricted Midnight values are identified rather than inspected.

## Installation

1. Exit World of Warcraft.
2. Extract `SimpleNameplates` into `_retail_/Interface/AddOns/`.
3. Enable **Simple Nameplates**.
4. Log in.

## Other Nameplate Addons

Simple Nameplates checks the enabled addon list at login. If it finds another third-party addon whose name or title contains “plate,” it displays a warning listing the possible conflicts. Blizzard's own internal addons are ignored.

Running multiple nameplate addons can cause competing colors or duplicate nameplates. Disable the others and reload the UI if you see problems.

## Midnight and Secret Values

World of Warcraft: Midnight may mark some threat information as secret.

Simple Nameplates does not attempt to inspect secret values. Threat percentage is displayed only when WoW allows the value to be read.

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so the attacking-PC color is best effort: it is used when WoW reports threat on you or your pet, or when the hostile player is targeting you, your pet, guardian, or minion.

## Changelog

### 1.0.32

* Added a master styling switch that restores Blizzard nameplates and friendly-color settings when disabled.
* Added `/snp debug` diagnostics for the current target.
* Labeled every color row as a colored name or health bar and added individual reset buttons.
* Added a threat-percentage display toggle, enabled by default.
* Clarified that PC glow applies only to PCs with visible health bars.

### 1.0.31

* Reduced attack detection to the player and the player's pets, guardians, and minions.
* Health events now update only health instead of reclassifying and restyling the plate.
* Coalesced duplicate event refreshes and narrowed Blizzard hooks to the visual they repair.
* Replaced repeated name rewriting with a slower cached drift check.
* Reduced new-nameplate delayed refreshes and refreshes TRP3 text from profile events.

### 1.0.30

* Reset the standalone addon's release line to `1.0.(build number)`.
* Updated the tracked Git hook to generate future `1.0` build versions automatically.

### 1.0.29

* Changed the defaults to light-blue friendly NPCs and green friendly PCs and player-controlled units.
* Uses yellow for both attackable non-aggressive NPCs and attackable non-attacking PCs.
* Uses actual two-way attackability rather than inferred War Mode to decide whether an opposing PC receives a health bar.
* Correctly recognizes the player's own temporary guardians and minions as friendly player-controlled units.
* Added an optional same-color glow around PC health bars, disabled by default.

### 1.0.28

* Left-aligned names and TRP3 full titles with the health bar.
* Kept threat percentages right-aligned with the health bar.

### 1.0.27

* Added optional TRP3 roleplaying full names with automatic WoW-name fallback.
* Added optional short titles before names.
* Added `[OOC]` indicators that replace short titles; IC profiles receive no marker.
* Added optional full titles on a separate line above the name and always outside the health bar.

### 1.0.26

* Added an optional `TRP3.lua` integration skeleton using public TRP3 APIs.
* Added a TRP3 settings page with a master profile-display toggle, disabled by default.
* Added TRP3 availability status and `/snp trp3`.
* No TRP3 profile fields are displayed yet.

### 1.0.25

* Added a Text settings page with separate name and threat-font selectors.
* Changed both default fonts to Arial Narrow with a normal outline.
* Added Above Bar and Inside Bar placement for names on hostile-unit health bars.
* Inside-bar names automatically shrink and reserve space for the threat percentage.
* Added `/snp text`.

### 1.0.24

* Distinguishes same-faction and opposite-faction players by actual faction rather than sanctuary reaction.
* Keeps non-PvP opposite-faction players name-only and applies their configured name color.
* Repairs Blizzard name-color overwrites with a lightweight cached-state reconciliation pass.

### 1.0.23

* Fresh standalone release with no previous-version or legacy-settings handling.
* Warns at login when another enabled third-party “plate” addon may conflict.
* Uses `/snp` for settings and About commands.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))
Licensed under the GNU General Public License v3.0 (GPL-3.0):
https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
