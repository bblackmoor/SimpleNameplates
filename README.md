# Simple Nameplates

A deliberately simple standalone nameplate-color addon for World of Warcraft.

## The Short Version

Simple Nameplates keeps Blizzard's standard Midnight nameplates, but gives NPCs and player characters separate, customizable color languages:

| Priority | Category | Default color | Display |
| --- | --- | --- | --- |
| 1 | Attacking me | Red | Health bar; includes attacks on your controlled units |
| 2 | Hostile | Orange | Health bar; aggressive NPCs and eligible PvP opponents |
| 3 | Neutral | Yellow | Health bar; can attack you without meeting an earlier priority |
| 4 | Friendly | Green | Name out of combat; health bar in combat when supported |
| 5 | NPC - Interactive | Light grey | Interactive NPC: name out of combat; supported bar in combat |
| 6 | NPC - Background | Gray | Remaining entities: name out of combat; supported bar in combat |
| — | Interruptible cast | Cyan | Optional pulsing cast-bar border |
| — | Native overhead names without an accessible plate | Unchanged | Entity types and contexts are recorded below |

## How It Works

Simple Nameplates does **not** draw its own replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for creating each nameplate and for health depletion, casting, channels, target treatment, and other standard nameplate behavior. Simple Nameplates classifies addon-accessible units into its six Priority Colors.

Entity observations are collected separately in `EntityFacts.lua`, then the first matching priority wins. Faction, player control/ownership, directional attackability, interaction evidence, and unknown values remain separate facts. Thus an opposing player in sanctuary can be Friendly while retaining its opposite-faction identity; a hostile interactive NPC uses the higher combat priority. A PvP flag or desired War Mode alone does not establish an eligible opponent. Readable attackability determines eligibility, including duels; contextual sanctuary evidence prevents a flag-only inference.

Appearance profiles have one NPC - Interactive color (light grey `#D3D3D3` by default) and one NPC - Background color (medium grey `#999999` by default), shared inside and outside sanctuaries and across combat states. Existing Priority Colors choices remain authoritative; obsolete separate sanctuary NPC colors are discarded during normal settings validation. Player - Friendly likewise uses one shared color, green (`#33CC33`) by default, in all world contexts. Existing Friendly color choices are retained; the obsolete separate sanctuary player color is discarded during validation. Higher danger categories always keep their own colors. Opposite-faction players retain their existing colors. The top Reset all colors button restores every color and switch below it. High Contrast uses its factory palette; Default and custom profiles use the factory Default palette. Priority-category switches reset globally to Active, and the selected profile's cast-highlight switch resets to Inactive. Colors affect only addon-accessible nameplates; Blizzard-controlled overhead names remain unchanged.

NPC - Interactive currently means readable `UnitIsInteractable` evidence on an NPC. This is not a permanent vendor/service catalog, and friendliness or overhead-name color alone is insufficient. Missing, failed, or secret observations remain unknown. NPC - Background is the remaining-entity fallback, not a claim that unknown entities offer no interaction.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

Even when WoW is configured to show friendly, enemy, and always-visible nameplates, it may not create a nameplate for every unit. If Blizzard supplies no addon-accessible nameplate frame, Simple Nameplates has nothing it can recolor.

On login and when styling is enabled using **Active** in `/snp profiles`, Simple Nameplates checks Blizzard's plate settings. If a readable setting conflicts, styling pauses and a setup dialog lists its current value, required value, and purpose. Choose **Apply and enable** to make the listed changes, or **Disable styling** to leave styling off. Compatible settings produce no dialog. The check requires Always Show Nameplates, Enemy Unit Nameplate, Friendly Player Nameplates, and Friendly NPC Nameplates on, with **Only Show Names off** so the addon can manage friendly health bars in combat. It does not alter the NPC Names world-label filter, stacking, realm names, or size. Unsupported/unreadable CVars are skipped. This setup cannot guarantee plates for nonattackable opposite-faction players in sanctuary.

Only values changed through the setup dialog are backed up, separately for each character, and survive `/reload`. Disabling styling restores them; writes and restoration wait until combat ends when necessary, and failed restoration retains its backup for retry. A rejected setup change leaves styling paused with a retry/disable choice. Settings are checked again on each login or explicit enable, rather than continuously overwritten during play.

## Known Presentation Limits

