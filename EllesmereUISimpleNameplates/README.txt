EllesmereUI Simple Nameplates 0.3.0
===================================

PURPOSE
A deliberately simple alternative nameplate-color module for EllesmereUI.

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
Open Options > AddOns > EllesmereUI Simple Nameplates, or type /esnp. All
eight colors can be changed and apply immediately. The panel includes a
Reset Colors button.

INSTALL
1. Exit WoW.
2. Extract EllesmereUISimpleNameplates into _retail_/Interface/AddOns/.
3. Disable "EllesmereUI Nameplates" in the AddOns list.
4. Enable "EllesmereUI Simple Nameplates" and EllesmereUI.
5. Log in.

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
