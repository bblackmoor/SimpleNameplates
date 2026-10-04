# Details Framework settings conversion

Phase 1 completed on 2026-10-04 against Simple Nameplates 1.0.149,
commit `80f8dad348c0d87497a9db6b3dd6b7437ab57c87`. This document records
current source behavior and the implementation sequence for ChatGPT to follow.
Phase 1 adds documentation only; the accompanying release is 1.0.150.

This is the authoritative settings baseline for this conversion. Earlier
settings/runtime design documents describe previous iterations and must not
be used to recreate removed controls or change current ownership.

## Scope and execution

Convert settings widgets to Details Framework and refactor within each
converted page. Preserve saved settings, UI behavior, and the established
layout. Keep `Database.lua`, schema 2, the existing event lifecycle, and the
current Global/Profile split. Do not adopt AceDB, the framework's addon/profile
scaffold, replacement nameplates, or framework unit/cast bars.

For every phase: pull, inspect applicable repository instructions, edit within
scope, run appropriate tests and `git diff --check`, update version/changelog,
and commit/push through the configured GitHub plugin. Complete and report the
requested phase; do not silently advance to the next one. No AGENTS.md was
found in the workspace during this baseline inspection.

## Source inventory

| Module | Current responsibility | Conversion treatment |
| --- | --- | --- |
| `SettingsControls.lua` | Scrollable canvas, measured description reflow, setting rows, thumb switches, info links, action buttons, refresh helper | Retain layout initially; introduce a separate widget adapter before deleting helpers |
| `SettingsColors.lua` | Six color rows/global switches, RGB picker apply/cancel, per-color resets, effect selector, whole-page reset | First page to convert |
| `SettingsAppearance.lua` | Dynamic font menus, sliders, placement, sanctuary/threat switches, scoped reset | Convert after Colors; retain targeted font refreshes |
| `SettingsBehavior.lua` | Global styling switch on Profiles and critter visibility on Appearance | Shared callbacks must retain setup consent, suspension, and restoration |
| `SettingsProfiles.lua` | Shared selectors, CRUD buttons, native dialogs, bundled-profile restore | Preserve character assignments and protected Default profile |
| `SettingsTRP3.lua` | Global integration switch, availability message, dependent name/title controls | Preserve enable/disable and fallback behavior |
| `SettingsAbout.lua` | Metadata, commands, copy-source dialog, limitations, three read-only swatches/info links | Keep read-only swatches distinct from editable pickers |
| `Settings.lua` | One-time registration and slash routing | Retain Blizzard Settings integration and registration order |
| `FontMedia.lua` | Built-in/shared font IDs, paths, labels, dynamic choices and media callbacks | Keep as the font policy adapter; do not duplicate it in DF code |
| `Defaults.lua` / `Database.lua` | Factory values, validation, ownership, profiles, reset semantics | No database replacement or schema change |

Page order is About, Profiles, Appearance, Colors, TRP3. `/snp` and
`/snp appearance` open Appearance; `/snp profiles`, `/snp colors`, `/snp trp3`,
`/snp about`, and diagnostic routes remain. There is no Behavior page/route.
Settings cannot open through these commands during combat.

## Behavior to preserve

| Setting/group | Ownership and factory value | Required behavior |
| --- | --- | --- |
| Styling Active switch | Global, true | Located beside Selected profile on Profiles; reflects effective suspension while setup consent is pending; disabling restores native presentation |
| Selected profile | Per-character assignment to account-wide profiles; Default initially | Profile changes refresh current page and plates; hidden pages reread on show |
| Six category modes | Global, all Active | Active/Inactive only, no Hide option; Inactive preserves Blizzard presentation |
| Priority colors | Profile | First-match order: attacking, hostile, neutral, friendly, useful, useless |
| Cast color/style | Profile; cyan and None | RGB-only color; None, Moving dashes, Autocast Shine, Action Button Glow, Proc Glow; no Pulse or separate cast switch |
| Name font | Profile, `FRIZQT` | Six existing built-in IDs remain valid; shared `LSM:` selections survive missing providers and reloads |
| Threat font | Profile, `ARIALN` | Independent font choice; same dynamic shared registry and missing-font fallback |
| Sanctuary font matching | Profile, true | Changes name/title face only; selected name font applies when disabled |
| Name size | Profile, 21 | 8–36 points in steps of 1; also controls threat size; titles use 80% |
| Health bar width | Profile, 100% | 80–150% in steps of 5; preserve existing rounding/clamping |
| Name placement | Profile, Above bar | Above/Inside only; keep existing bar-height, text-shadow, and padding behavior |
| Threat display | Profile, true | Preserve available/secret-safe percentage rendering |
| Hide critter/companion names | Global, false | Appearance, noncombat units only; preserve captured originals/restoration |
| TRP3 integration | Global, false | Dependent switches disabled/dimmed when off; detected/absent status remains |
| TRP3 name, short title, full title, OOC preferences | Global, all true | Preserve refresh/cache handling, WoW-name fallback and full-title suppression while bars show |

