# Changelog

## 1.0.134

* Removes dark outlines and shadows from styled names, NPC/TRP3 titles, and threat percentages, and removes the dark backing around interruptible-cast borders.
* Makes threat percentages follow the selected name size while preserving the separate threat font; inside-bar names reserve proportionate space for the larger percentage.

## 1.0.133

* Keeps inside-bar names at the full selected font size and expands health bars and containers as needed, with three UI units of padding above and below. Original heights are restored when inside-bar styling ends.
* Renders threat percentages through WoW's supported formatter, including secret values without inspecting them. Ensures labels have a valid font, are shown above bar artwork, and follow replacement health bars.
* Adds threat-display status to diagnostics; absent or undisplayable threat percentages remain blank.

## 1.0.132

* Adds `/snp debug mouseover` to inspect hovered creatures without changing the target or their nameplate presentation. Existing `/snp debug` continues to inspect the target.
* Identifies the inspected token in reports and handles missing mouseover units explicitly.

## 1.0.131

* Removes the redundant Sanctuary colors section and its duplicate controls and descriptions. Priority colors remains the single place to edit all six categories; color and activation behavior is unchanged.

## 1.0.130

* Makes Player - Friendly share its profile color and global activation switch between Priority colors and Sanctuary colors, matching the NPC controls. Keeps green as the default and retains existing Friendly color choices.
* Removes the separate sanctuary player color; obsolete saved values are discarded without migration.

## 1.0.129

* Ensures a restoration error cannot leave an accessible plate permanently marked as restoring. Failed work stays queued, and successful retries resume styling for the frame's current unit.
* Reports the last restoration error in diagnostics, and shows no blocked region or active restoration when those fields are absent.

## 1.0.128

* Renames the NPC color labels to NPC - Interactive and NPC - Background in both color sections; saved category keys and behavior are unchanged.

## 1.0.127

* Removes the obsolete behavior command alias and its help references. Startup setup guidance points to Appearance.
* Keeps Enable Simple Nameplates global; appearance-profile selection and resets do not change it.

## 1.0.126

* Moves global Active/Inactive category handling to thumb switches beside their colors, including synchronized sanctuary copies. Colors remain profile-specific.
* Moves global Enable styling and Hide critter/companion switches above Reset text and layout on Appearance, preserving startup compatibility checks and restoration behavior.
* Removes the empty Behavior tab; `/snp` and the existing behavior/general/settings aliases open Appearance. Reset actions do not alter the global switches.

## 1.0.125

* Reorganizes settings into About, Behavior, Profiles, Appearance, Colors, and TRP3. Appearance/Colors keep compact profile selectors; management actions move to Profiles.
* Uses sentence-case headings, white labels, muted wrapping descriptions, a shared control column, and section actions below controls.
* Keeps all global TRP3 options together, moves informational native-label swatches into About, and preserves the combat sections on Appearance.
* Names reset scopes explicitly, adds a six-category priority reset, and preserves the existing complete color and text/layout resets. Saved fields and runtime presentation rules are unchanged.

## 1.0.124

* Corrects regression checks to identify color controls separately from matching Behavior labels and to test inside-bar font restoration when the bar is visible.
* Changes the default Name font to Friz Quadrata and the default name size to 21 points. New profiles, missing/invalid values, and Reset Appearance use these defaults; existing valid profile choices are retained.

## 1.0.123

* Adds the profile setting "Match Blizzard font in sanctuaries," enabled by default and included in Reset Appearance.
* Uses Blizzard's localized SystemFont_World font face for accessible names and NPC/TRP3 titles in sanctuaries, including names inside health bars. Preserves selected fonts elsewhere, size, outline, colors, placement, and the separate threat font.
* Invalidates cached name styling when the effective font changes; adds regression checks for defaults, profile values, the switch, sanctuary transitions, titles, and bar names.

## 1.0.122

* Uses one Useful color and one Useless color per appearance profile, shared inside and outside sanctuaries and across combat states. Both settings copies update immediately on picker changes, cancellation, and reset.
* Keeps existing Priority Colors values; obsolete separate sanctuary NPC color fields are discarded by ordinary validation without migration. Factory defaults are light grey for Useful and medium grey for Useless; High Contrast keeps its blue and white defaults.
* Retains the separate same-faction player sanctuary color and higher danger priorities. Updates developer notes and regression checks.

