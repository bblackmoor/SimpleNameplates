# Details Framework settings conversion

Historical implementation record, reviewed for 1.0.220 on 2026-10-08. Version-specific defaults, controls, paths and unchecked phase items below describe those releases; they are not current instructions. Use [settings architecture](settings-architecture.md), [saved data](saved-data-model.md), [runtime evaluation](evaluation-overview.md) and [live verification](live-wow-verification.md) for current behavior and acceptance. Category activation controls, the Behavior page, experimental replacement, glyph copies and glow selectors have been removed. Current controls use profile Health Bar preferences and a cast pulse Active switch.

Conversion completion recorded at 1.0.163: phases 1–6 repository work is complete; all 18 smoke
suites pass. Final in-game verification remains pending. The baseline and earlier
phase notes below describe their recorded releases, not the current widget inventory.

Phase 1 completed on 2026-10-04 against Simple Nameplates 1.0.149,
commit `80f8dad348c0d87497a9db6b3dd6b7437ab57c87`. This document records
the source behavior and implementation sequence at that historical baseline.
Phase 1 adds documentation only; the accompanying release is 1.0.150.

This was the settings baseline for that completed conversion; current ownership and controls are documented in settings-architecture.md and saved-data-model.md. Earlier
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

| Module | Baseline responsibility (1.0.149) | Conversion treatment |
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
Settings cannot open through these commands during combat. Diagnostic and `/snp perf start|stop|report` commands remain available; profiling is session-only and has no settings widget.

## Historical baseline behavior to preserve during conversion

| Setting/group | Ownership and factory value | Required behavior |
| --- | --- | --- |
| Styling Active switch | Global, true | Located beside Selected profile on Profiles; reflects effective suspension while setup consent is pending; disabling restores native presentation |
| Selected profile | Per-character assignment to account-wide profiles; Default initially | Profile changes refresh current page and plates; hidden pages reread on show |
| Six category modes | Global, all Active | Active/Inactive only, no Hide option; Inactive preserves Blizzard presentation |
| Priority colors | Profile | First-match order: attacking, hostile, neutral, friendly, useful, useless |
| Cast color/style | Profile; cyan and None | RGB-only color; None, Moving dashes, Autocast Shine, Action Button Glow, Proc Glow; no Pulse or separate cast switch |
| Name font | Profile, `FRIZQT` | Six existing built-in IDs remain valid; shared `LSM:` selections survive missing providers and reloads |
| Threat font | Profile, `ARIALN` | Independent font choice; same dynamic shared registry and missing-font fallback |
| Slug font rendering | Profile, true | Appearance toggle near fonts; shared rendering flags, thin solid outlines on all styled text |
| Sanctuary font matching | Profile, true | Changes name/title face only; selected name font applies when disabled |
| Name size | Profile, 21 | 8–36 points in steps of 1; also controls threat size; titles use 80% |
| Health bar width | Profile, 100% | 80–150% in steps of 5; preserve existing rounding/clamping |
| Name placement | Profile, Above bar | Above/Inside only; keep existing bar-height, text-shadow, and padding behavior |
| Threat display | Profile, true | Preserve available/secret-safe percentage rendering |
| Hide critter/companion names | Global, false | Appearance, noncombat units only; preserve captured originals/restoration |
| TRP3 integration | Global, false | Dependent switches disabled/dimmed when off; detected/absent status remains |
| TRP3 name, short title, full title, OOC preferences | Global, all true | Preserve refresh/cache handling, WoW-name fallback; long titles below health bars or names, hidden during native casts/channels |

