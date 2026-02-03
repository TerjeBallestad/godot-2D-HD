# Roadmap: HD-2D Rendering Prototype

## Overview

This prototype evaluates whether Godot 4 can achieve the HD-2D visual style (Octopath Traveler-like) well enough to warrant switching from Unreal Engine. Starting with an interior house scene foundation, we progressively layer in pixel art sprites, click-to-move controls, post-processing effects, and culminate with the signature depth-based tilt-shift shader. The go/no-go decision is made by walking through the finished scene and judging by gut feel.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Interior scene and WorldEnvironment setup
- [x] **Phase 2: Character** - Sprite3D player with pixel-art filtering
- [x] **Phase 3: Controls** - Click-to-move navigation and camera controls
- [x] **Phase 4: Atmosphere** - Post-processing, volumetric fog, and lighting
- [x] **Phase 5: Tilt-Shift** - Depth-based DoF shader with character-following focal point
- [ ] **Phase 6: Pathfinding** - Restore navigation so character paths around furniture

## Phase Details

### Phase 1: Foundation
**Goal**: A viewable interior house scene exists with proper rendering environment configured
**Depends on**: Nothing (first phase)
**Requirements**: ENV-01, ENV-02
**Success Criteria** (what must be TRUE):
  1. Interior house scene renders with user's pixel art assets visible
  2. WorldEnvironment shows ACES tone mapping applied (colors look HDR-correct)
  3. Ambient lighting illuminates the scene appropriately for interior space
  4. Camera shows the scene from a fixed isometric-style angle
**Plans**: 2 plans

Plans:
- [x] 01-01-PLAN.md — Scene infrastructure (WorldEnvironment, layered lighting, isometric camera)
- [x] 01-02-PLAN.md — Pixel art asset integration and visual verification

### Phase 2: Character
**Goal**: Player character exists as a pixel-art billboard sprite in the 3D scene
**Depends on**: Phase 1
**Requirements**: SPRT-01, SPRT-02
**Success Criteria** (what must be TRUE):
  1. Player character sprite is visible in the scene as a Sprite3D
  2. Sprite billboards horizontally to face camera (Y-axis only, stays upright)
  3. Sprite displays with crisp nearest-neighbor filtering (no blurry interpolation)
  4. Sprite integrates visually with the 3D environment (correct scale and positioning)
**Plans**: 1 plan

Plans:
- [x] 02-01-PLAN.md — Player character Sprite3D with Y-axis billboard, blob shadow, and scene integration

### Phase 3: Controls
**Goal**: User can navigate the character and adjust camera to evaluate the scene from different perspectives
**Depends on**: Phase 2
**Requirements**: CTRL-01, CTRL-02, CTRL-03
**Success Criteria** (what must be TRUE):
  1. Clicking on the floor moves the character to that position smoothly
  2. Character sprite animates or moves visibly (not teleporting)
  3. Camera can orbit around the scene using mouse/keyboard controls
  4. Camera can zoom in and out to inspect detail levels
**Plans**: 2 plans

Plans:
- [x] 03-01-PLAN.md — Click-to-move navigation with NavigationAgent3D and eased motion
- [x] 03-02-PLAN.md — Camera gimbal with orbit rotation (45-degree snapping) and zoom controls

### Phase 4: Atmosphere
**Goal**: Scene has the dreamy, atmospheric look characteristic of HD-2D through post-processing and lighting
**Depends on**: Phase 3
**Requirements**: REND-02, REND-03, REND-04, SPRT-03
**Success Criteria** (what must be TRUE):
  1. Bloom/glow creates soft light bleeding on bright areas
  2. Vignette darkens and optionally blurs screen edges for cinematic focus
  3. Volumetric fog adds visible atmospheric haze appropriate for interior
  4. Point light casts visible character shadow onto the environment
**Plans**: 3 plans

Plans:
- [x] 04-01-PLAN.md — Bloom and volumetric fog configuration in Environment
- [x] 04-02-PLAN.md — Vignette shader creation (rectangular falloff with warm tint)
- [x] 04-03-PLAN.md — Vignette integration, point light shadows, and visual verification

### Phase 5: Tilt-Shift
**Goal**: The signature HD-2D miniature/diorama effect is achieved with depth-based blur
**Depends on**: Phase 4
**Requirements**: REND-01
**Success Criteria** (what must be TRUE):
  1. Objects far from the character are visibly blurred
  2. Objects near the character (focal plane) remain sharp
  3. Focal point follows the character as they move through the scene
  4. The combined effect creates the characteristic "miniature" look
**Plans**: 1 plan

Plans:
- [x] 05-01-PLAN.md — Tilt-shift shader with depth-based blur and focal tracking

### Phase 6: Pathfinding
**Goal**: Character navigates around furniture instead of walking through it
**Depends on**: Phase 5
**Requirements**: None (gap closure from audit)
**Gap Closure**: Fixes "Walk-and-Look" flow degradation identified in v1-MILESTONE-AUDIT.md
**Success Criteria** (what must be TRUE):
  1. NavigationAgent3D is actively used for pathfinding (not orphaned)
  2. Character paths around furniture when clicking on the far side
  3. Character cannot walk through solid objects
  4. Navmesh is properly baked and queried at runtime
**Plans**: 1 plan

Plans:
- [ ] 06-01-PLAN.md — Restore NavigationAgent3D pathfinding with deferred setup and MESH_INSTANCES navmesh

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5 -> 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete | 2026-02-02 |
| 2. Character | 1/1 | Complete | 2026-02-02 |
| 3. Controls | 2/2 | Complete | 2026-02-02 |
| 4. Atmosphere | 3/3 | Complete | 2026-02-03 |
| 5. Tilt-Shift | 1/1 | Complete | 2026-02-03 |
| 6. Pathfinding | 0/1 | Pending | — |