## 1.0.121

* Reorganizes Appearance below the existing profile controls into Shared Appearance, Out of Combat, and In Combat sections. Fonts, sizes, Priority Colors, and sanctuary colors remain shared.
* Groups health-bar name placement, threat font/display, and cast highlighting under In Combat, explaining that they also apply to danger-category bars out of combat.
* Moves the existing global TRP3 long-title switch to Appearance / Out of Combat, preserves its saved value and integration enablement, and keeps other TRP3 options on their existing page. NPC service titles remain automatic.
* Preserves runtime presentation, profile/reset behavior, and all existing saved-setting keys; no separate combat configuration or data migration.

## 1.0.120

* Describes presentation limits by entity type and world context, removing individual character names from the README, About notes, and developer review.

## 1.0.119

* Records unresolved presentation limits in the README and in-game About notes: nonattackable opposite-faction PCs in Silvermoon sanctuary without accessible matching plates.
* Distinguishes those unresolved contexts from resolved duplicate widget-plate text on NPCs and ordinary NPC visibility fixed by enabling friendly NPC plates.
* Documents the actual implemented evaluation order and decision trees in the developer notes. No runtime classification change.

## 1.0.118

* Checks Blizzard plate visibility settings on login and when enabling styling. Conflicts pause styling and offer a reviewable Apply-and-enable or Disable-styling choice; compatible settings require no dialog.
* Keeps Only Show Names off so the addon can control friendly bars in combat. Setup changes only listed conflicts, saves originals per character across reloads, and restores them when styling is disabled.
* Defers setup/restoration during combat and verifies writes before resuming styling. Failed writes keep styling paused; failed restoration retains backups for retry.
* Added regression coverage for consent, reloads, character isolation, rejected writes, unsupported CVars, and combat deferral. Documented current Blizzard/Plater findings and the unresolved sanctuary opposite-faction plate case.

## 1.0.117

* Suppresses name/title text on confirmed widget-only plates in Active categories while preserving their frames, widgets, and Blizzard bar visibility. Ordinary plates continue displaying NPC names and service titles.
* Repairs text suppression after Blizzard updates and restores original name opacity when styling is disabled, the category becomes Inactive, or a frame changes plate type.
* Added regressions for simultaneous widget-only/ordinary NPC plates, text drift, frame reuse, unavailable flags, and restoration.

## 1.0.116

* Limits `/snp debug` plate details to the target, its direct lookup, and plates with the same readable unit name. Nearby unrelated units no longer flood the chat history.
* Distinguishes same-name diagnostic candidates from verified target identity, retains widget-only and subtitle reports, and prints each relevant frame only once.
* Added regression coverage for unrelated plates, duplicate enumeration, multiple same-name presentations, and unavailable names.

## 1.0.115

* Tries a structured `unit:<GUID>` hyperlink tooltip first for confirmed NPC subtitles, then retains the working unit-token and GUID/name cache fallbacks. Missing, failed, restricted, or rejected hyperlink data does not prevent fallback.
* Preserves affirmative interaction evidence learned with a subtitle so direct hyperlink extraction does not revert a useful nameplate to the useless-NPC color.
* `/snp debug` reports hyperlink title/extraction results, each unit's soft-interaction match and widget-only flag, and the `nameplateShowFriendlyNpcs` CVar. These reads do not alter name visibility or suppress duplicate world labels.
* Added regressions for hyperlink precedence, failed/restricted reads, rejected layouts, secret GUIDs, player exclusion, useful title/color presentation, and interaction-plate diagnostics.

## 1.0.114

* Allows unambiguous NPC-name subtitle fallback when a readable nameplate GUID cannot be associated with a fuller world-unit tooltip, as well as when GUIDs are unavailable.
* Learns matching-name target, mouseover, and soft-interaction NPC subtitles during normal rendering, without requiring a debug command. Exact GUID evidence remains preferred, and name associations never populate the exact-GUID cache.
* Bounds both session caches to 256 entries. Conflicting subtitles block name fallback; diagnostics distinguish unmatched and unavailable GUIDs.
* Added regressions for cold title discovery, readable unmatched GUIDs, conflicting names, exact-GUID precedence, and nameplate title/color presentation.

