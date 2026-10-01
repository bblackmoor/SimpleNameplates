# Settings and runtime architecture

Status: Original Phases 2–6 and subsequent runtime refactor phases 1–2 implemented. Global + Profile ownership and the version-2 saved-data shape are unchanged; live WoW checks remain open.

## Current inventory

The .toc loads `Defaults.lua`, `Core.lua`, `WorldContext.lua`, `ManagedNames.lua`, and `Database.lua` before runtime and settings consumers. `Defaults.lua` owns factory values; `Database.lua` owns version-2 validation, Profile lifecycle, and Global/Profile settings access. `ManagedNames.lua` owns CVar definitions/actions; `Core.lua` retains metadata, warnings, and accessibility helpers. `NameplateClassification.lua` owns priority decisions. Frame access, text/layout repair, threat display, cast highlights, presentation/restoration, and diagnostics have focused modules; `Nameplates.lua` owns the single event frame and refresh lifecycle. `TRP3.lua` is the optional integration adapter. The settings page modules construct their controls; `Settings.lua` registers pages and slash routes.

The settings UI uses scroll layout, thumb switches, circled-i links, and section constructors. The Appearance panel combines Profile management, text/layout, colors, fixed Blizzard swatches, and cast effects. `SettingsProfiles.lua` owns Profile dialogs and selection. `SettingsAppearance.lua` owns color-picker apply/cancel rollback and Appearance construction, using shared row controls from `SettingsControls.lua`.

## Current source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory Global/Profile values, preset definitions, valid ranges |
| `Database.lua` | Validate version-2 data, character selection, Profile lifecycle, explicit Global/Profile access |
| `ManagedNames.lua` | Managed CVars, restoration ledger, combat deferral, friendly class colors |
| `Core.lua` | Metadata and shared helpers/conflict warning |
| `WorldContext.lua` | Event-driven world snapshot, revision, and unknown-value preservation |
| `PresentationCapabilities.lua` | Frame/region access assessment and observational reads |
| `TRP3.lua` | Existing integration adapter |
| `NameplateClassification.lua` | Six-category priority classification and name-only state |
| `NameplateFrames.lua` | Shared nameplate and region access through capability assessment |
| `NameplateText.lua` | Names, TRP3 titles, placement, inside-bar sizing, and cached text repair |
| `NameplateThreat.lua` | Readable threat-percentage text |
| `CastHighlight.lua` | Interruptible-cast border and pulse |
| `NameplatePresentation.lua` | Apply/repair current category styling and restore frames |
| `Nameplates.lua` | Events, hooks, refresh queues, and nameplate lifecycle |
| `Diagnostics.lua` | Targeted-unit relationship and presentation reporting |
| `SettingsControls.lua` | Shared scroll layout, switches, info links, section helpers, and refresh helper |
| `SettingsAbout.lua` | About |
| `SettingsTRP3.lua` | Global TRP3 preferences |
| `SettingsBehavior.lua` | Global addon, categories, and Blizzard name handling |
| `SettingsProfiles.lua` | Profile selection, create/copy/rename/delete/restore inside Appearance |
| `SettingsAppearance.lua` | Profile text/layout, color picker and rollback, Blizzard fixed-color explanations, cast effect |
| `Settings.lua` | Settings registration and slash routes |

The visible tabs are About, Behavior, Appearance, and TRP3; Profile management appears at the top of Appearance. Its separate source module supports readability without introducing a separate tab. Keep each tab's section/control constructors in visual order and avoid splitting a small cohesive component solely to match a filename list.

## Runtime and UI contracts

