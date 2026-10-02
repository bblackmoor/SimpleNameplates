# Settings and runtime architecture

Status: Original Phases 2–6 and subsequent runtime refactor phases 1–4 implemented. Global + Profile ownership and the version-2 saved-data shape are unchanged; live WoW checks remain open.

## Current inventory

The .toc loads `Defaults.lua`, `Core.lua`, `WorldContext.lua`, `ManagedNames.lua`, and `Database.lua` before runtime and settings consumers. `Defaults.lua` owns factory values; `Database.lua` owns version-2 validation, Profile lifecycle, and Global/Profile settings access. `ManagedNames.lua` owns critter visibility, CVar restoration, and friendly class colors; `Core.lua` retains metadata, warnings, and accessibility helpers. `EntityFacts.lua` owns observations; `NameplateClassification.lua` owns priority decisions. Frame access, text/layout repair, threat display, cast highlights, presentation/restoration, and diagnostics have focused modules; `Nameplates.lua` owns the single event frame and refresh lifecycle. `TRP3.lua` is the optional integration adapter. The settings page modules construct their controls; `Settings.lua` registers pages and slash routes.

The settings UI uses scroll layout, thumb switches, circled-i links, aligned setting rows, and sentence-case section headings. Profiles owns management; Appearance owns text/layout and display effects; Colors owns color-picker apply/cancel rollback and duplicate shared NPC color controls. About owns native-label examples and limitations. All TRP3 controls stay together and remain global.

## Current source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory Global/Profile values, preset definitions, valid ranges |
| `Database.lua` | Validate version-2 data, character selection, Profile lifecycle, explicit Global/Profile access |
| `ManagedNames.lua` | Critter CVar, restoration-only name/plate allowlist, ledger, combat deferral, friendly class colors |
| `Core.lua` | Metadata and shared helpers/conflict warning |
| `WorldContext.lua` | Event-driven world snapshot, revision, and unknown-value preservation |
| `PresentationCapabilities.lua` | Frame/region access assessment and observational reads |
| `TRP3.lua` | Existing integration adapter |
| `EntityFacts.lua` | Readable identity, faction, attackability, interaction and attacking evidence, with unknown results |
| `NameplateClassification.lua` | Pure six-category first-match classification and winning rule |
| `PresentationRules.lua` | Scoped context/entity decisions and independent combat health-bar policy |
| `NameplateRestoration.lua` | Original visibility and deferred restoration/cleanup retries |
| `NameplateFrames.lua` | Shared nameplate and region access through capability assessment |
| `NameplateText.lua` | Names, TRP3 titles, placement, inside-bar sizing, and cached text repair |
| `NameplateThreat.lua` | Readable threat-percentage text |
| `CastHighlight.lua` | Interruptible-cast border and pulse |
| `NameplatePresentation.lua` | Apply one shared presentation decision for styling and both Blizzard repair hooks |
| `Nameplates.lua` | Events, hooks, refresh queues, and nameplate lifecycle |
| `Diagnostics.lua` | Targeted-unit relationship and presentation reporting |
| `SettingsControls.lua` | Shared scroll layout, switches, info links, section helpers, and refresh helper |
| `SettingsAbout.lua` | Metadata, commands, limitations and read-only native-label examples |
| `SettingsTRP3.lua` | Global TRP3 preferences |
| `SettingsBehavior.lua` | Global addon, categories, and Blizzard name handling |
| `SettingsProfiles.lua` | Profiles page and compact selectors reused on Appearance/Colors |
| `SettingsAppearance.lua` | Profile fonts, text/layout, threat display, and cast-highlight switch |
| `SettingsColors.lua` | Profile colors, picker rollback, shared duplicate controls and scoped resets |
| `Settings.lua` | Settings registration and slash routes |