Keep this register updated by **entity type and world context** whenever in-game verification shows a presentation that Simple Nameplates cannot alter. Individual character names are not relevant. The same limits appear in the addon's About notes. Record a resolution when one is demonstrated; do not silently discard an unresolved limitation or present it as a settings fix.

| Entity type | World context observed | Presentation the addon cannot currently alter | Evidence / status |
| --- | --- | --- | --- |
| Opposite-faction PCs, nonattackable in either direction | Sanctuary; verified in Silvermoon City, The Bazaar, with an Alliance viewer and Horde PCs | Native purple overhead name and guild/title presentation: color, font, size, text, and position | 2026-10-02: repeated direct lookups missing; nearby accessible-plate scans found zero matching frames. Unresolved. |

Friendly-player, enemy, and always-show nameplate settings were enabled during the investigation. Only Show Names was also tested off without producing matching frames. These limits remain unresolved after repeated investigation; no supported workaround was demonstrated in the Blizzard/Plater review. This records the current result, not proof that no solution could ever exist. Other entities need their own evidence before being added. See [the source review](docs/design/nameplate-settings-review.md).

**Resolved contexts:** Friendly service NPCs in Silvermoon sanctuary: a widget-only plate and an ordinary NPC plate could produce duplicate labels. v1.0.117 suppresses the widget-only actor text while preserving widgets; ordinary NPC names and service titles remain styled. Ordinary friendly NPC plates become available when Friendly NPC Nameplates is enabled. These contexts are not listed as currently unalterable.

The [evaluation decision tree in the developer notes](docs/design/evaluation-overview.md) documents the actual implemented order for entity classification, context colors, and presentation access.

## What's Displayed

NPC subtitles such as `<Voidforge Steward>` are read first from structured GUID hyperlink tooltip data, then from unit-token tooltip data and the existing subtitle caches and displayed beneath addon-controlled name-only NPC labels at 80% of the name size, in the same color. They do not require TRP3 and are hidden with visible health bars. The reader accepts a single plain subtitle between the typed unit-name line and a typed level line or plain level text verified against WoW's localized template and the unit's level. When a nameplate tooltip omits its subtitle, the addon first uses exact NPC GUID matches. If GUID matching cannot resolve it, a matching readable NPC name can supply an unambiguous subtitle learned from a fuller target, mouseover, or soft-interaction tooltip during normal rendering. This name association is a heuristic; conflicting observed titles disable it. GUID and name caches each retain up to 256 entries for the session. Interaction evidence learned with the subtitle also contributes to useful-NPC classification. Unresolved or restricted data omits the title. This does not suppress Blizzard's separate overhead label or establish that every titled NPC is useful. `/snp debug` reports the detected NPC subtitle.

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Blizzard target scaling and highlighting; decorative bar borders are removed
* Optional threat percentage at the right side of the health bar when WoW supplies a percentage its text API can display
* Optional pulsing cyan border around interruptible cast bars

## Global behavior

Open **Options → AddOns → Simple Nameplates → Appearance**, or type `/snp`. Category activation is on **Colors** (`/snp colors`). The global Active switch is beside the selected profile on Profiles. Hide critter/companion names is on Appearance; category activation is beside each category color on Colors.

The six categories are evaluated from top to bottom. The first matching category wins. Every category has an Active / Inactive thumb switch; category hiding is not available:

* **Active** applies its Priority Color and Simple Nameplates styling, including threat percentage when WoW supplies a displayable value.
* **Inactive** leaves Blizzard's display unchanged for that category. Restoration of previously styled restricted frames is retried when access returns, including while styling is disabled.

## Appearance Profiles and Settings

The settings pages are organized by purpose. Changes apply immediately and are saved between sessions.

| Page | Contents | Command |
| --- | --- | --- |
| About | Version, source, commands, presentation limits, and informational native-label swatches | `/snp about` |
| Profiles | Select, create, copy, rename, delete, and restore profiles; global Active switch | `/snp profiles` |
| Appearance | Fonts, sizing, layout, display effects, global critter/companion visibility, and Reset settings | `/snp appearance` or `/snp` |
| Colors | Profile colors, global category switches, profile cast-highlight switch, and Reset all colors | `/snp colors` |
| TRP3 | All global RP-name, title, and OOC options | `/snp trp3` |

