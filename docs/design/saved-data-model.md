# Saved data model

Status: implemented version-2 schema. Simple Nameplates uses Global behavior and appearance Profiles, with no separate Theme layer.

## Why two scopes are sufficient

Unlike RP Emote Menu, Simple Nameplates has no categories, emotes, window state, or other substantial Profile content to separate from appearance. Its current Profiles already hold the visual configuration. A Profile -> Theme reference would make Profiles mostly wrappers, add shared-reference and deletion rules, and complicate selection without a clear user benefit.

Keep the existing chain:

```text
Character -> appearance Profile
Global behavior applies across characters
```

Account-wide Profiles are selected independently by each character through `profileKeys`. A character without a valid assignment uses Default. There is no Theme collection or Theme reference.

## Current schema (version 2)

```lua
SimpleNameplatesDB = {
    schemaVersion = 2,
    global = { categoryModes = { ... }, trp3 = { ... },
               stylingEnabled = true, hideCritterCompanionNames = false,
               highContrastRemoved = true, -- Optional; only after removal of the bundle.
               managedNameCVarOriginals = { ... },
               nameplateSetupOriginals = { ["Player-GUID"] = { ... } } },
    profiles = {
        Default = { priorityColors = { ... }, effectColors = { ... },
                    appearance = { ... }, healthBars = { attacking = true, hostile = true,
                        neutral = true, friendly = true, useful = true, useless = true },
                    showThreat = true, gradients = false,
                    interruptibleCastStyle = "NONE" },
        ["High Contrast"] = { ... },
    },
    profileKeys = { ["Player-GUID"] = "Default" },
}
```

A valid version-2 saved database separates behavior from look and feel. The structural refactor kept this shape and version. Validation reconstructs settings from defaults, discards invalid and unknown fields, and retains recognized valid settings regardless of the saved schema marker. No one-off migration or import/export facility is needed.

Useful and Useless each have one `priorityColors` entry per profile, used in all world and combat contexts. Player - Friendly uses one `friendly` entry in all world and combat contexts, with green (`#33CC33`) as the default. The former `sanctuaryFriendly`, `sanctuaryUseful`, and `sanctuaryUseless` fields are unknown settings and are discarded during validation; valid `useful` and `useless` values are retained without conversion.

`appearance.useSlugRendering` is a per-profile boolean, on by default. It selects Slug rendering for styled plate text, with thin outlines outside health bars and unoutlined glyphs/underlayers inside. Copies and reloads retain it; Reset Appearance enables it. Missing or invalid values use the default. Schema remains 2.

`appearance.matchSanctuaryFont` is a per-profile boolean, enabled by default. It selects Blizzard's localized world-name font face in sanctuaries without replacing the saved `nameFont`. Profile copies retain it and Reset Appearance restores the default; invalid or missing values use the default.

Profiling introduced in 1.0.163 is session-only. It adds no fields to `SimpleNameplatesDB`, does not follow profile selection and starts disabled after every UI reload. Stopped results are retained only in memory until a new session or reload.

## Ownership inventory

| Setting | Owner | Reason |
| --- | --- | --- |
| `stylingEnabled` | Global | Master addon behavior |
| Six `healthBars` booleans | Profile | Per-category health-bar visibility; all on by default |
| Legacy `categoryModes` | Global | Retained for compatibility; ignored by rendering |
| `hideCritterCompanionNames` | Global | Blizzard name management |
| `trp3.enabled`, `useRoleplayingName`, `showShortTitle`, `showFullTitle`, `showOOC` | Global | TRP3 integration and display policy |
| Six `priorityColors`, `effectColors.interruptible` | Profile | Appearance colors |
| `appearance.nameFont`, `nameSize`, `threatFont`, `namePlacement`, `matchSanctuaryFont`, `useSlugRendering`, `healthBarWidth` | Profile | Text and layout |
| `showThreat`, `interruptibleCastStyle` | Profile | Threat visibility and cast effect choice (NONE/PIXEL/AUTOCAST/BUTTON/PROC) |
| `profileKeys` | Account-wide character selection map | Independent Profile choice per character |
| `global.managedNameCVarOriginals` | Internal restoration ledger | Original critter and legacy managed values, retained until restored |
| `global.nameplateSetupOriginals` | Internal ledger keyed by character GUID | Visibility values captured after setup consent, restored when styling is disabled |

Do not confuse the six editable Priority Colors with fixed Blizzard-controlled lavender/yellow/green overhead names. The latter are explanations in the settings UI, not Profile values. The classification precedence is runtime logic, not a saved setting.

## Bundled Profile rules

Default and High Contrast are editable account-wide Profiles. Default always exists and can be restored but cannot be renamed or deleted. High Contrast can be edited and restored or recreated, and the current lifecycle permits renaming and deleting it. A validated optional `global.highContrastRemoved` marker preserves deletion or renaming of High Contrast across reloads. Fresh databases still receive both bundles. Recreating High Contrast or restoring bundled profiles clears the marker. The Restore Bundled Profiles action restores both factory definitions. Deleting a selected Profile reassigns every affected character to Default. Creating a Profile starts with Default factory values; Copy duplicates the active Profile. Profile changes refresh visible nameplates.

## CVar safety and compatibility

Managed overhead-name original values are persisted in `global.managedNameCVarOriginals` and must survive the refactor unchanged until restored. Setup-approved visibility originals are stored separately per character in `global.nameplateSetupOriginals`. Friendly class-color CVars are observed only; the addon does not capture or write them. Keep combat deferral, capture-before-set, and restoration on disable or when no longer managed. A code-layout refactor has no reason to bump `schemaVersion`; it remains descriptive metadata rather than a reason to reset valid settings. The saved schema marker does not reject an otherwise valid setting. Recognized fields are validated in their current locations without conversion; retain valid restoration-ledger entries until they are restored.

## Runtime phase-3 category fields

Both Global category modes and Profile priority colors recognize only `attacking`, `hostile`, `neutral`, `friendly`, `useful`, and `useless`. Valid values at these keys are retained. The obsolete `unfriendlyNPC`, `unfriendlyPC`, `friendlyPC`, and `other` keys are discarded without remapping. Unrelated valid preferences, profile selections, and managed-CVar restoration records remain valid. The schema marker remains 2; it never overrides individual field validation.

## Removal of experimental replacement (1.0.105)

`replaceBlizzardOverheadNames` is no longer a recognized field and is silently discarded. No preference is converted. Valid `managedNameCVarOriginals` entries for its former Blizzard settings remain restoration records: normal managed-settings processing restores them without capturing or applying new replacement values, retains them after failed writes, and defers restricted restoration until combat ends. Only the independent critter/companion control makes ordinary-name CVar claims now; friendly class-color CVars are read-only.


`healthBars` accepts boolean values only. Copies and reloads retain false; missing or invalid values default to true. Reset all colors turns all six bars on in the selected profile. Reset Appearance preserves these choices. Names default to size 18; saved sizes are preserved, and long titles use the chosen name size minus two.

`gradients` is a per-profile boolean, on by default. Copies/reloads retain it; invalid or missing values default off. Colors reset disables it; Appearance reset preserves it. It controls fixed-position health fill tinting and inside-bar text underlayers, not cast fill or health values.
