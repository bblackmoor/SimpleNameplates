# Live WoW integration verification

Status: pending. These checks require a World of Warcraft client; local Lua stubs do not establish actual frame behavior, secure CVar behavior, or Midnight secret-value safety. Record the client build, addon version, date, and observed result when running them. Leave a check open until it is observed in game.

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

## Nameplate presentation and integration

- [ ] Switch Profiles while plates are visible; confirm fonts, sizes, colors, threat percentage, and visual effects refresh immediately. Verify name-only plates and Blizzard-controlled overhead names reflect the documented limits.
- [ ] Move names inside and above health bars. Inside-bar font sizing and bar-height padding are correct; switching back and disabling styling restore Blizzard's original bar height.
- [ ] Observe interruptible and non-interruptible casts and channels. The optional border pulses only when Blizzard reports interruptibility; the existing shield and cast information remain intact.
- [ ] With TRP3 installed and absent, exercise cached RP names, short/full titles, OOC marker, unavailable-field fallback, and name-length limits. Full titles disappear for visible health bars as documented.
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
- [ ] After phase 4, in combat show health bars for all Active entities where supported; out of combat show bars only for Neutral, Hostile, and Attacking. Inactive categories keep Blizzard presentation. Refresh when entering/leaving combat; suppress TRP3 long titles whenever a health bar is displayed.

## Runtime phase 4 (1.0.106)

- [ ] Verify every Active category gains a supported bar during player combat, including same/opposite-faction players, interactive NPCs, unmatched NPCs, and minions. On combat exit, only Attacking/Hostile/Neutral retain supported bars. Inactive categories retain Blizzard presentation and missing-bar entities keep colored names.
- [ ] Verify above/inside layout, 80% font size and padding, white bar names, category colors, threat text, and cast effects through repeated combat entry/exit and Blizzard name/health repair hooks. Old cached text must not undo a transition.
- [ ] Verify long titles disappear for requested or observed bars and return for name-only presentation, including friendly combat bars and missing-bar cases. Diagnose unavailable shown state explicitly.
- [ ] Disable styling during lockdown on a previously styled frame; after combat, confirm original visibility and bar/container heights return while styling stays disabled. Repeat with temporarily forbidden base plates and Inactive categories becoming accessible without a context event.
- [ ] Remove/recycle plates while restricted and verify deferred cleanup does not clear another entity's name or leave stale overlays. Confirm scoped sanctuary/PvP rule identifiers in diagnostics, with no nameplate-visibility CVar writes.
