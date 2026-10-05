# Settings and runtime architecture

Current as of 1.0.167. Settings conversion and runtime module work are implemented; live WoW checks remain open. Saved data stays schema 2, with global behavior and account-wide appearance profiles selected per character. Earlier phase history is preserved in the [original implementation plan](implementation-plan.md), [runtime refactor plan](runtime-refactor-plan.md) and [Details Framework conversion record](details-framework-conversion.md).

## Settings ownership and pages

The pages are About, Profiles, Appearance, Colors and TRP3, in that order. All use the Details Framework widget adapter with shared layout helpers, native dialogs and yellow circled-i links. There is no Behavior page or slash route.

| Page | Current responsibility |
| --- | --- |
| About | Metadata, source link, commands, known presentation limits and read-only native-label swatches |
| Profiles | Account-wide profile management and the global styling Active switch |
| Appearance | Profile fonts, Slug rendering, name size/placement, health-bar width and threat display; global critter/companion hiding |
| Colors | Six profile priority colors, profile cast color/effect and six global Active/Inactive category switches |
| TRP3 | Global integration and RP-name/title/OOC preferences |

Visible pages refresh their selected-profile controls immediately; hidden pages reread on show. Profile switching cancels active previews before changing selection and refreshes plates. Native profile dialogs capture name and object identity at opening and reject acceptance after selection changes or same-name replacement. Database mutations cancel affected drafts before switching or replacing their targets.

Reset settings on Appearance restores profile appearance and threat display plus global critter hiding. Reset all colors restores the selected profile's factory colors and cast effect None, and all six global category modes Active. Individual color resets affect only that color. Neither page reset changes the global styling switch or TRP3 preferences. See the [saved-data model](saved-data-model.md) for exact field ownership.

## Current source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory values, bundled profiles and valid ranges |
| `FontMedia.lua` | Built-in/shared font registry, IDs, provider changes and fallback policy |
| `Core.lua` | Metadata, conflict warning and safe accessibility helpers |
| `Profiler.lua` | Off-by-default session timing wrappers and performance commands; no saved data |
| `WorldContext.lua` | Event-driven world snapshot, revision and unknown-value preservation |
| `ManagedNames.lua` | Critter CVar ownership, legacy restoration ledger and combat deferral; friendly class-color CVars are read-only |
| `NameplateSetup.lua` | Consent-based plate-visibility compatibility review and per-character restoration |
| `Database.lua` | Schema-2 field validation, profiles, character selection and scoped settings access |
| `TRP3.lua` | Optional cached RP integration with normal-name fallback |
| `EntityFacts.lua` / `NameplateClassification.lua` | Safe observations and six-category first-match priority |
| `PresentationCapabilities.lua` / `PresentationRules.lua` | Frame access and uniform Active presentation policy |
| `FontRendering.lua` / `TextUnderlayers.lua` | Shared font flags and two black glyph underlayers for inside-bar text |
| `NameplateFrames.lua` | Region access, original bar artwork/width and flat-fill styling |
| `NPCTitles.lua` | Safe structured-tooltip subtitle resolution and bounded session caches |
| `NameplateText.lua` | Names/titles, placement, bar-height padding, cast/title visibility and cached repair |
| `NameplateThreat.lua` | Secret-safe formatted threat percentage; blank when unavailable |
| `CastHighlight.lua` | Interruptible-cast LibCustomGlow effects and visibility/icon lifecycle |
| `NameplateRestoration.lua` | Original presentation restoration and deferred cleanup/retries |
| `NameplatePresentation.lua` | Shared full styling path and Blizzard name/health repair entry points |
| `Nameplates.lua` | Single event frame, secure hooks, refresh queues, retries and 0.25-second reconciliation |
| `Diagnostics.lua` | Read-only context, targeted-unit and relevant-plate reporting |
| `SettingsControls.lua` / `SettingsWidgets.lua` | Shared layout/reflow and the Details Framework widget adapter |
| `SettingsColorPicker.lua` | Native RGB session ownership, captured target, preview/commit/cancel and stale callbacks |
| `SettingsProfileDialogs.lua` | Captured profile identity and native lifecycle/restore confirmations |
| `SettingsAbout.lua` / `SettingsProfiles.lua` | About page, profile management and shared selectors |
| `SettingsBehavior.lua` | Global styling/critter controls and their setup/restoration callbacks |
| `SettingsAppearance.lua` / `SettingsColors.lua` / `SettingsTRP3.lua` | Page construction, refresh and scoped user actions |
| `Settings.lua` | Settings registration and slash routing |

## Shared settings contracts

Factories live in SettingsPanels; RegisterSettingsPanels uses explicit pageOrder and keyed categories/panels with API/factory preflight and duplicate protection. Ordinary editable pages expose panel.Refresh. SettingsControls, then SettingsColorPicker and SettingsWidgets, load before page construction; SettingsProfileDialogs loads before SettingsProfiles. Native scroll/reflow remains page-owned. See [shared conventions and coverage](settings-conventions.md) and [the completed four-phase record](addon-standardization.md).

## Runtime contracts

Classification determines priority color. Every ordinary Active accessible plate shows its available health bar in and out of combat; missing-bar plates use colored floating names. Inactive/disabled styling restores native presentation. Widget-only plates keep widgets while actor text is suppressed. Blizzard controls cast/channel lifecycle; a visible cast replaces the NPC/TRP3 long title below the health bar. No unknown health value is fabricated. See the [runtime evaluation](evaluation-overview.md) for the complete order.

WorldContext reads game APIs only on refresh events; its Get operation returns the cache. Presentation and repair paths assess frame access before inspecting or writing regions. Unknown and secret observations remain distinct from false. Threat percentages use the supported text formatter without addon arithmetic on secret values.

Queued refreshes run from the per-frame callback. Restoration retries, pending unit/plate retries, cached-name drift scans and pending title-visibility repairs run on the 0.25-second reconciliation cadence. Reconciliation does not routinely reclassify every visible entity; unresolved cached repair can fall back to full styling. Profiling wraps these existing paths without changing their cadence.

## Load order and CVar safety

The `.toc` is authoritative. Bundled libraries load first, then Defaults, FontMedia, Core, Profiler and WorldContext. ManagedNames constructs the restoration allowlist before Database validates saved records; its callbacks resolve database functions after loading. NameplateSetup also loads before Database. Runtime modules follow Database/TRP3, and settings modules follow Nameplates/Diagnostics.

Critter hiding claims only its supported world-name CVar. Legacy managed-name records are restoration-only. Approved setup changes have a separate per-character backup. Failed writes retain originals, and restricted writes/restoration defer until allowed. Friendly class-color CVars are observed without mutation. Profile switches do not change plate-visibility CVars.

## Verification

Run all 20 smoke suites and whitespace checks using the commands in the [README](../../README.md#development). They cover real bundled libraries under UI stubs, saved-field validation, profile/reset scopes, previews/dialogs, context/access gates, uniform presentation, cast/title transitions, restoration, secret-safe formatting, lifecycle and reachable upvalue limits. Profiling has deterministic timing and actual runtime/slash coverage.

Local tests cannot establish native rendering, client frame permissions or secret-value safety. Record observations in the [live WoW checklist](live-wow-verification.md); client items remain open until observed.

