# Settings and database refactor record

The original six code phases are complete. This record retains their resulting boundaries; obsolete phase tasks and superseded control inventories have been removed. Current contracts are in [settings architecture](settings-architecture.md), [saved data](saved-data-model.md), and [live verification](live-wow-verification.md).

## Implemented decisions

- Separate factory defaults, database validation/profile lifecycle, managed CVars, settings construction, and runtime presentation.
- Keep schema 2 and character-to-account-profile assignments; no separate Theme layer or database-framework replacement.
- Preserve capture-before-change and retry-safe CVar restoration through combat, failed writes, reload, and disabling styling.
- Split settings layout, widget adaptation, RGB sessions, native profile dialogs, page construction, and registration by responsibility.
- Keep classification independent from rendering; restoration retains original region baselines and current-unit identity checks.
- Cover saved-value validation, profile CRUD/restore, two-character selection, setup/restoration, registration, runtime behavior, and stale editor callbacks with focused smoke suites.

Code completion does not close client-only checks. The single current live checklist records those observations. Version-by-version implementation history remains in the [changelog](../../CHANGELOG.md).
