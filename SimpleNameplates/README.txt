Simple Nameplates
=================

PURPOSE
A deliberately simple standalone nameplate-color addon for World of Warcraft.

DEFAULT COLOR LANGUAGE
Green      = friendly NPC name
Light blue = friendly same-faction PC name
Yellow     = attackable but non-aggressive NPC health bar
Orange     = aggressive NPC or PvP-enabled opposing PC health bar
Red        = PC or NPC attacking you or one of your controlled units
Periwinkle blue = Blizzard overhead-name color; locked and not addon-editable

HOW IT WORKS
Simple Nameplates no longer draws its own replacement nameplate. It keeps the
normal Blizzard Midnight nameplate and recolors its existing health bar and
name. Blizzard remains responsible for creating each nameplate and for health
depletion, casting, channels, target treatment, classification, and the other
normal nameplate behavior. Even when WoW is configured to show friendly,
enemy, and always-visible nameplates, it may not create a frame for every unit.

DISPLAYED
- Normal Blizzard unit name and health bar
- Normal health depletion as the unit takes damage
- Normal Blizzard cast/channel bar and spell information
- Normal Blizzard target treatment
- Optional threat percentage added at the right side of the health bar when Midnight
  exposes a non-secret threat percentage
- Optional attacking-color glow around attacking PC and NPC health bars

COLOR SETTINGS
Open Options > AddOns > Simple Nameplates > Colors, or type /snp. Five colors
can be changed and apply immediately. Each editable row says whether its color
appears on the name or health bar and has its own Reset button. A locked row
explains Blizzard-controlled periwinkle-blue overhead names. The panel also
includes Reset Colors, a master styling switch, and a Glow attacking
units toggle, disabled by default. The glow uses the configured Attacking color
and applies to attacking PCs and NPCs. Units without health bars use the
relationship color for their name. When a bar is present, the name stays white
for contrast and the bar carries the relationship color. Blizzard's overhead
names for non-attackable opposing PCs and player-controlled pets, guardians,
totems, and minions cannot be recolored because they are not addon-accessible
nameplate frames. Enabling every relevant nameplate setting cannot force WoW
to create those missing frames.

TEXT SETTINGS
Open Options > AddOns > Simple Nameplates > Text, or type /snp text. Choose a
unit-name font, a separate threat-percentage font, whether available threat
percentages are shown, and whether names appear above or inside visible health
bars. Both fonts default to Arial Narrow with a normal outline. Inside-bar names
shrink to fit the existing bar and reserve space for threat percentage. The bar
is not resized. Friendly name-only plates and Blizzard-controlled overhead
names without nameplate frames are unaffected by name placement.

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

DIAGNOSTICS
Target a unit and type /snp debug to report its detected type, reaction,
faction, attackability, PvP and threat information, resulting state, display
treatment, and color. Restricted Midnight values are identified, not inspected.

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
complete threat table, so applying the shared red attacking color to PCs is
best effort. It is used when WoW reports threat on you or your pet, or when the
hostile player is targeting you, your pet, guardian, or minion.

CHANGELOG
1.0.46
- Renamed Blizzard's fixed overhead-name color from lavender to periwinkle blue.

1.0.45
- Clarified that addons can request nameplates but cannot force WoW to create them.
- Simplified the attacking-glow label and corrected overhead-name descriptions.

1.0.44
- Changed the optional glow into an attacking-state indicator for PCs and NPCs.
- The glow now always uses the configured Attacking color.

1.0.43
- Consolidated hostile NPCs and PvP-enabled opposing PCs into one orange setting.
- Consolidated attacking PCs and NPCs into one red combat-override setting.
- Added a locked informational row for Blizzard-controlled periwinkle-blue overhead names.
- Migrates customized NPC hostile and attacking colors and removes obsolete PC-specific colors.

1.0.42
- Removed the nonfunctional global overhead-name font setting and its saved value.

1.0.41
- Prevented recursive database initialization during legacy CVar restoration.
- Clears obsolete replacement-name state before restoring its saved WoW settings.

1.0.40
- Delayed overhead-font initialization until saved variables are available.
- Added a safe Blizzard-font fallback for missing or invalid saved selections.

1.0.39
- Added a global font selector for Blizzard's engine-drawn overhead unit names.
- Preserves Blizzard's locale-appropriate font by default and warns when a full restart may be needed.

1.0.38
- Removed the ineffective replacement-name toggle and ongoing CVar enforcement.
- Restores saved WoW nameplate settings once for users who enabled the removed option.
- Retained nameplate-frame availability in /snp debug for diagnosing engine-drawn names.

1.0.37
- Made replacement names persistent by enabling Always Show Nameplates and forcing nameplate names.
- Added nameplate-frame availability to /snp debug output.

1.0.36
- Kept ordinary-name settings enabled because they also control whether nameplate text can appear.
- Restores ordinary-name settings previously captured and changed by version 1.0.35.

1.0.35
- Added an optional, reversible replacement for Blizzard's uncolorable overhead player and minion names.

1.0.34
- Replaced the screenshot-sampled default values with a clean web-safe RGB palette.

1.0.33
- Neutralized Blizzard's additional vertex tint so configured name colors display accurately.
- Updated all eight default colors to match the documented settings palette.

1.0.32
- Added a master styling switch that restores Blizzard nameplates and friendly-color settings when disabled.
- Added /snp debug diagnostics for the current target.
- Labeled every color row as a colored name or health bar and added individual reset buttons.
- Added a threat-percentage display toggle, enabled by default.
- Clarified that PC glow applies only to PCs with visible health bars.

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
- Keeps non-PvP opposite-faction players name-only and periwinkle blue.
- Repairs Blizzard name-color overwrites with a lightweight reconciliation.

1.0.23
- Fresh standalone release with no previous-version or legacy-settings handling.
- Warns when another enabled third-party "plate" addon may conflict.
- Uses /snp for settings and About commands.
