# Plan 05-01 Summary: Tilt-shift shader with depth-based blur and focal tracking

**Status:** Complete
**Duration:** ~25 min (including debugging)
**Commits:** 4

## What Was Built

Depth-based tilt-shift blur effect that creates the signature HD-2D miniature/diorama aesthetic:

1. **Tilt-shift shader** (`shaders/tilt_shift.gdshader`)
   - Spatial shader with screen/depth texture sampling
   - View-space depth reconstruction using `INV_PROJECTION_MATRIX`
   - Spherical distance calculation from focal point
   - Smoothstep falloff for natural depth blur transition
   - Edge blur reduction to prevent screen boundary artifacts
   - Mipmap-based blur via `textureLod()` for performance
   - Toggle and debug modes for development

2. **Focal tracking controller** (`scenes/interior/tilt_shift_controller.gd`)
   - Exponential smoothing for lagged focal point following
   - World-to-view-space transformation for focal point
   - Mid-body anchor with configurable height offset
   - Debug mode cycling and effect toggle methods

3. **Scene integration** (`scenes/interior/interior_scene.tscn`)
   - TiltShiftQuad as Camera3D child with proper culling margin
   - Tuned parameters: focus_distance=0.6, blur_max=1.5, blur_transition=2.0

4. **Camera controls** (`scenes/interior/camera_rig.gd`)
   - T key toggles effect on/off for A/B comparison
   - D key cycles debug visualization modes

## Commits

| Hash | Type | Description |
|------|------|-------------|
| 38eab05 | feat | Create tilt-shift depth shader |
| 69b90a4 | feat | Add TiltShiftQuad with focal tracking controller |
| fa40de6 | fix | Handle null debug_mode parameter |
| b5ea472 | fix | Switch to view-space depth comparison |

## Technical Decisions

- **View-space over world-space**: World position reconstruction failed due to fullscreen quad matrix issues. View-space comparison works reliably.
- **Mipmap blur**: Single `textureLod()` sample leverages GPU mipmap hardware instead of expensive multi-sample kernels.
- **Tuned for subtlety**: blur_max=1.5 creates enhancement rather than distraction, matching HD-2D aesthetic.

## Deviations from Plan

1. **Matrix approach changed**: Plan specified using built-in `INV_VIEW_MATRIX` for world reconstruction. Implementation uses view-space comparison instead due to spatial shader limitations with fullscreen quads.

2. **Debug modes expanded**: Added view_X, view_Y, linear_depth modes beyond original off/distance/depth for troubleshooting.

## Verification

- [x] Objects far from character are visibly blurred
- [x] Objects near character (focal plane) remain sharp
- [x] Focal point follows character as they move
- [x] Toggle exists for A/B comparison (T key)
- [x] Combined effect creates miniature/diorama look
- [x] User approved visual quality ✓