Default priority RGB values are red `#FF0000`, orange `#FF6600`, yellow
`#FFCC00`, green `#33CC33`, light grey `#D3D3D3`, grey `#999999`.
High Contrast uses `#FF00FF`, `#FF6600`, `#FFFF00`, `#00FFFF`, `#0066FF`,
`#FFFFFF`, and a green cast color `#00FF00`. Colors are canonical across zones
and combat; do not reintroduce separate sanctuary color controls.

| Action | Exact scope |
| --- | --- |
| Per-color Reset | That color in the selected profile, using High Contrast factory colors only for the High Contrast profile; no category-mode reset |
| Picker Cancel | Restores the RGB values captured when opened, redraws swatches, and refreshes plates |
| Reset all colors | Selected profile's six colors/cast color and cast style None; also all six global category modes Active; leaves other settings alone |
| Reset settings on Appearance | Selected profile's appearance and threat display true; global critter hiding false; preserves styling activation, colors, cast effect, profile selection and TRP3 |
| Create | Factory-default profile, selects it for this character |
| Copy | Independent validated copy of active profile, selects it |
| Rename | Updates all character assignments; trimmed/case-insensitive uniqueness, 64-character limit; Default protected |
| Delete | Confirmation; all assigned characters fall back to Default; Default protected |
| Restore bundled profiles | Confirmation; replaces/recreates Default and High Contrast, preserves custom profiles and globals |

The shipped code places Reset all colors and Reset settings near the top,
before their controls. Preserve this placement rather than following stale
prose claiming all section actions belong at the bottom. Actions never share
heading rows. Labels precede controls, followed by related reset/info links.
Current reference measurements: control column 340 UI units (Profiles selector
184), switch 44×20, swatch 26×26, related controls 8 units apart, info link gap
10, setting rows 32 high with 6 below. Dropdowns are 190 wide, sliders 180 wide.
Preserve comfortable spacing and wrapped-description reflow rather than
assuming DF template defaults match these dimensions.

Info links remain yellow circled-i text without a button background. About's
three swatches are read-only and show explanatory dialogs/tooltips.

## Verified upstream API and dependency findings

