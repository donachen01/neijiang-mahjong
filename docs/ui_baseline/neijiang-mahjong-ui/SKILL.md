# Neijiang Mahjong UI Skill

Use this project skill whenever modifying the Godot UI for this Mahjong project.

This skill exists because the desired style is not a normal flat UI. It is a warm, realistic 3D cartoon Mahjong world matching the splash screen. Do not try to reach that quality by only tweaking `StyleBoxFlat` colors.

## Goal

Build a clear mobile-landscape Mahjong UI inspired by the project splash screen and UI baseline:

- Large readable tiles.
- Large readable scores and action buttons.
- Minimal always-visible explanatory panels.
- Settlement screens that show winner, hand type, fan/score, and payment at a glance.
- Warm realistic 3D cartoon style: rounded wood, soft lighting, cute character-friendly shapes, thick Mahjong tiles.

## Core Truth

For this project, high-quality UI is asset-driven.

Use Godot controls to assemble and interact. Use art assets, nine-patch panels, texture buttons, rendered tile surfaces, and screenshots to create the 3D cartoon feeling.

Avoid promising splash-screen quality from code-only Godot styling. Code-only styling may be acceptable for prototypes, but the target quality requires generated or hand-made assets.

## Required Workflow

1. Read `docs/ui_baseline/UI_BASELINE.md`.
2. Classify the work:
   - `layout`: positioning, scale, hierarchy.
   - `asset`: panel/button/tile/background artwork.
   - `implementation`: Godot scene/script wiring.
   - `verification`: screenshot comparison.
3. If the change affects the main look of table or settlement UI, create or update a mockup first. Do not jump straight into Godot layout unless the user explicitly asks for a small patch.
4. Break the mockup into an asset list.
5. Implement with Godot using `TextureRect`, `NinePatchRect`, `TextureButton`, `Control`, and existing scene patterns.
6. Run Godot.NET scene load if possible.
7. Capture screenshots for at least one landscape viewport.
8. Compare against the baseline before finalizing.

## Mockup First Rule

Use a mockup before major visual implementation.

Mockup output should define:

- Table background and wood frame.
- Self hand scale and placement.
- Opponent player card style.
- Action button style and placement.
- Settlement modal shape and colors.
- Main result typography and score hierarchy.

The mockup can be a generated bitmap, Figma frame, or carefully assembled static Godot screen. A bitmap mockup is acceptable before building exact interactive UI.

## Asset Pipeline

Prefer this asset order:

1. Generate or design full-screen target mockup.
2. Extract or recreate reusable assets:
   - wood table frame / panel nine-patch
   - green felt texture
   - cream content panel nine-patch
   - warm red/orange result banner
   - round/jelly action buttons
   - thick Mahjong tile face and side style
   - player avatar frame
   - title/score badge style
3. Save assets under a clear project path such as `res/art/ui_3d_cartoon/`.
4. Use nine-patch/texture assets in Godot instead of redrawing everything with flat styleboxes.
5. Keep original mockups and exported screenshots under `docs/ui_baseline/` or `artifacts/ui_baseline/`.

## Table UI Rules

- Self hand tiles are the primary visual element.
- Target self tile size is around `104x156` to `108x162` on a `2048x1152` design basis.
- Tile visuals should feel thick and tactile: warm white face, green side edge, rounded corners, soft drop shadow.
- Action buttons must be thumb-friendly:
  - Primary action around `144px` diameter.
  - Secondary actions around `112-128px` diameter.
- Action buttons should look like rounded 3D props or jelly buttons, not flat rectangles.
- Avoid persistent large debug/stat cards on the main table.
- Keep player info attached to screen edges.
- Text must not overlap tiles or buttons.
- Prefer warm wood and felt-table materials over cold flat panels.

## Settlement UI Rules

- Use a large modal around `80-86vw` wide and `66-74vh` tall.
- Show player list on the left and selected result detail on the right.
- Make score deltas large.
- Show hand tiles large enough to inspect.
- Use one-line large settlement rows instead of dense tables where possible.
- Bottom action buttons must be large and easy to tap.
- Translate reference settlement layout into the splash-screen style: wooden frame, cream content area, warm red/orange-gold result banner, thick shadows.

## Style Rules

- Overall style: realistic 3D cartoon, same world as the splash screen.
- Use warm indoor lighting, honey wood, green felt, cream tiles, orange-gold highlights.
- Use rounded thick panels with highlights and shadows.
- Avoid casino neon, backend-dashboard cards, cold tech styling, and thin flat outlines.
- Important Chinese text should use cartoon-like large type with outline/shadow when possible.
- Do not use generic dark green panels with thin gold borders as the final style unless explicitly keeping a legacy screen.

## Godot Implementation Rules

- Use `TextureRect`/`NinePatchRect` for major decorative panels.
- Use `TextureButton` or texture-backed `Button` styles for main actions.
- Use `Control` containers for responsive layout; avoid absolute positions except for intentionally floating action clusters.
- Preserve touch target sizes.
- Keep UI state and game logic separated; do not move Mahjong rules into UI scripts.
- After major visual changes, run scene load with Godot.NET and capture screenshots.

## Verification Checklist

- Self hand 14 tiles are all visible.
- Last drawn tile has clear spacing.
- Reaction buttons are easy to tap and do not cover hand tiles.
- Settlement page clearly shows winner, hand type, fan/score, and total score change.
- `1365x768` still fits without text overflow.
- The screen feels like the splash image world: warm wood, rounded thickness, soft light, cute approachable style.

## Confidence Guidance

- Layout-only clarity improvements: high confidence.
- 3D cartoon feeling with generated assets and screenshot iteration: medium-high confidence.
- Splash-screen-level polish from code-only styling: low confidence. Ask to create assets first.

