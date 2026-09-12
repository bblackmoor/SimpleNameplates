EllesmereUI Simple Nameplates 0.2.0
===================================

PURPOSE
A deliberately simple alternative nameplate-color module for EllesmereUI.

COLOR LANGUAGE
Green  = friendly / you cannot fight them
Yellow = neutral / attackable but non-aggressive
Orange = hostile / not currently attacking you
Red    = attacking you / you have aggro

HOW 0.2 WORKS
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

CHANGELOG
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
