---
phase: 04-atmosphere
plan: 03
subsystem: rendering
tags: [vignette, shadows, post-processing, emissive-sprite, CanvasLayer]

# Dependency graph
requires:
  - phase: 04-02
    provides: Vignette shader file
provides:
  - Vignette post-processing overlay
  - Point light shadows from OmniLights
  - Emissive sprite shader for character

# Tech tracking
tech-stack:
  added:
    - CanvasLayer post-processing pattern
    - Emissive spatial shader with billboard
  patterns:
    - ColorRect with shader overlay at layer 100
    - Y-axis billboard in vertex shader
    - ALPHA_SCISSOR_THRESHOLD for shadow casting

key-files:
  created:
    - shaders/sprite_emissive.gdshader
  modified:
    - scenes/interior/interior_scene.tscn
    - scenes/character/player_character.tscn
    - shaders/vignette.gdshader

key-decisions:
  - "Simple alpha overlay vignette (no screen texture sampling)"
  - "CanvasLayer layer=100 for post-processing to render on top"
  - "Emissive sprite shader with emission_strength=0.3 for character visibility"
  - "Y-axis billboard implemented in vertex shader for custom material"
  - "ALPHA_SCISSOR_THRESHOLD for proper shadow casting from sprites"

patterns-established:
  - "Post-processing: CanvasLayer > ColorRect with canvas_item shader"
  - "Emissive sprites: spatial shader with EMISSION output"
  - "Billboard sprites: vertex shader rotation toward camera"

# Metrics
duration: 25min
completed: 2026-02-03
---

# Phase 4 Plan 3: Vignette Integration & Shadows Summary

**Complete HD-2D atmosphere with vignette overlay, point light shadows, and emissive character sprite**

## Performance

- **Duration:** 25 min (including debugging and iteration)
- **Completed:** 2026-02-03
- **Tasks:** 3 (2 auto + 1 checkpoint)

## Accomplishments

- Added PostProcessing CanvasLayer with vignette ColorRect
- Vignette shader simplified to alpha overlay approach (more reliable)
- Enabled shadows on TableLamp, FloorLamp, and Fireplace OmniLights
- Created emissive sprite shader for character with:
  - Subtle self-illumination (emission_strength=0.3)
  - Y-axis billboard in vertex shader
  - Proper alpha scissor for shadow casting
- User approved atmosphere visual quality

## Task Commits

1. **Tasks 1-2 + checkpoint fixes** - `2e6746f` (feat)
   - Vignette integration, shadows, emissive sprite shader

## Files Created/Modified

- `shaders/sprite_emissive.gdshader` - Emissive spatial shader with billboard
- `shaders/vignette.gdshader` - Simplified to alpha overlay
- `scenes/interior/interior_scene.tscn` - PostProcessing layer, shadow settings
- `scenes/character/player_character.tscn` - Material override with emissive shader

## Decisions Made

- **Vignette approach:** Simple alpha overlay instead of screen texture sampling (more reliable across Godot versions)
- **CanvasLayer layer:** 100 (ensures rendering on top of 3D scene)
- **Emissive strength:** 0.3 for subtle character glow without washing out
- **Billboard in shader:** Required because material_override breaks Sprite3D's built-in billboard
- **Alpha scissor:** Using ALPHA_SCISSOR_THRESHOLD for proper shadow casting

## Issues Encountered

- Screen texture sampling (`hint_screen_texture`) didn't work reliably for 3D post-processing
- Custom spatial shader broke Sprite3D billboard - fixed with vertex shader rotation
- Manual `discard` in shader prevented shadow casting - fixed with ALPHA_SCISSOR_THRESHOLD
- Character appeared dark initially - fixed with emissive shader
- Godot scene caching required close/reopen to see changes

## User Feedback Applied

- Character darkness fixed with emissive shader
- Import settings caused sprite artifacts (user fixed by switching to Lossless)
- Shadows restored with proper bias settings

## Next Phase Readiness

- All Phase 4 atmosphere effects complete and approved
- Ready for Phase 5: Tilt-Shift (depth-based DoF shader)

---
*Phase: 04-atmosphere*
*Completed: 2026-02-03*
