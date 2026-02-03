# HD-2D Rendering Prototype

## What This Is

A technical prototype in Godot 4 demonstrating the HD-2D visual style (Octopath Traveler-like) with an interior house scene featuring tilt-shift depth-of-field, volumetric lighting, and 2D sprite integration in 3D space. **v1.0 shipped 2026-02-03** - ready for visual evaluation to decide Godot vs Unreal.

## Core Value

The visual quality must feel right when moving through the scene — this is the go/no-go decision for building a life-sim game in Godot instead of Unreal.

## Requirements

### Validated

- Interior house scene built with user's pixel art assets — v1.0
- Depth-based tilt-shift shader with focal point following character — v1.0
- Volumetric lighting / atmospheric effects appropriate for interior — v1.0
- Bloom/glow post-processing — v1.0
- Vignette effect (edge darkening/blur) — v1.0
- Sprite3D billboard characters with pixel-art filtering (nearest neighbor) — v1.0
- Player character movement (click-to-move) — v1.0
- Camera controls (rotate and zoom to evaluate from different angles) — v1.0
- Point lights casting character shadows on environment — v1.0

### Active

(None — awaiting visual evaluation decision)

### Out of Scope

- Gameplay mechanics beyond movement — this is a rendering evaluation, not a game
- Multiple environments — one interior scene is sufficient to judge
- Sound/music — visual evaluation only
- UI systems — no menus needed
- Save/load — prototype only
- Life-sim mechanics — deferred to actual game development
- Performance optimization — acceptable performance for evaluation, not shipping
- Pathfinding — direct movement sufficient for visual evaluation; can be restored if needed

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
| Depth-based tilt-shift over screen-based | More accurate focal plane blur, follows character properly | Good - view-space comparison works reliably |
| Interior scene for evaluation | Harder lighting case (no sun), if this works outdoor will be easier | Good - interior atmosphere achieved |
| ACES tone mapping | Octopath-style dreamy look | Good |
| 3D furniture, Sprite3D characters | Standard HD-2D approach | Good |
| View-space depth (not world-space) | World position reconstruction failed with fullscreen quad | Good - required workaround |
| Direct movement (pathfinding deferred) | NavigationAgent3D had oscillation issues | Acceptable - sufficient for visual evaluation |

## Current State

**v1.0 shipped 2026-02-03**

- 832 LOC (GDScript/scenes/shaders)
- 6 phases, 10 plans completed
- 12/12 requirements satisfied
- Tech stack: Godot 4.6 Forward+, GDShader, Sprite3D

**Tech Debt:**
- print() debug statements in tilt_shift_controller.gd
- Unused NavigationAgent3D/NavigationRegion3D nodes in scene

---
*Last updated: 2026-02-03 after v1.0 milestone*
