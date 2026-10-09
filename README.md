# Simple Nameplates

Documentation reviewed for 1.0.228 (2026-10-09). The runtime fixes through 1.0.219 are retained. Crowded-scene appearance convergence is confirmed for 1.0.218; broader normal-play acceptance remains open.

A deliberately simple standalone nameplate-color addon for World of Warcraft.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| Priority | Category | Default color | Display |
| --- | --- | --- | --- |
| 1 | Attacking me | Red | Health bar; includes attacks on your controlled units |
| 2 | Hostile | Orange | Health bar; aggressive NPCs and eligible PvP opponents |
| 3 | Neutral | Yellow | Health bar; can attack you without meeting an earlier priority |
| 4 | Friendly | Blue | Available health bar in and out of combat |
| 5 | NPC - Interactive | Green | Interactive NPC: available health bar in both combat states |
| 6 | NPC - Background | Gray | Names by default; optional health bar |
| — | Interruptible cast | Cyan | Optional pulsing cast-bar border |
| — | Native overhead names without an accessible plate | Unchanged | Entity types and contexts are recorded below |

## How It Works

Simple Nameplates does **not** draw its own replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for creating each nameplate and for health depletion, casting, channels, target treatment, and other standard nameplate behavior. Simple Nameplates classifies addon-accessible units into its six Priority Colors.

Entity observations are collected separately in `EntityFacts.lua`, then the first matching priority wins. Faction, player control/ownership, directional attackability, interaction evidence, and unknown values remain separate facts. Thus an opposing player in sanctuary can be Friendly while retaining its opposite-faction identity; a hostile interactive NPC uses the higher combat priority. A PvP flag or desired War Mode alone does not establish an eligible opponent. Readable attackability determines eligibility, including duels; contextual sanctuary evidence prevents a flag-only inference.

Appearance profiles have one NPC - Interactive color (green `#00FF00` by default) and one NPC - Background color (medium grey `#999999` by default), shared inside and outside sanctuaries and across combat states. Existing Priority Colors choices remain authoritative; obsolete separate sanctuary NPC colors are discarded during normal settings validation. Player - Friendly likewise uses one shared color, blue (`#0000FF`) by default, in all world contexts. Existing Friendly color choices are retained; the obsolete separate sanctuary player color is discarded during validation. Higher danger categories always keep their own colors. Opposite-faction players retain their existing colors. The top Reset all colors button restores every color and control below it. High Contrast uses its factory palette; Default and custom profiles use the factory Default palette. Health Bar preferences reset to On for the first five categories and Off for NPC - Background; background-name dimming resets to On, cast highlighting to Inactive, and gradients to the profile default (100% for Default/custom profiles, 0% for High Contrast). Legacy global category modes also reset to Active internally but do not affect rendering. Colors affect only addon-accessible nameplates; Blizzard-controlled overhead names remain unchanged.

NPC - Interactive currently means readable `UnitIsInteractable` evidence on an NPC. This is not a permanent vendor/service catalog, and friendliness or overhead-name color alone is insufficient. Missing, failed, or secret observations remain unknown. NPC - Background is the remaining-entity fallback, not a claim that unknown entities offer no interaction.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

Even when WoW is configured to show friendly, enemy, and always-visible nameplates, it may not create a nameplate for every unit. If Blizzard supplies no addon-accessible nameplate frame, Simple Nameplates has nothing it can recolor.

On login and when styling is enabled using **Active** in `/snp profiles`, Simple Nameplates checks Blizzard's plate settings. If a readable setting conflicts, styling pauses and a setup dialog lists its current value, required value, and purpose. Choose **Apply and enable** to make the listed changes, or **Disable styling** to leave styling off. Compatible settings produce no dialog. The check requires Always Show Nameplates, Enemy Unit Nameplate, Friendly Player Nameplates, and Friendly NPC Nameplates on, with **Only Show Names off** so the addon can manage friendly health bars. It does not alter the NPC Names world-label filter, stacking, realm names, or size. Unsupported/unreadable CVars are skipped. This setup cannot guarantee plates for nonattackable opposite-faction players in sanctuary.

Only values changed through the setup dialog are backed up, separately for each character, and survive `/reload`. Disabling styling restores them; writes and restoration wait until combat ends when necessary, and failed restoration retains its backup for retry. A rejected setup change leaves styling paused with a retry/disable choice. If restoration of settings retained from an older version fails, setup stays paused and retries before reviewing compatibility, so a later restoration cannot silently invalidate an approved setup. Settings are checked again on each login or explicit enable, rather than continuously overwritten during play.