Appearance and Colors each have a compact Selected profile control; profile-management actions are on Profiles. On Profiles, the selector sits farther left with an Active/Inactive thumb switch immediately to its right, matching the Colors-page controls. This switch enables styling globally for all characters and profiles, including the existing startup compatibility review. Appearance has **Reset settings** immediately beneath its profile selector, and global Hide critter/companion names farther down. Category switches sit beside their color swatches on Colors. The cast-highlight color has a matching profile-specific Active/Inactive switch, shared with Appearance. Reset all colors sits directly below the Colors profile selector; the bottom reset section and separate priority reset are removed. Changing profiles does not change these global switches. The former Behavior tab and its command are removed.

Profiles are shared account-wide, while each character remembers its active profile. **Create** starts with factory-default appearance settings; **Copy** duplicates the complete active profile. Profiles can be renamed and deleted, except **Default**, which is the permanent fallback. Deleting a profile moves characters assigned to it back to Default.

The editable bundled profiles are **Default** and **High Contrast**. High Contrast uses magenta `#FF00FF`, orange `#FF6600`, yellow `#FFFF00`, cyan `#00FFFF`, blue `#0066FF`, and white `#FFFFFF` for Priority Colors 1–6; and green `#00FF00` for interruptible casts. **Restore bundled profiles** resets both bundles and recreates High Contrast if it was deleted or renamed. Custom profiles are left untouched.

For Active categories, when the player is out of combat, only Attacking, Hostile, and Neutral use supported health bars. When the player is in combat, every entity with an accessible, supported health bar uses it. Visible bars receive the category color and names become white; entities without a supported bar use a colored floating name. Inactive categories keep Blizzard presentation. Unknown player combat state also falls back to Blizzard presentation.

`PresentationRules.lua` selects narrow rules for opposite-faction players in sanctuary, eligible PvP, and non-PvP contexts, with a shared fallback for other entities. Those rules do not change classification or infer PvP eligibility from the zone name. A sanctuary opponent normally uses a colored name out of combat and a supported bar during player combat; an eligible opponent uses a bar in both cases. Actual attackability and higher combat priorities still apply.

Simple Nameplates styles accessible nameplates supplied by the game; it has no supported direct styling path for separate native overhead world names. The entity types and world contexts above document where this prevents the requested presentation. Plate-visibility changes require the startup review's Apply choice. The former experimental overhead replacement option has been removed; its saved toggle is discarded without conversion. Previously captured original Blizzard values are restored, with failed or combat-restricted restoration retried and originals retained until success. Any WoW CVar still changed by the addon is restored when its option is disabled or styling is disabled.

**Hide critter and companion names** controls ordinary overhead names for noncombat critters and companions. Their prior WoW settings are restored when disabled.

Appearance groups presentation by combat state:

| Section | Controls and presentation |
| --- | --- |
| Fonts and sizing | Unit-name font, shared 8–36 point name size, and sanctuary font matching |
| Out of combat | Explains floating names and automatic NPC service titles; danger categories retain supported bars |
| In combat | Bar-name placement, threat font/display, and interruptible-cast highlighting; also applies whenever bars appear out of combat |

The sections use the same saved settings in both combat states. All TRP3 options, including the global long-title switch, are together on TRP3. Name-only titles can remain visible in combat if no supported health bar is available.

Headings use sentence case, labels use normal white text, and muted descriptions wrap below the relevant row. Controls share a common column. Individual resets follow their controls; section actions appear beneath the section's controls, with explicit scope. **Reset settings** restores every setting below it on Appearance: the selected profile's fonts, sizing, sanctuary font matching, name placement, threat display (on), and cast highlighting (off), plus global critter/companion hiding (off). It leaves profile selection, the Profiles-page Active switch, color values, global category activation, and TRP3 preferences unchanged. The cast-highlight switch on Colors reflects the same profile value.

**Match Blizzard font in sanctuaries** is enabled by default in each appearance profile. It uses Blizzard's localized native world-name font face for addon-controlled names and NPC/TRP3 titles throughout sanctuary areas, including names inside health bars. Turn it off to use the selected Name font everywhere. Outside sanctuaries, the selected font applies normally. Sizes, colors, positioning, and the separate threat font retain their existing behavior. This improves consistency with inaccessible opposite-faction PC labels; it does not make those labels editable or guarantee identical sizing and outlines.

