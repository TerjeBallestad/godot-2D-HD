# Phase 4: Atmosphere - Research

**Researched:** 2026-02-03
**Domain:** Godot 4 Post-Processing (Bloom, Vignette, Volumetric Fog, Point Light Shadows)
**Confidence:** HIGH

## Summary

This phase implements the dreamy atmospheric look characteristic of HD-2D games through four distinct effects: bloom/glow for emissive objects, vignette for cinematic framing, volumetric fog for light shafts, and point light shadows for directional depth. All effects build on Godot 4's Forward+ renderer which the project already uses.

The key finding is that Godot 4 provides native support for bloom and volumetric fog via the Environment resource (already present in the scene as WorldEnvironment), but vignette requires a custom shader since there is no built-in vignette effect. Point light shadows are straightforward - enable `shadow_enabled` on existing OmniLight3D nodes and adjust `shadow_blur` for softness.

For emissive-only bloom, the strategy is to keep `glow_bloom` at 0.0 and rely on `glow_hdr_threshold` to only affect HDR-bright surfaces (emission_energy > 1.0). Volumetric fog with very low density creates visible light shafts from existing lamps without obscuring the scene.

**Primary recommendation:** Configure bloom/fog in existing WorldEnvironment, add vignette as ColorRect+shader in CanvasLayer, and enable shadows on existing OmniLight3D nodes.

## Standard Stack

The established tools for this domain:

### Core (Built-in)
| Component | Version | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| Environment resource | Godot 4.6 | Bloom, volumetric fog, tonemap | Native, optimized, no dependencies |
| WorldEnvironment node | Godot 4.6 | Applies Environment to scene | Already exists in interior_scene.tscn |
| OmniLight3D | Godot 4.6 | Point light with shadows | Already exists (TableLamp, FloorLamp, Fireplace) |
| ColorRect + ShaderMaterial | Godot 4.6 | Custom vignette post-processing | Official approach for effects not in Environment |

### Supporting
| Component | Version | Purpose | When to Use |
|-----------|---------|---------|-------------|
| CanvasLayer | Godot 4.6 | Orders post-processing over 3D | Required for ColorRect vignette to render over scene |
| FogVolume | Godot 4.6 | Localized volumetric fog | If global fog insufficient for light shafts |
| StandardMaterial3D emission | Godot 4.6 | HDR-bright surfaces for bloom | Mark lamps/candles as emissive |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| ColorRect vignette | TextureRect with vignette PNG | Less flexible, no blur, but simpler |
| Global volumetric fog | FogVolume nodes per lamp | More control but more setup complexity |
| OmniLight3D shadows | Decal-based fake shadows | Less realistic but no shadow atlas cost |

**No Installation Required:** All components are built into Godot 4.6.

## Architecture Patterns

### Recommended Node Structure
```
InteriorScene (existing)
├── WorldEnvironment (existing - add bloom/fog settings)
├── Lighting (existing)
│   └── Lamps (existing - enable shadows)
│       ├── TableLamp (OmniLight3D - enable shadow_enabled)
│       └── FloorLamp (OmniLight3D - enable shadow_enabled)
└── PostProcessing (NEW CanvasLayer)
    └── Vignette (ColorRect with ShaderMaterial)
```

### Pattern 1: Emissive-Only Bloom
**What:** Configure glow to only affect HDR-bright surfaces (emission > 1.0)
**When to use:** When you want lamps to glow but not bright floors/walls
**Configuration:**
```gdshader
# In Environment resource (WorldEnvironment)
glow_enabled = true
glow_intensity = 0.8       # Overall brightness
glow_strength = 1.0        # Blur spread
glow_bloom = 0.0           # CRITICAL: Keep at 0 for emissive-only
glow_hdr_threshold = 1.0   # Only HDR values trigger glow
glow_hdr_luminance_cap = 12.0  # Clamp extreme values
glow_blend_mode = 0        # Additive blending
glow_levels/1 = true       # Local glow
glow_levels/2 = true       # Slightly spread
glow_levels/4 = true       # Medium spread
```