## Known Presentation Limits

Keep this register updated by **entity type and world context** whenever in-game verification shows a presentation that Simple Nameplates cannot alter. Individual character names are not relevant. The same limits appear in the addon's About notes. Record a resolution when one is demonstrated; do not silently discard an unresolved limitation or present it as a settings fix.

| Entity type | World context observed | Presentation the addon cannot currently alter | Evidence / status |
| --- | --- | --- | --- |
| Opposite-faction PCs, nonattackable in either direction | Sanctuary; verified in Silvermoon City, The Bazaar, with an Alliance viewer and Horde PCs | Native purple overhead name and guild/title presentation: color, font, size, text, and position | 2026-10-02: repeated direct lookups missing; nearby accessible-plate scans found zero matching frames. Unresolved. |

Friendly-player, enemy, and always-show nameplate settings were enabled during the investigation. Only Show Names was also tested off without producing matching frames. These limits remain unresolved after repeated investigation; no supported workaround was demonstrated in the Blizzard/Plater review. This records the current result, not proof that no solution could ever exist. Other entities need their own evidence before being added. See [the source review](docs/design/nameplate-settings-review.md).

**Resolved contexts:** Friendly service NPCs in Silvermoon sanctuary: a widget-only plate and an ordinary NPC plate could produce duplicate labels. v1.0.117 suppresses the widget-only actor text while preserving widgets; ordinary NPC names and service titles remain styled. Ordinary friendly NPC plates become available when Friendly NPC Nameplates is enabled. These contexts are not listed as currently unalterable.

The [evaluation decision tree in the developer notes](docs/design/evaluation-overview.md) documents the actual implemented order for entity classification, context colors, and presentation access.

## What's Displayed

NPC subtitles and TRP3 long titles are limited to the configured health-bar width, including when their bar is hidden. Longer text is truncated by the game’s single-line font layout.

NPC subtitles such as `<Voidforge Steward>` are read first from structured GUID hyperlink tooltip data, then from unit-token tooltip data and the existing subtitle caches and displayed below the health bar (or below the name if no bar exists) at 80% of the name size, in white with a thin black outline. They do not require TRP3. An active cast or channel hides the subtitle; it returns when casting ends. The reader accepts a single plain subtitle between the typed unit-name line and a typed level line or plain level text verified against WoW's localized template and the unit's level. When a nameplate tooltip omits its subtitle, the addon first uses exact NPC GUID matches. If GUID matching cannot resolve it, a matching readable NPC name can supply an unambiguous subtitle learned from a fuller target, mouseover, or soft-interaction tooltip during normal rendering. This name association is a heuristic; conflicting observed titles disable it. GUID and name caches each retain up to 256 entries for the session. Interaction evidence learned with the subtitle also contributes to useful-NPC classification. Unresolved or restricted data omits the title. This does not suppress Blizzard's separate overhead label or establish that every titled NPC is useful. `/snp debug` reports the detected NPC subtitle.

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Blizzard target scaling and highlighting; decorative bar borders are removed
* Optional scaled threat percentage at the right side of the health bar when WoW supplies a percentage its text API can display
* Optional selected border or glow around interruptible cast bars, with a configurable solid color

## Global behavior

Open **Options → AddOns → Simple Nameplates → Appearance**, or type `/snp`. The global Active switch is beside the selected profile on Profiles. Colors (`/snp colors`) contains each category's profile Health Bar switch; Appearance contains global critter/companion hiding.

The six categories are evaluated from top to bottom; the first match wins. All ordinary accessible plates receive styling while the global Active switch is enabled. A category's Health Bar switch controls its bar, not whether the category is styled. Off shows its name and title without a health bar. Legacy category Active/Inactive values are ignored by rendering.

Disabling styling restores Blizzard presentation. Restoration of restricted frames is retried when access returns, including while styling stays disabled. Restoration uses the current WoW unit name and preserves Blizzard's current cast/channel visibility. Native bars and containers retain their captured dimensions, visibility and colors; replacement regions receive a fresh baseline after retired regions are restored.

## Appearance Profiles and Settings

The settings pages are organized by purpose. Changes apply immediately and are saved between sessions.

