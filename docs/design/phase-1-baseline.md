# Phase 1: existing behavior and integration checks

Status: Core smoke checks implemented and run; live WoW checks remain pending. This is characterization only. No runtime Lua or saved-data schema changed.

## Automated Core behavior

Run from the repository root with a standard Lua interpreter:

```sh
lua tests/core-behavior-smoke.lua
```

The same script was run locally using `luatex --luaonly tests/core-behavior-smoke.lua`; result: `Core behavior smoke: passed`.

The stub covers:

- Fresh version-2 defaults, six-category behavior default, TRP3 default, and Default/High Contrast selection.
- Independent character Profile selections, create/copy with independent colors, rename propagation, deletion fallback, Default protection, duplicate names, and bundled restore.
- Valid schema-2 settings preserved across a fresh Core load; malformed individual settings fall back; incompatible schema is ignored.
- Managed name-CVar capture, overlapping hide/replacement claims, restoration when the last claim ends, persistence and restoration across module reload, and combat deferral until `ApplyPendingManagedNameSettings`.
- Phase 3 extensions: failed and silently refused restoration retain originals for retry; explicit restore during combat waits; friendly class-color restoration retries and defers in combat.

The test loads `Defaults.lua`, `Core.lua`, `ManagedNames.lua`, and `Database.lua` with simulated WoW globals and CVar storage, then checks all .toc module paths/order and Lua syntax. It is intentionally a behavioral contract, not an implementation snapshot.

## Entry points to preserve

| Entry point | Current location | Expected effect |
| --- | --- | --- |
| `ADDON_LOADED` | Nameplates.lua `HandleEvent` | `EnsureDB` for this addon |
| `PLAYER_LOGIN` | Nameplates.lua `HandlePlayerLogin` | Apply managed name settings; register settings and TRP3 callbacks; refresh visible plates when enabled |
| `PLAYER_REGEN_ENABLED` | Nameplates.lua `HandleEvent` | Apply deferred CVar settings and queue refresh |
| `CVAR_UPDATE` | Nameplates.lua `HandleCVarUpdate` | Reapply managed/friendly class settings as needed; queue refresh |
| `NAME_PLATE_UNIT_ADDED` | Nameplates.lua `HandleNameplateEvent` | Refresh unit immediately and after 0.5 seconds |
| Settings registration | Settings.lua `RegisterSettingsPanel` | About, Behavior, Appearance, TRP3; one-time registration |
| `/snp` commands | Settings.lua `RegisterSettingsPanel` | Behavior default, About/Appearance/Colors/TRP3 routes, Debug |
| Profile/appearance control callbacks | SettingsProfiles.lua / SettingsAppearance.lua | Refresh selected controls and `ns.RefreshAll` |
| `RefreshAll` / `RestoreAll` | Nameplates.lua | Update or restore visible nameplates |

## Live WoW checks before marking the full phase complete

The consolidated Phase 6 integration matrix is in [live-wow-verification.md](live-wow-verification.md). The original characterization checks remain below for historical context.

- [ ] Settings appear once after login; About, Behavior, Appearance, and TRP3 open; `/snp`, `/snp colors`, `/snp trp3`, and `/snp debug` route correctly.
- [ ] Different characters independently select Default and High Contrast, then keep those selections across reload/logout.
- [ ] A Profile edit refreshes visible names, text placement inside a health bar, threat percent, and cast highlight; restoring bundled Profiles returns factory colors.
- [ ] Active/inactive/hide category changes show the correct Blizzard-permitted effect, and restoring or disabling styling returns captured Blizzard CVar values.
- [ ] A mode change during combat is applied after combat without taint/secret-value errors.
- [ ] TRP3 cached names and title fallback work with and without Total RP 3 installed.
- [ ] Fixed Blizzard-controlled overhead names remain described accurately; inspect both combat plates and name-only units.

The stub cannot emulate Blizzard's secure execution, secret values, actual frame templates, or settings rendering. Record in-client results here as they become available. Do not mark these boxes solely because the Lua smoke script passes.
