# Simple Nameplates staged refactor plan

Status: proposal. Phase 0 documents the analysis and design only; no Lua or saved-data schema was changed.

See [saved-data-model.md](saved-data-model.md) and [settings-architecture.md](settings-architecture.md). Based on Simple Nameplates main at `22f8515` and the RP Emote Menu Phase 0–8 approach. Keep the model and readability changes in separate reviewable commits.

## Phase 0 — Analysis and documentation

- [x] Inventory current schema, settings ownership, tabs, runtime consumers, and major source responsibilities.
- [x] Record Global/Profile/Theme ownership and preserve Global category modes.
- [x] Propose Default/High Contrast Profile and Theme behavior, deletion and fallback rules.
- [x] Document schema compatibility and CVar restoration risk.
- [x] Preserve all proposed phases and acceptance checks in this directory.

## Phase 1 — Defaults and saved-data shape

- [ ] Introduce explicit Global/Profile/Theme defaults and schema version 3 after deciding the compatibility policy.
- [ ] Make every setting's owner unambiguous; keep internal CVar originals available for safe restoration.
- [ ] Make factory Profile and Theme instances independent copies; validate malformed settings against their own defaults.
- [ ] Keep both bundled names editable and independently restorable.
- [ ] Establish invalid reference fallbacks without accidentally discarding character assignments.

Acceptance: fresh install and invalid-value cases produce correct defaults; disabling/reloading safely restores owned CVars; existing user-data handling matches the documented compatibility decision.

## Phase 2 — Explicit lifecycle APIs

- [ ] Add Global, active Profile, and referenced Theme accessors with no ambiguous writable merged table.
- [ ] Implement Profile create/copy/rename/delete/restore and per-character selection.
- [ ] Implement Theme create/copy/rename/delete/restore, Theme assignment, and referencing-Profile query.
- [ ] Guard Default, normalize deleted/invalid references, and require explicit confirmation for an in-use Theme deletion.

Acceptance: multiple Profiles can share a Theme; deleting a Profile reassigns all affected characters; deleting a Theme after confirmation reassigns every referencing Profile; cancel is lossless.

## Phase 3 — Runtime consumers and CVar behavior

- [ ] Route nameplate style to Global modes, active Profile presentation toggles, and referenced Theme colors/fonts.
- [ ] Extract managed-name CVar logic from Core with original-value preservation and combat deferral.
- [ ] Retain TRP3 cache/fallback logic and category precedence.
- [ ] Check active Profile/Theme switches, reset behavior, and disable/re-enable refreshes.

Acceptance: existing name, inside-bar placement, threat, cast highlight, hidden-category, and Blizzard-fixed-name behavior survive account/character switching and reloads; no new secret-value errors.

## Phase 4 — Profile and Theme settings UI

- [ ] Separate Profile selection/management and Theme assignment from Theme editing.
- [ ] Move editable color/font/placement controls to Themes; show Profile-owned presentation toggles in Profiles.
- [ ] Keep Behavior and TRP3 Global and About informative.
- [ ] Distinguish immutable Blizzard overhead swatches from editable colors, preserve six Priority Colors' order and current switch/info layout.

Acceptance: Profile switching updates the selected Theme, a Theme edit updates all Profiles using it, and Theme selection for editing never silently changes the active Profile.

## Phase 5 — Settings readability refactor

- [ ] Split settings code by tab and shared controls, with visual order matching source order.
- [ ] Give color swatch/picker/rollback, Profile dialogs, tab registration, and refresh orchestration named responsibilities.
- [ ] Reuse/simplify the existing scroll cursor; keep ordinary rows consistent without hiding each tab's layout in generic abstractions.
- [ ] Verify Lua upvalues, .toc ordering, registration, and slash-command opening.

Acceptance: a developer can find a control from its tab and read its label, state binding, callback, and refresh together; tab construction remains understandable without tracing across unrelated features.

## Phase 6 — Core and nameplate readability

- [ ] Extract defaults, database, and CVar management from Core along the documented boundaries.
- [ ] Review Nameplates.lua for focused splits (classification, style/repair, event glue, diagnostics) only where coupling and upvalues warrant them.
- [ ] Keep TRP3.lua a single adapter unless a concrete problem appears; retain accessible-value guards and safe frame updates.

Acceptance: startup and event registration run once; .toc order is correct; classification and nameplate repair match current behavior in live client checks.

## Phase 7 — Cleanup and verification

- [ ] Remove temporary compatibility accessors and stale Profile-as-appearance terminology.
- [ ] Update README, About text, changelog, and schema documentation.
- [ ] Run Lua syntax and focused data-model/settings tests and a live WoW matrix: fresh install, per-character selection, shared Theme edit, Profile switch, reset, delete/cancel, hidden-category CVars, interruptible cast, TRP3 fallback, reload/logout, and disabled-addon restoration.

Acceptance: tests pass and outstanding client-only checks are identified explicitly. Release/version changes follow the repository's existing conventions.

## Scope decisions before Phase 1

1. Confirm whether the proposed clean schema-3 break may reset valid schema-2 saved settings, or whether existing valid data must be converted. Restoring Blizzard CVar originals remains mandatory either way.
2. Confirm whether `showThreat` and `interruptibleHighlight` are Profile presentation choices as proposed, or Theme settings.
3. Confirm retaining the High Contrast Profile (pointing at High Contrast Theme) to preserve the current two-Profile experience.

Import/export is absent in this addon. Adding Profile, Theme, or Everything exchange would need its own format and UI specification; it is not part of these phases.

## Commit discipline

Deliver small, coherent commits for each phase, and keep saved-data/runtime changes separate from settings code layout and cosmetic work. Phase 0 is documentation only.