### Pattern 2: ColorRect Post-Processing
**What:** Full-screen shader via CanvasLayer > ColorRect
**When to use:** Effects not in Environment (vignette, color grading)
**Setup:**
```
1. Add CanvasLayer as child of scene root
2. Add ColorRect as child of CanvasLayer
3. Set ColorRect anchor preset to "Full Rect"
4. Assign ShaderMaterial with canvas_item shader
5. Shader uses hint_screen_texture for screen access
```

### Pattern 3: Very Low Density Volumetric Fog
**What:** Enable volumetric fog with near-zero density for light shafts
**When to use:** Interior scenes where you want visible light rays
**Configuration:**
```gdshader
# In Environment resource
volumetric_fog_enabled = true
volumetric_fog_density = 0.01     # Very low - barely visible haze
volumetric_fog_albedo = Color(1, 1, 1, 1)  # Neutral gray/white
volumetric_fog_emission = Color(0, 0, 0, 1)
volumetric_fog_emission_energy = 0.0
volumetric_fog_gi_inject = 0.0
volumetric_fog_anisotropy = 0.6   # Forward scattering for light shafts
volumetric_fog_length = 64.0
volumetric_fog_detail_spread = 2.0
volumetric_fog_ambient_inject = 0.0
```

### Anti-Patterns to Avoid
- **High bloom with low threshold:** Makes everything glow, losing emissive-only effect. Keep glow_bloom at 0.0.
- **High fog density:** Obscures scene, loses crisp pixel art look. Keep density below 0.05.
- **Circular vignette for rectangular screen:** User wants rectangular following screen edges, not oval.
- **Disabling blob shadow when adding point light shadow:** Keep both - blob for grounding, point for depth.

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Bloom/glow | Custom multi-pass blur shader | Environment.glow_* | GPU-optimized, handles HDR correctly |
| Volumetric light shafts | Screen-space god ray shader | Environment.volumetric_fog | Physically-based, interacts with scene geometry |
| Soft shadows | Custom PCF shader | Light3D.shadow_blur | Integrated with shadow atlas, GPU-optimized |
| Screen texture access | Manual viewport copying | hint_screen_texture | Built-in, handles MSAA/HDR correctly |

**Key insight:** Godot 4's Forward+ renderer has sophisticated post-processing built in. Custom shaders are only needed for effects not provided (vignette).

## Common Pitfalls

### Pitfall 1: Everything Glows Instead of Just Emissives
**What goes wrong:** Scene looks washed out, all bright surfaces have halos
**Why it happens:** glow_bloom > 0 makes glow affect non-HDR areas
**How to avoid:** Set glow_bloom = 0.0, rely only on glow_hdr_threshold
**Warning signs:** White walls or bright textures have visible glow

### Pitfall 2: Volumetric Fog Obscures Pixel Art
**What goes wrong:** Scene looks hazy, loses crisp pixel art clarity
**Why it happens:** Fog density too high for interior scene scale
**How to avoid:** Start with density = 0.01, increase slowly until light shafts visible
**Warning signs:** Character sprite edges look soft or hazy

### Pitfall 3: Vignette Too Strong
**What goes wrong:** Screen edges too dark, feels like tunnel vision
**Why it happens:** Default shader values often tuned for cinematic games
**How to avoid:** Start with very subtle values (alpha 0.3-0.4, high inner_radius)
**Warning signs:** Player notices the vignette consciously

### Pitfall 4: Point Light Shadows Flicker or Jitter
**What goes wrong:** Shadow edges shimmer during camera movement
**Why it happens:** Low shadow atlas resolution, temporal aliasing
**How to avoid:** Enable soft shadows (shadow_blur > 0), ensure adequate shadow atlas size in project settings
**Warning signs:** Shadow edges look noisy or unstable

### Pitfall 5: Vignette Shader Breaks with UI
**What goes wrong:** Vignette appears over UI elements
**Why it happens:** CanvasLayer ordering incorrect
**How to avoid:** Set vignette CanvasLayer.layer to low number (e.g., 0), UI layers higher
**Warning signs:** UI elements are darkened at screen edges

