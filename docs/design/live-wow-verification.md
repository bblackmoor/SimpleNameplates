# Live WoW integration verification

Status: pending. Details Framework phases 1–6 repository work and follow-up fixes
are complete through 1.0.163, with all 18 local smoke suites passing. These checks
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

- [ ] Compare Slug off/on with built-in and SharedMedia fonts at several UI scales. Check floating, above-bar and inside-bar names, titles, threat, native health text and cast labels; confirm smoothness, thin outlines, both black underlayers and unchanged padding.
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
- [ ] Verify above/inside layout, full selected name size, four-unit top/three-unit bottom bar padding, white inside-bar text with two black underlayers, white above-bar names, category colors, threat text, and cast effects through repeated combat entry/exit and Blizzard name/health repair hooks. Old cached text must not undo a transition.
- [ ] Verify long titles appear below health bars and disappear during active casts/channels, including friendly combat bars and missing-bar cases. Diagnose unavailable shown state explicitly.
- [ ] Disable styling during lockdown on a previously styled frame; after combat, confirm original visibility and bar/container heights return while styling stays disabled. Repeat with temporarily forbidden base plates and Inactive categories becoming accessible without a context event.
- [ ] Remove/recycle plates while restricted and verify deferred cleanup does not clear another entity's name or leave stale overlays. Confirm the uniform presentation rule in diagnostics; normal refreshes must not make new nameplate-visibility CVar claims.