| Page | Contents | Command |
| --- | --- | --- |
| About | Version, source, commands, presentation limits, and informational native-label swatches | `/snp about` |
| Profiles | Select, create, copy, rename, delete, and restore profiles; global Active switch | `/snp profiles` |
| Appearance | Fonts, sizing, name placement, threat display, global critter/companion visibility, and Reset settings | `/snp appearance` or `/snp` |
| Colors | Profile colors, Health Bar switches, background-name dimming, gradients/preview, cast Active switch/effect dropdown/preview, and Reset all colors | `/snp colors` |
| TRP3 | All global RP-name, title, and OOC options | `/snp trp3` |

Appearance and Colors each have a compact Selected profile control; management actions are on Profiles. On Profiles, the selector sits farther left with an Active/Inactive switch immediately to its right. This switch enables styling globally, including the startup compatibility review. Appearance's **Reset settings** and Colors' **Reset all colors** sit directly below their selectors. Health Bar switches sit beside the six category color swatches on Colors and apply to the selected profile. Individual color reset buttons and category Active switches have been removed. The cast-highlight **Active** switch sits beside its color; Inactive turns highlighting off for the selected profile. The **Effect** dropdown selects Pulsing border or Solid border. Both share the Border thickness slider (default 4 on all four edges), anchored directly to the cast bar with zero inset. Fade in and Fade out control the pulse (default 0.2 seconds each); pulse opacity remains fixed at 35–100%. The labeled preview demonstrates the selected effect even while Inactive; it does not detect a real cast. These controls are on Colors; the Advanced page and other effects have been removed. Reset all colors restores thickness and timing as well. Combat disables edits. Changing profiles selects that profile's Health Bar preferences.

Profiles are shared account-wide, while each character remembers its active profile. **Create** starts with factory-default appearance settings; **Copy** duplicates the complete active profile. Profiles can be renamed and deleted, except **Default**, which is the permanent fallback. Deleting a profile moves characters assigned to it back to Default.

The editable bundled profiles are **Default** and **High Contrast**. High Contrast uses magenta `#FF00FF`, orange `#FF6600`, yellow `#FFFF00`, cyan `#00FFFF`, blue `#0066FF`, and white `#FFFFFF` for Priority Colors 1–6; and green `#00FF00` for interruptible casts. Deleting or renaming High Contrast persists across reloads. **Restore bundled profiles** resets both bundles and recreates High Contrast if it was deleted or renamed. Custom profiles are left untouched.

Each category uses its available health bar when its profile Health Bar switch is on, in and out of combat, with its priority color. Switch it off to show a colored name and title with a one-unit gap and no health bar. Protected or inaccessible Blizzard plates retain native presentation. On styled plates with a displayed bar, ordinary names, threat percentages and native health labels are white; NPC - Background names use the dimming preference. Other entities without a displayed supported bar use their category color for the floating name. Retired category Active settings no longer affect styling, and widget-only plates preserve their widgets while suppressing actor text. Unknown player combat state no longer changes this layout.

`PresentationRules.lua` uses one uniform presentation policy. Entity facts still determine priority color, and world context still supports classification, access checks and sanctuary font matching. Health values and cast progress remain Blizzard-driven; unavailable threat text stays blank, and no replacement bars or fabricated health values are introduced.

Simple Nameplates styles accessible nameplates supplied by the game; it has no supported direct styling path for separate native overhead world names. The entity types and world contexts above document where this prevents the requested presentation. Plate-visibility changes require the startup review's Apply choice. The former experimental overhead replacement option has been removed; its saved toggle is discarded without conversion. Previously captured original Blizzard values are restored, with failed or combat-restricted restoration retried and originals retained until success. Any WoW CVar still changed by the addon is restored when its option is disabled or styling is disabled.

**Hide critter and companion names** controls ordinary overhead names for noncombat critters and companions. Their prior WoW settings are restored when disabled.

Appearance groups fonts, health-bar controls, and global visibility:

| Section | Controls and presentation |
| --- | --- |
| Fonts and sizing | Unit-name font, Slug rendering, shared 8–36 point name size, and sanctuary font matching |
| Health bars | Bar width (80–150%, default 120%), name placement, and threat font/display |
| Global visibility | Hide critter and companion names |

