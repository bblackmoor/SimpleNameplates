# Live WoW integration verification

Status: pending. Repository work includes all four performance phases through
1.0.205, with all 21 local smoke suites passing. These checks
require a World of Warcraft client; local Lua stubs do not establish actual frame
behavior, secure CVar behavior, or Midnight secret-value safety. Record the client
build, addon version, date, and observed result when running them. Leave a check
open until it is observed in game.

## Details Framework foundation (1.0.151)

- [ ] With Details, Plater and standalone Details Framework disabled, reload and log in; confirm no library startup errors and all existing settings pages behave as before.
- [ ] Repeat with an external DF embedder enabled; record its DF minor version and confirm startup/settings work without library conflicts.
- [ ] Enter/leave combat and reload with the new bundle; record any taint/secret-value errors. Phase 2 does not convert visible controls, so adapter rendering remains a later page-conversion check.

## Details Framework Colors conversion (1.0.152)

- [ ] Check Colors alignment, wrapped descriptions and scrolling; verify swatch borders/insets, switch thumbs, status text, reset buttons, and the effect dropdown at different UI scales.
- [ ] Apply and cancel RGB edits for priority/cast colors; use each individual reset and Reset all colors in Default, High Contrast and a custom profile. Verify the documented profile/global reset scope and no opacity control.
- [ ] Switch profiles and reopen Colors; check refreshed colors/effects without changing global activation modes. Exercise all five effects, including None, and compare actual cast highlighting.
- [ ] Repeat startup/settings and combat checks without Details/Plater and with an external DF embedder; record client build and library minor, and leave unobserved rendering/taint checks pending.

## Details Framework Appearance conversion (1.0.154)

- [ ] Check Appearance alignment, scrolling, endpoint captions and pt/% labels at different UI scales. Exercise name size 8–36/step 1 and bar width 80–150%/step 5.
- [ ] Type values into both sliders; test Enter/Escape, focus loss, page hide, profile switching and Reset settings during previews. Verify rollback belongs to the original profile and a later Escape cannot undo reset values.
- [ ] Open both font menus with a large SharedMedia pack; test scrolling/selection, absent saved fonts, late registrations and global font overrides. Labels refresh without resetting unrelated controls or saved font choices.
- [ ] Verify sanctuary matching, name placement, threat and critter toggles; reset Appearance and confirm its documented profile/global scope. Repeat with Details/Plater absent and an external DF embedder present, recording any combat/taint errors.

## Details Framework Profiles/TRP3/About conversion (1.0.155)

- [ ] Check Profiles selector/switch/status alignment, management-button spacing and 64-character names at different UI scales; verify scrolling with many profiles and updated menus after create/copy/rename/delete/restore on every visual page.
- [ ] Exercise native dialogs with accept/cancel/Enter/Escape; check Default protection, cross-character assignments, independent copies and bundled restore scope. Verify Appearance previews cancel before switching profiles.
- [ ] Disable/re-enable styling; check setup consent/suspension and native presentation restoration. Test with Details/Plater absent and an external DF embedder present.
- [ ] Test TRP3 detected/absent, master and dependent switches, saved choices, disabled/dimmed labels and actual name/title fallback/refreshes.
- [ ] Verify About's source link is borderless, changes color on hover and opens a usable Ctrl+C dialog. The three color examples remain undimmed and never open a picker; their info links and tooltips work.
- [ ] Record client build, DF minor, addon version and combat/taint observations. Leave unobserved checks pending.

## Picker and profile-dialog review (1.0.157)

- [ ] Preview a color, then reset that row or the entire page, switch profiles, hide Colors, or open another swatch. Verify rollback stays with the original profile and later Cancel cannot undo a reset or affect the next edit. Accept with Okay and verify the accepted color remains after subsequent page/profile actions.
- [ ] Open another addon's picker while a Simple Nameplates edit is active; verify this addon does not close or edit the other picker's session.
- [ ] Open Copy, Rename or Delete, change the selected profile before accepting, then accept. Verify no profile changes and the message asks to reopen the dialog. Confirm normal unchanged-selection operations still work.

## Styling consent display (1.0.159)

- [ ] Keep Profiles visible while enabling styling with incompatible Blizzard visibility settings. Confirm Inactive while consent is pending, Active immediately after successful Apply and enable, and Inactive after refusal or rejected writes, without reopening the page.
- [ ] Approve during combat, then leave combat; confirm the switch and status update after deferred completion while saved intent and captured originals retain their documented behavior.

