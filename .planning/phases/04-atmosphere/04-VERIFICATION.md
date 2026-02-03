---
phase: 04-atmosphere
verified: 2026-02-03T14:03:05Z
status: gaps_found
score: 3/4 must-haves verified

gaps:
  - truth: "Bloom/glow creates soft light bleeding on bright areas (emissive-only)"
    status: partial
    reason: "Bloom is enabled but glow_bloom=0.47 causes all bright surfaces to glow, not just emissive materials"
    artifacts:
      - path: "scenes/interior/interior_scene.tscn"
        issue: "Environment has glow_bloom=0.47 instead of 0.0, missing glow_hdr_threshold setting"
    missing:
      - "Set glow_bloom = 0.0 (currently 0.47) to prevent all bright surfaces from glowing"
      - "Add glow_hdr_threshold = 1.0 to enable emissive-only bloom effect"
      - "Add glow_intensity = 0.8 as specified in plan"
      - "Add glow_hdr_luminance_cap = 12.0 for controlled bloom"

  - truth: "Volumetric fog adds visible atmospheric haze appropriate for interior"
    status: partial
    reason: "Volumetric fog density is 9x higher than planned, may be too dense"
    artifacts:
      - path: "scenes/interior/interior_scene.tscn"
        issue: "volumetric_fog_density=0.09 instead of 0.01, missing volumetric_fog_enabled flag"
    missing:
      - "Add volumetric_fog_enabled = true (implicit enablement not explicit)"
      - "Reduce volumetric_fog_density from 0.09 to 0.01 for subtle effect"
      - "Remove volumetric_fog_emission settings (not in plan, adds unwanted colored fog)"
      - "Add volumetric_fog_length = 64.0 and detail_spread = 2.0 per plan"
      - "Add temporal_reprojection settings for smoother rendering"
---

# Phase 4: Atmosphere Verification Report

**Phase Goal:** Scene has the dreamy, atmospheric look characteristic of HD-2D through post-processing and lighting

**Verified:** 2026-02-03T14:03:05Z

**Status:** gaps_found

**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Bloom/glow creates soft light bleeding on bright areas | ⚠️ PARTIAL | glow_enabled=true but glow_bloom=0.47 causes wrong behavior (all bright surfaces glow, not just emissive). Missing glow_hdr_threshold=1.0 for emissive-only effect. |
| 2 | Vignette darkens and optionally blurs screen edges for cinematic focus | ✓ VERIFIED | PostProcessing CanvasLayer with ColorRect using vignette.gdshader. ShaderMaterial configured with warm brown tint (0.1, 0.07, 0.03), opacity 0.4. Rectangular falloff using UV multiplication. |
| 3 | Volumetric fog adds visible atmospheric haze appropriate for interior | ⚠️ PARTIAL | volumetric_fog_density=0.09 exists but is 9x denser than plan specifies (0.01). Missing volumetric_fog_enabled explicit flag. Has unwanted fog_emission settings creating colored fog. |
| 4 | Point light casts visible character shadow onto the environment | ✓ VERIFIED | TableLamp, FloorLamp, and Fireplace OmniLight3D all have shadow_enabled=true, shadow_blur=1.5-2.0, shadow_bias=0.02. Character Sprite3D has custom emissive shader with ALPHA_SCISSOR_THRESHOLD for proper shadow casting. |

