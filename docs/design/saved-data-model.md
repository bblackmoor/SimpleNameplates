# Saved data model for the refactor

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
               stylingEnabled = true, managedNameCVarOriginals = { ... }, ... },
    profiles = {
        Default = { priorityColors = { ... }, effectColors = { ... },
                    appearance = { ... }, showThreat = true,
                    interruptibleHighlight = false },
        ["High Contrast"] = { ... },
    },
    profileKeys = { ["Player-GUID"] = "Default" },
}
```

A valid version-2 saved database separates behavior from look and feel. The structural refactor kept this shape and version. Validation reconstructs settings from defaults, discards invalid and unknown fields, and retains recognized valid settings regardless of the saved schema marker. No one-off migration or import/export facility is needed.

## Ownership inventory

| Setting | Owner | Reason |
| --- | --- | --- |
| `stylingEnabled` | Global | Master addon behavior |
| Six `categoryModes` (attacking/hostile/neutral/friendly/useful/useless; active/inactive) | Global | Per-category nameplate styling behavior |
| `hideCritterCompanionNames` | Global | Blizzard name management |
| `trp3.enabled`, `useRoleplayingName`, `showShortTitle`, `showFullTitle`, `showOOC` | Global | TRP3 integration and display policy |
| Six `priorityColors`, `effectColors.interruptible` | Profile | Appearance colors |
| `appearance.nameFont`, `nameSize`, `threatFont`, `namePlacement` | Profile | Text and layout |
| `showThreat`, `interruptibleHighlight` | Profile | Which optional visual elements this appearance Profile displays |
| `profileKeys` | Account-wide character selection map | Independent Profile choice per character |
| `global.managedNameCVarOriginals` | Internal restoration ledger | Original Blizzard values, not a user preference |

Do not confuse the six editable Priority Colors with fixed Blizzard-controlled lavender/yellow/green overhead names. The latter are explanations in the settings UI, not Profile values. The classification precedence is runtime logic, not a saved setting.

## Bundled Profile rules

Default and High Contrast are editable account-wide Profiles. Default always exists and can be restored but cannot be renamed or deleted. High Contrast can be edited and restored or recreated, and the current lifecycle permits renaming and deleting it. The Restore Bundled Profiles action restores both factory definitions. Deleting a selected Profile reassigns every affected character to Default. Creating a Profile starts with Default factory values; Copy duplicates the active Profile. Profile changes refresh visible nameplates.

## CVar safety and compatibility

Managed overhead-name original values are persisted in `global.managedNameCVarOriginals` and must survive the refactor unchanged until restored. Some friendly class-color original values are held in memory separately. Keep combat deferral, capture-before-set, and restoration on disable or when no longer managed. A code-layout refactor has no reason to bump `schemaVersion`; it remains descriptive metadata rather than a reason to reset valid settings. The saved schema marker does not reject an otherwise valid setting. Recognized fields are validated in their current locations without conversion; retain valid restoration-ledger entries until they are restored.

## Runtime phase-3 category fields

Both Global category modes and Profile priority colors recognize only `attacking`, `hostile`, `neutral`, `friendly`, `useful`, and `useless`. Valid values at these keys are retained. The obsolete `unfriendlyNPC`, `unfriendlyPC`, `friendlyPC`, and `other` keys are discarded without remapping. Unrelated valid preferences, profile selections, and managed-CVar restoration records remain valid. The schema marker remains 2; it never overrides individual field validation.

## Removal of experimental replacement (1.0.105)

`replaceBlizzardOverheadNames` is no longer a recognized field and is silently discarded. No preference is converted. Valid `managedNameCVarOriginals` entries for its former Blizzard settings remain restoration records: normal managed-settings processing restores them without capturing or applying new replacement values, retains them after failed writes, and defers restricted restoration until combat ends. Only the independent critter/companion control makes ordinary-name CVar claims now; friendly class-color handling remains separate.
