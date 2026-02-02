# Roadmap: HD-2D Rendering Prototype

## Overview

This prototype evaluates whether Godot 4 can achieve the HD-2D visual style (Octopath Traveler-like) well enough to warrant switching from Unreal Engine. Starting with an interior house scene foundation, we progressively layer in pixel art sprites, click-to-move controls, post-processing effects, and culminate with the signature depth-based tilt-shift shader. The go/no-go decision is made by walking through the finished scene and judging by gut feel.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Foundation** - Interior scene and WorldEnvironment setup
- [ ] **Phase 2: Character** - Sprite3D player with pixel-art filtering
- [ ] **Phase 3: Controls** - Click-to-move navigation and camera controls
- [ ] **Phase 4: Atmosphere** - Post-processing, volumetric fog, and lighting
- [ ] **Phase 5: Tilt-Shift** - Depth-based DoF shader with character-following focal point

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
**Plans**: TBD

Plans:
- [ ] 01-01: TBD
- [ ] 01-02: TBD

### Phase 2: Character
**Goal**: Player character exists as a pixel-art billboard sprite in the 3D scene
**Depends on**: Phase 1
**Requirements**: SPRT-01, SPRT-02
**Success Criteria** (what must be TRUE):
  1. Player character sprite is visible in the scene as a Sprite3D
  2. Sprite billboards to always face the camera regardless of camera angle
  3. Sprite displays with crisp nearest-neighbor filtering (no blurry interpolation)
  4. Sprite integrates visually with the 3D environment (correct scale and positioning)
**Plans**: TBD

Plans:
- [ ] 02-01: TBD

### Phase 3: Controls
**Goal**: User can navigate the character and adjust camera to evaluate the scene from different perspectives
**Depends on**: Phase 2
**Requirements**: CTRL-01, CTRL-02, CTRL-03
**Success Criteria** (what must be TRUE):
  1. Clicking on the floor moves the character to that position smoothly
  2. Character sprite animates or moves visibly (not teleporting)
  3. Camera can orbit around the scene using mouse/keyboard controls
  4. Camera can zoom in and out to inspect detail levels
**Plans**: TBD

Plans:
- [ ] 03-01: TBD
- [ ] 03-02: TBD

### Phase 4: Atmosphere
**Goal**: Scene has the dreamy, atmospheric look characteristic of HD-2D through post-processing and lighting
**Depends on**: Phase 3
**Requirements**: REND-02, REND-03, REND-04, SPRT-03
**Success Criteria** (what must be TRUE):
  1. Bloom/glow creates soft light bleeding on bright areas
  2. Vignette darkens and optionally blurs screen edges for cinematic focus
  3. Volumetric fog adds visible atmospheric haze appropriate for interior
  4. Point light casts visible character shadow onto the environment
**Plans**: TBD

Plans:
- [ ] 04-01: TBD
- [ ] 04-02: TBD

### Phase 5: Tilt-Shift
**Goal**: The signature HD-2D miniature/diorama effect is achieved with depth-based blur
**Depends on**: Phase 4
**Requirements**: REND-01
**Success Criteria** (what must be TRUE):
  1. Objects far from the character are visibly blurred
  2. Objects near the character (focal plane) remain sharp
  3. Focal point follows the character as they move through the scene
  4. The combined effect creates the characteristic "miniature" look
**Plans**: TBD

Plans:
- [ ] 05-01: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 -> 2 -> 3 -> 4 -> 5

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/2 | Not started | - |
| 2. Character | 0/1 | Not started | - |
| 3. Controls | 0/2 | Not started | - |
| 4. Atmosphere | 0/2 | Not started | - |
| 5. Tilt-Shift | 0/1 | Not started | - |