Inspected [Details Framework](https://github.com/Tercioo/Details-Framework) at
commit `653af57120e1287be784d468324590a9c150ae98` (2026-10-02), library minor
762, LibStub major `DetailsFramework-1.0`. The standalone TOC is
`LibDFramework-1.0.toc`, advertises Interface 120100, and loads `load.xml`.
The library is LGPL 2.1. These are source observations, not client validation.

Reviewed the library's Lua sources, loading manifest, widget XML, reference
docs and license. Relevant pinned source files:
[fw.lua](https://github.com/Tercioo/Details-Framework/blob/653af57120e1287be784d468324590a9c150ae98/fw.lua),
[load.xml](https://github.com/Tercioo/Details-Framework/blob/653af57120e1287be784d468324590a9c150ae98/load.xml),
[slider.lua](https://github.com/Tercioo/Details-Framework/blob/653af57120e1287be784d468324590a9c150ae98/slider.lua),
[dropdown.lua](https://github.com/Tercioo/Details-Framework/blob/653af57120e1287be784d468324590a9c150ae98/dropdown.lua),
[button.lua](https://github.com/Tercioo/Details-Framework/blob/653af57120e1287be784d468324590a9c150ae98/button.lua),
[textentry.lua](https://github.com/Tercioo/Details-Framework/blob/653af57120e1287be784d468324590a9c150ae98/textentry.lua).

| Control | Verified entry point / adapter requirement |
| --- | --- |
| Switch | `CreateSwitch(parent, onSwitch, defaultValue, width, height, ...)`; callback `(self, fixedValue, value)`; `SetChecked` normally suppresses callbacks; use toggle styling, not checkbox styling |
| Slider | `CreateSlider(parent, width, height, minValue, maxValue, step, defaultValue, ...)`; callback `(self, fixedValue, value)`; `SetValue` runs callbacks; inspect/test `SetValueNoCallback` and keep a refresh guard |
| Dropdown | `CreateDropDown(parent, optionsFunction, defaultValue, width, height, ...)`; options contain `label`, `value`, `onclick`; callback `(dropdown, fixedValue, value)`; `Select(value, false, false, false)` suppresses onclick but evaluates the options provider |
| Button | `CreateButton(parent, callback, width, height, text, ...)`; callback starts with Blizzard button and click type; adapter should expose a simple action callback |
| Color picker | `CreateColorPickButton(parent, name, member, callback, alpha, template)`; RGB/alpha conversion and cancel restoration need explicit characterization; wrapper `Cancel()` hides the picker and must not be assumed equivalent to user Cancel rollback |
| Text entry | `CreateTextEntry(parent, callback, width, height, ...)`; adapt focus/Enter/Escape deliberately; retain native profile dialogs initially |

DF controls are wrappers. Use `GetUIObject()`/`.widget` when passing them as
Blizzard frame arguments (parents, relative anchors, tooltip owners). Hide this
conversion inside the adapter. Normalize enable state and refresh-versus-user
callbacks there; never let a programmatic refresh write saved settings.

The core requires LibStub and LibSharedMedia. SharedMedia requires
CallbackHandler; all three are already bundled. Source also contains optional
or helper-specific calls to Ace libraries, LibDeflate, LibGraph and
LibClassicCasterino. Do not add them merely because those helpers exist:
use widgets only, avoid addon/profile, compression, graph and classic helpers,
and verify the complete embedded load chain in phase 2. Load the existing
libraries first, then DF's complete upstream `load.xml` and its referenced
Lua/XML files, then the addon and widget adapter. Retain upstream license,
version arbitration and source provenance; do not register a partial library.

Several default widget paths reference `Interface/AddOns/Details/images/...`;
the reviewed repository has no image assets. Phase 2 must configure the used
widgets with Blizzard atlases/WHITE8X8 or properly supplied assets and test
with Details and Plater absent. Installing either addon must not be required.

Keep `FontMedia` policy and late-provider handling. Dropdown Select evaluates
its option provider, so cache/invalidate menu entries where needed to preserve
the existing cheap label-refresh path. Test long lists and scrolling before
converting Appearance. A newer external DF copy may win LibStub arbitration;
verify the required methods at adapter initialization and test coexistence.

## Baseline checks and later acceptance criteria

All 13 smoke suites passed with `luatex --luaonly tests/<name>-smoke.lua`:
bar-artwork, core-behavior, entity-facts, nameplate-setup, nameplate-threat,
nameplates, npc-titles, pixel-glow, presentation-rules, settings, shared-media,
text-underlayers, world-context. Working tree was clean; `git diff --check`
passed. No GitHub Actions workflows are currently present; do not restore
automatic ZIP packaging as part of this conversion.

`settings-smoke.lua` currently finds controls through native templates,
frame dimensions and texture children. Adapt these inspections as widgets
change, but retain assertions about user behavior, ownership, reset scope,
refresh suppression, dialogs, enable state and page order. Add adapter tests
for raw-frame boundaries and programmatic updates. Do not simply discard
checks that fail because of wrapper differences.

`core-behavior-smoke.lua` checks the exact TOC Lua order. Phase 2 must account
for the new XML loader, recursively validate all referenced Lua/XML files and
compile Lua sources while retaining explicit addon dependency-order checks.
Existing runtime suites remain regression gates. Stub results cannot prove
actual DF rendering, native secure behavior or combat safety.

## Remaining implementation phases

1. Baseline — complete in 1.0.150; no widget/runtime conversion yet.
2. Bundle the pinned DF load chain and introduce an isolated widget adapter;
   leave all pages on their existing implementation. Validate assets, wrapper
   boundaries, callback suppression and standalone/coexisting library loading.
3. Convert Colors; preserve six global modes, RGB apply/cancel/reset, profile
   colors, the five effect choices and top reset placement. Check in-game.
4. Convert Appearance; preserve fonts and late registrations, slider ranges,
   sanctuary matching, placement, threat and global critter reset scope. Test
   long shared-font lists, keyboard interaction and scrolling. Check in-game.
5. Convert Profiles, TRP3 and About in separately reviewable changes; preserve
   all existing database/dialog semantics and disabled/read-only controls.
6. Remove unreferenced legacy widget code, consolidate page duplication,
   update docs, run full regression checks and final in-game verification.

At the three client checkpoints, record client build, addon version and actual
observations: alignment/reflow, scrolling, switches, picker cancel, resets,
profile changes, missing/shared fonts, startup with/without other DF embedders,
and absence of combat/taint errors. Leave unobserved checks pending.

Documentation debt noted for later phases: About still mentions a pulsing
highlight although Pulse was removed; older design prose still mentions
sanctuary duplicates, class-color writes and controls that were removed. None
of these historical descriptions authorizes restoring the old behavior.
