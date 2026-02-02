# Phase 1: Foundation - Research

**Researched:** 2026-02-02
**Domain:** Godot 4 interior scene setup with HD-2D visual style (WorldEnvironment, ACES tone mapping, layered lighting, isometric camera)
**Confidence:** HIGH

## Summary

This phase establishes a viewable interior house scene with proper rendering environment for HD-2D style evaluation. The research focused on Godot 4.6's WorldEnvironment configuration, ACES tone mapping for the "warm, soft, dreamy" Octopath Traveler aesthetic, layered interior lighting (window daylight + ambient + practical lamps), and fixed isometric camera positioning.

The project already has a comprehensive technical guide (`HD2D tiltishift godot research.md`) that aligns well with the user's decisions. Godot 4.6 with Forward Plus renderer provides all necessary features: ACES tone mapping, SSAO for subtle ambient occlusion, and full lighting capabilities. The key insight is that HD-2D interior scenes require careful balance between multiple light sources with warm color temperatures (2700K-3000K equivalent) to achieve the cozy, lived-in feel.

**Primary recommendation:** Build the scene with a WorldEnvironment using ACES tone mapping (exposure ~1.0, white ~6.0), layered lighting using DirectionalLight3D (window daylight, cool but weak), OmniLight3D (warm lamps, dominant), and ambient light (warm fill), plus subtle SSAO (intensity ~1.0-2.0) for corner darkening.

## Standard Stack

### Core (Built into Godot 4.6)
| Node/Resource | Purpose | Why Standard |
|---------------|---------|--------------|
| WorldEnvironment | Scene-wide rendering settings (tone mapping, SSAO, glow) | Single point of control for all post-processing |
| Environment (resource) | Holds all environment settings | Attached to WorldEnvironment |
| DirectionalLight3D | Simulates window daylight | Parallel light rays, natural sun/window simulation |
| OmniLight3D | Point light sources (lamps, fireplace) | Radiates in all directions, perfect for practical lights |
| Camera3D | Scene viewing | Fixed isometric angle for HD-2D style |
| Sprite3D | 2D pixel art assets in 3D space | Billboard support, texture filtering control |

### Supporting
| Node/Resource | Purpose | When to Use |
|---------------|---------|-------------|
| SpotLight3D | Focused light (optional fireplace glow) | When directional focus needed |
| Node3D | Scene organization containers | Grouping environment, lighting, assets |

### Not Needed This Phase
| Feature | Why Not |
|---------|---------|
| Custom shaders | Tone mapping, SSAO, glow are built-in |
| VoxelGI/SDFGI | Interior is small enough for direct lighting |
| Volumetric fog | Not specified in requirements; add in later phase |

## Architecture Patterns

### Recommended Scene Structure
```
InteriorScene (Node3D)
├── WorldEnvironment
│   └── Environment (resource)
├── Lighting (Node3D)
│   ├── WindowLight (DirectionalLight3D)  # Cool daylight
│   ├── Lamps (Node3D)
│   │   ├── Lamp1 (OmniLight3D)           # Warm lamp
│   │   └── Lamp2 (OmniLight3D)           # Warm lamp
│   └── Fireplace (OmniLight3D or SpotLight3D)  # Warmest
├── Environment (Node3D)
│   └── [Room geometry and static props]
├── Assets (Node3D)
│   └── [Sprite3D furniture, decor, characters]
└── Camera3D                               # Fixed isometric
```

### Pattern 1: Layered Interior Lighting
**What:** Multiple light sources at different color temperatures creating depth and mood
**When to use:** Always for interior HD-2D scenes
**Configuration:**

```gdscript
# Window daylight - cool but weak (overpowered by warm lamps per user decision)
var window_light = DirectionalLight3D.new()
window_light.light_color = Color(0.9, 0.95, 1.0)  # Slight blue tint
window_light.light_energy = 0.3  # Weak - lamp overpowers
window_light.rotation_degrees = Vector3(-30, -45, 0)  # Angled through window

# Practical lamp - warm and dominant
var lamp = OmniLight3D.new()
lamp.light_color = Color(1.0, 0.85, 0.6)  # ~2700K warm white
lamp.light_energy = 1.5  # Strong - dominates the scene
lamp.omni_range = 8.0
lamp.omni_attenuation = 1.5  # Gradual falloff

# Fireplace - warmest accent
var fireplace = OmniLight3D.new()
fireplace.light_color = Color(1.0, 0.7, 0.4)  # ~1800K firelight
fireplace.light_energy = 2.0
fireplace.omni_range = 6.0
```

### Pattern 2: ACES Tone Mapping for Octopath Aesthetic
**What:** Academy Color Encoding System creates rich, vibrant colors with natural highlight rolloff
**When to use:** Always for HD-2D style
**Key characteristics:**
- Desaturates bright areas naturally (communicates brightness without clipping)
- Higher contrast than Reinhard or Filmic
- Darkens scenes slightly (compensate with light energy)

```gdscript
var env = Environment.new()
env.tonemap_mode = Environment.TONE_MAPPER_ACES
env.tonemap_exposure = 1.0   # Start neutral, adjust by eye
env.tonemap_white = 6.0      # Common value for scenes with bright highlights
```