## Setup and saved data

- [ ] Fresh install with no `SimpleNameplatesDB`: Default and High Contrast appear, the active Profile is Default, and Global behavior uses factory values.
- [ ] Load an existing valid schema-2 database: colors, fonts, sizes, placement, category modes, TRP3 preferences, and managed-CVar originals retain their meaning. Verify invalid fields are discarded individually while valid fields survive regardless of the schema marker.
- [ ] On two characters, select different Profiles; reload and log out/in on each. Selections persist independently and edits to an account-wide Profile appear for both where selected.
- [ ] Create, copy, rename, and delete a Profile. Copy retains the selected appearance, renaming propagates to character assignments, deletion falls back to Default, and Default cannot be renamed/deleted.
- [ ] Edit both bundled Profiles, then Restore Bundled Profiles. Factory appearances return and High Contrast is recreated after removal without changing custom Profiles.

## Settings and Blizzard names

- [ ] About, Profiles, Appearance, Colors, and TRP3 render once, scroll correctly, and maintain the expected layout and controls; `/snp`, `/snp profiles`, `/snp appearance`, `/snp colors`, `/snp trp3`, `/snp about`, and `/snp debug` route correctly.
- [ ] Exercise Active and Inactive for all six priority categories on representative addon-accessible units. Confirm first-match priority and threat/effect behavior; no category Hide option is available.
- [ ] Confirm experimental replacement is absent. Load valid stored originals from previous replacement use and verify player/NPC/minion names and nameplate-visibility CVars restore, including with styling disabled or restoration deferred by combat. Failed writes retain originals until successful. Verify critter/companion hiding still captures/restores its own CVar independently; no taint or secret-value errors.
- [ ] Disable and re-enable styling; addon visuals and inside-bar sizing restore and reapply correctly without losing Global modes or the selected Profile.

## Slug font rendering (1.0.161)

- [ ] Compare Slug off/on with built-in and SharedMedia fonts at several UI scales. Check floating, above-bar and inside-bar names, titles, threat, native health text and cast labels; confirm smoothness, thin solid outlines, no black glyph copies and unchanged padding.
- [ ] Switch/copy profiles, reload, reset Appearance and disable styling. Verify the toggle follows profiles, old caches do not undo the chosen rendering, and native font flags restore without taint or secret-value errors.

## Uniform presentation and cast/title transitions (1.0.162)

- [ ] Verify available health bars in every Active priority category, both combat states and sanctuary/non-sanctuary areas. Keep Inactive categories native, widget-only actor text suppressed, and missing-bar names colored. Check bar widths, inside/above placement, Slug and threat text.
- [ ] With TRP3 enabled/absent, verify long titles and NPC service subtitles below health bars; missing-bar titles stay below the name. Observe cast and channel start/end/interruption: the native cast bar replaces the title and the title returns afterward. Verify no idle cast bar is forced visible.
- [ ] Repeat with plate/bar reuse, temporary forbidden/restricted access, unknown cast visibility, title toggles and disabling styling. Confirm no stale title revival, duplicate cast bars, lost shields, or taint/secret-value errors.

## Opt-in profiling (1.0.163)

- [ ] After login/reload, confirm profiling is off and `/snp perf report` reports no session. Start a short session in a representative crowded scene, stop and report; record client build, addon version, approximate plate count, combat state and other enabled nameplate addons.
- [ ] Check call counts and total/average/longest timings for paths exercised in that scene; rows not called may be absent. Verify the report labels inclusive overlap and measurement overhead. Do not sum rows as total CPU or treat session elapsed time as CPU usage.
- [ ] Report while running without stopping, try a duplicate start, then stop and repeat reports. Confirm running reports use only start memory, duplicate starts preserve the session and stopped results remain fixed. Starting after stop replaces old results; reload clears them.
- [ ] Repeat start/stop/report during combat, with no target and with styling disabled. Observe names, casts, titles and restoration for behavior changes, errors or taint; no settings page should open from performance commands.
- [ ] Compare similar scenes with profiling off/on and repeat across external library embedders. Treat start/end memory as aggregate accounting affected by shared libraries, profiler storage and garbage collection; negative changes are valid. Record unavailable timer/memory messages if observed, without assuming stub coverage proves native safety.

## Nameplate presentation and integration