Default priority RGB values are red `#FF0000`, orange `#FF6600`, yellow
`#FFCC00`, blue `#0000FF`, green `#00FF00`, grey `#999999`.
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
Historical baseline reference measurements: control column 340 UI units (Profiles selector
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

Phase 2 is complete in 1.0.151. `Libs/DetailsFramework/load.xml` and its entire
pinned load chain load after the existing embedded dependencies. The separate
`SettingsWidgets.lua` module exposes `CreateSwitch`, `CreateSlider`,
`CreateDropdown`, `CreateButton`, `CreateColorPicker`, and `GetFrame` without
replacing `ns.SettingsUI` or constructing/registering any pages. Native profile
dialogs remain in place; a text-entry adapter is deferred until a converted
page needs one.

Handles expose explicit native frames, enable state and silent value setters.
Slider refreshes use a depth guard rather than DF's one-shot suppression flag.
Dropdowns cache options until `InvalidateOptions`; `SetLabel` does no menu
work. Picker swatches are DF controls with an adapted click callback that opens
Blizzard's RGB-only picker and restores captured RGB on user Cancel. No DF
globals/templates are patched. Used controls receive explicit Blizzard assets,
including the nested dropdown scrollbar thumb that DF normally reskins with
Details' `icons2` image.

`details-framework-smoke.lua` loads all 52 scripts/9 manifests with native UI
stubs and real embedded dependencies, exercises the actual DF widgets through
the adapter, inspects final widget assets, and emulates a higher compatible
LibStub minor winning arbitration. This does not test a different external DF
implementation or native client behavior. All 14 smoke suites pass; core tests
also compile recursive XML script references and retain explicit addon order.
Before converting Colors, verify client startup/settings with Details and
Plater absent, then with an external embedder present. Rendering, secure/combat
behavior and actual external-copy compatibility remain unobserved.

1. Baseline — complete in 1.0.150; no widget/runtime conversion yet.
2. Foundation — complete in 1.0.151: bundle the pinned DF load chain and introduce an isolated widget adapter;
   leave all pages on their existing implementation. Validate assets, wrapper
   boundaries, callback suppression and standalone/coexisting library loading.
3. Colors conversion — implemented in 1.0.152; preserve six global modes, RGB apply/cancel/reset, profile
   colors, the five effect choices and top reset placement. Check in-game.
4. Appearance conversion — implemented in 1.0.154; preserve fonts and late registrations, slider ranges,
   sanctuary matching, placement, threat and global critter reset scope. Test
   long shared-font lists, keyboard interaction and scrolling. Check in-game.
5. Profiles, TRP3 and About conversion — implemented in 1.0.155 in separate page
   modules; preserves database/dialog semantics and disabled/read-only controls.
6. Repository cleanup — implemented in 1.0.156: remove unused legacy controls,
   consolidate repeated page construction, update docs and run all regressions.
   Final in-game verification remains pending.

At the three client checkpoints, record client build, addon version and actual
observations: alignment/reflow, scrolling, switches, picker cancel, resets,
profile changes, missing/shared fonts, startup with/without other DF embedders,
and absence of combat/taint errors. Leave unobserved checks pending.

Documentation debt: phase 5 fixes About's stale pulsing-highlight description;
older design prose still mentions
sanctuary duplicates, class-color writes and controls that were removed. None
of these historical descriptions authorizes restoring the old behavior.

## Phase 3 implementation (1.0.152)

Colors' seven editable swatches, six activation switches, seven individual
reset buttons, page-reset button and effect dropdown now use SettingsWidgets.
The shared native profile selector and layout/reflow helpers remain in place;
Profiles and the other pages are not converted in this phase. Swatches retain
26×26 dimensions, a dark background, three-unit fill inset, border hover and
native tooltip ownership. Individual resets retain 54×22 dimensions; the page
reset remains 190×24 above the controls. DF's dropdown uses the actual control
column, without the old native dropdown's sixteen-unit template compensation.

One context refresh list replaces separate mode/effect and swatch redraw lists.
Widget setters suppress callbacks, so redraws and page shows do not change
saved values or schedule plate refreshes. Explicit user actions refresh the
page and plates once. Database schema, ownership and reset definitions remain
unchanged. The RGB-only adapter retains the opening color for user Cancel.

The existing settings suite now loads real DF against native UI stubs and
retains its page-order, callback, ownership, enable-state and layout assertions.
`settings-colors-smoke.lua` additionally uses the real database to verify all
six modes, picker apply/cancel/redraw, individual reset scope, all five effects
through DF's option-click handler, profile switching, High Contrast reset,
unrelated-profile/settings preservation, and silent construction/show refresh.
All 15 suites pass. A shared test loader removes duplicated manifest loading.

The phase 3 implementation is complete; the planned client checkpoint is still
pending. Record native rendering/scrolling, picker behavior, profile switches,
resets and combat/taint observations with Details/Plater absent and with an
external embedder present before treating client verification as complete.

## Slider cancellation fix (1.0.153)

The phase 4 review reproduced a DF shared-editor Escape closure restoring the
first slider's value when canceling another slider. SettingsWidgets now gives
each adapted slider a private native editor through an instance-local TypeValue
override. Opening captures that slider's current value; valid previews use the
existing range/step normalization, Enter commits, and Escape/close/focus loss/
disable restores its opening value and notifies the page if a preview changed
it. The bundled DF source and its shared editor are untouched. The real-DF
adapter smoke test covers both sliders and cleanup. Appearance was not yet
converted in that release; native client verification remains pending.

## Phase 4 implementation (1.0.154)

Appearance now uses DF font/placement dropdowns, size/width sliders, sanctuary,
threat and global critter switches, and its top reset button. The shared profile
selector remains native for phase 5. The critter row moved out of the otherwise
Profiles-specific SettingsBehavior helper; its existing getter/setter still
owns global CVar capture/restoration. Database definitions and nameplate runtime
code are unchanged. Size controls retain 180×18 dimensions, endpoint captions
and adjacent pt/% labels; font/placement controls use the 340-unit column.

The dropdown adapter accepts an explicit label with SetValue, using DF's
Selected method without evaluating the options provider. Constructor selection
is deferred. Font refreshes resolve labels through FontMedia and invalidate
cached choices, but rebuild/sort only on the next menu opening. A changed
selection also invalidates choices to retain selected duplicate/missing keys.
Media callbacks still refresh only the two font controls, without touching
sliders or saved settings. FontMedia remains the sole font policy layer.

Appearance exports cancellation for shared profile selectors to run before
changing the active profile. Reset cancels previews before restoring defaults;
page hide cancels them in the current profile. Silent slider redraws and user
no-op guards preserve existing setter/refresh behavior. Scope remains the active
profile's appearance/threat plus global critter visibility, leaving styling,
colors, effects, other profiles and TRP3 intact.

The existing settings suite retains its behavior checks using actual DF widgets.
settings-appearance-smoke.lua additionally uses real SharedMedia and database
code to exercise ranges/rounding, unit labels, slider Escape/Enter, rollback
before profile changes/resets/hide, missing/returning providers, cheap targeted
label refreshes, sixty-font menu construction/scrolling, and reset preservation.
All 16 suites pass. Native rendering, input/security behavior and external-copy
compatibility remain pending client observations in the live checklist.

## Phase 5 implementation (1.0.155)

Profiles now uses adapted shared selectors, 88×24 management buttons, the
210×24 bundled-restore button, and the global styling switch/status. Its selector
uses the 184-unit column; Appearance and Colors retain the 340-unit column.
The adapter unwraps relative anchors. Refresh invalidates profile choices and
updates the label without building the menu; menus rebuild on opening after
create/copy/rename/delete/restore. Appearance previews still cancel before
selection changes. Native profile dialogs and Database.lua remain unchanged.
Management callbacks are bound when their buttons are created; disabled Default
Rename/Delete buttons suppress actions through the adapter.

TRP3 now uses adapted switches and retains its integration refresh, availability
message, saved preferences, disabled dependent controls and dimmed labels.
Programmatic refreshes do not notify the integration or write saved settings.

About uses a DF button styled as a transparent source link, retaining its native
Ctrl+C dialog and hover colors. A separate CreateColorDisplay adapter uses a
DF-backed decorative frame with a 26×26 border and inset RGB texture, with mouse
handling disabled and no color-picker path. Containing rows retain tooltips and
yellow info links remain native. The introductory description now names selectable
interruptible-cast highlights instead of the removed Pulse effect.

settings-secondary-smoke.lua uses the real library and database to cover
construction/show suppression, native dialog cancellation/acceptance, validated
creation, independent copies, duplicate rejection, cross-character rename/delete,
Default protection, bundled reset scope, setup consent/restoration, TRP3 disabled
choices and absent integration, read-only RGB displays, info dialogs and the
transparent source link/copy dialog. Appearance and Colors regressions exercise
the converted shared selector. All 17 suites pass. Client observations remain
pending; phase 6 owns unused legacy helper removal and final consolidation.

## Phase 6 repository cleanup (1.0.156)

SettingsControls.lua retains the scrolling/reflow engine, headings, descriptions,
setting rows, native yellow info links and refresh helper. Its unused native
CreateSwitch, AddToggle and AddActionButton implementations/exports are removed.
AddSwitchRow, AddSwitchStatus, CreateDropdownRow and AddPageAction compose the
DF adapter with shared layout. They resolve ns.SettingsWidgets at construction
time because the adapter loads after this module. The adapter remains responsible
for wrapper boundaries, enabled state and silent widget updates.

Appearance/TRP3 share switch-row alignment and refresher registration. Colors
and Profiles share switch/status sizing and Active/Inactive text. Font, placement,
cast-effect and profile menus share dropdown-row alignment; their providers,
cache invalidation and label-refresh policy stay with their original owners.
Appearance/Colors resets and Profiles bundled restore share action-row layout.
Their placement, reset scope and callbacks are unchanged. Fonts/sliders/picker
rollback, native profile dialogs and setup consent remain page responsibilities;
no generic page state/controller was introduced.

The settings layout test now uses the adapted page action when checking wrapped
text reflow. All 17 existing smoke suites pass after consolidation, including
actual DF/SharedMedia/database integration tests and recursive library loading.
The README describes current controls/ownership and includes the full test loop;
historical design notes remain historical and are not instructions to restore
removed controls. No further implementation phase is planned. Final acceptance
still requires observed client rendering/input, external-copy compatibility and
combat/taint checks in live-wow-verification.md.

## Post-conversion review (1.0.157)

Review reproduced two settings races with the real library/database tests: an
old color Cancel callback restored a custom color after Reset all colors, and
accepting Delete after changing selection deleted the newly selected profile.
The tests failed before fixes and pass afterward.

The adapter now separates OpenColorEditor, ApplyColor and FinishColorEdit from
swatch construction. Each opening is tagged through Blizzard's extraInfo /
GetExtraInfo contract; stale callbacks are ignored. Explicit cancellation
rolls back before resets or shared profile selection and closes only the owned
picker. Native hide retires accepted edits without rollback. Disable/hide also
close a swatch's editor, and opening another swatch rolls back the previous
preview. Native setup's synchronous color event is suppressed. The modern
picker lifecycle was checked against the [Blizzard source mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_ColorPickerFrame/Mainline/ColorPickerFrame.lua).

Copy/Rename/Delete dialogs capture their target profile name; acceptance checks
it against the current selection and rejects a changed target. Create remains
independent of the previously selected profile. Database behavior is unchanged.
New regressions cover stale callbacks after page/individual resets and profile
changes, previous-profile rollback, Okay/hide commitment, editor replacement,
disable, another addon's picker, initial setup suppression, and all three stale
profile actions. All 17 smoke suites pass; native client timing/security still
requires the open live checklist.

## Errors and omissions review (1.0.158)

The modern Blizzard GameDialogMixin exposes GetButton1(); the profile-name Enter
callback still read only the legacy button1 field and silently did nothing on
that contract. The real-library/database test reproduced the omission before
the fix. Enter now uses the getter with a legacy fallback and checks the native
button's enabled state. Tests cover modern and legacy acceptance plus a disabled
accept button. The contract was checked against the [Blizzard dialog source mirror](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_StaticPopup_Game/GameDialog.lua).

README and live-checklist text still described an outline/no-shadow presentation,
three-unit top padding and luminance-based text colors. Those descriptions now
match the white inside-bar glyphs and four/three
padding; the rendering code itself is unchanged. All 17 suites pass. Actual
keyboard/rendering/security observations remain pending in the live checklist.

## Setup-state review (1.0.159)

Approval can complete after the styling-switch callback returns, including after
combat deferral. The Profiles switch refreshed only on its click or page show;
approval resumed styling but left the visible control Inactive. The real-library,
database and setup test reproduced that stale display before the fix.

NameplateSetup now routes pending-state changes through SetPending and invokes
an optional silent RefreshStylingControl callback registered by the Profiles
styling control. Suspend/resume/check/restore use the same path. Getter policy,
saved intent, consent, CVar writes and restoration remain unchanged. Tests cover
approval, suspension outside the switch callback, refusal, rejected writes and
combat-deferred completion without reopening the page. All 17 suites pass.

The saved-data guide now names interruptibleCastStyle rather than the removed
boolean, includes sanctuary matching and bar-width ownership, documents the
character-specific setup ledger, and removes the obsolete class-color backup
claim. These are documentation corrections, not a schema or data migration.
Native client timing/security verification remains pending.


Phase 1 of the [performance plan](performance-plan.md) subsequently removed the glyph underlayers and their dedicated smoke suite; all styled text now uses thin solid outlines. Earlier test-run records above describe their original revisions.
