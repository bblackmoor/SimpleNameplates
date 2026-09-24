# Changelog

## 1.0.78

* Render inside-bar names on the health bar's overlay layer so the bar cannot cover them.
* Corrected the inside-bar height check to match the configured two-unit padding above and below the name.

## 1.0.77

* Removed the attacking glow, its appearance control, and its saved profile field.
* Made the optional interruptible cast border thicker and opaque with a dark outer edge and a pulsing animation.

## 1.0.76

* Aligned Appearance labels and controls in compact rows and narrowed the name-size slider.
* Moved the name-size explanation beside its control and placed section reset buttons on their heading rows.

## 1.0.75

* Added named appearance profiles shared account-wide with per-character active-profile selection.
* Added editable bundled Default and High Contrast profiles plus Create, Copy, Rename, Delete, and Restore Bundled Profiles controls.
* Protected Default as the permanent fallback; deleting another profile returns assigned characters to Default.
* Combined profile management, text and layout, colors, and visual effects on one Appearance tab; `/snp colors` remains an alias for it.
* Replaced the one-shot High Contrast preset with the editable High Contrast profile.

## 1.0.74

* Split saved settings into a validated global section for addon behavior and user preferences and an appearance profile for colors, visual effects, fonts, sizing, placement, and threat display.
* Added a Behavior settings page, renamed Text to Appearance, and reordered the settings pages as Behavior, Appearance, Colors, and TRP3.
* Moved category modes and Blizzard overhead-name controls out of Colors and into Behavior.
* Added a schema version and intentionally ignore older or incompatible saved layouts instead of carrying one-off migration code.

## 1.0.73

* Renamed the six-color system and its saved setting to **Priority Colors** and `priorityColors`.
* Clarified that rows are evaluated from top to bottom and the first matching category wins.
* Kept the rows ordered from immediate danger through friendly and least-consequential units.
* Does not import the obsolete `relationshipColors` key; only the exact current `priorityColors` setting is accepted.

## 1.0.72

* Replaced the former color model with six explicitly prioritized categories: attacking, aggressive, neutral-attackable, opposing PC, same-faction PC, and all other colorable units.
* Added an Active, Inactive, or Hide behavior selector to every prioritized category.
* Limited Simple Nameplates coloring, threat text, and effects to Active categories; Inactive categories restore Blizzard's presentation.
* Added best-effort category hiding for addon-accessible frames and matching Blizzard overhead-name CVars, with prior game settings restored when released.
* Preserved only previous settings whose names and values exactly match current valid settings; no renamed or legacy setting aliases are imported.
* Updated the defaults, High Contrast preset, settings descriptions, diagnostics, and documentation for the six-category model.

## 1.0.71

* Added 90-day development ZIP artifacts for every commit to `main`, identified by addon version and short commit SHA.
* Reserved permanent, cleanly named GitHub Releases for matching version tags.

## 1.0.70

* Added an experimental toggle that hides selected Blizzard overhead player, minion, and NPC names while requesting colorable Blizzard nameplates in their place.
* Combined Midnight's forced-name and friendly-player name-only CVars so hidden world-name settings do not also suppress replacement nameplate text.
* Restores every affected WoW CVar when the experiment or Simple Nameplates styling is disabled.
* Reports the replacement state through `/snp debug`.

## 1.0.69

* Removed legacy SavedVariables migration and import behavior for the fresh-install release.
* Kept recognized valid current settings while silently replacing invalid values with defaults and discarding unknown or obsolete saved fields.

## 1.0.68

* Moved the High Contrast and Reset Colors buttons to the top of the Colors panel.
* Added a locked green row documenting Blizzard-controlled vendor-NPC overhead names.
* Stopped writing health and maximum-health values into Blizzard nameplate bars, preventing secret-number taint in Blizzard heal prediction.

## 1.0.67

* Fixed a Midnight secret-string error in the cached name-style reconciliation loop.

## 1.0.66

* Added an option to hide Blizzard overhead names for noncombat critters and companions.
* Added a locked yellow row documenting Blizzard-controlled interactive-NPC overhead names.
* Restored the prior Blizzard name setting when the option is disabled.

## 1.0.65

* Moved TRP3 long titles beneath names and sized them to 80% of the configured name size.
* Hidden long titles for units with visible health bars.

## 1.0.64

* Added an option to hide Blizzard-controlled friendly and enemy pet, guardian, totem, and minion names while leaving opposing-player names visible.
* Restored the prior Blizzard name settings when the option is disabled.

## 1.0.63

* Increased inside-bar name padding to two UI units above and below.

## 1.0.62

* Expanded the shared name-size range to 8–36 points.

## 1.0.61

* Prevented health events for forbidden target-of-target unit tokens from being passed to the nameplate API.

## 1.0.60

* Replaced **Colorblind — Web Safe** with a brighter **High Contrast** preset that avoids relying on red versus green.
* Moved each color's affected-element explanation beneath its relationship label so it no longer looks attached to the Reset button.
* Fixed the preset and reset button row floating over the panel description.

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
* Added versioned SavedVariables migrations and separated unit-state colors from effect colors internally.
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