Settings changes are disabled while your character is in combat. Entering combat cancels unfinished color-picker, typed-slider and slider-drag previews, closes dropdown menus and profile dialogs, and restores controls to committed values. Already completed changes are retained. Settings become editable again when combat ends, with normal profile and TRP3 restrictions preserved. Choose the interruptible effect before engaging a test enemy; `/snp debug` and profiling commands remain available in combat.

The sections use the same saved settings in both combat states. All TRP3 options, including the global long-title switch, are together on TRP3. Long titles use the selected name size minus two (16 with the default size 18). They use the space below the health bar, or directly below the name when its bar is off or unavailable; an active cast or channel replaces them.

Headings use sentence case, labels use normal white text, and brief notes explain scope or exceptions without repeating the labels. Controls share a common column. Page resets sit near the top with explicit scope; Colors has no individual reset buttons. Headings have separate rows. **Reset settings** restores every setting below it on Appearance: the selected profile's fonts, Slug rendering (on), sizing, sanctuary font matching, name placement, threat display (on), plus global critter/companion hiding (off). It leaves profile selection, the Profiles-page Active switch, color values, category Health Bar preferences, gradients, and TRP3 preferences unchanged. Cast highlighting is controlled and reset on Colors.

**Use smoother font rendering (Slug)** is a per-profile switch near the font choices, on by default. It applies WoW's Slug renderer to accessible names, NPC/TRP3 titles, native health labels, threat percentages and cast labels. Names, titles and cast labels use a thin outline with either rendering setting; text inside health bars keeps outlined white glyphs and the existing padding. Font choices and the gradient setting are unchanged. Reset settings turns it on. Actual appearance depends on the font and UI scale and should be compared in game.

**Dim background NPC names** on Colors, below NPC - Background, applies to the selected profile. Off displays background NPC names in white (`#FFFFFF`); On uses grey (`#999999`). Their titles use the same shade. It applies above or inside health bars and when their bars are disabled. Threat percentages and health-bar colors keep their own styling. Dimming defaults On. Reset all colors turns it on; Reset Appearance preserves it.

**Gradient opacity** is a per-profile 0–100% slider above Priority colors, defaulting to 100% for Default/custom profiles and 0% for High Contrast. At 0% there is no gradient; at 100% the existing gradient is applied unchanged. Intermediate values scale its opacity: 50% produces 40% black at the left edge. Its full-health preview shows a white “Sample” name and **255%** threat. The original tint starts at 80% black and fades linearly to clear at 95% of full bar width; the final 5% remains clear. That geometry remains fixed as health falls, with a native-fill mask clipping the tint without reading secret health values. Cast bars stay flat. The retired `gradients` boolean is discarded without conversion; valid `gradientOpacity` values are retained and other values use defaults.

All styled names, NPC/TRP3 titles, threat percentages, native health labels, and cast labels use thin solid black outlines at every gradient opacity. No black glyph copies or health-dependent text-layer changes are used. Reset all colors restores the active profile’s gradient default (100% for Default, 0% for High Contrast); Reset Appearance preserves the choice.

**Match Blizzard font in sanctuaries** is enabled by default in each appearance profile. It uses Blizzard's localized native world-name font face for addon-controlled names and NPC/TRP3 titles throughout sanctuary areas, including names inside health bars. Turn it off to use the selected Name font everywhere. Outside sanctuaries, the selected font applies normally. Sizes, colors, positioning, and the separate threat font retain their existing behavior. This improves consistency with inaccessible opposite-faction PC labels; it does not make those labels editable or guarantee identical sizing and outlines.

The selected Name font defaults to WoW's built-in **Friz Quadrata**, the threat-percentage font defaults to **Arial Narrow**, names and threat percentages share the selected name size (18 points by default), and outside-bar names and titles use a thin outline whether Slug rendering is on or off. Inside-bar text uses a thin solid black outline; background names retain their configured dimming shade. The Name font and Threat-percentage font menus include built-in fonts and fonts registered through the bundled LibSharedMedia library by other addons or SharedMedia packs. No separate library installation is required. Shared font selections survive profile copying and reloads; an unavailable font temporarily uses Arial Narrow, and its saved selection resumes when the supplying addon registers it again. External font files are supplied by those other addons, not bundled here. Health-bar width defaults to 120% of Blizzard’s native width; valid saved widths are preserved, and Reset settings restores 120%. Name placement defaults to Inside for Default and new custom profiles, and Above for High Contrast. Valid saved choices are preserved; Reset settings restores the active profile’s placement default. Ordinary inside-bar names are white; background names retain their dimming shade. Inside-bar names retain the full selected size. Threat text occupies the right edge with three units of padding. Displayed native health percentage/value labels form a chain to its left, with three-unit gaps; without threat, health labels start at the right edge. Inside-bar names end three units before the combined labels, or three units from the bar edge when none are displayed. Native health visibility changes update this layout during reconciliation; disabling styling restores the original native label anchors. Their health bars expand as needed to leave four UI units above and three below the text, then return to Blizzard's original height when names move above the bar or Simple Nameplates styling is disabled. Name-only plates are unaffected by the placement setting; Friendly, NPC - Interactive, and NPC - Background use the same above/inside layout whenever their supported bars are available. Blizzard-controlled overhead names have no nameplate frame, so their size and font remain controlled by the game.

