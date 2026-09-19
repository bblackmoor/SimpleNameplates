# Simple Nameplates

A deliberately simple standalone nameplate-color addon for World of Warcraft.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| Unit state | Default color | Meaning |
| --- | --- | --- |
| Friendly NPC | Green | You cannot fight them |
| Unfriendly NPC | Yellow | Attackable, but non-aggressive |
| Hostile NPC | Orange | Will attack, but is not attacking your group |
| Attacking NPC | Red | Attacking you, a pet, or a group member |
| Friendly PC | Light blue | Same faction |
| Unfriendly PC | Periwinkle | Opposite faction, but not PvP-enabled; name only |
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

Open **Options → AddOns → Simple Nameplates → Colors**, or type `/snp`, to customize all eight colors. Changes apply immediately and are saved between sessions. The panel also includes a **Reset Colors** button.

## About

The main **Simple Nameplates** AddOns page is an About screen showing the addon version, author, category, license, source repository, and slash commands. The displayed version is read directly from the addon's `.toc` metadata so it cannot drift from the installed release. Click the source URL to open a copy-ready dialog.

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

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so the attacking-PC color is best effort: it is used when WoW reports threat or when the hostile player is targeting you, your pet, or a member of your group.

## Changelog

### 2.0.24

* Distinguishes same-faction and opposite-faction players by actual faction rather than sanctuary reaction.
* Keeps non-PvP opposite-faction players name-only and applies their configured name color.
* Repairs Blizzard name-color overwrites with a lightweight cached-state reconciliation pass.

### 2.0.23

* Fresh standalone release with no previous-version or legacy-settings handling.
* Warns at login when another enabled third-party “plate” addon may conflict.
* Uses `/snp` for settings and About commands.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))
Licensed under the GNU General Public License v3.0 (GPL-3.0):
https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
