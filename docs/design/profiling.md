# Runtime profiling

Available since 1.0.163. Profiling is an optional diagnostic, off by default. It helps identify frequent or expensive runtime paths before changing them; enabling it does not make the addon faster.

## Run a session

1. Choose a representative scene, such as a crowded area or combat with several visible plates.
2. Enter `/snp perf start`.
3. Play normally for a short, consistent interval, for example 30 seconds.
4. Enter `/snp perf stop`, then `/snp perf report`.
5. Copy the chat output with the addon version, client build, scene, approximate plate count, combat state and other enabled nameplate addons.

These commands also work during combat. No target is required.

| Command | Behavior |
| --- | --- |
| `/snp perf start` | Starts a fresh session, replacing the previous stopped results; an already-running session is left intact |
| `/snp perf stop` | Stops collection and captures the end memory reading; repeated stops leave results intact |
| `/snp perf report` or `/snp perf` | Prints the running or last stopped session; does not stop collection |

Results remain available until a new session or UI reload. There is no saved setting, automatic startup, periodic memory scan, log file or new library dependency. A missing or unreadable precise timer prevents starting; unavailable memory readings do not prevent timing.

## Read the timings

Rows appear in descending total elapsed time, with call count, total milliseconds, average milliseconds per call and longest call. Only paths called during the session appear.

| Report row | Measured path |
| --- | --- |
| Full styling | Complete presentation setup used by initialization, settings/context refreshes, changed structure and invalid-cache fallbacks |
| Classification | Entity-fact collection and priority classification together |
| NPC title lookup | Title resolution, including cache and tooltip paths when used |
| Text repair | Selective cached-name repair attempts; direct calls may return without writing |
| Runtime update | The per-frame callback: elapsed clock, urgent queued refreshes, periodic native-list discovery and the shared routine-work budget |
| Urgent refresh | The detached urgent event batch, including focused/all-plate updates before the routine budget; idle calls also count |
| Periodic work | The scheduler slice, including bounded reconciliation/restoration/cast/unit/plate jobs; idle calls are also counted |
| Plate discovery | Native visible-list snapshot and Lua queue membership bookkeeping, normally every 0.25 seconds while enabled |
| Reconciliation | One current plate job for pending artwork/title visibility and cached-name drift; due again 0.25 seconds after service, with later service possible under load |
| Access assessment | Complete frame/region capability assessment; routine reconciliation shares one across lookup, observation and repair, with renewal after invalidation |
| Bar artwork | Guarded application of flat fills, gradient, native text outlines and decorative edge removal |
| Health text layout | Native health-label/threat anchoring; can run multiple times within styling |
| Name/title styling | Name content, fonts, dimensions, layout and full-title presentation |
| Name drift check | Cached presentation validation and readable property observations, collecting selective differences or returning no drift |
| Name hook repair | Focused native-name repair; includes content updates or full fallback if needed |
| Health-color repair | Focused category bar-color/visibility repair; includes full fallback if needed |
| Data update | Coalesced classification, name/title, threat, cast and layout work for one current plate |
| Name layout update | Existing name/title geometry updated for changed native-label/threat presence, without content/font work |

These are inclusive elapsed timings, not exclusive CPU accounting. For example, Full styling can include Classification, which can include NPC title lookup. Runtime update can include Reconciliation and Text repair. Do not add the rows together or interpret their sum as total addon CPU. The elapsed session duration measures wall time, not time spent executing addon code.

Call counts include early-return and failed attempts. High call counts alone do not prove a bottleneck: compare total time, average and longest call. Frequent low-cost updates and rare long tooltip lookups can have very different implications. The report covers selected entry points, not every addon or library function.

Profiling itself adds clock reads, protected calls and temporary return-value storage. Nested timings include some of that overhead. Compare sessions with similar duration, plate counts, settings and activity; differences between unrelated scenes cannot establish an optimization's effect.

## Read the reason counters

After the timing rows, the same chat report prints one short row for each observed reason. Counters are session-only, reset on a fresh start, freeze on stop and create no records or clock reads when profiling is disabled. Labels contain no unit names, GUIDs or secret native values. Group names are sorted; reasons within each group are sorted by descending count, then alphabetically.

| Group | Meaning |
| --- | --- |
| Styling requests | Every full-styling entry, including all/unit refreshes, new/late/pending plates, reconciliation fallbacks and invalid-cache/structure fallbacks from focused paths |
| Styling outcomes | Styled, text suppressed, inaccessible, guarded, deferred/native, or failed; one outcome per request that reaches the guarded styling entry |
| Queued unit events | Event requests before per-unit coalescing |
| Queued global refresh | Requests affecting all visible plates before coalescing: context/settings/CVar/restoration can require full styling, while target/mouseover/TRP3 callbacks request focused work |
| Focused requests | Name hook, health-color hook or data-update entries, including guarded/inaccessible attempts |
| Focused outcomes | Updated, guarded, inaccessible, native/restored, restoration pending, failed, or invalid-cache/presentation-change fallback |
| Name drift | First observed readable mismatch or structural invalidation for a plate in each pass; simultaneous mismatches repair together but are not enumerated |
| Name size drift | From 1.0.209: observed -> requested dimensions and anchor count for every readable bar/container size mismatch; at most eight distinct samples plus an overflow row per session |
| Bar anchor preparation | From 1.0.210: success or skip reason for sizing preparation. `released opposing anchors` distinguishes successful preparation from unreadable/inaccessible or unsupported layouts; `already unconstrained` means fewer than two anchors. Counts are preparation calls, not unique plates. |
| Reconciliation repairs | Successful cached repair versus a full-style fallback request; a fallback request does not establish that full styling succeeded |
| Font drift components | Readable face, size and/or flag differences; multiple components can count for one drift repair |
| Focused cache invalidation | Specific reason for a focused path falling back, including initialization, context/settings, region replacement and identity |
| Name appearance writes | External native name setters repaired immediately from the cache; addon/restoration writes do not count |
| Periodic jobs | Attempted jobs by group: reconciliation, restoration frame/plate, cast retry and unit/plate retry; includes guarded/blocked/no-write jobs |
| Periodic limits | Slices stopped by job count or time target, plus discarded stale plate assignments; count/time reasons can overlap |

