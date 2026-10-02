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
| 5 | Useful | Light blue | Interactive NPC: name out of combat; supported bar in combat |
| 6 | Useless | Gray | Remaining entities: name out of combat; supported bar in combat |
| — | Interruptible cast | Cyan | Optional pulsing cast-bar border |
| — | Blizzard-controlled overhead names | Locked | Some opposing PCs, minions, interactive NPCs, and vendors |

## How It Works

Simple Nameplates does **not** draw its own replacement nameplates.

Instead, it keeps Blizzard's normal Midnight nameplates and recolors their existing health bars and names. Blizzard remains responsible for creating each nameplate and for health depletion, casting, channels, target treatment, and other standard nameplate behavior. Simple Nameplates classifies addon-accessible units into its six Priority Colors.

Entity observations are collected separately in `EntityFacts.lua`, then the first matching priority wins. Faction, player control/ownership, directional attackability, interaction evidence, and unknown values remain separate facts. Thus an opposing player in sanctuary can be Friendly while retaining its opposite-faction identity; a hostile interactive NPC uses the higher combat priority. A PvP flag or desired War Mode alone does not establish an eligible opponent. Readable attackability determines eligibility, including duels; contextual sanctuary evidence prevents a flag-only inference.

Appearance profiles also have three independent sanctuary colors: same-faction players default to sky blue (`#87CEEB`), useful NPCs to light grey (`#D3D3D3`), and other NPCs to medium grey (`#999999`). These apply only to their non-danger categories in sanctuaries; combat danger colors take priority. Opposite-faction players retain their existing colors. Each sanctuary color can be edited or reset, and Reset Colors includes all three. Existing profiles receive the new defaults for missing values. Colors affect only addon-accessible nameplates; Blizzard-controlled overhead names remain unchanged.

Useful currently means readable `UnitIsInteractable` evidence on an NPC. This is not a permanent vendor/service catalog, and friendliness or overhead-name color alone is insufficient. Missing, failed, or secret observations remain unknown. Useless is the remaining-entity fallback, not a claim that unknown entities offer no interaction.

This avoids duplicate nameplates and preserves the normal Blizzard nameplate functionality.

Even when WoW is configured to show friendly, enemy, and always-visible nameplates, it may not create a nameplate for every unit. If Blizzard supplies no addon-accessible nameplate frame, Simple Nameplates has nothing it can recolor.

## What's Displayed

NPC subtitles such as `<Voidforge Steward>` are read first from structured GUID hyperlink tooltip data, then from unit-token tooltip data and the existing subtitle caches and displayed beneath addon-controlled name-only NPC labels at 80% of the name size, in the same color. They do not require TRP3 and are hidden with visible health bars. The reader accepts a single plain subtitle between the typed unit-name line and a typed level line or plain level text verified against WoW's localized template and the unit's level. When a nameplate tooltip omits its subtitle, the addon first uses exact NPC GUID matches. If GUID matching cannot resolve it, a matching readable NPC name can supply an unambiguous subtitle learned from a fuller target, mouseover, or soft-interaction tooltip during normal rendering. This name association is a heuristic; conflicting observed titles disable it. GUID and name caches each retain up to 256 entries for the session. Interaction evidence learned with the subtitle also contributes to useful-NPC classification. Unresolved or restricted data omits the title. This does not suppress Blizzard's separate overhead label or establish that every titled NPC is useful. `/snp debug` reports the detected NPC subtitle.

* Normal Blizzard unit name and health bar
* Normal health depletion as the unit takes damage
* Normal Blizzard cast/channel bar and spell information
* Normal Blizzard target treatment
* Optional threat percentage at the right side of the health bar when Midnight exposes a non-secret threat percentage
* Optional pulsing cyan border around interruptible cast bars

## Behavior Settings

Open **Options → AddOns → Simple Nameplates → Behavior**, or type `/snp`. This page contains global addon behavior and user preferences: the master styling toggle, category handling, and Blizzard overhead-name controls.

The six categories are evaluated from top to bottom. The first matching category wins. Every category has an Active / Inactive behavior selector; category hiding is not available:

