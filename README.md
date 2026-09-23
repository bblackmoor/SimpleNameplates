# Simple Nameplates

A deliberately simple standalone nameplate-color addon for World of Warcraft.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| Priority | Category | Default color | Display |
| --- | --- | --- | --- |
| 1 | Attacking me | Red | Health bar; includes attacks on your controlled units |
| 2 | Will attack me if it notices me | Orange | Health bar |
| 3 | Attackable by me, but not hostile | Yellow | Health bar |
| 4 | Opposite-faction PC | Periwinkle blue | Name when not attackable; attackable opponents use priority 1 or 2 |
| 5 | My-faction PC | Green | Name |
| 6 | Anything else Simple Nameplates can color | Light blue | Name; includes friendly NPCs and unmatched colorable units |
| — | Interruptible cast | Cyan | Optional cast-bar outline |
| — | Blizzard-controlled overhead names | Locked | Some opposing PCs, minions, interactive NPCs, and vendors |

## How It Works

Simple Nameplates does **not** draw its own replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for creating each nameplate and for health depletion, casting, channels, target treatment, classification, and other standard nameplate behavior.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

Even when WoW is configured to show friendly, enemy, and always-visible nameplates, it may not create a nameplate for every unit. If Blizzard supplies no addon-accessible nameplate frame, Simple Nameplates has nothing it can recolor. The experimental replacement option can therefore leave a unit without a visible name and is disabled by default.

## What's Displayed

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Normal Blizzard target treatment
* Optional threat percentage at the right side of the health bar when Midnight exposes a non-secret threat percentage
* Optional attacking-color glow around the health bars of attacking PCs and NPCs
* Optional cyan outline around interruptible cast bars

## Color Settings

Open **Options → AddOns → Simple Nameplates → Colors**, or type `/snp`. The six **Priority Colors** are evaluated from top to bottom. The first matching category wins. Every row has its own color and behavior selector:

* **Active** applies its Priority Color and Simple Nameplates styling, including threat percentage when Midnight exposes a readable value.
* **Inactive** leaves Blizzard's display unchanged for that category.
* **Hide** conceals that category's addon-accessible names and nameplates, and also hides matching Blizzard overhead-name categories where WoW permits it.

Color controls are available only while a category is Active. Changes apply immediately and are saved between sessions. Three locked rows document Blizzard-controlled periwinkle-blue opposing-player/minion names, yellow interactive-NPC names, and green vendor-NPC names.

The **High Contrast** preset changes Priority Colors 1–6 to magenta `#FF00FF`, orange `#FF6600`, yellow `#FFFF00`, blue `#0066FF`, cyan `#00FFFF`, and white `#FFFFFF`; changes the interruptible cast highlight to green `#00FF00`; and enables the attacking glow. It does not change the six category modes or WoW's colorblind settings.

Priority Colors 1–3 put their color on visible health bars and leave the name white for contrast. Priority Colors 4–6 are name-only whenever Simple Nameplates can style an addon-accessible frame.

Blizzard's separate overhead world names are not addon-accessible and cannot be recolored directly. **Replace Blizzard overhead names (experimental)** hides selected world-name categories and requests corresponding Blizzard nameplates so priorities 4–6 can style them. Blizzard still decides whether a unit receives a nameplate, so the experiment can leave a unit without a visible name. Any WoW CVar changed by the addon is restored when no current option needs it or Simple Nameplates styling is disabled.

**Hide Blizzard-controlled minion names** and **Hide critter and companion names** remain independent narrow controls. Their prior WoW settings are restored when disabled.

The interruptible highlight is a static outline around Blizzard's existing cast bar. It uses Blizzard's own interruptibility result, applies to casts and channels, and preserves Blizzard's normal non-interruptible shield treatment.

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

Type `/snp debug` with a unit targeted to report its detected type, reaction, faction, attackability, PvP and threat information, resulting priority category, category mode, display treatment, color, nameplate availability, and whether experimental overhead replacement is enabled. It also reports the name text region's shown, effective visibility, alpha, and immediate-parent state, plus whether the interruptible highlight is enabled, the target's cast bar and icon were found, the visibility hook was installed, and the highlight is currently shown. Restricted Midnight values are identified rather than inspected.

All four settings pages scroll when their contents do not fit the available window height.

## Download

Permanent, ready-to-install ZIP files are available from the [GitHub Releases](https://github.com/bblackmoor/SimpleNameplates/releases) page. Each release contains a `SimpleNameplates-<version>.zip` archive.

Every commit to `main` also creates a development build under [GitHub Actions](https://github.com/bblackmoor/SimpleNameplates/actions/workflows/release.yml). Development archives are named `SimpleNameplates-<version>-dev-<commit>.zip` and retained for 90 days. A version tag such as `v1.0.73` publishes the corresponding permanent release.

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