- `StateForUnit` and category priority do not depend on Profile; six Global modes keep their current active/inactive semantics.
- `NameplatePresentation.ApplySimpleStyle` uses Global behavior and the active appearance Profile. Profile switches refresh plates, including inside-bar placement, cached name repair, full-title suppression, threat text, and interruptible cast highlight.
- Name CVars capture original values before changing them, restore them when no longer managed or styling is disabled, and defer restricted changes in combat. Profile switches must not rewrite category CVars.
- Keep TRP3's cache and normal-WoW-name fallback. Do not introduce reads or comparisons of Midnight secret values in new helper or refresh paths.
- Keep six Priority Colors in danger-to-friendly order and fixed Blizzard swatches distinct from editable colors.
- Standard setting row order stays label, control, reset (if any), info glyph (if any), with consistent spacing and the established thumb switches.

Use a simple tab -> section -> control structure; separate construction from refresh/enable-state callbacks where helpful. Reuse the existing scroll cursor and avoid a generic declarative framework. Extract large nested callbacks into named helpers or context tables when this reduces Lua upvalues. Preserve explicit .toc load order and settings registration.

## Verification

Characterize existing defaults, validation, Profile CRUD, per-character selection, CVar capture/reapply/restore, settings registration, and styling refresh. Run targeted Lua syntax/smoke checks and a live WoW matrix. Local stubs cannot prove Blizzard frame behavior or secret-value safety in the client.

## Load-order constraint

`Database.lua` validates `global.managedNameCVarOriginals` using the allowlist that `ManagedNames.lua` constructs. ManagedNames resolves `ns.EnsureDB`, `ns.GetCategoryMode`, and `ns.GetStylingEnabled` only inside callbacks after Database has loaded. Runtime load order after Database/TRP3 is Classification -> PresentationCapabilities -> Frames -> Text -> Threat -> CastHighlight -> Presentation -> Nameplates -> Diagnostics, followed by settings modules. Failed CVar writes retain the captured original; combat restores defer until `PLAYER_REGEN_ENABLED`. Friendly class colors keep their separate in-memory originals and retry path.

## Phase 4 verification

`tests/settings-smoke.lua` uses a small WoW UI stub to exercise panel registration, one-time registration, slash routing, Profile create/restore dialogs, the master switch, and color-picker apply/cancel. The Core smoke test verifies .toc order and Lua compilation for all modules. Visual alignment and actual settings rendering still require a live WoW client.

## Phase 5 verification

`tests/nameplates-smoke.lua` executes the runtime modules with small WoW stubs. It checks representative classification cases, one event frame, two Blizzard repair hooks, event counts, login and CVar callbacks, and reachable upvalue counts. It cannot establish actual Blizzard frame layout or Midnight secret-value behavior; those remain live WoW checks.

## Phase 6 verification

Run all three smoke scripts from the repository root. The pending game-client integration matrix is tracked in [live-wow-verification.md](live-wow-verification.md); do not infer client behavior from the stubs.

## Subsequent runtime phase 1

The current category and presentation decisions are unchanged. The targeting predicate used by classification is explicitly exported for Diagnostics, fixing the previous unavailable-function call. The runtime smoke test now executes presentation, TRP3 title suppression, inside-bar sizing, cached drift repair, restoration, and the diagnostic path in addition to event registration and upvalue checks. Phase 2 adds cached context and capability assessment; new category definitions and the combat-dependent bar policy remain pending; see [runtime-refactor-plan.md](runtime-refactor-plan.md).

## Subsequent runtime phase 2

WorldContext loads after Core and before runtime consumers. Its Get operation does not query game APIs; Refresh is event-driven, retains false versus unknown, and changes the revision only when facts change. Player combat and combat lockdown are independent. The cache remains active with styling disabled. Frame helpers and exported presentation/text/effect entry points use PresentationCapabilities before reading or modifying Blizzard regions. Blizzard hooks obtain context explicitly rather than interpreting extra hook arguments as context. Diagnostics reports cached context and observed region access/visibility; it never initializes cast overlays.

Run the additional `tests/world-context-smoke.lua` script for context caching, API failures/secrets, event filters, region availability, and forbidden/protected access. Runtime tests cover forbidden-frame refresh/restoration/hooks/cleanup/drift and read-only diagnostics. These checks do not establish actual Blizzard client permissions; the client checklist remains open.