### Pattern 3: Subtle SSAO for Depth
**What:** Screen-space ambient occlusion darkens corners and crevices
**When to use:** User specified "subtle ambient occlusion"
**Configuration:**

```gdscript
env.ssao_enabled = true
env.ssao_intensity = 1.5      # Subtle but visible (range: 1.0-2.0)
env.ssao_radius = 1.0         # Default, adjust based on scene scale
env.ssao_power = 1.5          # Slightly sharper falloff
env.ssao_light_affect = 0.0   # Keep realistic (only affects indirect)
env.ssao_ao_channel_affect = 0.0  # No interaction with AO textures
```

### Anti-Patterns to Avoid
- **Overly bright ambient light:** Flattens the scene, removes depth from layered lighting
- **All lights same color temperature:** Loses the warm/cool contrast that creates visual interest
- **SSAO intensity > 3.0:** Becomes distracting, loses subtlety
- **Perspective camera for HD-2D:** Breaks the diorama/miniature aesthetic

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Tone mapping | Custom HDR shader | Environment.tonemap_mode = ACES | Built-in, optimized, well-tested |
| Ambient occlusion | Custom AO shader | Environment.ssao_enabled | GPU-accelerated, integrated with renderer |
| Bloom/glow | Custom blur passes | Environment.glow_* properties | Multi-level, blendable, performant |
| Color grading | Manual color math | tonemap_exposure + tonemap_white | ACES handles this naturally |

**Key insight:** Godot 4.6's built-in environment effects are production-quality and match what HD-2D games use. Custom solutions add complexity without benefit for this phase.

## Common Pitfalls

### Pitfall 1: ACES Darkening
**What goes wrong:** Scene appears too dark after enabling ACES tone mapping
**Why it happens:** ACES has higher contrast and darker shadows than linear; scenes designed without ACES need adjustment
**How to avoid:**
- Start with ACES enabled from the beginning
- Increase light energy values by 20-50% compared to linear
- Use tonemap_exposure to globally brighten if needed
**Warning signs:** Shadows become black with no detail

### Pitfall 2: Texture Filtering Blur
**What goes wrong:** Pixel art sprites appear blurry/smeared
**Why it happens:** Default texture filtering is Linear, which interpolates pixels
**How to avoid:**
- Project Settings > Rendering > Textures > Default Texture Filter = Nearest
- For Sprite3D: set texture_filter = TEXTURE_FILTER_NEAREST
**Warning signs:** Pixel edges appear soft or anti-aliased

### Pitfall 3: Camera Angle Breaking Depth Illusion
**What goes wrong:** Scene looks flat or depth-based effects don't work
**Why it happens:** Wrong camera angle or using orthographic when tilt-shift needs depth
**How to avoid:**
- Use perspective camera with moderate FOV (50-70)
- Position at ~35-45 degree down angle
- Octopath uses "looking into" not "looking down onto" the scene
**Warning signs:** Tilt-shift blur doesn't follow expected depth planes

### Pitfall 4: Warm Lights Too Orange
**What goes wrong:** Scene looks like everything is on fire, unrealistic warmth
**Why it happens:** Using pure orange/red instead of proper warm white
**How to avoid:**
- Use actual warm white colors: RGB(255, 217, 153) for 2700K equivalent
- Firelight can be warmer: RGB(255, 180, 100)
- Always keep some green component
**Warning signs:** Scene has halloween/fire emergency feel

### Pitfall 5: Ambient Light Overpowering Direct Lights
**What goes wrong:** No shadows, flat lighting despite multiple light sources
**Why it happens:** Ambient light energy too high
**How to avoid:**
- Keep ambient_light_energy low (0.2-0.5)
- Use ambient for fill only, not primary illumination
- Set ambient_light_source to COLOR for control
**Warning signs:** Moving/adding lights doesn't change scene appearance much

## Code Examples

### Complete WorldEnvironment Setup
```gdscript
# Source: Synthesized from Godot 4 documentation and HD-2D requirements
extends WorldEnvironment

func _ready():
    var env = Environment.new()

    # === BACKGROUND ===
    # Interior scene - solid dark color, not sky
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.05, 0.05, 0.08)  # Very dark blue-gray

    # === AMBIENT LIGHT ===
    # Warm fill to complement the lamp dominance
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.4, 0.35, 0.3)  # Warm gray
    env.ambient_light_energy = 0.3  # Low - let direct lights dominate

    # === TONE MAPPING (Octopath style) ===
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0
    env.tonemap_white = 6.0  # Soft highlight rolloff

    # === SSAO (Subtle per user decision) ===
    env.ssao_enabled = true
    env.ssao_intensity = 1.5  # Subtle
    env.ssao_radius = 1.0
    env.ssao_power = 1.5
    env.ssao_light_affect = 0.0

    # === GLOW (for dreamy feel) ===
    env.glow_enabled = true
    env.glow_intensity = 0.5
    env.glow_bloom = 0.1
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
    env.glow_hdr_threshold = 1.2

    environment = env
```