## 1.0.113

* When an NPC nameplate exposes a readable name but no GUID, it can reuse an unambiguous subtitle previously learned from a verified full NPC tooltip with the same name.
* GUID matching remains preferred; conflicting verified subtitles for the same NPC name disable the name fallback for that name.


## 1.0.112

* Accepts NPC subtitles followed by a plain level line when its text matches WoW's localized level template and the unit's readable level, including the observed service-NPC tooltip layout.
* Fills missing nameplate subtitles from target, mouseover, or soft-interaction tooltips only when readable NPC GUIDs match; remembers up to 256 NPC subtitles for the session and refreshes on mouseover changes.
* Uses the resolved subtitle beneath name-only NPC labels and carries verified interaction evidence into useful-NPC classification, allowing the sanctuary useful color to apply to both name and title. Subtitles alone do not establish usefulness.
* Diagnostics report the resolved title source and unavailable identity. Added regressions for sparse tooltips, localization, target changes, restricted identities, token reuse, and sanctuary presentation.

## 1.0.111

* NPC title diagnostics now distinguish missing APIs/data, failed reads, restricted fields, rejected line layouts, and unsupported or empty subtitles.
* `/snp debug` reports up to twelve readable tooltip line types and left/right texts for the target and each scanned NPC nameplate, with explicit field-access status. Diagnostic text escapes tooltip markup; no visible tooltip is created or changed.

## 1.0.110

* Reads NPC subtitles such as "Voidforge Steward" from readable structured unit-tooltip data and displays them in angle brackets below addon-controlled name-only NPC labels at 80% of the name size.
* NPC subtitles are independent of TRP3 settings, share the name's configured color, and hide when a health bar is displayed. Missing, restricted, or ambiguous tooltip layouts omit the title.
* Added subtitle diagnostics and extraction/presentation regressions. Blizzard overhead-name duplication remains a separate issue.

## 1.0.109

* `/snp debug` now reports every enumerated nameplate, including frames that do not match the target: current unit token/name, displayed name text, visibility, addon markers, original unit, and cached name/presentation.
* Keeps unknown identities and inaccessible frames explicit; these read-only diagnostics do not change nameplate presentation.

## 1.0.108

* Expanded `/snp debug` to search existing nameplates for the selected unit when direct lookup misses it, using readable unit identity rather than displayed names.
* Reports matching frames, lookup restrictions, Simple Nameplates styling markers, cached text/presentation, and inside-name/long-title regions to investigate duplicate labels without changing name visibility.

## 1.0.107