Styled health and cast bars use flat fills and backgrounds without native decorative borders or shaded overlays. The bright right-edge absorb overflow glow is suppressed on styled health bars; shield fill and healing predictions remain visible. Cast lookup supports both direct legacy fields and Retail's native `CastBarsContainer.castBar` layout, checking container and bar access before use. Cast spell and target labels keep their native font and size with thin outlines whether Slug is on or off, and no shadows. Cast progress, spell icons, non-interruptible shields, and Blizzard target/mouseover selection highlighting and classification-badge visibility are preserved; original artwork is restored when styling ends.

About contains three informational swatches for native opposite-faction PC sanctuary labels, interactive-NPC labels, and vendor-NPC labels. These describe native labels, not blanket unalterable entity categories; separate accessible NPC plates can be styled. The optional interruptible highlight draws the selected colored border or glow around Blizzard's existing cast bar; the Active switch enables or disables it. Effect defaults to Pulsing border and resets with Colors; Appearance reset preserves it. The effect is anchored to the native bar and does not read cast-bar dimensions. It never calls Midnight's secrecy-wrapped `IsInterruptable()`. Blizzard's already-rendered spell-icon/shield visibility supplies the initial state at cast start; explicit interruptible/not-interruptible events then become authoritative for mid-cast changes and cast-stop events clear the pulse. Modern and Classic nameplate styles are both supported, and Blizzard's native non-interruptible shield treatment is preserved.

For a repeatable cast test, see [interruptible-effect testing](docs/design/cast-effect-testing.md). Native icon/shield and cast-bar SetShown/Show/Hide transitions trigger recovery; unreadable initial state retries rather than being treated as interruptible.

## TRP3 Integration

Open **Options → AddOns → Simple Nameplates → TRP3**, or type `/snp trp3`. The page begins with **Display TRP3 profile information**, which is disabled by default.

When enabled, Simple Nameplates can use a character's TRP3 roleplaying full name, put the short title before the name, show the long title below the health bar (or below the name if no bar exists), and mark out-of-character profiles. If the OOC option is enabled, `[OOC]` replaces the short title; IC profiles receive no marker. Long titles use the name size minus two and white text with a thin black outline, independently of category color. Titles beneath dimmed background NPC names use the same grey as the name. Blizzard controls cast-bar visibility: an active cast or channel hides the title, and it returns when casting ends. Unreadable cast visibility conservatively hides the title and retries when readable.

Each field has its own toggle. To keep nameplates readable, roleplaying names are limited to 32 characters, short titles to 20, and long titles to 48; longer values end with an ellipsis. The normal WoW name is used whenever a cached TRP3 profile or selected field is unavailable. `TRP3.lua` keeps the optional profile access isolated, and Simple Nameplates continues to work normally without TRP3.

## Saved Settings

Look-and-feel settings are stored in named appearance profiles: priority colors, cast-highlight color, Active state and selected effect, Health Bar preferences, background-name dimming, gradients, fonts, sizing, placement, and threat display. Global settings cover styling enablement, critter/companion visibility, and TRP3 preferences. Legacy category modes remain stored but do not affect presentation. Each character selects an account-wide profile.

Saved settings are validated individually in their current locations. Recognized valid values are retained regardless of the saved schema marker; invalid and unknown settings are silently discarded, with defaults supplying missing values. The current category keys are `attacking`, `hostile`, `neutral`, `friendly`, `useful`, and `useless`. Obsolete category fields are discarded; valid current fields and unrelated settings remain. The retired `interruptibleCastStyle` is discarded without conversion. Only valid current values are imported; invalid, missing and removed values use defaults. The shared thickness and pulse timing retain their existing saved locations; solid-specific and other retired parameters are discarded.

