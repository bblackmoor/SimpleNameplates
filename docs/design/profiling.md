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
| Full styling | Shared presentation entry used by refreshes and Blizzard name/health repair hooks |
| Classification | Entity-fact collection and priority classification together |
| NPC title lookup | Title resolution, including cache and tooltip paths when used |
| Text repair | Cached-name repair attempts, including attempts that return without repairing |
| Runtime update | The per-frame callback: context access, queued refreshes and periodic restoration, deferred cast-highlight retry and reconciliation work |
| Reconciliation | The visible-plate scan for pending title visibility and cached-name drift (including visibility and readable text), normally every 0.25 seconds while styling is enabled |

These are inclusive elapsed timings, not exclusive CPU accounting. For example, Full styling can include Classification, which can include NPC title lookup. Runtime update can include Reconciliation and Text repair. Do not add the rows together or interpret their sum as total addon CPU. The elapsed session duration measures wall time, not time spent executing addon code.

Call counts include early-return and failed attempts. High call counts alone do not prove a bottleneck: compare total time, average and longest call. Frequent low-cost updates and rare long tooltip lookups can have very different implications. The report covers selected entry points, not every addon or library function.

Profiling itself adds clock reads, protected calls and temporary return-value storage. Nested timings include some of that overhead. Compare sessions with similar duration, plate counts, settings and activity; differences between unrelated scenes cannot establish an optimization's effect.

## Read the memory figures

The profiler refreshes WoW's addon memory accounting at start and stop and reports Simple Nameplates' start/end KiB and change. Reporting while running shows only the start reading; reporting a stopped session reuses the frozen readings.

These are aggregate addon readings, not allocations by function. They can include profiler storage and shared-library attribution, and garbage collection can produce a negative change. The profiler does not force garbage collection. A growing reading from a single session is insufficient evidence of a leak.

## Implementation and verification

`Profiler.lua` loads after `Core.lua` and before the runtime consumers. Wrappers preserve return values, including nil positions, and propagate the original error object. With profiling disabled they only check the active session and call the original function; they read no clock or memory API and allocate no measurement records. Calls spanning stop/restart cannot modify stopped results or a new session.

`tests/profiler-smoke.lua` checks deterministic nested timings, lifecycle, disabled measurement work, return/error preservation, missing timer and failed memory APIs. Runtime and settings smoke suites check the actual hooks and combat command routing. Native timing, rendering and secret-value/taint checks remain on the [live WoW checklist](live-wow-verification.md).