The selected Name font defaults to WoW's built-in **Friz Quadrata**, the threat-percentage font defaults to **Arial Narrow**, names and threat percentages share the selected name size (21 points by default), and addon-styled text has no outline or shadow. Other standard Blizzard fonts are available without an external font library. Inside-bar names retain the full selected size. Names end three UI units before a displayed threat percentage; when threat is blank or disabled they extend to three units from the bar edge. Their health bars expand as needed to leave three UI units above and below the text, then return to Blizzard's original height when names move above the bar or Simple Nameplates styling is disabled. Name-only plates are unaffected by the placement setting; Friendly, NPC - Interactive, and NPC - Background use the same above/inside layout when their supported bars appear during combat. Blizzard-controlled overhead names have no nameplate frame, so their size and font remain controlled by the game.

Styled health and cast bars use flat fills and backgrounds without native decorative borders or shaded overlays. Cast spell and target labels keep their native font and size with outlines and shadows removed. Cast progress, spell icons, and non-interruptible shields are preserved; original artwork is restored when styling ends.

About contains three informational swatches for native opposite-faction PC sanctuary labels, interactive-NPC labels, and vendor-NPC labels. These describe native labels, not blanket unalterable entity categories; separate accessible NPC plates can be styled. The optional interruptible highlight is a pulsing, solid-color border without a dark outer edge around Blizzard's existing cast bar. It uses Blizzard's own interruptibility result, applies to casts and channels, and preserves Blizzard's normal non-interruptible shield treatment.

## TRP3 Integration

Open **Options → AddOns → Simple Nameplates → TRP3**, or type `/snp trp3`. The page begins with **Display TRP3 profile information**, which is disabled by default.

When enabled, Simple Nameplates can use a character's TRP3 roleplaying full name, put the short title before the name, show the long title on a separate line beneath the name, and mark out-of-character profiles. If the OOC option is enabled, `[OOC]` replaces the short title; IC profiles receive no marker. Long titles use 80% of the name size and are hidden whenever a bar is requested or observed shown. With an existing bar whose shown state is unavailable, the title is conservatively suppressed. Missing-bar entities can retain a title in combat.

Each field has its own toggle. To keep nameplates readable, roleplaying names are limited to 32 characters, short titles to 20, and long titles to 48; longer values end with an ellipsis. The normal WoW name is used whenever a cached TRP3 profile or selected field is unavailable. `TRP3.lua` keeps the optional profile access isolated, and Simple Nameplates continues to work normally without TRP3.

## Saved Settings

Look-and-feel settings are stored in named appearance profiles: Priority Colors, effect colors and toggles, fonts, sizing, placement, and threat display. Addon behavior and user preferences are global: styling enablement, category handling, Blizzard overhead-name controls, and TRP3 integration.

Saved settings are validated individually in their current locations. Recognized valid values are retained regardless of the saved schema marker; invalid and unknown settings are silently discarded, with defaults supplying missing values. The current category keys are `attacking`, `hostile`, `neutral`, `friendly`, `useful`, and `useless`. Obsolete category fields are discarded; valid current fields and unrelated settings remain. No old settings are renamed, relocated, or converted.

## About and Diagnostics

In Active categories, confirmed widget-only plates retain their widgets but do not draw an additional name or title. Ordinary NPC plates continue displaying names and service subtitles. This prevents duplicate addon labels when WoW supplies both plate types for one NPC. Friendly NPC nameplates must be enabled in WoW to supply ordinary friendly NPC plates; Simple Nameplates does not change that visibility setting.

`/snp debug` inspects your target; `/snp debug mouseover` inspects the hovered unit without targeting it. For a distant enemy, put `/snp debug mouseover` in a keybound macro and press the key while hovering over its body. The report identifies the inspected unit token and distinguishes missing plates from inaccessible ones. If nothing is under the pointer, it reports that no mouseover unit is available.

`/snp debug` limits detailed plate reports to the targeted unit, its direct nameplate lookup, and plates sharing its readable unit name. Same-name candidates are explicitly distinguished from identity matches, and each relevant frame is printed once. Unrelated nearby plates contribute only to scan counts, keeping duplicate presentations together in chat.

