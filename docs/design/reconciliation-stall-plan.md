# Appearance convergence investigation

The targeted investigation and fixes are complete; temporary checkpoint diagnostics were removed in 1.0.219. This record preserves findings and measurement limits. Obsolete requests to install intermediate builds or repeat completed phase recordings have been removed.

## Findings and repairs

| Builds | Finding/result |
| --- | --- |
| 1.0.206–1.0.207 | Direct native font-object/text-height writes bypassed name updates; immediate appearance hooks, normalized font comparison, and focused counters were added |
| Through 1.0.213 | Native geometry/visibility resets caused unnecessary cache fallback; geometry and visibility became selective repair work |
| 1.0.214 | Broad global refreshes were distributed as per-plate jobs; explicit and current/previous priority units remained immediate |
| 1.0.215–1.0.216 | Guarded native callbacks and alpha resets required retained notifications and immediate/pending opacity repair; safe-field reads reduced closure allocation |
| 1.0.217 | Temporary checkpoints located color/alpha failures at cached/artwork operation completion |
| 1.0.218 | Selective/artwork repairs finish with bounded, identity/access-validated color/alpha finalization after structural callbacks |
| 1.0.219 | Temporary checkpoints, Show audits, origin counters, and session audit fields removed; repairs and ordinary profiling retained |

The 118.4-second 1.0.217 report found all 551 first color mismatches already wrong after cached repair, with 618 color and 185 alpha failures at artwork/cached checkpoints. The 94.4-second 1.0.218 report then recorded 4,686 reconciliation checks without reported appearance drift or fallback and 11,534 checkpoints without failures. Finalization caught 660 color resets; Runtime update/Urgent refresh maxima were 4.728/2.951 ms. This establishes convergence in that crowded scene only.

## Measurement limits and future diagnosis

Before 1.0.205, Reconciliation measured an all-plate pass; afterward it measured one plate job. These averages cannot be compared as an exact improvement. Broad Global refresh now measures discovery/enqueueing and immediate priority work; Global plate refresh measures one plate visit. Inclusive rows overlap, separate maxima do not prove simultaneous callbacks, and aggregate memory changes do not prove leaks.

A cooperative budget cannot interrupt one slow native operation. Immediate priority work and discovery are outside the periodic budget. Confirm the installed build and capture a complete current report if flicker or hitches recur; use matched scenes/activity/settings and profiling off/on before attributing performance changes. Additional slow-call or queue-age instrumentation is conditional on a reproduced unresolved problem.

Current code contracts are in [settings architecture](settings-architecture.md), report interpretation in [profiling](profiling.md), and pending client checks in [live verification](live-wow-verification.md). Earlier release details remain in the [changelog](../../CHANGELOG.md).