### Layered Lighting Setup
```gdscript
# Source: Synthesized from lighting research and user requirements
extends Node3D

func setup_lighting():
    # Window daylight (cool, weak)
    var window = DirectionalLight3D.new()
    window.name = "WindowLight"
    window.light_color = Color(0.85, 0.9, 1.0)  # Cool daylight
    window.light_energy = 0.4
    window.rotation_degrees = Vector3(-35, -60, 0)
    window.shadow_enabled = true
    add_child(window)

    # Primary lamp (warm, strong)
    var lamp1 = OmniLight3D.new()
    lamp1.name = "TableLamp"
    lamp1.light_color = Color(1.0, 0.85, 0.65)  # ~2700K warm
    lamp1.light_energy = 2.0  # Dominant
    lamp1.omni_range = 10.0
    lamp1.omni_attenuation = 1.2
    lamp1.position = Vector3(2, 2, 0)  # Adjust to scene
    add_child(lamp1)

    # Fireplace (warmest)
    var fire = OmniLight3D.new()
    fire.name = "Fireplace"
    fire.light_color = Color(1.0, 0.65, 0.35)  # ~1800K fire
    fire.light_energy = 2.5
    fire.omni_range = 6.0
    fire.omni_attenuation = 1.5
    fire.position = Vector3(-3, 1, 0)  # Adjust to fireplace
    add_child(fire)
```

### Sprite3D Pixel Art Configuration
```gdscript
# Source: Godot documentation and pixel art best practices
extends Sprite3D

func _ready():
    # Critical for pixel art
    texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

    # Billboard options
    billboard = BaseMaterial3D.BILLBOARD_DISABLED  # Or BILLBOARD_ENABLED for characters

    # Alpha handling for pixel art
    alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD  # Hard pixel edges
    # Or ALPHA_CUT_OPAQUE_PREPASS for better shadows

    # Scale
    pixel_size = 0.01  # Adjust based on your asset scale
```

### Isometric-Style Camera Setup
```gdscript
# Source: HD-2D camera angle research
extends Camera3D

func _ready():
    # Perspective camera (not orthographic) for depth-based effects
    projection = PROJECTION_PERSPECTIVE
    fov = 50.0  # Moderate FOV reduces distortion

    # Isometric-style angle
    # Octopath "looks into" the scene, not straight down
    rotation_degrees = Vector3(-35, -45, 0)  # X: down tilt, Y: rotation

    # Position for room overview
    position = Vector3(8, 6, 8)  # Adjust based on room size

    # Clipping
    near = 0.1
    far = 100.0
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom tone mapping shaders | Built-in ACES/AgX | Godot 4.0 | No need for custom HDR pipeline |
| Manual AO baking | Real-time SSAO | Godot 4.0 | Dynamic scenes possible |
| Linear tonemapper default | ACES widely adopted | 2020s | Richer, more cinematic colors |

**Recent in Godot 4.6:**
- AGX tone mapping added (alternative to ACES, better hue preservation)
- For this project, stick with ACES per Octopath reference

**Deprecated/outdated:**
- Manual glow passes: Use built-in Environment.glow_*
- Orthographic camera for HD-2D: Perspective needed for depth effects

## Open Questions

1. **Exact camera distance and position**
   - What we know: ~35-45 degree angle, perspective projection
   - What's unclear: Exact distance depends on room size and desired framing
   - Recommendation: Start at 10 units distance, 50 FOV, adjust to frame full room

2. **Optimal SSAO radius for scene scale**
   - What we know: Default 1.0 radius works for typical scenes
   - What's unclear: Depends on world unit scale of pixel art assets
   - Recommendation: Start at 1.0, increase if AO appears too localized

3. **Glow intensity for "dreamy" feel**
   - What we know: Octopath uses visible bloom, softlight blend mode
   - What's unclear: Exact intensity is taste-dependent
   - Recommendation: Start at 0.5 intensity, 0.1 bloom, tune by eye

## Sources

### Primary (HIGH confidence)
- Godot 4.3 Environment Class Documentation (Rokojori Labs mirror) - SSAO, tonemap, ambient, glow properties
- Godot Engine Official Documentation - Environment and post-processing, Camera3D
- Project's existing `HD2D tiltishift godot research.md` - Comprehensive HD-2D technical guide

### Secondary (MEDIUM confidence)
- GDQuest Tonemap Glossary - ACES vs AgX comparison, tonemapper descriptions
- GDQuest Pixel Art Setup Guide - Texture filtering, project settings
- Color temperature references - Warm light Kelvin values (1800K-3000K range)

### Tertiary (LOW confidence)
- Octopath Traveler camera angle discussions - General guidance that it "looks into" not "onto" scenes
- Interior lighting patterns from Unity HDRP guides - Layered lighting concepts (engine-agnostic)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All features built into Godot 4.6, documented
- Architecture: HIGH - Node structure follows Godot patterns and existing research doc
- Lighting values: MEDIUM - Color temperatures verified, exact energies are starting points
- Camera setup: MEDIUM - Angle approach verified, exact values need tuning
- Pitfalls: HIGH - Common issues well-documented across sources

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - Godot 4.6 is stable release)
