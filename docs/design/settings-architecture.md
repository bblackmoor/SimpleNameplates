# Settings and runtime architecture

Reviewed for 1.0.222 on 2026-10-08. Settings conversion and runtime module work are implemented; live WoW checks remain open. Saved data stays schema 2, with global behavior and account-wide appearance profiles selected per character. Earlier phase history is preserved in the [original implementation plan](implementation-plan.md), [runtime refactor plan](runtime-refactor-plan.md) and [Details Framework conversion record](details-framework-conversion.md).

## Settings ownership and pages

The pages are About, Profiles, Appearance, Colors and TRP3, in that order. All use the Details Framework widget adapter with shared layout helpers, native dialogs and yellow circled-i links. There is no Behavior page or slash route.

| Page | Current responsibility |
| --- | --- |
| About | Metadata, source link, commands, known presentation limits and read-only native-label swatches |
| Profiles | Account-wide profile management and the global styling Active switch |
| Appearance | Profile fonts, Slug rendering, name size/placement, health-bar width and threat display; global critter/companion hiding |
| Colors | Six profile priority colors, profile cast color/Active switch/effect dropdown/preview and six profile Health Bar switches, background-name dimming, a profile gradient opacity slider (0–100%) and full-health preview |
| TRP3 | Global integration and RP-name/title/OOC preferences |

Visible pages refresh their selected-profile controls immediately; hidden pages reread on show. Profile switching cancels active previews before changing selection and refreshes plates. Native profile dialogs capture name and object identity at opening and reject acceptance after selection changes or same-name replacement. Database mutations cancel affected drafts before switching or replacing their targets.

Reset settings on Appearance restores profile appearance and threat display plus global critter hiding. Reset all colors restores the selected profile's factory colors, cast highlighting off and effect Pulsing border, background dimming on, gradient opacity 100% for Default/custom profiles or 0% for High Contrast, and Health Bar preferences On except NPC - Background. There are no individual color reset buttons. Neither page reset changes the global styling switch or TRP3 preferences. See the [saved-data model](saved-data-model.md) for exact field ownership.

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
| `PresentationCapabilities.lua` / `PresentationRules.lua` | Frame access and profile Health Bar presentation policy |
| `PeriodicWork.lua` | Fair due-time scheduler, shared job/time budgets and elapsed-time retry clock |
| `FontRendering.lua` | Shared thin solid outline flags for all styled plate text |
| `NameplateFrames.lua` | Region access, native geometry/restoration baselines, restricted-anchor fallback and flat-fill artwork |
| `HealthGradient.lua` | Opacity-scaled fixed 80%-black to clear-at-95% tint clipped by the native fill |
| `NPCTitles.lua` | Safe structured-tooltip subtitle resolution and bounded session caches |
| `NameplateText.lua` | Names/titles, placement, bar-height padding, cast/title visibility and cached repair |
| `NameplateThreat.lua` | Secret-safe formatted threat percentage; blank when unavailable |
| `CastHighlight.lua` | Interruptible border/glow selection, DF renderer lifecycle, preview and native bar/icon/shield hooks |
| `NameplateRestoration.lua` | Original presentation restoration and deferred cleanup/retries |
| `NameplatePresentation.lua` | Full styling, focused native name/health-color repairs and data updates |
| `Nameplates.lua` | Single event frame, secure hooks, urgent refresh queues, periodic discovery and per-plate reconciliation |
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

Classification determines priority color. Every ordinary accessible plate shows its available health bar when its category Health Bar preference is on in and out of combat; disabled/missing-bar plates use colored floating names with titles directly underneath. Disabled styling restores native presentation. Widget-only plates keep widgets while actor text is suppressed. Blizzard controls cast/channel lifecycle; a visible cast replaces the NPC/TRP3 long title below the health bar. No unknown health value is fabricated. See the [runtime evaluation](evaluation-overview.md) for the complete order.

WorldContext reads game APIs only on refresh events; its Get operation returns the cache. Presentation and repair paths assess frame access before inspecting or writing regions. Unknown and secret observations remain distinct from false. Threat percentages use the supported text formatter without addon arithmetic on secret values.