The pages are About, Behavior, Profiles, Appearance, Colors, and TRP3 in that order. Each visual page refreshes its compact profile selector and controls on show; selecting a profile immediately refreshes the current page and nameplates. Management is confined to Profiles. Hidden pages reread the active profile when shown. No saved values are relocated or converted.

The hierarchy is page title, sentence-case yellow section heading, white setting label, muted description. A common control column holds switches, dropdowns, sliders, and swatches. Row resets/info links follow the control. Section actions occupy their own rows below controls, never share a heading row. Descriptions are measured at the available width and the scroll layout reflows on page show and resize.

Reset priority colors resets only the six classification colors. Reset all profile colors keeps the existing complete color reset, including sanctuary-player and effect colors. Reset text and layout keeps the prior appearance reset: fonts/size/sanctuary-font/name placement plus enabling threat display, without resetting colors or cast-highlight enablement. Shared Useful/Useless controls in the sanctuary section still edit canonical category colors.

## Runtime and UI contracts

- `StateForUnit` and category priority do not depend on Profile; six Global modes keep their current active/inactive semantics.
- `NameplatePresentation.ApplySimpleStyle` uses Global behavior and the active appearance Profile. Profile switches refresh plates, including inside-bar placement, cached name repair, full-title suppression, threat text, and interruptible cast highlight.
- Critter visibility manages ordinary-name CVars; startup compatibility setup separately manages approved plate-visibility values. Prior captured world-name values remain restoration-only. Retain originals and retry until restored. Friendly class colors remain separately managed. Profile switches must not change nameplate-visibility CVars.
- Keep TRP3's cache and normal-WoW-name fallback. Do not introduce reads or comparisons of Midnight secret values in new helper or refresh paths.
- Keep six Priority Colors in danger-to-friendly order and fixed Blizzard swatches distinct from editable colors.
- Standard setting row order stays label, control, reset (if any), info glyph (if any), with consistent spacing and the established thumb switches.

Use a simple tab -> section -> control structure; separate construction from refresh/enable-state callbacks where helpful. Reuse the existing scroll cursor and avoid a generic declarative framework. Extract large nested callbacks into named helpers or context tables when this reduces Lua upvalues. Preserve explicit .toc load order and settings registration.

## Verification

Characterize existing defaults, validation, Profile CRUD, per-character selection, CVar capture/reapply/restore, settings registration, and styling refresh. Run targeted Lua syntax/smoke checks and a live WoW matrix. Local stubs cannot prove Blizzard frame behavior or secret-value safety in the client.

## Load-order constraint

`Database.lua` validates `global.managedNameCVarOriginals` using the allowlist that `ManagedNames.lua` constructs. ManagedNames resolves `ns.EnsureDB`, `ns.GetCategoryMode`, and `ns.GetStylingEnabled` only inside callbacks after Database has loaded. Runtime load order after Database/TRP3 is EntityFacts -> Classification -> PresentationCapabilities -> PresentationRules -> Frames -> Text -> Threat -> CastHighlight -> Restoration -> Presentation -> Nameplates -> Diagnostics, followed by settings modules. Failed CVar writes retain the captured original; combat restores defer until `PLAYER_REGEN_ENABLED`. Friendly class colors keep their separate in-memory originals and retry path.

## Phase 4 verification

`tests/settings-smoke.lua` uses a small WoW UI stub to exercise panel registration, one-time registration, slash routing, Profile create/restore dialogs, the master switch, and color-picker apply/cancel. The Core smoke test verifies .toc order and Lua compilation for all modules. Visual alignment and actual settings rendering still require a live WoW client.

## Phase 5 verification

`tests/nameplates-smoke.lua` executes the runtime modules with small WoW stubs. It checks representative classification cases, one event frame, two Blizzard repair hooks, event counts, login and CVar callbacks, and reachable upvalue counts. It cannot establish actual Blizzard frame layout or Midnight secret-value behavior; those remain live WoW checks.

## Phase 6 verification

