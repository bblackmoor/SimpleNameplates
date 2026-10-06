# Nearby-entity performance: four phases

## Baseline and scope

The 2026-10-06 live report recorded 119.6 seconds: 8,454 full-styling calls
(20,134.112 ms inclusive), 440 reconciliation passes (11,435.746 ms inclusive,
25.990 ms average, 116.109 ms maximum), and 9,866 cached-text repair calls
(5,232.329 ms inclusive). Classification and NPC-title lookup were smaller
measured costs. Inclusive rows overlap and must not be summed. Profiler overhead
and differing scenes prevent exact FPS predictions or a memory-leak conclusion.

The code routes Blizzard name and health-color hooks through full styling,
repeats frame access assessments within operations, and broadly repairs small
text differences. The original black glyph copies also synchronized repeatedly
through setter hooks, including when only health-dependent alpha changed.

The agreed presentation is now thin solid black outlines on all styled text.
The gradient remains 80% black at the left, clear at 95% width, and clipped by
native remaining fill geometry. Removing glyph copies also removes their former
80% health threshold. Existing title/cast substitution, dimming, native health
progress, restricted-value handling and restoration must remain correct.

## Phase 1 — Simplify text and improve measurements

Implemented in 1.0.202; live acceptance pending.

- Remove the glyph-copy module and its native setter hooks, preview copies,
  curve API, health-dependent alpha path and health-event registrations.
- Keep OUTLINE or SLUG,OUTLINE on names, titles, health, threat and cast labels;
  preserve dimensions, colors and original native restoration data.
- Add optional access/artwork/name/layout/drift timings and bounded reason
  counters to the existing screenshot-friendly chat report.
- Preserve existing drift decisions, refresh cadence and full-styling behavior
  for later phases. Counters distinguish requests, outcomes, queue coalescing
  inputs and reconciliation repairs; they contain no unit identities.
- Update tests and documentation. Repeat a comparable crowded recording to
  establish the simplified baseline and identify recurring work triggers.

## Phase 2 — Separate styling from updates

Implemented in 1.0.203; live acceptance pending.

- Ordinary native-name hooks restore the cached name/font/color/visibility. A
  readable native source-name change updates content and classification, without
  artwork when presentation structure is unchanged.
- Ordinary health-color hooks repair category bar color/visibility. Settings,
  current token/readable GUID, original regions, cast-region identity and context
  revision validate the focused cache; invalid state safely falls back to full
  styling. Retired native name regions retain their own restoration baseline.
- Per-unit work flags merge with all-plate work. A detached batch protects requests
  queued by synchronous callbacks; inaccessible unit lookups retain their merged
  work, and removal discards work for the departed unit.
- Name events update content/classification, threat events update threat and
  classification, cast events update highlight/title visibility, and target or
  interaction events request focused all-plate work. TRP3 callbacks queue name
  content. Threat/native-label presence can request a separate name-layout update.
- Tests verify absent unrelated timing rows for ordinary hooks and cast/value
  updates, queue preservation, structural fallback, recycling and error guards.

Original phase 2 requirements:

- Introduce focused name and health-color repair paths for Blizzard hooks.
- Separate classification, name/title content, threat, cast state and layout
  updates. Coalesce pending work per current plate assignment.
- Reserve complete styling for initialization, relevant settings/context
  changes, replaced regions and invalid presentation state.
- Verify ordinary name/color hooks do not cause full restyling, including
  recycled plates, synchronous callbacks and failures.

## Phase 3 — Make reconciliation cheaper

Pending.

- Reuse an assessment only within one operation. Renew it after restoration,
  region replacement or other invalidation; retain restricted-frame safeguards.
- Repair only the properties whose readable observations show drift.
- Treat unreadable native properties as unknown, with bounded retries rather
  than repeated repairs caused solely by an unknown comparison.
- Avoid duplicate layout scans and redundant font, geometry and anchor writes.
- Confirm unchanged plates cause no repair writes and retain event-driven
  title/cast behavior. No underlayer batching work remains after phase 1.

## Phase 4 — Bound periodic work and verify in WoW

Pending.

- If the optimized scan still causes spikes, distribute routine reconciliation
  across frames with a bounded work budget and fair progress for every plate.
- Keep urgent names, threat and cast changes event-driven; do not merely lower
  scan frequency while allowing delayed or incorrect presentation.
- Run smoke suites and native checks for crowded scenes, combat transitions,
  recycled/replaced plates, restricted values, profile changes and TRP3.
- Compare similar durations, activity, plate counts and settings, with profiling
  off/on. Measure actual FPS and scan cost; do not infer FPS from overlapping
  timing totals or declare a leak from aggregate memory changes.

## Verification

Run `texlua` on each `tests/*-smoke.lua` and `git diff --check` after each phase.
The suite uses UI stubs and cannot establish native secure behavior or rendering.
The [live checklist](live-wow-verification.md) retains pending client acceptance;
the [profiling guide](profiling.md) defines counter and timing interpretation.
