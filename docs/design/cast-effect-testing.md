# Interruptible-effect testing

Current for 1.0.221, 2026-10-08. Local smoke tests cover rendering and callbacks; these steps verify the actual WoW client. The effect surrounds the enemy's **nameplate cast bar**, not the target-frame cast bar or health bar.

## A simple enemy to try

Use a **Kobold Geomancer in or around Jasperlode Mine, Elwynn Forest**, east of Goldshire. The [Warcraft Wiki entry](https://warcraft.wiki.gg/wiki/Kobold_Geomancer) records that location and its Fireball cast. This is a practical low-level caster to try from an Alliance character; confirm the actual current-client cast with your interrupt rather than treating the location/spell listing as live proof of interruptibility. Avoid other nameplate addons for this test.

1. Open `/snp colors` and select the profile used by this character. Under Cast highlight color, turn **Active** on, choose **Solid border** initially, and use a bright color. Confirm the labeled **Effect preview** shows that border. The preview runs even while Inactive and does not classify a real cast.
2. Find one Geomancer, keep its enemy nameplate visible and stay within cast range. At high level, engage without damaging it if possible (a taunt, if available); stop attacks and dismiss attacking pets/minions so it survives. Stay out of melee reach while allowing it to cast.
3. Let one Fireball finish. Watch the small nameplate cast bar beneath its health bar. Repeat and interrupt another Fireball with your actual interrupt to confirm that particular cast can be interrupted. A stun or displacement alone does not establish interruptibility.
4. Repeat with the other effects: Pulsing border, Soft border, Marching ants and Spell-alert glow. The indicator should stop at cast end/interruption, hide for noninterruptible casts, and remain absent while Active is off. Switching profiles changes both activation and effect.
5. If the preview works but the real cast has no effect, target the caster and capture `/snp debug` **while the cast is running**. A keybound macro helps capture the short cast:

```text
/snp debug
```

Include the Interruptible highlight line, Presentation access and cast-bar availability. A report after the cast ends correctly describes a hidden/inactive cast and cannot diagnose its preceding state. Repeat with a different real caster if this enemy's current cast is unavailable or cannot be interrupted.

## Distinguish rendering from detection

| Observation | What to check next |
| --- | --- |
| No effect in preview | Selected renderer, library/template availability, color and UI scale |
| Preview works, real effect absent | Active for the selected profile, accessible nameplate cast bar, running cast, resolved state/source and native icon/shield hooks |
| Debug says interruptibility unavailable | Capture during a longer active cast; unknown state retries rather than claiming the cast is interruptible |
| Renderer differs from selection | Debug renderer error; unavailable DF method/template falls back to the pulse |
| Target-frame bar glows nowhere | The effect belongs to the separate enemy nameplate cast bar |

## Implementation and acceptance

| Choice | Implementation |
| --- | --- |
| Pulsing border | Existing addon-owned four-edge alpha animation |
| Solid border | Bundled DF `CreateFullBorder` |
| Soft border | Bundled DF `CreateBorderWithSpread` |
| Marching ants | Bundled DF `CreateAnts` plus owned sprite animation for clients without AnimateTexCoords |
| Spell-alert glow | Bundled DF `CreateGlowOverlay`, using the native alert template supported by the running client |

The upstream `CreateBorderSolid` is empty and is not offered. No LibCustomGlow, Details or Plater installation is required. Library constructors receive owned frames; glow dimensions are initialized from a fixed owned frame before anchoring, without reading secret native cast dimensions. Requested renderers are cached, failed construction does not repeat each update, and unavailable effects fall back to pulse with a diagnostic reason.

SetShown, direct Show/Hide and cast-bar visibility callbacks refresh the current highlight. A hidden bar suppresses explicit event state; an unreadable active state retries. Explicit interruptibility-change events remain authoritative, and casts are never classified solely from the preview. Validate casts/channels, modern/classic layouts, recycled bars/icons, temporary access loss, disabling styling and profile/color/effect changes in game. The callback regressions do not prove the cause of every previous missing live highlight.
