# Proposed saved data model

Status: design proposal for Simple Nameplates. No runtime change has been made.

## Existing state (main at 22f8515)

`SimpleNameplatesDB` uses schema version 2 with `global`, `profiles`, and `profileKeys`. `profileKeys` maps a character GUID (or name-realm fallback) to an account-wide appearance Profile. Default and High Contrast are editable bundled Profiles. `Core.lua` reconstructs valid settings from defaults and ignores saved data whose schema version differs. There is currently no Theme, import/export format, or separate per-character SavedVariables declaration.

## Proposed relationship

```text
Character selection -> Profile -> Theme
                         |
                         +-> presentation choices
```

Global preferences, Profiles, and Themes are account-wide. Each character independently selects a Profile through `profileKeys`. An unassigned or invalid selection resolves to Default Profile, which initially references Default Theme. Profiles reference a Theme by name; they never embed a copy. Two Profiles sharing a Theme display the same visual edits.

### Global: addon behavior and integration

| Setting | Existing location | Proposed owner |
| --- | --- | --- |
| `stylingEnabled` | `global` | Global |
| Six `categoryModes` (active/inactive/hide) | `global` | Global |
| `hideBlizzardMinionNames` | `global` | Global |
| `hideCritterCompanionNames` | `global` | Global |
| `replaceBlizzardOverheadNames` | `global` | Global |
| `trp3.enabled`, `useRoleplayingName`, `showShortTitle`, `showFullTitle`, `showOOC` | `global.trp3` | Global |

Keep category modes global: the user already chose that ownership and those modes affect managed Blizzard CVars, sometimes after combat. Keep TRP3 interpretation global; a Theme only changes presentation. `global.managedNameCVarOriginals` is a restoration ledger, not a preference: give it a clearly named internal saved area (or retain its stable storage while moving APIs). Preserve original values until CVars are safely restored. Friendly class-color original values are currently in-memory and have a separate restore path.

### Profile: presentation choices and Theme assignment

| Setting | Existing location | Proposed owner |
| --- | --- | --- |
| Theme reference | absent | Profile |
| `showThreat` | Profile | Profile |
| `interruptibleHighlight` | Profile | Profile |

`showThreat` and `interruptibleHighlight` determine whether optional information is displayed. Keeping them in Profile lets two Profiles share colors/fonts while selecting different information. If these should instead always travel with appearance, make that decision before Phase 1 and put both in Theme. This is the only substantive scope choice not dictated by the current Global/appearance split.

Default Profile always exists, is editable/restorable, and cannot be renamed/deleted. Retain the bundled High Contrast *Profile* as a convenient editable selection whose factory Theme reference is High Contrast Theme, preserving the existing two-profile experience. Restore Bundled Profiles must restore those two Profile definitions only; Theme restoration is a separate action. Deleting any other Profile reassigns all affected character selections to Default. Profile selection must update visible nameplates without changing Global behavior.

### Theme: visual appearance

| Setting | Existing location | Proposed owner |
| --- | --- | --- |
| Six `priorityColors` | Profile | Theme |
| `effectColors.interruptible` | Profile | Theme |
| `appearance.nameFont`, `nameSize`, `threatFont`, `namePlacement` | Profile | Theme |

Default Theme and High Contrast Theme contain the current factory visual definitions. Both are editable and restorable. Default cannot be renamed/deleted; a deleted High Contrast Theme can be recreated by Restore Bundled Themes. Invalid references resolve to Default Theme. Deleting a Theme in use requires a warning listing affected Profiles; confirm reassigns them to Default Theme, cancel changes nothing. Distinguish an actively edited Theme from the Theme attached to the current character's Profile when designing the UI.

The fixed lavender, yellow, and green Blizzard-controlled overhead-name swatches are documentation of engine colors, not saved Theme values. The six priority classifications and their precedence are runtime logic, not saved visual settings.

## Proposed schema sketch

```lua
SimpleNameplatesDB = {
    schemaVersion = 3, -- proposal, not yet implemented
    global = { ... },
    internal = { managedNameCVarOriginals = { ... } },
    profiles = {
        Default = { theme = "Default", showThreat = true, interruptibleHighlight = false },
        ["High Contrast"] = { theme = "High Contrast", showThreat = true, interruptibleHighlight = false },
    },
    themes = {
        Default = { priorityColors = { ... }, effectColors = { ... }, appearance = { ... } },
        ["High Contrast"] = { priorityColors = { ... }, effectColors = { ... }, appearance = { ... } },
    },
    profileKeys = { ["Player-GUID"] = "Default" },
}
```

## Compatibility decision for Phase 1

The current validator explicitly discards any database with another schema version. The prior Simple Nameplates decision was to avoid one-off legacy migrations and silently ignore invalid saved values. Accordingly, this proposal uses a clean version-3 boundary and does not add permanent migration code. **This resets valid version-2 saved Profiles and Global settings when installed.** Decide explicitly whether that loss is acceptable before Phase 1. If preserving valid version-2 settings is required, plan a bounded conversion that preserves custom Profile names, per-character assignments, appearance values, and the original-CVar restoration ledger. Never discard recorded original CVar values before restoring managed CVars, even during a clean break.

No JSON import/export exists today. Profile/Theme/Everything transfer is a separate optional product feature, not a prerequisite for separating ownership or making settings code readable. If later added, define a separate format version and atomic validation, with missing Theme references falling back to Default.
