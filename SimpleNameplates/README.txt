Simple Nameplates
=================

PURPOSE
A deliberately simple standalone nameplate-color addon for World of Warcraft.

DEFAULT COLOR LANGUAGE
Light blue = friendly NPC
Yellow     = unfriendly NPC / attackable but non-aggressive
Orange     = hostile NPC / will attack but not attacking you or your controlled units
Red        = NPC attacking you, your pet, guardian, or minion
Green      = friendly PC, including your pets, guardians, and minions
Yellow     = opposite-faction PC when neither side can attack (name only)
Yellow     = attackable opposite-faction PC not attacking you or your controlled units
Red        = PC attacking you, your pet, guardian, or minion (best effort)

HOW IT WORKS
Simple Nameplates no longer draws its own replacement nameplate. It keeps the
normal Blizzard Midnight nameplate and recolors its existing health bar and
name. This means Blizzard remains responsible for health depletion, casting,
channels, target treatment, classification, and the other normal nameplate
behavior.

DISPLAYED
- Normal Blizzard unit name and health bar
- Normal health depletion as the unit takes damage
- Normal Blizzard cast/channel bar and spell information
- Normal Blizzard target treatment
- Threat percentage added at the right side of the health bar when Midnight
  exposes a non-secret threat percentage
- Optional same-color glow around PC health bars

COLOR SETTINGS
Open Options > AddOns > Simple Nameplates > Colors, or type /snp. All eight
colors can be changed and apply immediately. The panel includes a Reset Colors
button and a Glow PC health bars toggle, disabled by default. Units without
health bars use the relationship color for their name. When a bar is present,
the name stays white for contrast and the bar carries the relationship color.

TEXT SETTINGS
Open Options > AddOns > Simple Nameplates > Text, or type /snp text. Choose a
unit-name font, a separate threat-percentage font, and whether names appear
above or inside visible health bars. Both fonts default to Arial
Narrow with a normal outline. Inside-bar names shrink to fit the existing bar
and reserve space for threat percentage. The bar is not resized. Name-only
friendly and unattackable plates are unaffected by name placement.

TRP3 SETTINGS
Open Options > AddOns > Simple Nameplates > TRP3, or type /snp trp3. The page
starts with a Display TRP3 profile information toggle, disabled by default.
When enabled, separate options can display the TRP3 roleplaying full name, a
short title before the name, [OOC] in place of the short title, and a full title
on a separate line above the name. IC profiles receive no status marker. Full
titles always remain outside the health bar. The WoW name is used when profile
information is unavailable. Simple Nameplates continues to work without TRP3.

ABOUT
The main Simple Nameplates AddOns page shows the version, author,
category, GPL-3.0 license, source repository, and slash commands. The version
is read directly from the addon's TOC metadata. Click the source URL for a
copy-ready dialog. Type /snp about to open this page directly.

INSTALL
1. Exit WoW.
2. Extract SimpleNameplates into _retail_/Interface/AddOns/.
3. Enable "Simple Nameplates".
4. Log in.

CONFLICT WARNING
At login, Simple Nameplates warns if another enabled third-party addon has
"plate" in its name or title. Blizzard's internal addons are ignored. Running
multiple nameplate addons can cause competing colors or duplicate nameplates.

NOTES
Midnight may make some threat information secret. Simple Nameplates does not
attempt to inspect secret values. Threat percentage is shown only when WoW
allows the value to be read.

NPC aggro uses WoW's threat information. PvP does not expose an equally
complete threat table, so the attacking-PC color is best effort. It is used
when WoW reports threat on you or your pet, or when the hostile player is
targeting you, your pet, guardian, or minion.

CHANGELOG
1.0.31
- Reduced attack detection to the player and the player's pets, guardians, and minions.
- Health events now update only health instead of reclassifying and restyling the plate.
- Coalesced duplicate event refreshes and narrowed Blizzard hooks to the visual they repair.
- Replaced repeated name rewriting with a slower cached drift check.
- Reduced new-nameplate delayed refreshes and refreshes TRP3 text from profile events.

1.0.30
- Reset the standalone release line to 1.0.(build number).
- Updated the Git hook to generate future 1.0 build versions automatically.

1.0.29
- Changed friendly NPCs to light blue and friendly PCs and minions to green.
- Uses yellow for attackable non-aggressive NPCs and non-attacking PCs.
- Classifies opposing PCs by actual two-way attackability, not inferred War Mode.
- Recognizes the player's temporary guardians and minions as friendly PCs.
- Added an optional same-color glow around PC health bars, off by default.

1.0.28
- Left-aligned names and TRP3 full titles with the health bar.
- Kept threat percentages right-aligned with the health bar.

1.0.27
- Added optional TRP3 roleplaying full names with WoW-name fallback.
- Added optional short titles before names.
- Added [OOC] in place of short titles; IC profiles receive no marker.
- Added optional full titles above names and always outside health bars.

1.0.26
- Added an optional TRP3.lua integration skeleton using public TRP3 APIs.
- Added a TRP3 settings page with a master toggle, disabled by default.
- Added TRP3 availability status and /snp trp3.
- No TRP3 profile fields are displayed yet.

1.0.25
- Added separate unit-name and threat-font selectors.
- Changed both default fonts to Arial Narrow with a normal outline.
- Added Above Bar and Inside Bar hostile-name placement.
- Inside-bar names shrink to fit and reserve space for threat percentage.
- Added /snp text.

1.0.24
- Distinguishes player factions independently of sanctuary reaction.
- Keeps non-PvP opposite-faction players name-only and periwinkle.
- Repairs Blizzard name-color overwrites with a lightweight reconciliation.

1.0.23
- Fresh standalone release with no previous-version or legacy-settings handling.
- Warns when another enabled third-party "plate" addon may conflict.
- Uses /snp for settings and About commands.
