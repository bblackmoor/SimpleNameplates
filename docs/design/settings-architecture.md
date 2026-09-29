# Settings and runtime architecture

Status: Phases 2–4 extraction implemented; later phases remain proposed. Preserve Global + Profile ownership and the version-2 saved-data shape.

## Current inventory

Originally the .toc loaded a roughly 997-line `Core.lua` before `TRP3.lua`, `Nameplates.lua`, and `Settings.lua`. The .toc now loads `Defaults.lua`, `Core.lua`, `ManagedNames.lua`, and `Database.lua` before those consumers. `Defaults.lua` owns factory values; `Database.lua` owns version-2 validation, Profile lifecycle, and Global/Profile settings access. `ManagedNames.lua` owns CVar definitions/actions; `Core.lua` retains metadata, warnings, and accessibility helpers. Before Phase 4, Settings.lua (roughly 972 lines) constructed About, TRP3, Behavior, and Appearance. It now registers pages and slash routes while the page modules build their controls. Nameplates.lua (roughly 1061 lines) contains classification, styling, frame repair, events, and diagnostics. TRP3.lua is already a focused optional adapter.

The settings UI already has scroll layout, thumb switches, circled-i links, and section constructors. Preserve these. The Appearance panel combines Profile management, text/layout, colors, fixed Blizzard swatches, and cast effects. `CreateColorRow` contains swatch, color picker, cancel rollback, reset, and refresh behavior. Profile dialogs and selection are embedded in the same file.

## Proposed source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory Global/Profile values, preset definitions, valid ranges |
| `Database.lua` | Validate version-2 data, character selection, Profile lifecycle, explicit Global/Profile access |
| `ManagedNames.lua` | Managed CVars, restoration ledger, combat deferral, friendly class colors |
| `Core.lua` | Metadata and shared helpers/conflict warning |
| `TRP3.lua` | Existing integration adapter |
| `Nameplates.lua` | Existing styling pipeline initially; split on actual responsibility boundaries later |
| `SettingsControls.lua` | Shared scroll layout, switches, info links, section helpers, and refresh helper |
| `SettingsAbout.lua` | About |
| `SettingsTRP3.lua` | Global TRP3 preferences |
| `SettingsBehavior.lua` | Global addon, categories, and Blizzard name handling |
| `SettingsProfiles.lua` | Profile selection, create/copy/rename/delete/restore inside Appearance |
| `SettingsAppearance.lua` | Profile text/layout, color picker and rollback, Blizzard fixed-color explanations, cast effect |
| `Settings.lua` | Settings registration and slash routes |

The listed settings modules and the earlier Defaults, Database, ManagedNames, and Core boundaries are implemented. The visible tabs remain About, Behavior, Appearance, and TRP3; Profile management stays at the top of Appearance. Avoid splitting a small cohesive component solely to match a filename list. Put each tab's section/control constructors in visual order. If Profile management remains at the top of Appearance, keep that UI arrangement; the separate source module is for readability, not a new tab mandate.

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

## Phase 2 load-order constraint

`Database.lua` validates `global.managedNameCVarOriginals` using the allowlist that `ManagedNames.lua` constructs. ManagedNames resolves `ns.EnsureDB`, `ns.GetCategoryMode`, and `ns.GetStylingEnabled` only inside callbacks after Database has loaded. `Nameplates.lua` and `Settings.lua` bind `ns` functions immediately at load time, so both remain after Database. Failed CVar writes retain the captured original; combat restores defer until `PLAYER_REGEN_ENABLED`. Friendly class colors keep their separate in-memory originals and retry path.

## Phase 4 verification

`tests/settings-smoke.lua` uses a small WoW UI stub to exercise panel registration, one-time registration, slash routing, Profile create/restore dialogs, the master switch, and color-picker apply/cancel. The Core smoke test verifies .toc order and Lua compilation for all modules. Visual alignment and actual settings rendering still require a live WoW client.