The main **Simple Nameplates** AddOns page is an About screen showing the addon version, author, category, license, source repository, and slash commands. The displayed version is read directly from the addon's `.toc` metadata so it cannot drift from the installed release. Click the source URL to open a copy-ready dialog.

`WorldContext.lua` caches zone/subzone/map, instance, territory/sanctuary, player faction, desired and active War Mode, PvP/FFA flags, player combat, and combat lockdown on relevant events, including while styling is disabled. Presentation reads this cache; location names do not determine permissions. `PresentationCapabilities.lua` assesses individual frames and regions and skips forbidden, unknown, or combat-restricted access.

Failed frame restorations release their temporary styling guard and remain queued for retry. Successful retries refresh addon presentation for the frame's current unit, including recycled plates. `/snp debug` reports the last restoration error while a failure remains pending; an absent blocked region is shown as `(none)`.

`Diagnostics.lua` owns read-only context and targeted-unit reporting. `/snp debug` reports the cached world context even without a target, keeping unknown values distinct from false. With a target, it reports presentation access status and observed health-bar visibility; missing nameplates do not establish whether Blizzard world names are displayed. Diagnostics inspects existing cast effects without creating frames or hooks. Type `/snp debug` with a unit targeted to report its detected type, reaction, faction, attackability, PvP and threat information, resulting priority category, category mode, display treatment, color, nameplate availability. It also reports the name text region's shown, effective visibility, alpha, and immediate-parent state, plus whether the interruptible highlight is enabled, the target's cast bar and icon were found, the visibility hook was installed, and the highlight is currently shown. The winning classification rule and its entity facts are reported together, followed by the presentation rule, action/reason, requested health-bar state, and title permission. Configured styling is distinguished from observed visibility; disabled styling and Inactive categories report Blizzard presentation. Restricted Midnight values are identified rather than inspected.

The diagnostic also enumerates existing nameplates and matches their unit tokens to the selected target, with readable GUIDs as a fallback when unit identity is unavailable. It reports the lookup source, matching-frame count, unknown identities, addon styling markers, cached name text and presentation revision, and the inside-name and long-title regions. These are read-only observations; a missing match does not prove that a world label belongs to Blizzard or another addon.

Every enumerated nameplate is also listed, even if it does not match the target, with its current unit token/name, displayed name, base/frame/text visibility, original unit token, and cached addon text. This helps identify stale labels on frames assigned to another unit. Inaccessible regions remain marked unavailable rather than read.

NPC tooltip diagnostics report separate GUID hyperlink and unit-token extraction results, the resolved title source, soft-interaction matches, widget-only flags, and the friendly NPC nameplate CVar. They distinguish unavailable APIs/data or identity, restricted fields, and parser rejection. For the target and each scanned NPC, the report lists up to twelve tooltip lines with numeric line type, left/right text, and field-access status. This helps verify live subtitle layouts without changing the visible tooltip or guessing that every second line is a title.

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

Simple Nameplates does not inspect or calculate with secret threat values. It passes percentages directly to WoW's supported text formatter, which can display secret values. Missing values or rejected formatting leave the percentage blank. Diagnostics reports whether threat display is disabled, unavailable, or displayed.

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so applying the shared red attacking color to PCs is best effort: it is used when WoW reports threat on you or your pet, or when the hostile player is targeting you, your pet, guardian, or minion.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Development

The [original staged refactor plan](docs/design/implementation-plan.md), [world-context runtime plan](docs/design/runtime-refactor-plan.md), and [source ownership guide](docs/design/settings-architecture.md) describe the Global behavior and appearance Profile boundaries. Run `lua tests/bar-artwork-smoke.lua`, `lua tests/core-behavior-smoke.lua`, `lua tests/settings-smoke.lua`, `lua tests/nameplates-smoke.lua`, `lua tests/nameplate-threat-smoke.lua`, `lua tests/world-context-smoke.lua`, `lua tests/entity-facts-smoke.lua`, and `lua tests/presentation-rules-smoke.lua` from the repository root for the local behavioral checks. Runtime phases 1–4 are implemented; phase 5 is client verification. The [live WoW checklist](docs/design/live-wow-verification.md) records integration checks that require the game client.

## AI Disclaimer

AI-assisted tools were used during the development of this project. The author reviewed and approved the resulting code and documentation and remains responsible for the project.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))

Licensed under the GNU General Public License v3.0 (GPL-3.0):

https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