- [ ] After 1.0.160, repeat cast-effect checks through plate/bar/icon reuse and temporary access loss. Confirm old icons do not restart or stop the current effect, and floating, above-bar and inside-bar name placement survives cached repair.
- [ ] Switch Profiles while plates are visible; confirm fonts, sizes, colors, threat percentage, and visual effects refresh immediately. Verify name-only plates and Blizzard-controlled overhead names reflect the documented limits.
- [ ] Move names inside and above health bars. Inside-bar font sizing and bar-height padding are correct; switching back and disabling styling restore Blizzard's original bar height.
- [ ] Observe interruptible and non-interruptible casts and channels. Test None, Moving dashes, Autocast Shine, Action Button Glow, and Proc Glow; effects appear only when Blizzard reports interruptibility. The existing shield and cast information remain intact.
- [ ] With TRP3 installed and absent, exercise cached RP names, short/full titles, OOC marker, unavailable-field fallback, and name-length limits. Full titles appear below health bars and disappear during active casts/channels.
- [ ] Target and update plates during combat and after reload/logout. Confirm frame repair, name visibility, and diagnostic output without restricted-value inspection or Lua errors.

The repository smoke scripts cover saved-data validation, settings callbacks, classification, and event/hook registration. Record client observations here; do not close these items from stub results alone.

## World-context/runtime refactor: pending client matrix

Test Silvermoon Shared and Silvermoon Horde separately, including transitions between them; also test Stormwind, Eversong Woods, Zul'Aman, and dungeon/raid instances. Record faction, War Mode/PvP state, client build, and the observed presentation. These are test locations, not hardcoded context categories.

- [ ] After phase 1, confirm the existing category behavior, fonts, TRP3 titles, cast highlight, inside-bar placement, restoration, and `/snp debug` still work after the module split.
- [ ] After phase 2, compare `/snp debug` context across Silvermoon Shared/Horde boundaries and the other test locations, including zone/subzone/map, territory/sanctuary, instance, faction, desired versus active War Mode, PvP/FFA, player combat, and lockdown. Verify context updates with styling disabled and appears without a target.
- [ ] After phase 2, inspect missing, accessible, and forbidden/restricted plates during combat and after combat exit. Verify refresh, hooks, drift repair, cleanup, restoration, and cast effects skip blocked frames without errors and retry when access returns. Repeated diagnostics must not create overlays or hooks; existing cast effects remain unchanged.
- [ ] After phase 3, verify all six priorities, including a hostile interactive NPC, an NPC that can attack you versus one attackable only by you, pets/guardians, and useful versus unmatched NPCs. Confirm interaction evidence at different distances and when the soft-interaction target changes; record unavailable/secret results explicitly.
- [ ] After phase 3, compare eligible PvP, sanctuary, non-PvP, and same-faction duel cases. PvP flags alone must not promote a player; faction identity remains in diagnostics when a combat priority wins. Confirm targeting a friendly unit does not make it Attacking.
- [ ] Verify category/profile changes do not apply replacement settings. Check defaults, presets, obsolete-field discard, and diagnostics reporting Blizzard presentation for Inactive/disabled styling. Confirm the separate critter control remains functional after original values from removed replacement use are restored.
- [ ] After phases 2–4, check context changes and the same entity's presentation across boundaries, including accessible and restricted frames.
- [ ] After phase 4, in combat show health bars for all Active entities where supported; out of combat also show available bars for every Active category. Inactive categories keep Blizzard presentation. Refresh when entering/leaving combat; place long titles below health bars, hiding them during casts/channels.

## Runtime phase 4 follow-up (current uniform policy, 1.0.162)

- [ ] Verify every Active category gains a supported bar during player combat, including same/opposite-faction players, interactive NPCs, unmatched NPCs, and minions. On combat exit, every Active category retains its supported health bar. Inactive categories retain Blizzard presentation and missing-bar entities keep colored names.
- [ ] Verify above/inside layout, full selected name size, four-unit top/three-unit bottom bar padding, white inside-bar text with thin solid black outlines, white above-bar names, category colors, threat text, and cast effects through repeated combat entry/exit and Blizzard name/health repair hooks. Old cached text must not undo a transition.
- [ ] Verify long titles appear below health bars and disappear during active casts/channels, including friendly combat bars and missing-bar cases. Diagnose unavailable shown state explicitly.
- [ ] Disable styling during lockdown on a previously styled frame; after combat, confirm original visibility and bar/container heights return while styling stays disabled. Repeat with temporarily forbidden base plates and Inactive categories becoming accessible without a context event.
- [ ] Remove/recycle plates while restricted and verify deferred cleanup does not clear another entity's name or leave stale overlays. Confirm the uniform presentation rule in diagnostics; normal refreshes must not make new nameplate-visibility CVar claims.


