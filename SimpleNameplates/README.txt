Simple Nameplates
=================

PURPOSE
A deliberately simple standalone nameplate-color addon for World of Warcraft.

DEFAULT COLOR LANGUAGE
Green      = friendly NPC
Yellow     = unfriendly NPC / attackable but non-aggressive
Orange     = hostile NPC / will attack but not attacking your group
Red        = NPC attacking you, a pet, or a group member
Light blue = friendly same-faction PC
Periwinkle = unfriendly opposite-faction PC
Purple     = hostile PvP-enabled opposite-faction PC
Magenta    = hostile PC attacking your group (best effort)

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

COLOR SETTINGS
Open Options > AddOns > Simple Nameplates > Colors, or type /snp. All eight
colors can be changed and apply immediately. The panel includes a Reset Colors
button. The old /esnp command remains available as an alias.

ABOUT
The main Simple Nameplates AddOns page shows the version, author,
category, GPL-3.0 license, source repository, and slash commands. The version
is read directly from the addon's TOC metadata. Click the source URL for a
copy-ready dialog. Type /snp about to open this page directly.

INSTALL
1. Exit WoW.
2. Remove the old EllesmereUISimpleNameplates folder if it is installed.
3. Extract SimpleNameplates into _retail_/Interface/AddOns/.
4. Disable "EllesmereUI Nameplates" in the AddOns list.
5. Enable "Simple Nameplates".
6. Log in.

WoW stores saved variables under the addon folder name. Upgrading from the old
EllesmereUI-dependent addon therefore resets custom colors to their defaults.
Set them again once in Options > AddOns > Simple Nameplates > Colors.

CONFLICT WARNING
If the standard EllesmereUI Nameplates addon is enabled, Simple Nameplates
shows a startup warning with a Disable & Reload button.

NOTES
Midnight may make some threat information secret. Simple Nameplates does not
attempt to inspect secret values. Threat percentage is shown only when WoW
allows the value to be read.

NPC aggro uses WoW's threat information. PvP does not expose an equally
complete threat table, so the attacking-PC color is best effort. It is used
when WoW reports threat or the hostile player is targeting you, your pet, or
a member of your group.

CHANGELOG
2.0.22
- Made Simple Nameplates standalone; EllesmereUI is no longer required.
- Renamed the installed addon folder and TOC to SimpleNameplates.
- Uses SimpleNameplatesDB; Version 1 custom colors must be selected again.
- Added /snp; /esnp remains available as an alias.

1.0.21
- Adopted major.minor.build versioning based on the Git commit count.

0.3.2
- Split the addon into focused core, nameplate, and settings modules without
  changing its behavior.

0.3.1
- Added an About screen modeled on RP Emote Menu.
- About reads its version directly from the addon TOC metadata.
- Added author, license, website, and category information.
- Moved color pickers to a Colors child page.
- Added /esnp about; /esnp still opens Colors.

0.3.0
- Added separate colors for four NPC and four player-character states.
- Added a standard WoW AddOns panel with eight color pickers and reset.
- Added /esnp to open the color settings.
- Safely handles restricted Midnight PvP and unit-comparison values.
- Player-controlled pets, guardians, minions, and vehicles use PC colors.

0.2.0
- Removed the custom overlay nameplate that caused double nameplates.
- Skin/recolor Blizzard's existing nameplate instead.
- Preserve Blizzard health depletion and cast/channel bars.
- Simplified all reaction/threat coloring to green/yellow/orange/red.
- Retained startup conflict warning for EllesmereUI Nameplates.

0.1.1
- Added startup conflict warning for EllesmereUI Nameplates.

0.1.0
- Initial test implementation.
