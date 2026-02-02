# Requirements: HD-2D Rendering Prototype

**Defined:** 2026-02-02
**Core Value:** Visual quality must feel right when moving through the scene — go/no-go decision for Godot

## v1 Requirements

Requirements for the evaluation prototype. Each maps to roadmap phases.

### Rendering

- [ ] **REND-01**: Depth-based tilt-shift shader with focal point following character
- [ ] **REND-02**: Bloom/glow post-processing via WorldEnvironment
- [ ] **REND-03**: Vignette effect (edge darkening/blur)
- [ ] **REND-04**: Volumetric fog for interior atmosphere

### Sprites

- [x] **SPRT-01**: Sprite3D billboard for player character
- [x] **SPRT-02**: Pixel-art filtering (nearest-neighbor) on all sprites
- [ ] **SPRT-03**: Point lights casting character shadows on environment

### Environment

- [ ] **ENV-01**: Interior house scene built with user's pixel art assets
- [ ] **ENV-02**: WorldEnvironment with tone mapping and ambient lighting

### Controls

- [x] **CTRL-01**: Click-to-move character navigation
- [x] **CTRL-02**: Camera orbit rotation
- [x] **CTRL-03**: Camera zoom

## v2 Requirements

Deferred to actual game development if prototype succeeds.

### Gameplay
- **GAME-01**: Life-sim mechanics (interact with objects, etc.)
- **GAME-02**: NPC sprites with basic behavior
- **GAME-03**: Day/night lighting cycle

### Polish
- **POLSH-01**: Screen-space god rays shader
- **POLSH-02**: GPU particle effects
- **POLSH-03**: Custom billboard shader with hit-flash

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Multiple environments | One interior scene is sufficient to judge the look |
| Sound/music | Visual evaluation only |
| UI systems | No menus needed for prototype |
| Save/load | Prototype only |
| Life-sim mechanics | Deferred to actual game if prototype succeeds |
| Performance optimization | Acceptable performance for evaluation, not shipping |
| Outdoor scene | Indoor is harder; if this works, outdoor will be easier |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| ENV-01 | Phase 1: Foundation | Complete |
| ENV-02 | Phase 1: Foundation | Complete |
| SPRT-01 | Phase 2: Character | Complete |
| SPRT-02 | Phase 2: Character | Complete |
| CTRL-01 | Phase 3: Controls | Complete |
| CTRL-02 | Phase 3: Controls | Complete |
| CTRL-03 | Phase 3: Controls | Complete |
| REND-02 | Phase 4: Atmosphere | Pending |
| REND-03 | Phase 4: Atmosphere | Pending |
| REND-04 | Phase 4: Atmosphere | Pending |
| SPRT-03 | Phase 4: Atmosphere | Pending |
| REND-01 | Phase 5: Tilt-Shift | Pending |

**Coverage:**
- v1 requirements: 12 total
- Mapped to phases: 12
- Unmapped: 0

---
*Requirements defined: 2026-02-02*
*Last updated: 2026-02-02 after roadmap creation*