## Gradient edge verification (1.0.185)

- [ ] With gradients on, verify full-health bars and the Colors preview have a dark left edge, a smooth fade to the original color at the right, and no bright left strip or faint rim. Repeat at different UI scales and bar widths.
- [ ] Damage and heal through 80%: the fixed gradient clips at the remaining health edge; threat text retains the same thin solid outline at every health level. Verify no tint extends into depleted health.
- [ ] Disable gradients and styling in turn; confirm normal flat fills and Blizzard restoration.


## Performance phase 1 acceptance

- [ ] Compare gradient off/on and Slug off/on: names, NPC/TRP3 titles, threat, native health labels and cast labels retain thin solid outlines without extra glyph copies. Confirm the settings preview matches and disabling styling restores native text.
- [ ] Repeat the crowded baseline with similar duration, plate count, settings and activity. Capture all `/snp perf report` timing and reason rows, approximate FPS, addon version and combat state; also compare profiling off/on.
- [ ] Verify the report identifies both Blizzard repair hooks, queued events, name-drift reasons and cached/fallback repairs when exercised. Check fresh sessions clear counters and stopped reports remain frozen.

See [the four-phase performance plan](performance-plan.md). Phase 1 is implemented; these native checks remain open.

## Performance phase 2 acceptance

- [ ] In similar crowded scenes, compare ordinary name/color hook timings and full-styling calls before/after phase 2, including profiling off/on. Capture all report rows; do not sum inclusive timings.
- [ ] Change target/mouseover, attack a unit, change threat and start/stop casts/channels. Verify immediate category color, threat updates and name space, cast pulse, and title substitution, with unchanged outlines/gradient.
- [ ] Confirm TRP3 callbacks update names/titles on the next runtime batch. Test category Health Bar switches and profile/font changes, including frames or regions replaced by Blizzard.
- [ ] Verify recycling and disabling styling restore the correct native regions, including native-name alpha/font, and blocked updates recover when access returns.

Phase 2 is implemented; native performance, rendering and secure acceptance remain pending.

## Performance phase 3 acceptance

- [ ] Repeat comparable crowded recordings with profiling off/on. Capture all timing/reason rows, FPS, addon version, approximate plate count and combat state. Compare Reconciliation, Access assessment, Text repair and full-styling fallback calls without summing inclusive timings.
- [ ] Verify stable names stay correct, including inside/above placement, dimming, thin outlines and title width. Change native health-label visibility and confirm name space updates without unrelated text/font changes.
- [ ] Test inaccessible/secret properties and readable recovery. Unknown observations must not cause repair storms; phase 4 uses elapsed retry eligibility of up to four seconds, followed by fair budgeted service. Native cast hooks/events must still immediately substitute title/cast visibility.
- [ ] Test replaced/recycled plates, context/profile/font changes, widgets-only transitions, TRP3 updates and disable/enable restoration. Record secure/taint errors and confirm current regions retain the correct native baseline.

Phase 3 is implemented; native performance, rendering and secure acceptance remain pending. Phase 4 retains work budgeting and final client validation.

## Performance phase 4 acceptance (1.0.205)

- [ ] In a similar crowded scene, record approximately 120 seconds with `/snp perf start`, then `/snp perf stop` and `/snp perf report`. Screenshot all rows and record approximate plate count, FPS/range, combat state, addon version, TRP3/gradient/Slug settings and activity. Repeat with profiling off and compare with earlier builds without summing inclusive rows.
- [ ] Confirm Periodic work, Plate discovery, per-plate Reconciliation and job/limit counters are readable. Reconciliation calls now mean individual plates, so pre-phase-4 per-call averages/counts are not comparable. Use runtime/total costs and observed frame pacing to tune the initial four-job/one-millisecond target.
- [ ] With many plates, move targets/mouseover, rename/update TRP3, gain/lose threat, and start/stop/interruption casts/channels. Confirm urgent changes and title/cast substitution stay immediate while routine work is distributed.
- [ ] Move away/back, remove/recycle plates, replace bars/names and switch profiles/fonts/context/combat state. All current plates must progress fairly; departed assignments must not receive stale text/layout. Check unknown/secret recovery, disable/re-enable and deferred restoration.
- [ ] Record errors/taint and compare profiling off/on. The time target is cooperative and cannot preempt one expensive UI operation. Heavy queues or low FPS can extend intervals and service after retry deadlines; record visible lag before choosing a different budget.

