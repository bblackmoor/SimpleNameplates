# World-context and entity-presentation runtime refactor

Status: phases 1–3 implemented through 1.0.104; phases 4–5 pending. This follows the completed original settings refactor and is a separate five-phase sequence.

## Baseline and accepted rules

Preserve the 1.0.101 baseline during phase 1: current six categories with Active/Inactive only, no dedicated minion-name hide switch, critter/companion hiding and experimental overhead replacement retained, and individual saved-field validation without aliases or conversion. Valid settings and CVar restoration records remain usable regardless of the schema marker.

The phase-3 classifier evaluates first-match priority:
1. Attacking me.
2. Aggressive NPC or eligible PvP opponent: Hostile.
3. Can attack me without meeting the earlier conditions: Neutral.
4. Player: Friendly.
5. NPC offering useful interaction: Useful.
6. Otherwise: Useless.

Retain specific identity, faction relationship, directional attackability, interaction evidence, and unavailable/restricted information independently of the category. Cached world context is updated on relevant events rather than re-queried for every presentation update. Context guides entity checks; actual presentation capabilities must still be checked.

Specific presentation rules must support combinations such as an opposite-faction player in sanctuary without changing other combinations. Share common operations, and split files by responsibility when warranted. Category-wide CVars can overlap priority categories and must be handled explicitly.

For Active categories, planned health-bar policy is separate from classification:
- Player in combat: show bars on every entity whose permitted nameplate supports one.
- Player out of combat: show bars only for Neutral, Hostile, and Attacking.
- Inactive: leave Blizzard presentation unchanged.
- Entering/leaving combat refreshes visible presentation; TRP3 long titles are suppressed whenever a bar is displayed.
Respect restricted frames and combat restrictions; do not assume a frame or permitted operation exists.

## Phase 1 — Separate runtime responsibilities

- [x] Split frame access, names/titles/layout and drift repair, threat text, cast effects, presentation/restoration, runtime events, and diagnostics.
- [x] Fix the diagnostic targeting helper dependency.
- [x] Preserve category decisions, update cadence, styling, restoration, and saved settings.
- [x] Verify TOC order, runtime presentation, TRP3 titles, inside-bar sizing, drift repair, restoration, diagnostics, and reachable upvalue counts using local Lua stubs.
- [ ] Complete client checks for the module split.

## Phase 2 — World context and capabilities

- [x] Add event-driven cached context and centralized capability assessment.
- [x] Pass context explicitly to its consumers and refresh visible entities after relevant changes.
- [x] Report context, capabilities, and unavailable information in diagnostics.

Context records overlapping facts, rather than assigning one exclusive label: zone/subzone/map, instance type/name, territory/sanctuary, player faction, desired and active War Mode, PvP/FFA flags, player combat, and combat lockdown. Login, world entry, zone/subzone, PvP/faction/flag, and combat events update it even when styling is off. Unchanged observations retain the snapshot and revision; presentation reads the cache. Unknown API results remain nil, separate from false. No location-name rules are hardcoded.

Capability assessment distinguishes missing, forbidden, combat-restricted, unknown, and accessible frames/regions. Refreshes, repair hooks, drift checks, cleanup, cast effects, and restoration skip blocked frames. Protected frames are conservatively skipped during lockdown and revisited on combat exit. Region presence is reported separately and does not guarantee every UI operation. Diagnostics read existing presentation without creating overlays or hooks, including context reporting without a target. Client verification remains pending.

## Phase 3 — Entity facts and revised classification

- [x] Collect entity facts separately from category selection.
- [x] Implement the accepted six first-match categories.
- [x] Update defaults, settings, documentation, and validation together without conversion code.

`EntityFacts.lua` collects readable observations using the cached context. `NameplateClassification.Classify(facts)` is independent of APIs and returns the first matching state and winning rule. `StateForUnit(unit, context)` returns state, rule, and facts. Targeting only contributes attacking evidence for a potentially dangerous entity; friendly units looking at the player are not promoted. Threat/target detection remains best effort, including controlled units.

Eligibility requires readable directional attackability for a player or player-controlled opponent. PvP flags, faction, and desired War Mode alone cannot promote it. Actual readable permissions remain authoritative for duels even if territory normally suppresses PvP. Useful requires readable NPC interaction evidence; unavailable data remains unknown and may leave the category at Useless without proving non-usefulness. Diagnostics shares these facts and reports configured versus observed presentation correctly.

Current category keys are attacking, hostile, neutral, friendly, useful, and useless. Old keys are discarded without aliases or conversion; current valid values, unrelated preferences, profiles, and restoration records survive. Replacement CVars are named by their Blizzard family instead of falsely identifying them with priority categories. Because shared controls overlap all categories, experimental replacement requires all six Active and releases its claims in mixed modes. Friendly class-color controls also respect the Active modes of possible player combat priorities. Independent critter hiding remains intact.

Local tests cover precedence, PvP/sanctuary/duels, hostile interactive NPCs, directional Neutral classification, minions, unknown/secret/missing/failed observations, saved-field validation, CVar release/resume, and diagnostic reporting. The combat-dependent bar policy and specific context/entity presentation rules remain phase 4. Client verification remains pending.

## Phase 4 — Specific presentation rules

- [ ] Select narrowly scoped context/entity presentation rules with shared fallbacks.
- [ ] Start with opposite-faction players in sanctuary versus PvP-capable areas.
- [ ] Implement the accepted combat-dependent health-bar and TRP3-title policy.
- [ ] Keep category-wide CVar policies separate from per-frame operations.

## Phase 5 — Client verification

- [ ] Test Silvermoon Shared and Silvermoon Horde separately, including boundary transitions.
- [ ] Test Stormwind, Eversong Woods, Zul'Aman, and instances.
- [ ] Test combat entry/exit, entity state changes, restriction handling, and restoration.
- [ ] Record actual observations in [live-wow-verification.md](live-wow-verification.md); local stubs do not establish Blizzard client behavior.
