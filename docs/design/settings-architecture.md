# Settings and runtime architecture

Status: Phases 2–6 repository work implemented. Global + Profile ownership and the version-2 saved-data shape are unchanged; live WoW checks remain open.

## Current inventory

The .toc loads `Defaults.lua`, `Core.lua`, `ManagedNames.lua`, and `Database.lua` before runtime and settings consumers. `Defaults.lua` owns factory values; `Database.lua` owns version-2 validation, Profile lifecycle, and Global/Profile settings access. `ManagedNames.lua` owns CVar definitions/actions; `Core.lua` retains metadata, warnings, and accessibility helpers. `NameplateClassification.lua` owns priority decisions while `Nameplates.lua` owns styling, repair, diagnostics, and the single event frame. `TRP3.lua` is the optional integration adapter. The settings page modules construct their controls; `Settings.lua` registers pages and slash routes.

The settings UI uses scroll layout, thumb switches, circled-i links, and section constructors. The Appearance panel combines Profile management, text/layout, colors, fixed Blizzard swatches, and cast effects. `SettingsProfiles.lua` owns Profile dialogs and selection. `SettingsAppearance.lua` owns color-picker apply/cancel rollback and Appearance construction, using shared row controls from `SettingsControls.lua`.

## Current source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory Global/Profile values, preset definitions, valid ranges |
| `Database.lua` | Validate version-2 data, character selection, Profile lifecycle, explicit Global/Profile access |
| `ManagedNames.lua` | Managed CVars, restoration ledger, combat deferral, friendly class colors |
| `Core.lua` | Metadata and shared helpers/conflict warning |
| `TRP3.lua` | Existing integration adapter |
| `NameplateClassification.lua` | Six-category priority classification and name-only state |
| `Nameplates.lua` | Styling, frame repair, events, and diagnostics |
| `SettingsControls.lua` | Shared scroll layout, switches, info links, section helpers, and refresh helper |
| `SettingsAbout.lua` | About |
| `SettingsTRP3.lua` | Global TRP3 preferences |
| `SettingsBehavior.lua` | Global addon, categories, and Blizzard name handling |
| `SettingsProfiles.lua` | Profile selection, create/copy/rename/delete/restore inside Appearance |
| `SettingsAppearance.lua` | Profile text/layout, color picker and rollback, Blizzard fixed-color explanations, cast effect |
| `Settings.lua` | Settings registration and slash routes |

The visible tabs are About, Behavior, Appearance, and TRP3; Profile management appears at the top of Appearance. Its separate source module supports readability without introducing a separate tab. Keep each tab's section/control constructors in visual order and avoid splitting a small cohesive component solely to match a filename list.

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

## Load-order constraint

`Database.lua` validates `global.managedNameCVarOriginals` using the allowlist that `ManagedNames.lua` constructs. ManagedNames resolves `ns.EnsureDB`, `ns.GetCategoryMode`, and `ns.GetStylingEnabled` only inside callbacks after Database has loaded. `NameplateClassification.lua`, `Nameplates.lua`, and the settings modules load after Database. Failed CVar writes retain the captured original; combat restores defer until `PLAYER_REGEN_ENABLED`. Friendly class colors keep their separate in-memory originals and retry path.

## Phase 4 verification

`tests/settings-smoke.lua` uses a small WoW UI stub to exercise panel registration, one-time registration, slash routing, Profile create/restore dialogs, the master switch, and color-picker apply/cancel. The Core smoke test verifies .toc order and Lua compilation for all modules. Visual alignment and actual settings rendering still require a live WoW client.

## Phase 5 verification

`tests/nameplates-smoke.lua` executes both runtime modules with small WoW stubs. It checks representative classification cases, one event frame, two Blizzard repair hooks, event counts, login and CVar callbacks, and reachable upvalue counts. It cannot establish actual Blizzard frame layout or Midnight secret-value behavior; those remain live WoW checks.

## Phase 6 verification

Run all three smoke scripts from the repository root. The pending game-client integration matrix is tracked in [live-wow-verification.md](live-wow-verification.md); do not infer client behavior from the stubs.
