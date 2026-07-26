# Screenshot sources and provenance

## Product captures

The interface images in `source/` were captured from the same `WinMine98` AppKit target used for the Release archive. Most use Debug-only starting-state selection; the one-flag image was captured by interacting with the packaged app directly. Its computer-use cursor artifact was removed deterministically by restoring the covered cell from an identical neighboring cell and overlaying the exact shipping `flag.png` asset. No other UI pixels were changed.

- `beginner-ready-large.png`: real Beginner board, Large interface scale.
- `beginner-playing-large.png`: real Beginner board after valid reveal and mark actions.
- `beginner-one-flag-large.png`: packaged app in a real Beginner state with one flag placed and `009` mines remaining, Large interface scale; cursor artifact removed as described above.
- `intermediate-ready-large.png`: real Intermediate board, Large interface scale.
- `intermediate-playing-large.png`: real Intermediate board after valid reveal and mark actions.
- `expert-ready-large.png`: real Expert board, Large interface scale.
- `expert-playing-large.png`: real Expert board after valid reveal and mark actions.

## Presentation system

- Background: solid `#008080`, the familiar default desktop teal.
- UI framing: `98.css` 0.1.21 by Jordan Scales and contributors, MIT License.
- Upstream repository: https://github.com/jdan/98.css
- Upstream HEAD checked during production: `b1d7a907371bbe523d6f64e3af97f714fdbd6d6a`.
- Export copy, placement, and dimensions are deterministic HTML/CSS compositions rendered with Playwright.

## Generated explorations not used

Two ImageGen background explorations are retained in `source/generated-teal-grid.png` and `source/generated-editorial-grid.png`. Neither appears in the final exports after the decision to use solid `#008080` throughout.

Prompts:

1. Deep teal, late-1990s desktop-inspired empty backdrop with a subtle pixel grid; no UI, devices, logos, text, or branding.
2. Warm off-white editorial grid backdrop with small abstract red and cobalt accents; no UI, devices, logos, text, or branding.