All four performance code phases are implemented. Live FPS, rendering, secure acceptance and budget tuning remain open; no native result is inferred from local stubs.

## 1.0.207 background-name flashing follow-up

- [ ] With background-name dimming on, observe Silvermoon Resident, Enchanted
  Broom and other ambient NPCs while stationary; names and subtitles stay grey.
- [ ] Turn dimming off and verify white names; toggle styling off and verify
  native colors/fonts restore. Target/mouseover, move and enter/exit combat.
- [ ] Confirm configured face/size, thin outline and optional SLUG rendering
  survive native frame-option updates and plate recycling without Lua/taint errors.
- [ ] Repeat the prior one-minute scene with a complete perf report. Inspect
  Font drift components, Name appearance writes, Focused cache invalidation and
  Urgent refresh. Continuous equivalent-font repairs should stop; real writes
  may still occur and be repaired immediately. Record actual FPS with profiling
  off/on and any remaining 16.7+ ms runtime callbacks.

## 1.0.208 sizing and color follow-up

- [ ] In the same Silvermoon scene, observe background NPC names while stationary,
  targeting, hovering and moving; no grey/white flashing.
- [ ] Set health-bar width above/below 100%; confirm bars resize around their
  native center and inside names retain sufficient vertical space. Reset width
  and use above-bar names; native anchors restore. Toggle styling off/on.
- [ ] Capture a full one-minute report. Bar-width/height drift should not recur
  on every job; native resets may require real one-time repairs. Inspect
  not-initialized fallbacks separately from the not-a-nameplate outcome.
- [ ] Check combat/restricted/recycled bars and restoration for Lua/taint errors.

## 1.0.209 color-channel follow-up

Live result: user confirmed that blinking stopped in the Silvermoon scene on
October 8. Broader color/restoration checks below remain separate acceptance work.

- [ ] Verify the installed version is 1.0.209 and reload. With dimming enabled,
  observe Silvermoon Resident and Enchanted Broom stationary, then target/hover
  and move. Names should remain grey. Repeat with profiling off.
- [ ] Toggle dimming off/on and styling off/on; confirm white/grey and native
  restoration. Check useful NPCs and hostile units retain their configured colors.
- [ ] If blinking persists, record a short video and a complete one-minute perf
  report, including Name size drift samples, Name appearance writes and Name drift.
  The size loop remains unresolved; these samples separate readable size deltas
  from anchor counts without changing repair behavior.
- [ ] Check combat, restricted and recycled plates for Lua/taint errors.

## 1.0.210 size-loop diagnosis

- [ ] In the same scene and with the same appearance settings, capture about one
  minute of profiling. Include Bar anchor preparation and Name size drift rows.
- [ ] Determine whether repeated two-anchor drift follows successful preparation
  (`released opposing anchors`) or a specific skip reason. Do not change width,
  UI scale or addon settings during this comparison.


## Restricted anchor sizing follow-up (1.0.211)

The 84.4-second 1.0.210 report recorded 10,436 `point getter failed`
preparations and cached repairs on all 3,806 reconciliation jobs. Widths
remained near 258 instead of 309 with two anchors. Urgent refresh reached
25.932 ms; that separate timing remains unresolved.

1. Install 1.0.211 and reload. Retain the 120% health-bar width and inside-name settings.
2. Verify bar width and name height, NPC grey colors, cast/title substitution and threat text.
3. Record a similar one-minute run with `/snp perf start`, `/snp perf stop`, then `/snp perf report`.
4. Include Bar anchor preparation, Name drift, Name size drift and Urgent refresh rows.
   Expect `released native restricted anchors` at setup or a native reset, followed by
   stable geometry rather than a cached repair on every check. Repeated release still
   requires investigation of native resets.
5. Reset width to 100% and move the name above the bar, then disable styling. Verify native
   anchoring returns. Repeat with Blizzard classic and modern bar styles and a different UI scale.

The patch derives the known native bar/container anchors from Blizzard
`NamePlateUnitFrameMixin:UpdateAnchors` inputs and writes them through PixelUtil.
It avoids GetPoint when IsAnchoringRestricted reports true and uses the same
validated fallback if the getter throws. Unsupported hierarchies remain untouched.
Smoke coverage models the failed getter, restoration and convergence; it cannot
establish native secure behavior or prove the runtime spike is fixed.