Run all six smoke scripts from the repository root. The pending game-client integration matrix is tracked in [live-wow-verification.md](live-wow-verification.md); do not infer client behavior from the stubs.

## Subsequent runtime phase 1

The current category and presentation decisions are unchanged. The targeting predicate used by classification is explicitly exported for Diagnostics, fixing the previous unavailable-function call. The runtime smoke test now executes presentation, TRP3 title suppression, inside-bar sizing, cached drift repair, restoration, and the diagnostic path in addition to event registration and upvalue checks. Phase 2 adds cached context and capability assessment; phase 3 adds new category definitions; phase 4 adds independent presentation and combat-dependent bars; see [runtime-refactor-plan.md](runtime-refactor-plan.md).

## Subsequent runtime phase 2

WorldContext loads after Core and before runtime consumers. Its Get operation does not query game APIs; Refresh is event-driven, retains false versus unknown, and changes the revision only when facts change. Player combat and combat lockdown are independent. The cache remains active with styling disabled. Frame helpers and exported presentation/text/effect entry points use PresentationCapabilities before reading or modifying Blizzard regions. Blizzard hooks obtain context explicitly rather than interpreting extra hook arguments as context. Diagnostics reports cached context and observed region access/visibility; it never initializes cast overlays.

Run the additional `tests/world-context-smoke.lua` script for context caching, API failures/secrets, event filters, region availability, and forbidden/protected access. Runtime tests cover forbidden-frame refresh/restoration/hooks/cleanup/drift and read-only diagnostics. These checks do not establish actual Blizzard client permissions; the client checklist remains open.

## Subsequent runtime phase 3

EntityFacts receives the cached context and preserves primitive true/false/unknown observations. Classification consumes facts independently of game APIs and returns the winning rule. Player identity and faction remain available even when a combat priority wins. NPC interaction evidence does not override Attacking, Hostile, or Neutral. The current category keys replace the previous PC/NPC distinction without saved-setting conversion. Defaults, bundled profiles, validation, settings rows, diagnostics, and managed-name policies use the same six keys.

In 1.0.104 experimental replacement required all categories Active. It was subsequently removed in 1.0.105; the critter control remains separate. Friendly class-color control respects Friendly and the possible player combat priorities. The new entity smoke script covers facts, precedence, and secret/API-error handling; existing smoke scripts cover saved-field retention/discard, CVar restoration, presentation, and diagnostics. Client behavior remains unverified.

## Removal of experimental replacement (1.0.105)

The replacement toggle, defaults, getter/setter/actions, diagnostic field, startup action, and CVar claims are removed. Database validation silently discards its obsolete preference. The existing managed-originals ledger retains an explicit allowlist of previously captured player/NPC/minion and nameplate-visibility values solely for restoration; these values are never captured or claimed again. Login invokes managed restoration even when styling is disabled. Failed and combat-blocked restoration retains originals for retries; current critter hiding can stay enabled independently. The generic RestoreManagedNameSettings operation supports disabling the remaining control.

The former permanent friendly-player name-only claim is gone. Phase 4 subsequently implements deferred frame restoration and the independent combat-dependent presentation decision. No in-game frame behavior is established by the smoke tests.

## Subsequent runtime phase 4

PresentationRules selects named rules by context and entity facts and returns one capability-dependent decision. Classification no longer owns name-only presentation. NameplatePresentation applies the same full decision from both repair hooks so name color/layout, bars, titles, threat, and cast effects stay consistent through transitions. NameplateText associates its cache with the decision and context revision and refuses stale or changed-bar repair; the runtime then recomputes current presentation.

NameplateRestoration captures original shown states before styling and retries skipped restoration with styling disabled. The runtime retains known removed-unit frames and pending refreshes for temporarily inaccessible plates. These retries assess access first and do not poll world APIs. Nameplate visibility CVars remain restoration-only; combat presentation does not modify them. All six smoke scripts pass locally; actual Midnight permissions and presentation require client verification.
