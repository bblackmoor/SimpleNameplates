EllesmereUI Simple Nameplates 0.1.0
===================================

PURPOSE
A deliberately simple alternative to EllesmereUI Nameplates.

COLOR LANGUAGE
Green  = friendly / you cannot attack them
Yellow = neutral / attackable but not aggressive
Orange = hostile / not currently attacking you
Red    = aggro on you

DISPLAYED
- Unit name
- Health bar
- Health percentage (when WoW exposes the value)
- Threat percentage (when WoW exposes a non-secret value)
- Cast bar and spell name
- Gray cast bar for non-interruptible casts
- Subtle target highlight

INSTALL
1. Exit WoW.
2. Extract EllesmereUISimpleNameplates into _retail_/Interface/AddOns/.
3. Disable "EllesmereUI Nameplates" in the AddOns list.
4. Enable "EllesmereUI Simple Nameplates" and EllesmereUI.
5. Log in.

IMPORTANT
Do not run EllesmereUI Nameplates and EllesmereUI Simple Nameplates together.
They both own the same Blizzard nameplate frames.

This is intentionally a first test build. It has no options panel yet. The
point of 0.1.0 is to validate the four-state reaction/threat logic in actual
Midnight gameplay before adding configuration complexity.

0.1.1: Added a startup conflict warning when the standard EllesmereUI Nameplates addon is enabled. The warning can disable it and reload the UI automatically.
