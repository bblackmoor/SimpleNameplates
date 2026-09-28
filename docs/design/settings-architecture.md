# Settings and runtime architecture

Status: revised proposal. Preserve Global + Profile ownership and the version-2 saved-data shape.

## Current inventory

The .toc loads `Core.lua`, `TRP3.lua`, `Nameplates.lua`, then `Settings.lua`. Core.lua (roughly 997 lines) combines defaults, database validation, Profile lifecycle, getters/setters, managed CVars, warnings, and accessibility helpers. Settings.lua (roughly 972 lines) constructs About, TRP3, Behavior, and Appearance. Nameplates.lua (roughly 1061 lines) contains classification, styling, frame repair, events, and diagnostics. TRP3.lua is already a focused optional adapter.

The settings UI already has scroll layout, thumb switches, circled-i links, and section constructors. Preserve these. The Appearance panel combines Profile management, text/layout, colors, fixed Blizzard swatches, and cast effects. `CreateColorRow` contains swatch, color picker, cancel rollback, reset, and refresh behavior. Profile dialogs and selection are embedded in the same file.

## Proposed source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory Global/Profile values, preset definitions, valid ranges |
| `Database.lua` | Validate version-2 data, character selection, Profile lifecycle, explicit Global/Profile access |
| `ManagedNames.lua` | Managed CVars, restoration ledger, combat deferral, friendly class colors |
| `Core.lua` | Metadata and small shared helpers/conflict warning |
| `TRP3.lua` | Existing integration adapter |
| `Nameplates.lua` | Existing styling pipeline initially; split on actual responsibility boundaries later |
| `SettingsControls.lua` | Shared layout, switches, info links, dropdown/color primitives |
| `SettingsAbout.lua` | About |
| `SettingsTRP3.lua` | Global TRP3 preferences |
| `SettingsBehavior.lua` | Global addon, categories, and Blizzard name handling |
| `SettingsProfiles.lua` | Profile selection, create/copy/rename/delete/restore |
| `SettingsAppearance.lua` | Profile text/layout, colors, Blizzard fixed-color explanations, cast effect |
| `Settings.lua` | Settings registration and refresh entry points |

These are candidate boundaries. Avoid splitting a small cohesive component solely to match a filename list. Put each tab's section/control constructors in visual order. If Profile management remains at the top of Appearance, keep that UI arrangement; the separate source module is for readability, not a new tab mandate.

## Runtime and UI contracts

- `StateForUnit` and category priority do not depend on Profile; six Global modes keep their current active/inactive/hide semantics.
- `ApplySimpleStyle` uses Global behavior and the active appearance Profile. Profile switches refresh plates, including inside-bar placement, cached name repair, full-title suppression, threat text, and interruptible cast highlight.
- Name CVars capture original values before changing them, restore them when no longer managed or styling is disabled, and defer restricted changes in combat. Profile switches must not rewrite category CVars.
- Keep TRP3's cache and normal-WoW-name fallback. Do not introduce reads or comparisons of Midnight secret values in new helper or refresh paths.
- Keep six Priority Colors in danger-to-friendly order and fixed Blizzard swatches distinct from editable colors.
- Standard setting row order stays label, control, reset (if any), info glyph (if any), with consistent spacing and the established thumb switches.

Use a simple tab -> section -> control structure; separate construction from refresh/enable-state callbacks where helpful. Reuse the existing scroll cursor and avoid a generic declarative framework. Extract large nested callbacks into named helpers or context tables when this reduces Lua upvalues. Preserve explicit .toc load order and settings registration.

## Verification

Characterize existing defaults, validation, Profile CRUD, per-character selection, CVar capture/reapply/restore, settings registration, and styling refresh. Run targeted Lua syntax/smoke checks and a live WoW matrix. Local stubs cannot prove Blizzard frame behavior or secret-value safety in the client.
