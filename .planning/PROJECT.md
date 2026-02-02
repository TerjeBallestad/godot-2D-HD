# HD-2D Rendering Prototype

## What This Is

A technical prototype in Godot 4 evaluating whether the HD-2D visual style can be achieved "close enough" to warrant switching from Unreal Engine. The prototype is a representative interior house scene (for a life-sim game) with controllable character and camera, demonstrating tilt-shift depth-of-field, volumetric lighting, and 2D sprite integration in 3D space.

## Core Value

The visual quality must feel right when moving through the scene — this is the go/no-go decision for building a life-sim game in Godot instead of Unreal.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Interior house scene built with user's pixel art assets
- [ ] Depth-based tilt-shift shader with focal point following character
- [ ] Volumetric lighting / atmospheric effects appropriate for interior
- [ ] Bloom/glow post-processing
- [ ] Vignette effect (edge darkening/blur)
- [ ] Sprite3D billboard characters with pixel-art filtering (nearest neighbor)
- [ ] Player character movement (WASD/arrow keys)
- [ ] Camera controls (rotate and zoom to evaluate from different angles)
- [ ] Point lights casting character shadows on environment

### Out of Scope

- Gameplay mechanics beyond movement — this is a rendering evaluation, not a game
- Multiple environments — one interior scene is sufficient to judge
- Sound/music — visual evaluation only
- UI systems — no menus needed
- Save/load — prototype only
- Life-sim mechanics — deferred to actual game development
- Performance optimization — acceptable performance for evaluation, not shipping

## Context

**Motivation:** User evaluated Unreal Engine for an HD-2D life-sim and liked the visual style, but found Unreal heavy, difficult to work with, and expensive. Godot could be a lighter alternative if the visuals are achievable.

**Research:** Comprehensive HD-2D research document exists in repo (`HD2D tiltishift godot research.md`) covering:
- Depth-based tilt-shift shaders (3 approaches)
- Volumetric fog and god rays
- Sprite3D billboard setup
- Post-processing stack (bloom, vignette)
- WorldEnvironment configuration
- Research rates HD-2D as 7-8/10 achievable in stock Godot 4, 9/10 with custom shaders

**Assets:** User has pixel art sprites and environment assets ready to import.

**Target aesthetic:** General HD-2D style (Octopath Traveler-like), not pixel-perfect match. "Close enough" is the bar.

**Evaluation method:** Walk around the scene and judge by gut feel in motion.

## Constraints

- **Engine**: Godot 4.6 with Forward+ renderer (already configured)
- **Assets**: Must work with user's existing pixel art assets
- **Outcome**: Binary go/no-go decision — if this works, the rendering setup becomes foundation for full game

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Depth-based tilt-shift over screen-based | More accurate focal plane blur, follows character properly | — Pending |
| Interior scene for evaluation | Harder lighting case (no sun), if this works outdoor will be easier | — Pending |

---
*Last updated: 2026-02-02 after initialization*