## About and Diagnostics

While styling is enabled, confirmed widget-only plates retain their widgets but do not draw an additional name or title. Ordinary NPC plates continue displaying names and service subtitles. This prevents duplicate addon labels when WoW supplies both plate types for one NPC. Friendly NPC nameplates must be enabled in WoW to supply ordinary friendly NPC plates; the startup setup dialog can request that change with consent. Normal styling does not continuously rewrite visibility settings.

Profiling is off by default and session-only. Use `/snp perf start`, play through a representative scene, then `/snp perf stop` and `/snp perf report`. The chat report shows call counts, total/average/longest timings and start/end addon memory. Additional rows measure focused name/color repairs, data/name-layout updates, access assessments, artwork, name/title styling, health-text layout, drift checks, periodic work and native plate discovery. Reconciliation now counts individual plate jobs; periodic counters identify processed groups and count/time limits. Reason counters distinguish full/focused requests and outcomes, queued events, the first observed name drift, cached repairs and full-styling fallbacks. Timings overlap and must not be summed as total CPU; memory is aggregate, not per-function allocation. Commands work during combat. See the [profiling guide](docs/design/profiling.md) for the measured paths, session behavior and interpretation.

For disappearing names that return when targeted or hovered, use
`/snp debug nearby Citadel Watcher` while the names are missing, with no target
and the mouse away from the units. This read-only snapshot uses existing plate
enumeration, avoids direct unit lookups/classification/tooltips, and reports local
and effective alpha, visibility and dimensions through the display hierarchy.
The optional name filter is a literal, case-insensitive substring; output is
limited to 20 matching plates. The 1.0.227 failure-state capture identified zero-width health bars and containers.
Version 1.0.228 preserves width when releasing native anchors for height changes
and tracks that width for untargeted recovery, including at 100% bar width.
Client confirmation remains pending.

`/snp debug` inspects your target; `/snp debug mouseover` inspects the hovered unit without targeting it. For a distant enemy, put `/snp debug mouseover` in a keybound macro and press the key while hovering over its body. The report identifies the inspected unit token and distinguishes missing plates from inaccessible ones. If nothing is under the pointer, it reports that no mouseover unit is available.

`/snp debug` limits detailed plate reports to the targeted unit, its direct nameplate lookup, and plates sharing its readable unit name. Same-name candidates are explicitly distinguished from identity matches, and each relevant frame is printed once. Unrelated nearby plates contribute only to scan counts, keeping duplicate presentations together in chat.

The main **Simple Nameplates** AddOns page is an About screen showing the addon version, author, category, license, source repository, and slash commands. The displayed version is read directly from the addon's `.toc` metadata so it cannot drift from the installed release. Click the source URL to open a copy-ready dialog.

`WorldContext.lua` caches zone/subzone/map, instance, territory/sanctuary, player faction, desired and active War Mode, PvP/FFA flags, player combat, and combat lockdown on relevant events, including while styling is disabled. Presentation reads this cache; location names do not determine permissions. `PresentationCapabilities.lua` assesses individual frames and regions and skips forbidden, unknown, or combat-restricted access.

Failed frame restorations release their temporary styling guard and remain queued for retry. Successful retries refresh addon presentation for the frame's current unit, including recycled plates. `/snp debug` reports the last restoration error while a failure remains pending; an absent blocked region is shown as `(none)`.

`Diagnostics.lua` owns read-only context and targeted-unit reporting. `/snp debug` reports the cached world context even without a target, keeping unknown values distinct from false. With a target, it reports presentation access status and observed health-bar visibility; missing nameplates do not establish whether Blizzard world names are displayed. Diagnostics inspects existing cast effects without creating frames or hooks. Type `/snp debug` with a unit targeted to report its detected type, reaction, faction, attackability, PvP and threat information, resulting priority category, Health Bar preference, display treatment, color, nameplate availability. It also reports the name text region's shown, effective visibility, alpha, and immediate-parent state, plus whether the interruptible highlight is enabled, the target's cast bar and icon were found, visibility hooks were installed, resolved interruptibility/source, selected and active renderer, renderer errors/fallback, and whether the highlight is shown. The winning classification rule and its entity facts are reported together, followed by the presentation rule, action/reason, requested health-bar state, and title permission. Configured styling is distinguished from observed visibility; disabled styling reports Blizzard presentation. Restricted Midnight values are identified rather than inspected.

