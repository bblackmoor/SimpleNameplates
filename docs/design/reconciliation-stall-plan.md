# Reconciliation stalls: follow-up plan

## Goal and status

Reduce noticeable nameplate hitches while preserving prompt names, colors, threat,
cast highlighting, title substitution and restoration. This is a follow-up to the
[four completed code phases](performance-plan.md), numbered phases 5–8 so the
earlier work remains distinguishable.

Status: planning only. No follow-up instrumentation, scheduler tuning or runtime
fix is implemented by this documentation commit. Runtime behavior remains that
of 1.0.205; 1.0.206 adds this plan and documentation links.

## First finding: verify the installed build

The October 8 screenshot contains only Runtime update, Reconciliation, Full
styling, Text repair, Classification and NPC title lookup rows. It contains no
Periodic work, Plate discovery, Access assessment or reason counters. In the
current runtime, Periodic work is wrapped and called by every Runtime update;
the newer report also emits observed reason counters. Their absence is strong
evidence that this report came from an older installed build, assuming the
screenshot contains the complete report. The screenshot does not show a version,
so the installed version is unconfirmed.

There is also a measurement change: before 1.0.205, Reconciliation timed an
all-plate pass; from 1.0.205 it times one plate job. Consequently, the earlier
comparison of 25.990 ms to 5.295 ms does **not** establish an 80% improvement.
Lower full-styling and text-repair calls per second are descriptive observations,
but unmatched scenes and an unknown build prevent attributing them to the fixes.

Do not tune the current scheduler from this screenshot alone.

## Recorded evidence

The screenshot records 1,160.6 seconds:

| Row | Calls | Total ms | Average ms | Longest ms |
| --- | ---: | ---: | ---: | ---: |
| Runtime update | 67,671 | 25,780.681 | 0.381 | 91.800 |
| Reconciliation | 4,563 | 24,160.982 | 5.295 | 91.781 |
| Full styling | 7,950 | 20,864.082 | 2.624 | 12.714 |
| Text repair | 19,604 | 10,857.542 | 0.554 | 21.113 |
| Classification | 7,709 | 1,224.246 | 0.159 | 3.189 |
| NPC title lookup | 6,690 | 928.280 | 0.139 | 3.156 |

The matching runtime/reconciliation maxima suggest a shared stall, but aggregate
maxima do not establish that they occurred in the same callback. Inclusive rows
overlap; never add them as total addon CPU. Memory fell from 370,531.2 to
119,799.3 KiB; collection and shared attribution prevent a leak conclusion.

## Current code map

| Location | Relevant behavior |
| --- | --- |
| `Nameplates.lua: RuntimeUpdate` | Flushes urgent work, discovers plates, runs the shared periodic budget |
| `Nameplates.lua: FlushQueuedRefreshes / RefreshAll` | Coalesces events but can update all visible plates before the periodic budget |
| `Nameplates.lua: DiscoverPlates` | Snapshots the native list every 0.25 seconds; queue bookkeeping is outside the periodic budget |
| `Nameplates.lua: ReconcileNames` | Validates current assignment, repairs pending artwork/title visibility, checks drift and applies selective repair or full fallback |
| `PeriodicWork.lua: Drain` | At most four jobs per frame; one-millisecond elapsed target checked after each atomic job |
| `PresentationCapabilities.lua: InspectFrame` | Operation-local access assessment |
| `NameplateText.lua` | Cache validation, readable drift observations, selective repair, elapsed retry backoff |
| `Profiler.lua` | Optional inclusive timing rows and bounded reason counters; no measurement clocks or records while disabled |

A cooperative budget cannot interrupt a single slow UI call. A 91 ms job can
therefore exceed the one-millisecond target. Urgent all-plate refreshes and
discovery can also exceed it because they run outside that budget. These are
candidate paths, not established causes.

## Phase 5 — Confirm the build and establish a matched baseline

### Implementation work

1. Keep this plan as the record for follow-up work; retain pending native
   acceptance in the original performance plan.
