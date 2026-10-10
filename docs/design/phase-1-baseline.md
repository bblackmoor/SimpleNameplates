# Test foundation record

The original characterization phase established tests for saved data, profile lifecycle, managed CVars, settings registration, and runtime behavior before the module refactor. Its phase-specific control inventory and pending tasks are superseded by current guides.

## Retained coverage

- Fresh defaults, valid/invalid field handling, copying/renaming/deleting/restoring profiles, and independent character assignments.
- CVar capture-before-change, overlapping restoration claims, failure retention, combat deferral, reload, and disable/re-enable behavior.
- One-time Settings/event/hook registration, slash routing, TOC module order, and reachable upvalue limits.
- Native region access, presentation/restoration, names/titles, threat formatting, and cast lifecycle.

Run current suites through [the developer entry point](../README.md#local-checks). Current ownership and compatibility are in [saved data](saved-data-model.md); native rendering/security observations belong in [live verification](live-wow-verification.md). Stubs characterize code behavior and do not establish live-client permissions.