* **Active** applies its Priority Color and Simple Nameplates styling, including threat percentage when Midnight exposes a readable value.
* **Inactive** leaves Blizzard's display unchanged for that category. Restoration of previously styled restricted frames is retried when access returns, including while styling is disabled.

## Appearance Profiles and Settings

Open **Options → AddOns → Simple Nameplates → Appearance**, or type `/snp appearance`. This page contains every profile-controlled setting: profile management, text and layout, Priority Colors, Blizzard-controlled color information, and visual effects. Changes apply immediately and are saved between sessions.

Profiles are shared account-wide, while each character remembers its active profile. **Create** starts with factory-default appearance settings; **Copy** duplicates the complete active profile. Profiles can be renamed and deleted, except **Default**, which is the permanent fallback. Deleting a profile moves characters assigned to it back to Default.

The editable bundled profiles are **Default** and **High Contrast**. High Contrast uses magenta `#FF00FF`, orange `#FF6600`, yellow `#FFFF00`, cyan `#00FFFF`, blue `#0066FF`, and white `#FFFFFF` for Priority Colors 1–6; and green `#00FF00` for interruptible casts. **Restore Bundled Profiles** resets both bundles and recreates High Contrast if it was deleted or renamed. Custom profiles are left untouched.

For Active categories, when the player is out of combat, only Attacking, Hostile, and Neutral use supported health bars. When the player is in combat, every entity with an accessible, supported health bar uses it. Visible bars receive the category color and names become white; entities without a supported bar use a colored floating name. Inactive categories keep Blizzard presentation. Unknown player combat state also falls back to Blizzard presentation.

`PresentationRules.lua` selects narrow rules for opposite-faction players in sanctuary, eligible PvP, and non-PvP contexts, with a shared fallback for other entities. Those rules do not change classification or infer PvP eligibility from the zone name. A sanctuary opponent normally uses a colored name out of combat and a supported bar during player combat; an eligible opponent uses a bar in both cases. Actual attackability and higher combat priorities still apply.

Blizzard's separate overhead world names are not addon-accessible and cannot be recolored directly. Simple Nameplates leaves player, NPC, and minion world names and nameplate-visibility settings under Blizzard control. It styles only accessible nameplates supplied by the game. The former experimental overhead replacement option has been removed; its saved toggle is discarded without conversion. Previously captured original Blizzard values are restored, with failed or combat-restricted restoration retried and originals retained until success. Any WoW CVar still changed by the addon is restored when its option is disabled or styling is disabled.

**Hide critter and companion names** controls ordinary overhead names for noncombat critters and companions. Their prior WoW settings are restored when disabled.

The Text and Layout section provides:

* The unit-name font.
* A shared 8–36 point size for addon-controlled floating names and names above health bars.
* A separate threat-percentage font.
* Whether names appear above or inside visible health bars.
* Whether available threat percentages are displayed.

Both fonts default to WoW's built-in **Arial Narrow** with a normal outline, and names default to 12 points. Other standard Blizzard fonts are available without an external font library. Inside-bar names use 80% of the selected size, rounded to the nearest point. Their health bars resize to leave two UI units above and below the text, then return to Blizzard's original height when names move above the bar or Simple Nameplates styling is disabled. Name-only plates are unaffected by the placement setting; Friendly, Useful, and Useless use the same above/inside layout when their supported bars appear during combat. Blizzard-controlled overhead names have no nameplate frame, so their size and font remain controlled by the game.

Three locked color rows document Blizzard-controlled periwinkle-blue opposing-player/minion names, yellow interactive-NPC names, and green vendor-NPC names. The optional interruptible highlight is a pulsing, solid-color border with a dark outer edge around Blizzard's existing cast bar. It uses Blizzard's own interruptibility result, applies to casts and channels, and preserves Blizzard's normal non-interruptible shield treatment.

## TRP3 Integration

Open **Options → AddOns → Simple Nameplates → TRP3**, or type `/snp trp3`. The page begins with **Display TRP3 profile information**, which is disabled by default.

When enabled, Simple Nameplates can use a character's TRP3 roleplaying full name, put the short title before the name, show the long title on a separate line beneath the name, and mark out-of-character profiles. If the OOC option is enabled, `[OOC]` replaces the short title; IC profiles receive no marker. Long titles use 80% of the name size and are hidden whenever a bar is requested or observed shown. With an existing bar whose shown state is unavailable, the title is conservatively suppressed. Missing-bar entities can retain a title in combat.

