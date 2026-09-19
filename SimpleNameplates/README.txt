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
button.

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
when WoW reports threat or the hostile player is targeting you, your pet, or
a member of your group.

CHANGELOG
2.0.23
- Fresh standalone release with no previous-version or legacy-settings handling.
- Warns when another enabled third-party "plate" addon may conflict.
- Uses /snp for settings and About commands.