Reason counters explain call volume, not elapsed time or unique plate counts. Queued requests can merge, hook requests can return under a guard, and checks can return unknown or early. A drift label identifies a readable mismatch or structural cache invalidation. Unknown property values do not count as drift and do not trigger repair writes; they retry with elapsed-time backoff from 0.25 seconds to four seconds. Independent readable properties continue to be checked. Native label-chain changes use selective layout repair, while replaced regions or invalid presentation require full styling. Unchanged reconciliation plates perform no repair writes; plates become eligible again after 0.25 seconds, with actual service subject to the shared budget.

From 1.0.205, Reconciliation counts individual plate jobs rather than complete
visible-list passes. Do not compare its call counts or per-call averages directly
with older builds. Compare matching sessions' total elapsed rows and FPS,
including Runtime update, Periodic work and Plate discovery, without adding
inclusive totals. A count/time limit indicates deferred routine work, not lost
updates or proof of a bottleneck. The initial four-job/one-millisecond budget is
cooperative: it cannot preempt one slow operation, and discovery/urgent events
are measured separately. Retry deadlines establish eligibility, not a hard
wall-time recovery guarantee under heavy queues or low FPS.

The additional wrappers increase profiling overhead. Compare each build in matching scenes, with profiling both off and on. Do not treat timing changes across different instrumentation versions as an exact performance gain.

## Read the memory figures

The profiler refreshes WoW's addon memory accounting at start and stop and reports Simple Nameplates' start/end KiB and change. Reporting while running shows only the start reading; reporting a stopped session reuses the frozen readings.

These are aggregate addon readings, not allocations by function. They can include profiler storage and shared-library attribution, and garbage collection can produce a negative change. The profiler does not force garbage collection. A growing reading from a single session is insufficient evidence of a leak.

## Implementation and verification

`Profiler.lua` loads after `Core.lua` and before the runtime consumers. Wrappers preserve return values, including nil positions, and propagate the original error object. With profiling disabled they only check the active session and call the original function; they read no clock or memory API and allocate no measurement records. Reason counters only check whether a session is active while disabled. Calls spanning stop/restart cannot modify stopped results or a new session.

`tests/profiler-smoke.lua` checks deterministic nested timings, lifecycle, disabled measurement work, return/error preservation, missing timer and failed memory APIs, counter reset/freeze and the disabled counter path. Runtime and settings smoke suites check the actual hooks and combat command routing. Native timing, rendering and secret-value/taint checks remain on the [live WoW checklist](live-wow-verification.md).


## Follow-up for long stalls

Use the [reconciliation stall plan](reconciliation-stall-plan.md) to confirm the
installed version, capture the entire report with consecutive screenshots and
run matched profiling-off/on recordings before tuning the scheduler. A current
runtime report includes Periodic work whenever Runtime update runs; missing new
rows and counters warrant checking installation and screenshot coverage first.

From 1.0.207, name appearance setter hooks repair font/color updates that bypass
CompactUnitFrame_UpdateName before rendering. They use fresh access and current
assignment/identity checks, avoid full styling and skip addon writes/restoration.
Font comparison ignores filename slash/case and flag ordering/duplicates, while
retaining real differences. Component counters report face, size and flags
separately. Urgent refresh is inclusive within Runtime update and outside the
routine scheduler target. Cache invalidation reasons distinguish legitimate
initialization from recurring failures; their counts do not prove every fallback
is unnecessary. The next native report must verify flashing and remaining costs.

From 1.0.208, the focused outcome `not a nameplate` identifies global native
hooks for raid/party or cleared-unit frames, which no longer request full
styling. Native nameplate initialization remains a legitimate cache fallback.
Bar dimension repairs now release opposing native anchors while preserving their
restoration baseline. The next recording should check whether repeated width and
height drift stops and whether background names stay grey during native bar
visibility changes. A current cached color is repaired independently of those
mutable layout properties.


In 1.0.211, `Bar anchor preparation: released native restricted anchors`
identifies sizing using the known Retail hierarchy without positional getters.
`restricted layout unsupported` leaves an unknown restricted hierarchy untouched.
A successful release should be followed by stable dimensions; repeated releases
can indicate Blizzard is resetting anchors. See the live verification checklist.


Version 1.0.212 adds inclusive `Geometry hook repair` and `Global refresh`
timings. `Initialization: reused initial plate` / `reused late plate` identify
focused refreshes replacing duplicate initialization. `Global refresh plates`
counts full/focused plate visits, and `Urgent batches` counts global full/focused
batches and remaining unit jobs. These counts do not identify the duration of
an individual batch. Compare matched runs; do not add nested timings or assume
that separately reported maxima occurred together.


As of 1.0.213, `Name drift: bar visibility` and `container visibility` can
request a cached repair instead of a full-style fallback. Native bar OnHide
also uses `Geometry hook repair` for current visibility and dimensions.
Compare Reconciliation repairs and Styling requests to distinguish selective
visibility recovery from actual cache invalidation.
