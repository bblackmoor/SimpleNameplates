# Simple Nameplates

A deliberately simple standalone nameplate-color addon for World of Warcraft.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| State or indicator | Default color | Meaning |
| --- | --- | --- |
| Friendly NPC | Green | Friendly non-player character; colored name |
| Friendly PC | Light blue | Friendly same-faction player; colored name |
| Unfriendly NPC | Yellow | Attackable, but non-aggressive; colored health bar |
| Hostile opponent | Orange | Aggressive NPC or PvP-enabled opposing PC; colored health bar |
| Attacking | Red | PC or NPC attacking you or one of your controlled units; colored health bar |
| Interruptible cast | Cyan | Optional cast-bar outline for interruptible casts and channels |
| Blizzard overhead name | Periwinkle blue, locked | Non-attackable opposing PCs and many player-controlled minions; minion, critter, and companion names can be hidden |
| Interactive NPC overhead name | Yellow, locked | Interactive NPCs such as city guards; cannot be restyled by addons |
| Vendor NPC overhead name | Green, locked | Vendor NPCs; cannot be restyled by addons |

## How It Works

Simple Nameplates does **not** draw replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for creating each nameplate and for health depletion, casting, channels, target treatment, classification, and other standard nameplate behavior.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

Even when WoW is configured to show friendly, enemy, and always-visible nameplates, it may not create a nameplate for every unit. If Blizzard supplies no addon-accessible nameplate frame, Simple Nameplates has nothing it can recolor or replace.

## What's Displayed

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Normal Blizzard target treatment
* Optional threat percentage at the right side of the health bar when Midnight exposes a non-secret threat percentage
* Optional attacking-color glow around the health bars of attacking PCs and NPCs
* Optional cyan outline around interruptible cast bars

## Color Settings

Open **Options → AddOns → Simple Nameplates → Colors**, or type `/snp`, to customize five relationship colors and the interruptible cast-bar highlight. Each editable row identifies where its color appears and has its own reset button. Changes apply immediately and are saved between sessions. Three locked informational rows explain Blizzard-controlled periwinkle-blue, yellow interactive-NPC, and green vendor-NPC overhead names. The **High Contrast** and **Reset Colors** buttons are at the top of the panel. Four options are disabled by default: **Hide Blizzard-controlled minion names**, **Hide critter and companion names**, **Glow attacking units**, and **Highlight interruptible casts and channels**.

The **High Contrast** preset replaces the editable colors with cyan `#00FFFF`, blue `#0066FF`, yellow `#FFFF00`, orange `#FF6600`, magenta `#FF00FF`, and white `#FFFFFF`. It avoids relying on a red/green distinction and enables the attacking glow so the attacking state also has a non-color cue. A confirmation explains both changes before the preset is applied. The preset does not alter WoW's own colorblind mode, filter type, or filter strength; Blizzard's global filter continues to affect the rendered addon normally.

Units without health bars display their relationship color on the name. When a health bar is present, the name remains white for contrast and the bar carries the relationship color.

Blizzard's separate overhead world names cannot be recolored because they are not addon-accessible nameplate frames. Yellow interactive-NPC names, including city guards that offer directions, and green vendor-NPC names have the same limitation as the periwinkle names. The periwinkle category includes non-attackable opposing-faction PCs and many player-controlled pets, guardians, totems, and minions. **Hide Blizzard-controlled minion names** hides the friendly and enemy minion categories while leaving opposing-player names visible. Disabling the option restores the prior Blizzard name settings. **Hide critter and companion names** separately hides Blizzard's overhead names for noncombat critters and companions, and likewise restores the prior game setting when disabled.

The interruptible highlight is a static outline around Blizzard's existing cast bar. It uses Blizzard's own interruptibility result, applies to both ordinary casts and channels, preserves their different bar textures and progress directions, and is drawn above the optional attacking glow. Non-interruptible abilities retain Blizzard's normal shield treatment without the added outline.

## Text Settings

Open **Options → AddOns → Simple Nameplates → Text**, or type `/snp text`, to choose:

* The unit-name font.
* A shared 8–36 point size for addon-controlled floating names and names above health bars.
* A separate threat-percentage font.
* Whether names appear above or inside visible health bars.
* Whether available threat percentages are displayed.

Both fonts default to WoW's built-in **Arial Narrow** with a normal outline, and names default to 12 points. Other standard Blizzard fonts are available without an external font library. Inside-bar names use 80% of the selected size, rounded to the nearest point. Their health bars resize to leave two UI units above and below the text, then return to Blizzard's original height when names move above the bar or Simple Nameplates styling is disabled. Friendly name-only plates are unaffected by the placement setting. Blizzard-controlled overhead names have no nameplate frame, so their size and font remain controlled by the game.

## TRP3 Integration

Open **Options → AddOns → Simple Nameplates → TRP3**, or type `/snp trp3`. The page begins with **Display TRP3 profile information**, which is disabled by default.

When enabled, Simple Nameplates can use a character's TRP3 roleplaying full name, put the short title before the name, show the long title on a separate line beneath the name, and mark out-of-character profiles. If the OOC option is enabled, `[OOC]` replaces the short title; IC profiles receive no marker. Long titles use 80% of the name size and are hidden for units with visible health bars.

Each field has its own toggle. To keep nameplates readable, roleplaying names are limited to 32 characters, short titles to 20, and long titles to 48; longer values end with an ellipsis. The normal WoW name is used whenever a cached TRP3 profile or selected field is unavailable. `TRP3.lua` keeps the optional profile access isolated, and Simple Nameplates continues to work normally without TRP3.

## About and Diagnostics

The main **Simple Nameplates** AddOns page is an About screen showing the addon version, author, category, license, source repository, and slash commands. The displayed version is read directly from the addon's `.toc` metadata so it cannot drift from the installed release. Click the source URL to open a copy-ready dialog.

Type `/snp debug` with a unit targeted to report its detected type, reaction, faction, attackability, PvP and threat information, resulting state, display treatment, and color. It also reports the name text region's shown, effective visibility, alpha, and immediate-parent state, plus whether the interruptible highlight is enabled, the target's cast bar and icon were found, the visibility hook was installed, and the highlight is currently shown. Restricted Midnight values are identified rather than inspected.

All four settings pages scroll when their contents do not fit the available window height.

## Download

Ready-to-install ZIP files are available from the [GitHub Releases](https://github.com/bblackmoor/SimpleNameplates/releases) page. Each release contains a versioned `SimpleNameplates-<version>.zip` archive.

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

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so applying the shared red attacking color to PCs is best effort: it is used when WoW reports threat on you or your pet, or when the hostile player is targeting you, your pet, guardian, or minion.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## AI Disclaimer

AI-assisted tools were used during the development of this project. The author reviewed and approved the resulting code and documentation and remains responsible for the project.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))

Licensed under the GNU General Public License v3.0 (GPL-3.0):

https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