Direct native name font-object, text-height and color setters also repair the
cached appearance immediately, with access/identity checks and reentry guards.
Equivalent font filename spellings and flag order do not cause periodic drift.
The profiler distinguishes font components, cache invalidation reasons and
external appearance writes, and measures urgent event refreshes separately.
Cached color repair remains eligible during native bar visibility changes.
Readable health-bar/container opacity resets and inside-name opacity drift are
repaired without targeting. Bar/container visibility and alpha callbacks recover
immediately; periodic reconciliation covers native changes that bypass hooks.
Whole-plate and unit-frame fades remain Blizzard-controlled, and disabling styling
restores captured native bar/container opacity. The disappearing hostile-NPC-name report was subsequently traced to zero-width
bar geometry and addressed in 1.0.228; client confirmation remains pending.
Configured dimensions release opposing native anchors while preserving their
restoration baseline; unchanged geometry should no longer trigger repeated repair.
Global repair hooks skip unrelated raid/party or cleared-unit frames.
The 94.4-second 1.0.218 crowded-scene report showed no appearance drift or repair fallback across 4,686 reconciliation checks, with no failures across 11,534 diagnostic checkpoints. The bounded finalizer caught 660 color resets before operation completion. Runtime update/Urgent refresh maxima were 4.728/2.951 ms. Temporary checkpoint instrumentation was removed in 1.0.219; the fixes and ordinary profiler remain. These observations establish convergence in that scene, not an exact FPS gain or complete combat/context acceptance.

Ordinary Blizzard name/color updates use focused repairs. Queued events merge classification, name/title, threat, cast and layout work per plate; a threat label appearing or disappearing adjusts the name space. Full styling is reserved for setup, settings/context changes, changed presentation structure and invalid cached state. TRP3 callbacks update content through the next queued runtime batch.

Name reconciliation shares an access assessment within each scan operation and repairs only observed differences in text, font, shadows, color, visibility and dimensions. Unchanged plates receive no repair writes; changed health-label chains receive layout updates. Restricted properties are unknown, with elapsed-time retry delays backing off from 0.25 seconds to four seconds while independent readable differences still repair. Unknown cast visibility keeps titles hidden; native cast hooks and events remain immediate. Missed cast-icon callbacks are retried when access returns using the current plate decision and icon visibility. Broad global refreshes, routine reconciliation and deferred restoration/cast/unit/plate retries share at most four jobs per frame with a one-millisecond target checked between jobs. Plates become due again after 0.25 seconds; heavy queues can extend service intervals. Explicit unit updates and current/previous target, mouseover and interaction plates remain immediate, outside the periodic budget. Broad settings/context/background updates settle over successive frames. The target cannot interrupt one slow operation; restoration remains eligible while styling is disabled.

The diagnostic also enumerates existing nameplates and matches their unit tokens to the selected target, with readable GUIDs as a fallback when unit identity is unavailable. It reports the lookup source, matching-frame count, unknown identities, addon styling markers, cached name text and presentation revision, and the inside-name and long-title regions. These are read-only observations; a missing match does not prove that a world label belongs to Blizzard or another addon.

Relevant nameplates (direct lookup, identity matches and readable same-name candidates) are listed with their current unit tokens/names, displayed name, base/frame/text visibility, original unit token, and cached addon text. This helps identify stale labels on frames assigned to another unit. Inaccessible regions remain marked unavailable rather than read.

NPC tooltip diagnostics report separate GUID hyperlink and unit-token extraction results, the resolved title source, soft-interaction matches, widget-only flags, and the friendly NPC nameplate CVar. They distinguish unavailable APIs/data or identity, restricted fields, and parser rejection. For the inspected unit and relevant NPC candidates, the report lists up to twelve tooltip lines with numeric line type, left/right text, and field-access status. This helps verify live subtitle layouts without changing the visible tooltip or guessing that every second line is a title.

All settings pages scroll when their contents do not fit the available window height.

## Download and Installation

