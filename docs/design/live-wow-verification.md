# Live WoW integration verification

Status: pending. These checks require a World of Warcraft client; local Lua stubs do not establish actual frame behavior, secure CVar behavior, or Midnight secret-value safety. Record the client build, addon version, date, and observed result when running them. Leave a check open until it is observed in game.

## Setup and saved data

- [ ] Fresh install with no `SimpleNameplatesDB`: Default and High Contrast appear, the active Profile is Default, and Global behavior uses factory values.
- [ ] Load an existing valid schema-2 database: colors, fonts, sizes, placement, category modes, TRP3 preferences, and managed-CVar originals retain their meaning. Verify invalid fields are discarded individually while valid fields survive regardless of the schema marker.
- [ ] On two characters, select different Profiles; reload and log out/in on each. Selections persist independently and edits to an account-wide Profile appear for both where selected.
- [ ] Create, copy, rename, and delete a Profile. Copy retains the selected appearance, renaming propagates to character assignments, deletion falls back to Default, and Default cannot be renamed/deleted.
- [ ] Edit both bundled Profiles, then Restore Bundled Profiles. Factory appearances return and High Contrast is recreated after removal without changing custom Profiles.

## Settings and Blizzard names

- [ ] About, Behavior, Appearance, and TRP3 render once, scroll correctly, and maintain the expected layout and controls; `/snp`, `/snp colors`, `/snp trp3`, `/snp about`, and `/snp debug` route correctly.
- [ ] Exercise Active and Inactive for all six priority categories on representative addon-accessible units. Confirm first-match priority and threat/effect behavior; no category Hide option is available.
- [ ] Exercise overhead replacement and the independent critter/companion control. Original managed Blizzard CVars are captured and restored when the last claim ends, when styling is disabled, after a reload, and after a combat-deferred change. Confirm no taint or secret-value errors.
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
- [ ] After phase 3, verify each Inactive category releases experimental replacement CVars and all Active resumes them; independent critter hiding stays separate. Check defaults, presets, obsolete-field discard, and diagnostics reporting Blizzard presentation for Inactive/disabled styling.
- [ ] After phases 2–4, check context changes and the same entity's presentation across boundaries, including accessible and restricted frames.
- [ ] After phase 4, in combat show health bars for all Active entities where supported; out of combat show bars only for Neutral, Hostile, and Attacking. Inactive categories keep Blizzard presentation. Refresh when entering/leaving combat; suppress TRP3 long titles whenever a health bar is displayed.