**Score:** 2/4 truths fully verified, 2/4 partial

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `scenes/interior/interior_scene.tscn` (Environment) | Glow enabled with emissive-only settings | ⚠️ PARTIAL | glow_enabled=true ✓, glow_levels configured ✓, but glow_bloom=0.47 (should be 0.0), missing glow_hdr_threshold, glow_intensity, glow_hdr_luminance_cap |
| `scenes/interior/interior_scene.tscn` (Environment) | Volumetric fog enabled with subtle density | ⚠️ PARTIAL | volumetric_fog settings exist, but density=0.09 (should be 0.01), missing explicit enabled flag, has unwanted emission settings, missing length/detail_spread/temporal settings |
| `shaders/vignette.gdshader` | Rectangular vignette shader for post-processing | ✓ VERIFIED | 30 lines, canvas_item shader, rectangular falloff via UV multiplication, warm brown color uniform, no stubs |
| `scenes/interior/interior_scene.tscn` (PostProcessing) | CanvasLayer with vignette ColorRect | ✓ VERIFIED | PostProcessing CanvasLayer at layer=100, Vignette ColorRect with ShaderMaterial_vignette, full viewport coverage, mouse_filter=2 |
| `scenes/interior/interior_scene.tscn` (OmniLights) | Shadow-enabled point lights | ✓ VERIFIED | TableLamp (shadow_enabled, blur=1.5), FloorLamp (shadow_enabled, blur=1.5), Fireplace (shadow_enabled, blur=2.0) |
| `shaders/sprite_emissive.gdshader` | Emissive spatial shader for character | ✓ VERIFIED | 47 lines, spatial shader with emission output, Y-axis billboard in vertex shader, ALPHA_SCISSOR_THRESHOLD for shadows, no stubs |
| `scenes/character/player_character.tscn` | Character with emissive shader | ✓ VERIFIED | Sprite3D with material_override using sprite_emissive.gdshader, emission_strength=0.3 |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| Environment resource | OmniLight3D nodes | volumetric fog scattering | ⚠️ PARTIAL | volumetric_fog settings exist and will scatter light, but density is too high (0.09 vs 0.01) |
| ColorRect (Vignette) | shaders/vignette.gdshader | ShaderMaterial assignment | ✓ WIRED | ext_resource line 19 loads shader, sub_resource ShaderMaterial_vignette references it, ColorRect has material=SubResource("ShaderMaterial_vignette") |
| OmniLight3D nodes | PlayerCharacter shadows | shadow casting | ✓ WIRED | TableLamp, FloorLamp, Fireplace all have shadow_enabled=true. Character Sprite3D has cast_shadow=0 but uses spatial shader with ALPHA_SCISSOR_THRESHOLD for proper shadow casting from transparency |
| Sprite3D (Character) | shaders/sprite_emissive.gdshader | material_override | ✓ WIRED | player_character.tscn has ext_resource for sprite_emissive.gdshader, ShaderMaterial_sprite references it, Sprite3D has material_override |

### Requirements Coverage

| Requirement | Status | Blocking Issue |
|-------------|--------|----------------|
| REND-02: Bloom/glow post-processing | ⚠️ PARTIAL | glow_bloom=0.47 creates wrong effect (all bright surfaces glow). Missing glow_hdr_threshold for emissive-only bloom |
| REND-03: Vignette effect | ✓ SATISFIED | Vignette shader and integration complete and verified |
| REND-04: Volumetric fog | ⚠️ PARTIAL | Fog density 9x too high (0.09 vs 0.01), has unwanted emission settings, missing several planned parameters |
| SPRT-03: Point light character shadows | ✓ SATISFIED | All point lights have shadows enabled, character has proper shadow-casting shader |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| scenes/interior/interior_scene.tscn | 45 | glow_bloom = 0.47 | 🛑 Blocker | Deviates from Plan 01 requirement (glow_bloom=0.0). Causes all bright surfaces to glow, not just emissive materials. Breaks emissive-only bloom design. |
| scenes/interior/interior_scene.tscn | 52 | volumetric_fog_density = 0.09 | ⚠️ Warning | 9x denser than Plan 01 specification (0.01). May obscure pixel art clarity. |
| scenes/interior/interior_scene.tscn | 54-55 | volumetric_fog_emission settings | ⚠️ Warning | Not in plan. Adds purple-tinted fog emission that may conflict with atmosphere design. |
| scenes/interior/interior_scene.tscn | N/A | Missing glow_hdr_threshold | 🛑 Blocker | Critical setting for emissive-only bloom. Without this, bloom triggers on all bright values, not just HDR (emission > 1.0). |

### Configuration Deviations from Plan

**Plan 01 specified emissive-only bloom configuration:**
```
glow_enabled = true          ✓ Present (correct)
glow_intensity = 0.8         ✗ Missing
glow_strength = 1.0          ✗ Present but = 0.3 (different)
glow_bloom = 0.0             ✗ Present but = 0.47 (wrong - blocker)
glow_hdr_threshold = 1.0     ✗ Missing (blocker)
glow_hdr_luminance_cap = 12.0 ✗ Missing
glow_blend_mode = 0          ✓ Present (correct)
glow_levels/1 = true         ✓ Present (correct)
glow_levels/2 = true         ✓ Present (correct)
glow_levels/4 = true         ✓ Present (correct)
```