2. Review a complete report from the installed current build before changing
   runtime behavior. If it still lacks new rows, resolve installation/version
   mismatch first.
3. Record version, client build, profile, enabled nameplate addons, scene,
   approximate plate count, activity and screenshot coverage with each result.

### Steps to follow in WoW

1. Exit WoW completely. Download the latest repository with **Code → Download
   ZIP**, following the [installation instructions](../../README.md#download-and-installation).
2. Replace the installed inner `SimpleNameplates` addon folder with the downloaded
   inner folder. Do not merge it with an old copy: removed Lua files can otherwise
   remain. Keep the normal SavedVariables settings.
3. Start WoW. Open the Simple Nameplates About page and confirm version 1.0.206
   for this documentation commit, or a later version if further work has landed.
4. Choose a repeatable route and approximately two-minute recording. Keep the
   character, profile, camera, other addons and activity consistent.
5. First traverse it with profiling off; note typical FPS, visible hitches and
   whether names, titles, threat and casts remain correct.
6. Repeat with `/snp perf start`, then `/snp perf stop` and
   `/snp perf report`. Capture the **entire** report by scrolling chat and taking
   consecutive screenshots, including reason counters below the timing rows.
7. Repeat three times in that scene. Include a quiet scene and a crowded scene;
   add combat if the hitches occur there. A long mixed session may be retained
   as supplemental evidence, but do not replace the matched short recordings.
8. Confirm Periodic work and, in a scene with styling enabled, Plate discovery
   appear. Record the About version alongside the report.

Completion gate: a confirmed current-build report with full rows/counters and
repeatable conditions. If stalls disappear on the correct build, proceed directly
to phase 8 rather than implementing unnecessary instrumentation or tuning.

## Phase 6 — Locate the expensive operation, if stalls remain

### Implementation work

1. Use existing Runtime update, Periodic work, Plate discovery, Access assessment,
   Name drift check, Text repair, Bar artwork and styling timings first.
2. Add separate profiler wrappers for urgent queue flushing and broad refresh
   work. Keep timings inclusive and describe their nesting.
3. Add a bounded slow-call summary to the existing chat report: count calls
   exceeding fixed 5, 16.7 and 50 ms thresholds. Threshold counts are cumulative.
   Retain a small fixed number of slow-event records, with a runtime callback
   sequence and the responsible nested stage/job group, to correlate maxima.
4. If existing stages do not explain the stall, instrument reconciliation
   assignment lookup, pending artwork/title work and cache validation more
   narrowly. Avoid timing every native getter by default.
5. Record routine backlog size, oldest eligible job age and processed jobs, plus
   urgent batch size. Separate queue age from operation duration. Use bounded
   numeric summaries; never log unit identities, secret values or unlimited
   history.
6. Keep collection off by default and session-only. Disabled profiling must
   introduce no profiling clocks, event records or counter allocations.
   Preserve return values, errors, stop/restart isolation and frozen reports.
7. Add deterministic tests in `tests/profiler-smoke.lua`,
   `tests/periodic-work-smoke.lua` and relevant runtime smoke coverage for
   thresholds, bounded retention, correlation, disabled collection and lifecycle.
   Update the profiling guide and changelog.

### Steps to follow in WoW

Install the phase 6 commit, confirm its About version, and repeat the phase 5
route with profiling off and on. Supply the full report and note whether the
hitch happened during targeting, mouseover, combat transition, plate arrival,
profile changes or ordinary movement.

Completion gate: attribute a recurring stall to a measured path, or establish
that instrumented overhead itself causes the apparent issue. A single maximum
without frequency/correlation is insufficient grounds for a broad rewrite.

## Phase 7 — Apply the smallest fix supported by the measurements

Select the relevant branch; do not implement every candidate automatically.

| Measured cause | Change to consider | Required safeguard |
| --- | --- | --- |
| Many cheap routine jobs | Adjust the shared job/time budget based on backlog and measured latency | Fair progress and bounded per-frame work |
| One slow reconciliation job | Remove repeated access/layout work or split safe stages across jobs | Fresh access and assignment validation after any yield; no stale observation/repair plan |
| Repeated readable drift | Fix the writer conflict or unnecessary invalidation; use existing reason counters | Preserve actual native changes and selective repair |
| Repeated unknown-value work | Correct retry scheduling or redundant pending writes | Unknown stays distinct from false; native cast hooks/events bypass backoff |
| Full-style fallback bursts | Fix the specific cache invalidation or replaced-region path | Full styling remains available for truly changed structure |
| Urgent all-plate batches | Narrow affected units or coalesce redundant requests; stage nonurgent broad work if necessary | Prompt target, threat, cast and content updates; reentrant requests survive |
| Discovery/bookkeeping spikes | Reduce allocations or membership churn; stage bookkeeping only if justified | Prompt addition/removal and reliable cancellation |
| Profiling-only stalls | Reduce enabled instrumentation allocations/nesting | Retain enough evidence for diagnosis and verify with profiling off |

Keep the initial four-job/one-millisecond budget until measurements justify
changing it. Reducing the budget does not fix a single slow native call. Never
retain capabilities, region observations or secret native data across yielded
work; revalidate the plate's current assignment, context and presentation state.

Implementation sequence:

1. Pull the latest head and review readiness against the phase 6 evidence.
2. Implement one coherent cause and its regression coverage.
3. Run all existing smoke suites and whitespace checks. Update relevant docs,
   changelog and the repository's commit-count version.
4. Commit and push the isolated fix. Repeat the same client recording before
   selecting another cause.
5. If presentation or recovery regresses, revert that fix and return to the
   measured cause; do not conceal it by suppressing updates.

Completion gate: matched current-build runs show fewer expensive callbacks or
shorter recurring stalls, and acceptable backlog/recovery with no presentation
regression. Treat 16.7 ms as a useful 60-FPS reference, not a guaranteed addon
budget or an automatic pass/fail boundary.

## Phase 8 — Verify live behavior and close the follow-up

### Automated verification

For any runtime implementation phase, run from the repository root:

```sh
for test in tests/*-smoke.lua; do
    texlua "$test" || exit 1
done
git diff --check
```

Exercise scheduler fairness/cancellation, callbacks enqueuing replacement work,
errors, recycled plates, disabled restoration, elapsed backoff, restricted values,
unchanged scans with no repair writes and immediate cast/title updates. UI stubs
cannot establish secure native behavior or actual rendering.

### Steps to follow in WoW

1. Repeat quiet, crowded and combat routes three times with consistent durations.
   Compare the same timing definitions and report calls per second or total
   milliseconds per session second where durations differ.
2. Compare profiling off/on. Record actual visible FPS/hitches separately from
   inclusive timing summaries.
3. Check plate arrival/removal and rapid targeting/mouseover; verify names and
   colors update without lingering stale labels.
4. Check threat appearing/disappearing, interruptible casts/channels and title
   restoration after casting.
5. Check combat entry/exit, sanctuary/restricted plates, zoning and recycled
   plates; no Lua errors or protected-action errors.
6. Change profiles/fonts/size/gradient and toggle styling off/on. Verify native
   restoration and prompt recovery. Check TRP3 content when available.
7. If backlog age rises continuously, investigate fairness/service capacity
   before accepting a smaller frame cost.
8. Record results in [live-wow-verification.md](live-wow-verification.md), with
   versions, scenes, repeat counts, remaining limitations and profiling overhead.

Completion gate: repeatable improvement in the problem scene, correct rendering
and recovery, no growing routine backlog under the tested load, and all smoke
suites passing. If current-build evidence does not reproduce the problem, record
that limited conclusion rather than declaring every possible stall fixed.

## Progress checklist

- [x] Inspect current main and document the report/build ambiguity.
- [x] Save this follow-up plan with links from the existing documentation.
- [ ] Phase 5: confirm the installed version and collect matched complete reports.
- [ ] Phase 6: add targeted diagnostics only if the current build still stalls.
- [ ] Phase 7: implement and validate the measured cause.
- [ ] Phase 8: complete client acceptance and record results.
