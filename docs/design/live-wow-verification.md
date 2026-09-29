# Live WoW integration verification

Status: pending. These checks require a World of Warcraft client; local Lua stubs do not establish actual frame behavior, secure CVar behavior, or Midnight secret-value safety. Record the client build, addon version, date, and observed result when running them. Leave a check open until it is observed in game.

## Setup and saved data

- [ ] Fresh install with no `SimpleNameplatesDB`: Default and High Contrast appear, the active Profile is Default, and Global behavior uses factory values.
- [ ] Load an existing valid schema-2 database: colors, fonts, sizes, placement, category modes, TRP3 preferences, and managed-CVar originals retain their meaning. Verify incompatible/malformed values fall back as documented.
- [ ] On two characters, select different Profiles; reload and log out/in on each. Selections persist independently and edits to an account-wide Profile appear for both where selected.
- [ ] Create, copy, rename, and delete a Profile. Copy retains the selected appearance, renaming propagates to character assignments, deletion falls back to Default, and Default cannot be renamed/deleted.
- [ ] Edit both bundled Profiles, then Restore Bundled Profiles. Factory appearances return and High Contrast is recreated after removal without changing custom Profiles.

## Settings and Blizzard names

- [ ] About, Behavior, Appearance, and TRP3 render once, scroll correctly, and maintain the expected layout and controls; `/snp`, `/snp colors`, `/snp trp3`, `/snp about`, and `/snp debug` route correctly.
- [ ] Exercise Active, Inactive, and Hide for all six priority categories on representative addon-accessible units. Confirm first-match priority, threat/effect behavior, and Blizzard-permitted hide behavior.
- [ ] Exercise overhead replacement and independent minion/critter controls. Original managed Blizzard CVars are captured and restored when the last claim ends, when styling is disabled, after a reload, and after a combat-deferred change. Confirm no taint or secret-value errors.
- [ ] Disable and re-enable styling; addon visuals and inside-bar sizing restore and reapply correctly without losing Global modes or the selected Profile.

## Nameplate presentation and integration

- [ ] Switch Profiles while plates are visible; confirm fonts, sizes, colors, threat percentage, and visual effects refresh immediately. Verify name-only plates and Blizzard-controlled overhead names reflect the documented limits.
- [ ] Move names inside and above health bars. Inside-bar font sizing and bar-height padding are correct; switching back and disabling styling restore Blizzard's original bar height.
- [ ] Observe interruptible and non-interruptible casts and channels. The optional border pulses only when Blizzard reports interruptibility; the existing shield and cast information remain intact.
- [ ] With TRP3 installed and absent, exercise cached RP names, short/full titles, OOC marker, unavailable-field fallback, and name-length limits. Full titles disappear for visible health bars as documented.
- [ ] Target and update plates during combat and after reload/logout. Confirm frame repair, name visibility, and diagnostic output without restricted-value inspection or Lua errors.

The repository smoke scripts cover saved-data validation, settings callbacks, classification, and event/hook registration. Record client observations here; do not close these items from stub results alone.