Queued refresh flags merge per unit and across all-plate requests, then run from a detached batch in the per-frame callback. Ordinary Blizzard name/color hooks use focused repair paths; invalid cached presentation falls back to full styling. Broad global refreshes, restoration, cast and pending unit/plate retries share a scheduler budget with per-plate reconciliation: at most four jobs per frame with a one-millisecond target checked between jobs. List discovery runs every 0.25 seconds; served plates become due again after 0.25 seconds. Explicit unit work and current/previous target, mouseover and interaction plates remain immediate; broad global work is coalesced into fresh per-plate jobs. Background settings/context updates settle over several frames. Restoration continues while styling is disabled. Reconciliation shares its lookup assessment through observation/repair, writes only readable differences and reuses native-label observations for changed layout. Unknown properties use elapsed-time retry deadlines of 0.25–4 seconds without blocking readable checks; unchanged plates receive no repair writes. It does not routinely reclassify every visible entity; structural invalidation can fall back to full styling. Profiling measures periodic slices, native-list discovery and individual plate jobs; it does not change scheduling settings.

## Load order and CVar safety

The `.toc` is authoritative. Bundled libraries load first, then Defaults, FontMedia, Core, Profiler, PeriodicWork and WorldContext. ManagedNames constructs the restoration allowlist before Database validates saved records; its callbacks resolve database functions after loading. NameplateSetup also loads before Database. Runtime modules follow Database/TRP3, and settings modules follow Nameplates/Diagnostics.

Critter hiding claims only its supported world-name CVar. Legacy managed-name records are restoration-only. Approved setup changes have a separate per-character backup. Failed writes retain originals, and restricted writes/restoration defer until allowed. Friendly class-color CVars are observed without mutation. Profile switches do not change plate-visibility CVars.

## Verification

Run all 23 smoke suites and whitespace checks using the commands in the [README](../../README.md#development). They cover real bundled libraries under UI stubs, saved-field validation, profile/reset scopes, previews/dialogs, context/access gates, uniform presentation, cast/title transitions, restoration, secret-safe formatting, lifecycle and reachable upvalue limits. Profiling has deterministic timing and actual runtime/slash coverage.

Local tests cannot establish native rendering, client frame permissions or secret-value safety. Record observations in the [live WoW checklist](live-wow-verification.md); client items remain open until observed.

## Native callback completion and live status

Native font/color/alpha setter hooks retain guarded notifications and repair the current cached appearance after guards release. Geometry callbacks restore configured dimensions without full styling. Known Retail restricted-anchor layouts use the native hierarchy/options and PixelUtil rather than relying on GetPoint; unsupported layouts remain untouched. Half a physical pixel tolerates dimension rounding where scale is readable, without weakening font/color comparisons.

Selective repairs finish color/opacity after visibility, sizing and layout callbacks, consume pending artwork, and perform one bounded validated color/alpha finalization. Standalone artwork receives the same completion check. Fresh access, context, ownership/cache and readable GUID validation gate writes; unknown observations remain for reconciliation. The finalizer adds no classification, name-font/layout work, scheduling or full styles.

The 1.0.218 crowded-scene report confirms appearance convergence in that scene. Version 1.0.219 removed temporary checkpoint/audit reads and retained the fixes. All 21 local smoke suites passed for that cleanup; broader normal-play, secure behavior and settings acceptance remain open in the live checklist.

## Interruptible effects (1.0.221)

Colors has a profile Effect dropdown with Pulsing border and Solid border, one shared Border thickness slider (default 4), pulse Fade in and Fade out (0.2 seconds each), and a labeled preview. Both use addon-owned four-edge borders anchored directly to the cast bar at zero inset. Pulse opacity is fixed at 35–100%; solid opacity is 100%. Advanced and all other effects/controls are removed. Direct icon/shield Show/Hide and cast-bar visibility changes refresh detection, hidden casts gate explicit events, and unknown active state retries conservatively. Actual cast and visual acceptance remains open. See [cast-effect testing](cast-effect-testing.md).

## Combat settings guard (1.0.222)

`SettingsControls.lua` installs one PLAYER_REGEN_DISABLED/ENABLED listener after page construction. On combat entry, `SettingsWidgets.lua` retires color/typed-slider/drag previews through a scoped rollback path, closes dropdown menus, disables the shared controls and refreshes every page from saved values. `SettingsProfileDialogs.lua` cancels owned dialogs and invalidates their data so retained acceptance callbacks remain inert after combat. Already committed edits remain saved; no cancelled session resumes on combat exit.

Widget callbacks and picker/dialog entry/acceptance also check current player combat/lockdown, including before the event arrives and when controls are constructed during combat. Handles retain page-requested enablement separately from effective combat enablement, preserving protected profile actions and TRP3 dependencies. Silent refresh guards still prevent setters during page refresh. Debug/perf slash commands remain available. The `settings-combat-smoke.lua` suite exercises the actual bundled framework, rollback, menus/dialogs, retained callbacks, combat refreshes and normal editing after combat. Native timing, rendering and secure behavior remain live-client checks.
