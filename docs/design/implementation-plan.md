# Simple Nameplates staged refactor plan

Historical implementation record, reviewed for 1.0.220 on 2026-10-08. Version-specific defaults, controls, paths and unchecked phase items below describe those releases; they are not current instructions. Use [settings architecture](settings-architecture.md), [saved data](saved-data-model.md), [runtime evaluation](evaluation-overview.md) and [live verification](live-wow-verification.md) for current behavior and acceptance. Category activation controls, the Behavior page, experimental replacement, glyph copies and glow selectors have been removed. Current controls use profile Health Bar preferences and a cast pulse Active switch.

Status: Phases 0–6 repository work implemented; live WoW checks remain open. The version-2 saved-data shape is unchanged.

The subsequent world-context/runtime work has its own [five-phase plan](runtime-refactor-plan.md); its phase 1 is now implemented.

See [saved-data-model.md](saved-data-model.md), [settings-architecture.md](settings-architecture.md), [phase-1-baseline.md](phase-1-baseline.md), and [live-wow-verification.md](live-wow-verification.md). This adapts the RP Emote Menu readability work to Simple Nameplates without adding Themes. Data/code-boundary changes and settings presentation changes were kept in distinct commits.

## Phase 0 — Analysis and design

- [x] Inventory schema, Global/Profile ownership, settings UI, runtime consumers, and large source responsibilities.
- [x] Keep the existing Character -> Profile selection and version-2 saved-data shape.
- [x] Record bundled Default/High Contrast behavior and managed-CVar restoration risk.
- [x] Preserve the staged plan and verification targets.

## Phase 1 — Characterize existing behavior

- [x] Add focused checks for fresh install, saved-value validation, Profile CRUD, independent character selection, and factory restore.
- [x] Capture Core-level CVar original-value behavior through styling disable/restore, category mode changes, reload, and combat deferral. Live-client verification remains open.
- [x] Record settings registration and nameplate refresh entry points, including known client-only checks.

Acceptance: Core smoke test passes; live WoW checks in phase-1-baseline.md remain pending. Changes in later phases can be compared with the existing behavior; avoid broad tests that merely restate implementation.

## Phase 2 — Clarify defaults and database responsibilities

- [x] Extract factory defaults/High Contrast values and schema-2 validation into clear units.
- [x] Extract Profile selection/lifecycle and explicit Global/Profile getters/setters from Core.
- [x] Preserve `schemaVersion = 2`, the saved-data shape, invalid-value handling, character keys, names, and every Profile operation.
- [x] Keep Default editable/restorable and High Contrast's existing lifecycle intact.

Acceptance: the updated Core behavior smoke test passes with the split modules and checks .toc paths/order and Lua syntax. Existing saved variables retain their meaning; no migration, reset, or unexpected Profile reassignment. Live WoW verification remains open.

Load order: `Defaults.lua` defines factory settings; `Core.lua` supplies metadata/helpers; `ManagedNames.lua` builds the CVar allowlist before `Database.lua` validates saved originals. ManagedNames callbacks resolve Database APIs only when invoked after loading. `TRP3.lua`, `NameplateClassification.lua`, `Nameplates.lua`, the settings page modules, and `Settings.lua` load in the explicit .toc order.

## Phase 3 — Isolate managed CVar behavior

- [x] Move managed overhead-name CVars, original-value ledger, combat deferral, and friendly class-color handling behind a focused API.
- [x] Preserve capture-before-change and restoration when styling is disabled or a CVar is no longer managed. Retain originals until restoration succeeds, including failed writes and combat deferral.
- [x] Keep Global category modes and Blizzard-controlled overhead-name limitations unchanged.

Acceptance: Core smoke checks pass for Profile-independent modes, saved CVar originals, overlapping claims, failed/silent writes, friendly class colors, and combat restoration; .toc paths and syntax pass. Live WoW confirmation of Profile switching, secret values, secure CVar behavior, and Blizzard-controlled overhead names remains open.

## Phase 4 — Make settings source human readable

- [x] Split About, TRP3, Behavior, Profile management, and Appearance construction into focused modules/sections.
- [x] Keep the existing visible tab arrangement.
- [x] Arrange source in the same tab -> section -> control order seen by the user.
- [x] Extract color picker/rollback, Profile dialogs, refresh, and registration responsibilities into named helpers/modules.
- [x] Reuse the existing scroll layout, switches, circled-i links, and consistent label/control/reset/info spacing.
- [x] Keep calls into CVar and nameplate subsystems explicit; verify .toc ordering and settings registration.

Acceptance: settings and Core smoke checks pass, covering one-time registration, tab/slash routes, Profile dialogs, master switch, color-picker cancel rollback, and all .toc module paths/syntax. Settings remain grouped by page/section and use the existing visual layout. Live WoW UI rendering remains to be checked.

## Phase 5 — Review nameplate runtime boundaries

- [x] Extract priority classification into NameplateClassification.lua; keep coupled styling/repair, event registration, and diagnostics together. Remove an unused dead function.
- [x] Preserve priority classification and leave name-inside-bar, TRP3 title/fallback, threat, highlight, and safe Midnight frame code in their existing paths.
- [x] Check reachable upvalues and that one event frame and two Blizzard repair hooks register on module load.

Acceptance: `tests/nameplates-smoke.lua` passes classification cases, one-time module setup, login/CVar callbacks, and upvalue checks. Core and settings smoke tests pass and .toc modules compile. Live-client verification of rendering, refresh paths, and secret-value safety remains open.

## Phase 6 — Cleanup and verification

- [x] Audit for transitional helpers and stale comments; update README, changelog, and developer docs. The About page already derives the version from .toc and describes the current behavior.
- [x] Run syntax and focused smoke checks.
- [ ] Run live WoW checks for fresh install, valid saved data, two characters selecting different Profiles, bundled restore, create/copy/rename/delete, six category modes, managed CVar restoration, inside-bar placement, interruptible casts, TRP3 fallback, reload/logout, and disable/re-enable.
- [x] Record outstanding client-only checks explicitly and follow repository version conventions.

Acceptance: repository smoke checks pass without changing settings behavior or the version-2 schema. Actual settings presentation and the remaining client-only behavior require the live WoW matrix in [live-wow-verification.md](live-wow-verification.md) before full integration acceptance.

## Scope

No Theme layer, new tab, JSON import/export, or schema bump is required. These would be separate feature proposals. Keep coherent phase commits separate so behavioral regressions can be traced.