**Plan 01 specified volumetric fog configuration:**
```
volumetric_fog_enabled = true              ✗ Missing (implicit only)
volumetric_fog_density = 0.01              ✗ Present but = 0.09 (9x too high)
volumetric_fog_albedo = Color(0.9,0.9,0.9) ✓ Present (correct)
volumetric_fog_emission = Color(0,0,0)     ✗ Present but has purple tint (not in plan)
volumetric_fog_emission_energy = 0.0       ✗ Present but = 0.1 (not in plan)
volumetric_fog_anisotropy = 0.6            ✓ Present (correct)
volumetric_fog_length = 64.0               ✗ Missing
volumetric_fog_detail_spread = 2.0         ✗ Missing
volumetric_fog_ambient_inject = 0.0        ✗ Missing
volumetric_fog_gi_inject = 0.0             ✗ Present but = 0.1 (different, not critical)
volumetric_fog_temporal_reprojection_enabled = true  ✗ Missing
volumetric_fog_temporal_reprojection_amount = 0.9    ✗ Missing
```

### Human Verification Required

The following items need human testing to fully verify:

#### 1. Bloom Visual Effect

**Test:** Run scene (F5 in Godot). Look at the lamp areas and any bright surfaces.

**Expected:** 
- With current settings (glow_bloom=0.47), you will see ALL bright surfaces glowing (floor highlights, window light, bright furniture edges)
- This is NOT the intended HD-2D emissive-only effect
- After fixing to glow_bloom=0.0 + glow_hdr_threshold=1.0, only materials with emission_energy > 1.0 should glow

**Why human:** Visual "feel" of bloom effect - does it look like dreamy HD-2D glow or overly bright/washed out?

#### 2. Volumetric Fog Density

**Test:** Run scene and orbit camera around lamps. Observe the air/atmosphere visibility.

**Expected:**
- With current density=0.09, fog may be noticeably dense, possibly obscuring pixel art clarity
- With planned density=0.01, should be barely perceptible dust-in-air effect with subtle light rays
- Scene should NOT look foggy or washed out

**Why human:** Visual assessment of fog density appropriateness for interior scene

#### 3. Overall Atmosphere Feel

**Test:** Run scene and navigate character around the room. Evaluate combined effect of all atmosphere elements.

**Expected:**
- Scene should feel dreamy and cozy with warm atmosphere
- Vignette should subtly frame the edges without tunnel vision
- Light shafts from lamps should be faintly visible
- Character shadows should be soft and visible from point lights
- Overall scene maintains pixel art crispness

**Why human:** Subjective aesthetic evaluation of HD-2D atmosphere achievement

#### 4. Dual Shadow System

**Test:** Position character near different lamps (TableLamp, FloorLamp, Fireplace) and observe shadows.

**Expected:**
- Blob shadow (Decal) visible directly under character for grounding
- Directional shadows from point lights visible on floor/walls
- Both shadow types should be visible simultaneously (dual shadow system)
- Point light shadows should be soft (shadow_blur 1.5-2.0)

**Why human:** Visibility and aesthetic quality of shadow interactions

### Gaps Summary

Phase 4 has **2 gaps blocking goal achievement**:

**1. Bloom Configuration Incorrect (BLOCKER)**
- Current: `glow_bloom = 0.47` causes all bright surfaces to glow
- Expected: `glow_bloom = 0.0` + `glow_hdr_threshold = 1.0` for emissive-only bloom
- Impact: Breaks the HD-2D emissive-only bloom design. All bright surfaces (floor highlights, window) glow instead of only emissive materials.
- Severity: 🛑 Blocker - prevents REND-02 requirement satisfaction

**2. Volumetric Fog Too Dense (WARNING)**
- Current: `volumetric_fog_density = 0.09` (9x higher than planned)
- Expected: `volumetric_fog_density = 0.01` for barely perceptible haze
- Impact: May obscure pixel art clarity, create overly foggy look
- Severity: ⚠️ Warning - fog works but may be too strong for interior scene aesthetic

**Other Issues:**
- Missing several planned volumetric fog parameters (length, detail_spread, temporal reprojection)
- Unwanted fog emission settings adding purple tint
- Missing glow_intensity and glow_hdr_luminance_cap

**What's Working Well:**
- ✓ Vignette shader and integration complete (shader is well-implemented, wiring correct)
- ✓ Point light shadows enabled on all lamps with proper soft blur
- ✓ Character emissive shader with proper shadow casting
- ✓ PostProcessing layer architecture correct

---

_Verified: 2026-02-03T14:03:05Z_  
_Verifier: Claude (gsd-verifier)_