### Pitfall 6: Bloom Color Tint Looks Unnatural
**What goes wrong:** Warm tint on bloom looks orange/artificial
**Why it happens:** Tint applied uniformly, not matching light color
**How to avoid:** Apply subtle tint (emission color on lamp materials, not global glow color)
**Warning signs:** White objects near lamps look orange

## Code Examples

Verified patterns from official sources:

### Bloom Configuration (Environment Resource)
```gdscript
# Source: Godot 4 Environment documentation
# Configure in Inspector or via script:
var env: Environment = world_environment.environment

# Emissive-only bloom settings
env.glow_enabled = true
env.glow_intensity = 0.8        # Overall glow brightness
env.glow_strength = 1.0         # How far glow spreads
env.glow_bloom = 0.0            # CRITICAL: 0 for emissive-only
env.glow_hdr_threshold = 1.0    # Only HDR values glow
env.glow_hdr_luminance_cap = 12.0
env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE

# Enable glow levels (1=local, 7=global/blurry)
env.glow_levels_1 = true
env.glow_levels_2 = true
env.glow_levels_4 = true
```

### Vignette Shader (canvas_item)
```gdshader
// Source: Godot Shaders (godotshaders.com/shader/vignette/)
// Adapted for rectangular vignette with color tint
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.15, 0.1, 0.05, 1.0); // Warm brown/sepia
uniform float softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
    vec4 screen_color = texture(screen_texture, SCREEN_UV);

    // Rectangular vignette (follows screen edges)
    vec2 uv = UV;
    uv *= 1.0 - uv.yx;
    float vig = uv.x * uv.y * 15.0;
    vig = pow(vig, vignette_intensity);

    // Apply subtle edge blur (complement to Phase 5 tilt-shift)
    float blur_amount = (1.0 - vig) * softness * 0.5;
    vec4 blurred = textureLod(screen_texture, SCREEN_UV, blur_amount * 2.0);

    // Blend with color tint
    vec3 vignetted = mix(screen_color.rgb, vignette_color.rgb, (1.0 - vig) * vignette_opacity);
    vignetted = mix(screen_color.rgb, vignetted, 1.0 - vig);

    // Mix blur at edges
    COLOR.rgb = mix(vignetted, blurred.rgb, blur_amount);
    COLOR.a = 1.0;
}
```

### Volumetric Fog Configuration
```gdscript
# Source: Godot 4 Volumetric Fog documentation
var env: Environment = world_environment.environment

# Very light fog for light shafts
env.volumetric_fog_enabled = true
env.volumetric_fog_density = 0.01          # Very low for subtle effect
env.volumetric_fog_albedo = Color(0.9, 0.9, 0.9, 1.0)  # Neutral gray/white
env.volumetric_fog_emission = Color(0.0, 0.0, 0.0, 1.0)
env.volumetric_fog_emission_energy = 0.0
env.volumetric_fog_anisotropy = 0.6        # Forward scattering for shafts
env.volumetric_fog_length = 64.0
env.volumetric_fog_detail_spread = 2.0
env.volumetric_fog_ambient_inject = 0.0
env.volumetric_fog_gi_inject = 0.0

# Temporal reprojection for smoother fog
env.volumetric_fog_temporal_reprojection_enabled = true
env.volumetric_fog_temporal_reprojection_amount = 0.9
```

### Point Light Shadow Configuration
```gdscript
# Source: Godot 4 Light3D documentation
# Configure on existing OmniLight3D nodes
var lamp: OmniLight3D = $Lighting/Lamps/TableLamp

lamp.shadow_enabled = true
lamp.shadow_blur = 1.5          # Soft penumbra (0=hard, higher=softer)
lamp.shadow_opacity = 0.35      # 30-40% as specified in CONTEXT
lamp.shadow_bias = 0.02         # Reduce shadow acne
lamp.shadow_normal_bias = 1.0   # Further reduce acne on curved surfaces

# Light itself (for contact hardening effect)
lamp.light_size = 0.1           # Small size = sharper shadows near caster
```

