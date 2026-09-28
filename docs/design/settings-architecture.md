# Proposed settings and runtime architecture

Status: design proposal. Based on the RP Emote Menu refactor's tab -> section -> control organization, adapted to Simple Nameplates.

## Current inventory

The .toc loads `Core.lua`, `TRP3.lua`, `Nameplates.lua`, then `Settings.lua`. `Core.lua` is roughly 997 lines and currently combines defaults, saved-data validation, Profile lifecycle, user-facing getters/setters, managed-CVar restoration, compatibility warnings, and debug accessors. `Settings.lua` is roughly 972 lines and builds About, TRP3, Behavior, and Appearance panels in one file. `Nameplates.lua` is roughly 1061 lines and combines classification, rendering, frame repair, events, and diagnostics. `TRP3.lua` already provides a focused adapter boundary.

The settings UI already has a scroll cursor, switches, circled-i links, row helpers, and separate named constructors for many sections. Keep these working pieces. Its Appearance panel mixes Profile management, text layout, priority colors, fixed Blizzard color explanations, and cast effects. `CreateColorRow` contains color-picker, rollback, swatch, reset, and refresh behavior in one function. `CreateProfileControls` includes selection and lifecycle presentation. Many `ns` exports at the end of Core form the current integration surface.

## Proposed source ownership

| Module | Responsibility |
| --- | --- |
| `Defaults.lua` | Factory Global, Profile, Theme definitions; identifiers and validation ranges |
| `Database.lua` | Validate saved data; explicit Global/Profile/Theme accessors and lifecycle; character selection and reference repair |
| `ManagedNames.lua` | Managed overhead-name CVars, original-value ledger, combat defer, safe restoration, friendly class colors |
| `Core.lua` | Metadata, startup-facing glue, conflict warning and tiny shared helpers |
| `TRP3.lua` | Existing optional Total RP 3 adapter |
| `Nameplates.lua` | Initially existing nameplate pipeline; split later only at genuine classification/rendering/event boundaries |
| `SettingsControls.lua` | Shared scroll layout, switches, info glyph, dropdown/color control primitives |
| `SettingsAbout.lua` | About tab |
| `SettingsTRP3.lua` | Global TRP3 tab |
| `SettingsBehavior.lua` | Global addon/category/overhead-name controls |
| `SettingsProfiles.lua` | Character selection, Profile management, Theme assignment and Profile information toggles |
| `SettingsThemes.lua` | Theme management, fonts/placement, priority/effect colors, Blizzard fixed-color explanations |
| `Settings.lua` | Tab registration and shared refresh orchestration |

These are candidate boundaries, not a requirement to create one file for every row. Put each tab's construction in visual order and keep popup and lifecycle operations out of the primary layout flow. Avoid a generic settings framework. Whenever `Settings*.lua` changes a setting, call a clear subsystem apply/refresh method; keep CVar and nameplate rendering details in their owning modules. Keep .toc dependency order explicit and check for WoW's upvalue limit after splitting.

## UI organization

- About: existing help and limitations.
- Behavior: styling enabled, category handling, experimental overhead replacement, hide minions, hide critters. These remain Global.
- TRP3: existing Global options, unchanged in meaning.
- Profiles: character's active Profile, create/copy/rename/delete, restore bundled Profiles, assigned Theme, show threat, and interruptible highlight.
- Themes: Theme selection and management, text/layout, six Priority Colors in danger-to-friendly order, fixed Blizzard swatches, and cast-border color. Editing a shared Theme changes every referencing Profile.
- Standard row order: label, control, reset button if any, info glyph if any; retain established spacing and thumb switches.

For direct Theme editing, clearly label the Theme currently being edited and whether it belongs to the active Profile. Avoid an automatic Profile switch when choosing a Theme to edit. Fixed Blizzard swatches must remain visibly distinct from editable Theme colors.

## Runtime boundaries and high-risk cases

- `StateForUnit` and category priority are independent of Theme. Mode active/inactive/hide and engine-controlled overhead names retain their present semantics.
- `ApplySimpleStyle` gets category mode from Global, display toggles from the active Profile, and colors/fonts from its referenced Theme. Profile/Theme changes refresh plates once, including name-inside-bar placement, cached name repair, title suppression, threat text, and interruptible highlight.
- CVar originals must be captured before changing Blizzard values and restored when no longer managed, on disable, and during schema transition. Preserve combat deferral and the separate friendly class-color path. Never make a Theme switch alter category-mode CVars.
- Honor Midnight secret values: do not add comparisons or reads of restricted frame/unit values to generic setters, validators, or refresh callbacks.
- Preserve the existing TRP3 cache adapter and fallback to the normal WoW name.
- Avoid enlarging a settings constructor's captured outer locals; explicit context tables and small named constructors help keep Lua upvalues below its limit.

## Readability and verification

Source order should broadly match on-screen tab -> section -> control order. Separate construction from refresh and enable-state updates. Reuse the existing layout cursor, extracting helpers only where repeated. Make lifecycle and refresh entry points explicit. First establish characterization of saved-data defaults, profile CRUD, CVar restore/reapply, settings registration, and frame refresh; then use targeted Lua smoke tests plus live WoW checks for Blizzard frames, CVar behavior, and secret-value restrictions. No automated stub can prove Blizzard nameplate behavior in the client.