* Added independent sanctuary color defaults: sky blue (#87CEEB) for same-faction players, light grey (#D3D3D3) for useful NPCs, and medium grey (#999999) for other NPCs.
* Sanctuary colors are editable and resettable in Appearance profiles, including existing profiles that lack these new values. Combat danger categories and opposite-faction colors retain their existing behavior.
* Applied the selected sanctuary color consistently to accessible name text, TRP3 long titles, and supported health bars. Blizzard-controlled world names remain under Blizzard control.

## 1.0.106

* Completed runtime phase 4: added independent presentation rules with narrow sanctuary/PvP/non-PvP opposite-player cases and shared defaults.
* During player combat, all Active entities with supported accessible bars display them; out of combat only Attacking, Hostile, and Neutral use bars. Missing bars use colored names; Inactive or unknown-combat presentation falls back to Blizzard.
* Names, TRP3 titles, sizing, threat, cast effects, and both Blizzard repair hooks share the decision. Stale caches cannot restore an old combat layout. Long titles are suppressed for requested/observed bars or unknown shown state on an existing bar.
* Added original-visibility capture and restoration retries after restrictions end, including while styling is disabled, plus blocked-refresh and removed-unit cleanup handling. No nameplate-visibility CVar claims were introduced.
* Expanded runtime regressions and added pure rule tests. Phase 5 live-client verification remains pending.

## 1.0.105

* Removed experimental Blizzard overhead-name replacement, including its control, defaults, saved preference, runtime APIs/actions, CVar claims, and diagnostic field.
* Retained valid previously captured Blizzard name/nameplate originals solely for restoration, including failed-write and combat-deferred retries. The obsolete preference is discarded without conversion.
* Retained independent critter/companion hiding, friendly class-color handling, and normal accessible-nameplate styling. Updated documentation and regression checks; phase 4 remains pending.

## 1.0.104

* Completed runtime phase 3: separated entity facts from classification and implemented Attacking, Hostile, Neutral, Friendly, Useful, and Useless in first-match order.
* Eligible PvP opponents use readable attackability; a PvP flag alone no longer promotes sanctuary/non-eligible players. Faction and interaction facts remain independent of category; higher combat priorities override NPC usefulness.
* Updated defaults, High Contrast, settings rows, validation, and documentation together. Obsolete category fields are discarded without conversion; valid current settings remain.
* Experimental overhead replacement now requires every category Active because its CVars overlap categories; mixed modes restore replacement originals. Independent critter control remains.
* Diagnostics reports shared facts and the winning rule, and correctly describes Inactive/disabled styling as Blizzard presentation. Added entity and regression coverage; the phase-4 combat bar policy and live-client checks remain pending.

## 1.0.103

* Completed runtime refactor phase 2: added cached, event-driven world context, including independent player-combat and combat-lockdown facts and desired versus active War Mode. Unknown values remain distinct from false.
* Centralized frame and region access assessment for refresh, hooks, styling, restoration, cleanup, drift repair, and cast effects.
* Expanded read-only `/snp debug` reporting for world context, frame capabilities, and observed visibility; diagnostics no longer creates cast overlays or hooks.
* Added context/access regression checks and the phase-2 client checklist. Existing categories, settings, and health-bar policy remain unchanged.

## 1.0.102

* Completed runtime refactor phase 1: separated frame access, name/title layout and repair, threat text, cast highlighting, presentation/restoration, runtime events, and diagnostics into focused modules.
* Fixed `/snp debug` calling an unavailable targeting helper by sharing the classification predicate explicitly.
* Extended runtime checks for presentation, TRP3 titles, inside-bar sizing, drift repair, restoration, diagnostics, and module load order. Current category and combat behavior remain unchanged.

## 1.0.101

* Removed Hide Blizzard-controlled minion names and its dedicated defaults, saved setting, CVar claims, and runtime callbacks.
* Validate recognized saved settings individually regardless of the schema marker; retain valid fields and silently discard invalid or unknown fields without conversion.
* Retained critter/companion hiding, experimental overhead replacement, and managed CVar restoration.

## 1.0.100

* Removed Hide from all six Priority Color category selectors, saved-setting validation, and runtime handling; categories now support Active or Inactive only.
* Invalid saved category modes, including the removed Hide value, silently fall back to Active. Existing managed CVar originals remain available for restoration.
* Retained the independent minion-name and critter/companion-name hide switches and experimental overhead replacement.

## 1.0.98

* Updated source and saved-data documentation to match the completed module split; clarified the README's Priority Color classification and local development checks.
* Recorded the remaining live WoW integration matrix separately from the Lua smoke checks. No saved-data schema or settings behavior changed.

## 1.0.97

* Isolated priority unit classification in `NameplateClassification.lua` while leaving the coupled styling, frame repair, and event pipeline together.
* Added a runtime smoke check for category decisions, event/hook registration, and Lua upvalue counts; removed an unused dead function.

## 1.0.96

* Split the settings UI into focused shared-control, About, Behavior, Profile, Appearance, and TRP3 modules while preserving the existing tabs and settings behavior.
* Added a settings registration and callback smoke test, including color-picker cancel rollback.

## 1.0.95

* Moved managed Blizzard name and friendly class-color CVar handling into `ManagedNames.lua` without changing the version-2 saved-data schema.
* Retained captured original CVar values when a restore is blocked or refused, and retried deferred restoration after combat.

## 1.0.84

* Replaced settings checkboxes with on/off switches while keeping their saved settings and effects.
* Aligned labels, controls, reset actions, and Blizzard color info links; replaced question-mark buttons with yellow circled info glyphs.
* Reorganized appearance profile management around selection, actions, restore, and concise guidance.

## 1.0.79

* Display restricted Midnight unit names directly in the inside-bar font string instead of replacing them with empty text.
* Skip Lua prefix concatenation when the unit name is restricted.

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