### Emissive Material Setup
```gdscript
# Source: Godot 4 StandardMaterial3D documentation
# For lamp shade/bulb materials to trigger bloom
var lamp_material: StandardMaterial3D = StandardMaterial3D.new()

lamp_material.emission_enabled = true
lamp_material.emission = Color(1.0, 0.85, 0.65)  # Warm lamp color
lamp_material.emission_energy_multiplier = 2.0   # HDR value > 1.0 triggers glow
```

### ColorRect Setup for Vignette
```gdscript
# In scene script or as scene structure
func _setup_vignette() -> void:
    var canvas_layer = CanvasLayer.new()
    canvas_layer.layer = 0  # Behind UI
    add_child(canvas_layer)

    var vignette_rect = ColorRect.new()
    vignette_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
    vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

    var shader = load("res://shaders/vignette.gdshader")
    var material = ShaderMaterial.new()
    material.shader = shader
    material.set_shader_parameter("vignette_intensity", 0.4)
    material.set_shader_parameter("vignette_opacity", 0.3)  # Very subtle
    vignette_rect.material = material

    canvas_layer.add_child(vignette_rect)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom bloom shader | Environment.glow_* | Godot 4.0 | GPU-optimized, HDR-aware |
| Separate fog pass | volumetric_fog in Environment | Godot 4.0 | Integrated with lighting |
| SCREEN_TEXTURE | hint_screen_texture sampler | Godot 4.0 | Proper MSAA/HDR handling |
| SpatialMaterial | StandardMaterial3D | Godot 4.0 | Renamed, same concept |

**Deprecated/outdated:**
- `glow_bicubic_upscale` removed in Godot 4.x (upscaling handled differently)
- `SCREEN_TEXTURE` as direct identifier (use `hint_screen_texture` sampler uniform)
- `hint_color` in shaders (use `source_color` for proper sRGB handling)

## Open Questions

Things that couldn't be fully resolved:

1. **Optimal fog density for light shafts**
   - What we know: Very low density (0.01-0.05) needed, anisotropy 0.6+ helps
   - What's unclear: Exact value depends on lamp positions and scene scale
   - Recommendation: Start at 0.01, adjust visually until light shafts visible without haze

2. **Shadow atlas size for multiple point lights**
   - What we know: Default shadow atlas may be insufficient for 3 OmniLight3D with shadows
   - What's unclear: Whether project settings need adjustment for quality
   - Recommendation: Test with defaults first, increase `rendering/lights_and_shadows/positional_shadow/atlas_size` if shadows look blocky

3. **Vignette interaction with Phase 5 tilt-shift**
   - What we know: Both affect screen edges, should complement not compete
   - What's unclear: Optimal layering order for visual coherence
   - Recommendation: Apply vignette before tilt-shift (lower CanvasLayer), keep vignette blur minimal

## Sources

### Primary (HIGH confidence)
- Godot 4 Environment documentation - glow, volumetric fog properties
- Godot 4 Light3D documentation - shadow properties
- Godot 4 Custom post-processing documentation - ColorRect/shader setup
- [godotshaders.com/shader/vignette](https://godotshaders.com/shader/vignette/) - vignette shader pattern
- [godotshaders.com/shader/blur-vignette](https://godotshaders.com/shader/blur-vignette-post-processing-colorrect-godot-4-2-1/) - blur vignette pattern

### Secondary (MEDIUM confidence)
- [GitHub godot-proposals #1806](https://github.com/godotengine/godot-proposals/issues/1806) - vignette feature request (confirms no built-in)
- [Godot Blog: Fog Volumes](https://godotengine.org/article/fog-volumes-arrive-in-godot-4/) - FogVolume introduction
- [Rokojori Godot Docs](https://rokojori.com/en/labs/godot/docs/4.3/environment-class) - Environment property reference

### Tertiary (LOW confidence)
- Godot Forum discussions on bloom threshold tuning
- Community reports on shadow quality settings

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Using only built-in Godot 4 features with official documentation
- Architecture: HIGH - Patterns verified in official docs and working examples
- Pitfalls: MEDIUM - Based on community reports and official issue tracker

**Research date:** 2026-02-03
**Valid until:** 2026-03-03 (Godot 4.6 stable, unlikely to change)
