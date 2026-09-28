# Simple Nameplates staged refactor plan

Status: Phases 0–2 implemented; live WoW checks remain open. The version-2 saved-data shape is unchanged.

See [saved-data-model.md](saved-data-model.md), [settings-architecture.md](settings-architecture.md), and [phase-1-baseline.md](phase-1-baseline.md). This adapts the RP Emote Menu readability work to Simple Nameplates without adding Themes. Keep data/code-boundary changes and settings presentation changes in distinct commits.

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

Phase 2 load order: `Defaults.lua` defines factory settings; `Core.lua` builds the managed CVar allowlist and exposes its runtime helpers; `Database.lua` validates saved data using that allowlist and exports the settings API before `TRP3.lua`, `Nameplates.lua`, and `Settings.lua` bind it. Core's callbacks resolve Database APIs only when invoked after loading. Phase 3 will move managed-CVar implementation out of Core.

## Phase 3 — Isolate managed CVar behavior

- [ ] Move managed overhead-name CVars, original-value ledger, combat deferral, and friendly class-color handling behind a focused API.
- [ ] Preserve capture-before-change and restoration when styling is disabled or a CVar is no longer managed.
- [ ] Keep Global category modes and Blizzard-controlled overhead-name limitations unchanged.

Acceptance: a Profile switch changes appearance without changing managed category CVars; disabling/restoring and combat transitions work as before.

## Phase 4 — Make settings source human readable

- [ ] Split About, TRP3, Behavior, Profile management, and Appearance construction into focused modules/sections.
- [ ] Keep existing visible tab arrangement unless a concrete UI problem calls for a change.
- [ ] Arrange source in the same tab -> section -> control order seen by the user.
- [ ] Extract color picker/swatch/rollback, dialogs, refresh, and registration responsibilities into named helpers.
- [ ] Reuse the existing scroll layout, switches, circled-i links, and consistent label/control/reset/info spacing.
- [ ] Keep calls into CVar and nameplate subsystems explicit; verify .toc ordering and settings registration.

Acceptance: a developer can locate a setting and understand its saved owner, UI callback, and refresh behavior without tracing unrelated code.

## Phase 5 — Review nameplate runtime boundaries

- [ ] Review Nameplates.lua for useful classification, styling/repair, event, and diagnostic boundaries; split only where coupling and size justify it.
- [ ] Preserve priority classification, name-inside-bar behavior, TRP3 long-title/fallback, threat text, interruptible highlight, and safe Midnight frame access.
- [ ] Check upvalues and that startup/event hooks register once.

Acceptance: existing nameplates and refresh paths work in a live client, without secret-value regressions.

## Phase 6 — Cleanup and verification

- [ ] Remove transitional helpers and stale comments; update README, About, changelog, and developer docs as needed.
- [ ] Run syntax and focused smoke checks.
- [ ] Run live WoW checks for fresh install, valid saved data, two characters selecting different Profiles, bundled restore, create/copy/rename/delete, six category modes, managed CVar restoration, inside-bar placement, interruptible casts, TRP3 fallback, reload/logout, and disable/re-enable.
- [ ] Record outstanding client-only checks explicitly and follow repository version conventions.

Acceptance: settings retain their previous meaning and presentation; documented behavior matches tested behavior.

## Scope

No Theme layer, new tab, JSON import/export, or schema bump is required. These would be separate feature proposals. Keep coherent phase commits separate so behavioral regressions can be traced.