1. Exit World of Warcraft.
2. On the [repository page](https://github.com/bblackmoor/SimpleNameplates), choose **Code → Download ZIP**.
3. Extract the downloaded ZIP and open the outer repository folder (usually `SimpleNameplates-main`).
4. Copy the inner `SimpleNameplates` addon folder into WoW's `_retail_/Interface/AddOns/` directory. The installed file should be `_retail_/Interface/AddOns/SimpleNameplates/SimpleNameplates.toc`.
5. Start World of Warcraft, enable **Simple Nameplates** in the AddOns list, and log in.

## Other Nameplate Addons

Simple Nameplates checks the enabled addon list at login. If it finds another third-party addon whose name or title contains “plate,” it displays a warning listing the possible conflicts. Blizzard's own internal addons are ignored.

Running multiple nameplate addons can cause competing colors or duplicate nameplates. Disable the others and reload the UI if you see problems.

## Midnight and Secret Values

World of Warcraft: Midnight may mark some threat information as secret.

Simple Nameplates does not inspect or calculate with secret threat values. It displays WoW's scaled threat percentage (the 0–100 pull-aggression scale) and does not use the raw percentage that can pin at 255 while tanking. Secret scaled values are passed directly to WoW's supported text formatter. Missing values or rejected formatting leave the percentage blank. Diagnostics reports whether threat display is disabled, unavailable, or displayed.

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so applying the shared red attacking color to PCs is best effort: it is used when WoW reports threat on you or your pet, or when the hostile player is targeting you, your pet, guardian, or minion.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Bundled libraries

Cast highlighting uses addon-owned four-edge borders for Pulsing border and Solid border. Both anchor directly to the native cast bar without reading its dimensions. Color, Active, effect, shared thickness and pulse fade times are on Colors. Cast effects do not require library border/glow constructors.

LibSharedMedia and CallbackHandler supply the shared font registry and provider-change notifications. External font packs are optional; solid bar fills have no texture selector.

Details Framework minor 762 (LGPL-2.1-or-later) is bundled for settings widgets. Details and Plater are not required.
All five settings pages use the DF widget adapter. Native dialogs, yellow info
links and shared layout helpers remain. Saved settings keep their existing
meaning and layout remains consistent with the previous pages.
See [library provenance](SimpleNameplates/Libs/README.md) and run
`luatex --luaonly tests/details-framework-smoke.lua` for the library/adapter check.

## Development

The [reconciliation stall plan](docs/design/reconciliation-stall-plan.md) provides
follow-up phases 5–8 and step-by-step client recordings. Confirm the installed
build before comparing older all-plate and current per-plate reconciliation data. Targeted fixes are complete and temporary diagnostics are removed; normal play with profiling off is the next acceptance step. Capture a new complete report if flicker or hitches return.


The [shared settings conventions](docs/design/settings-conventions.md) describe the completed four-phase standardization, contract coverage, optional tests with both addons, and pending native acceptance.

The [settings conversion plan](docs/design/details-framework-conversion.md) records the completed Details Framework code conversion and cleanup. The [original refactor plan](docs/design/implementation-plan.md) and [runtime plan](docs/design/runtime-refactor-plan.md) retain earlier implementation history. Saved data remains schema 2 with global behavior and appearance profiles.

Documentation entry points:

| Guide | Purpose |
| --- | --- |
| [Runtime evaluation](docs/design/evaluation-overview.md) | Actual classification, presentation and update order |
| [Settings architecture](docs/design/settings-architecture.md) | Current pages, modules, scheduling and ownership |
| [Saved data](docs/design/saved-data-model.md) | Schema, defaults, compatibility and reset scopes |
| [Profiling](docs/design/profiling.md) | Current report rows and interpretation |
| [Live verification](docs/design/live-wow-verification.md) | Current acceptance checklist and recorded evidence |
| [Library provenance](SimpleNameplates/Libs/README.md) | Shipped dependencies and pinned upstream sources |

Earlier implementation/conversion plans are historical records. Their original controls, defaults and pending findings are superseded by these current guides and later recorded results.

Run all 23 local smoke suites from the repository root (the verified interpreter here is LuaTeX):

```sh
for test in tests/*-smoke.lua; do
    texlua "$test" || exit 1
done
git diff --check
```

These checks cover the actual bundled libraries with native UI stubs; they do not establish rendering or secure behavior in WoW. The [live WoW checklist](docs/design/live-wow-verification.md) remains open for final client verification.

## AI Disclaimer

AI-assisted tools were used during the development of this project. The author reviewed and approved the resulting code and documentation and remains responsible for the project.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))

Licensed under the GNU General Public License v3.0 (GPL-3.0):

https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
