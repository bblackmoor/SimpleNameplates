# Changelog

## 1.0.59

* Made inside-bar names 80% of the selected name size, rounded to the nearest point.
* Resized inside-name health bars with one UI unit of vertical margin on each side and restored Blizzard's original height otherwise.

## 1.0.58

* Added a shared 6–24 point name-size setting, defaulting to 12, for addon-controlled floating names and names above health bars.
* Limited TRP3 roleplaying names to 32 characters, short titles to 20, and full titles to 48, adding an ellipsis when truncated.

## 1.0.57

* Centered friendly names and TRP3 full titles when their health bars are hidden.

## 1.0.56

* Fixed some friendly-player names disappearing when name-only styling hid Blizzard's containing health-bar frame.
* Expanded `/snp debug` with the name region's text, shown state, effective visibility, alpha, and immediate-parent visibility.

## 1.0.50

* Fixed TRP3 full-title refreshes attempting to set text before their custom FontString had a font.

## 1.0.49

* Added a confirmed **Colorblind — Web Safe** preset for all editable colors.
* Applying the accessibility preset also enables the attacking glow without changing Blizzard's colorblind settings.

## 1.0.48

* Added cast-highlight state to `/snp debug`.
* Added versioned SavedVariables migrations and separated relationship colors from effect colors internally.
* Made every settings page scrollable and replaced fixed vertical coordinates with a layout cursor.
* Moved release history out of the README and removed the redundant packaged `README.txt`.

## 1.0.47

* Added an optional, customizable interruptible cast-bar highlight, cyan by default.
* Preserves Blizzard's cast, channel, and non-interruptible treatments while drawing the highlight above the attacking glow.

## 1.0.46

* Renamed Blizzard's fixed overhead-name color from lavender to periwinkle blue.

## 1.0.45

* Clarified that addons can request nameplates but cannot force Blizzard to create them.
* Simplified the attacking-glow label and corrected descriptions of engine-controlled overhead names.

## 1.0.44

* Changed the optional glow into an attacking-state indicator for both PCs and NPCs.
* The glow now always uses the configured Attacking color.

## 1.0.43

* Consolidated hostile NPCs and PvP-enabled opposing PCs into one orange setting.
* Consolidated attacking PCs and NPCs into one red combat-override setting.
* Added a locked informational row explaining Blizzard-controlled periwinkle-blue overhead names.
* Migrates customized NPC hostile and attacking colors and removes obsolete PC-specific colors.

## 1.0.42

* Removed the nonfunctional global overhead-name font setting and its saved value.

## 1.0.41

* Prevented recursive database initialization when legacy CVar restoration fires `CVAR_UPDATE`.
* Clears obsolete replacement-name state before restoring its saved WoW settings.

## 1.0.40

* Delayed overhead-font initialization until saved variables are available.
* Added a safe Blizzard-font fallback for missing or invalid saved selections.

## 1.0.39

* Added a global font selector for Blizzard's engine-drawn overhead unit names.
* Preserves Blizzard's locale-appropriate font by default and warns when a full restart may be needed.

## 1.0.38

* Removed the ineffective replacement-name toggle and ongoing CVar enforcement.
* Restores saved WoW nameplate settings once for users who enabled the removed option.
* Retained nameplate-frame availability in `/snp debug` for diagnosing engine-drawn names.

## 1.0.37

* Made replacement names persistent by temporarily enabling Always Show Nameplates and forcing nameplate names to appear.
* Added nameplate-frame availability to `/snp debug` output.

## 1.0.36

* Kept Blizzard's ordinary-name settings enabled because they also control whether nameplate text can appear.
* Restores any ordinary-name settings previously captured and changed by version 1.0.35.

## 1.0.35

* Added an optional, reversible replacement for Blizzard's uncolorable overhead player and minion names.

## 1.0.34

* Replaced the screenshot-sampled default values with a clean web-safe RGB palette.

## 1.0.33

* Neutralized Blizzard's additional vertex tint so configured name colors display accurately.
* Updated all eight default colors to match the documented settings palette.

## 1.0.32

* Added a master styling switch that restores Blizzard nameplates and friendly-color settings when disabled.
* Added `/snp debug` diagnostics for the current target.
* Labeled every color row as a colored name or health bar and added individual reset buttons.
* Added a threat-percentage display toggle, enabled by default.
* Clarified that PC glow applies only to PCs with visible health bars.

## 1.0.31

* Reduced attack detection to the player and the player's pets, guardians, and minions.
* Health events now update only health instead of reclassifying and restyling the plate.
* Coalesced duplicate event refreshes and narrowed Blizzard hooks to the visual they repair.
* Replaced repeated name rewriting with a slower cached drift check.
* Reduced new-nameplate delayed refreshes and refreshes TRP3 text from profile events.

## 1.0.30

* Reset the standalone addon's release line to `1.0.(build number)`.
* Updated the tracked Git hook to generate future `1.0` build versions automatically.

## 1.0.29

* Changed the defaults to light-blue friendly NPCs and green friendly PCs and player-controlled units.
* Uses yellow for both attackable non-aggressive NPCs and attackable non-attacking PCs.
* Uses actual two-way attackability rather than inferred War Mode to decide whether an opposing PC receives a health bar.
* Correctly recognizes the player's own temporary guardians and minions as friendly player-controlled units.
* Added an optional same-color glow around PC health bars, disabled by default.

## 1.0.28

* Left-aligned names and TRP3 full titles with the health bar.
* Kept threat percentages right-aligned with the health bar.

## 1.0.27

* Added optional TRP3 roleplaying full names with automatic WoW-name fallback.
* Added optional short titles before names.
* Added `[OOC]` indicators that replace short titles; IC profiles receive no marker.
* Added optional full titles on a separate line above the name and always outside the health bar.

## 1.0.26

* Added an optional `TRP3.lua` integration skeleton using public TRP3 APIs.
* Added a TRP3 settings page with a master profile-display toggle, disabled by default.
* Added TRP3 availability status and `/snp trp3`.
* No TRP3 profile fields are displayed yet.

## 1.0.25

* Added a Text settings page with separate name and threat-font selectors.
* Changed both default fonts to Arial Narrow with a normal outline.
* Added Above Bar and Inside Bar placement for names on hostile-unit health bars.
* Inside-bar names automatically shrink and reserve space for the threat percentage.
* Added `/snp text`.

## 1.0.24

* Distinguishes same-faction and opposite-faction players by actual faction rather than sanctuary reaction.
* Keeps non-PvP opposite-faction players name-only and applies their configured name color.
* Repairs Blizzard name-color overwrites with a lightweight cached-state reconciliation pass.

## 1.0.23

* Fresh standalone release with no previous-version or legacy-settings handling.
* Warns at login when another enabled third-party “plate” addon may conflict.
* Uses `/snp` for settings and About commands.