Each field has its own toggle. To keep nameplates readable, roleplaying names are limited to 32 characters, short titles to 20, and long titles to 48; longer values end with an ellipsis. The normal WoW name is used whenever a cached TRP3 profile or selected field is unavailable. `TRP3.lua` keeps the optional profile access isolated, and Simple Nameplates continues to work normally without TRP3.

## Saved Settings

Look-and-feel settings are stored in named appearance profiles: Priority Colors, effect colors and toggles, fonts, sizing, placement, and threat display. Addon behavior and user preferences are global: styling enablement, category handling, Blizzard overhead-name controls, and TRP3 integration.

Saved settings are validated individually in their current locations. Recognized valid values are retained regardless of the saved schema marker; invalid and unknown settings are silently discarded, with defaults supplying missing values. The current category keys are `attacking`, `hostile`, `neutral`, `friendly`, `useful`, and `useless`. Obsolete category fields are discarded; valid current fields and unrelated settings remain. No old settings are renamed, relocated, or converted.

## About and Diagnostics

In Active categories, confirmed widget-only plates retain their widgets but do not draw an additional name or title. Ordinary NPC plates continue displaying names and service subtitles. This prevents duplicate addon labels when WoW supplies both plate types for one NPC. Friendly NPC nameplates must be enabled in WoW to supply ordinary friendly NPC plates; Simple Nameplates does not change that visibility setting.

`/snp debug` limits detailed plate reports to the targeted unit, its direct nameplate lookup, and plates sharing its readable unit name. Same-name candidates are explicitly distinguished from identity matches, and each relevant frame is printed once. Unrelated nearby plates contribute only to scan counts, keeping duplicate presentations together in chat.

The main **Simple Nameplates** AddOns page is an About screen showing the addon version, author, category, license, source repository, and slash commands. The displayed version is read directly from the addon's `.toc` metadata so it cannot drift from the installed release. Click the source URL to open a copy-ready dialog.

`WorldContext.lua` caches zone/subzone/map, instance, territory/sanctuary, player faction, desired and active War Mode, PvP/FFA flags, player combat, and combat lockdown on relevant events, including while styling is disabled. Presentation reads this cache; location names do not determine permissions. `PresentationCapabilities.lua` assesses individual frames and regions and skips forbidden, unknown, or combat-restricted access.

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

Simple Nameplates does not attempt to inspect secret values. Threat percentage is displayed only when WoW allows the value to be read.

NPC aggro uses WoW's threat information. PvP does not provide an equally complete threat table, so applying the shared red attacking color to PCs is best effort: it is used when WoW reports threat on you or your pet, or when the hostile player is targeting you, your pet, guardian, or minion.

See [CHANGELOG.md](CHANGELOG.md) for release history.

## Development

The [original staged refactor plan](docs/design/implementation-plan.md), [world-context runtime plan](docs/design/runtime-refactor-plan.md), and [source ownership guide](docs/design/settings-architecture.md) describe the Global behavior and appearance Profile boundaries. Run `lua tests/core-behavior-smoke.lua`, `lua tests/settings-smoke.lua`, `lua tests/nameplates-smoke.lua`, `lua tests/world-context-smoke.lua`, `lua tests/entity-facts-smoke.lua`, and `lua tests/presentation-rules-smoke.lua` from the repository root for the local behavioral checks. Runtime phases 1–4 are implemented; phase 5 is client verification. The [live WoW checklist](docs/design/live-wow-verification.md) records integration checks that require the game client.

## AI Disclaimer

AI-assisted tools were used during the development of this project. The author reviewed and approved the resulting code and documentation and remains responsible for the project.

---

Copyright © 2026 Brandon Blackmoor ([bblackmoor@blackgate.net](mailto:bblackmoor@blackgate.net))

Licensed under the GNU General Public License v3.0 (GPL-3.0):

https://www.gnu.org/licenses/gpl-3.0.en.html

Source: https://github.com/bblackmoor/SimpleNameplates
