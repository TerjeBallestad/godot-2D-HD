# HD-2D Style & Tilt-Shift Effects in Godot 4
## A Technical Guide to Achieving Octopath Traveler's Visual Style

---

## Table of Contents
1. [What is HD-2D?](#what-is-hd-2d)
2. [Key Visual Components](#key-visual-components)
3. [Scene Setup](#scene-setup)
4. [Depth of Field / Tilt-Shift](#depth-of-field--tilt-shift)
5. [Volumetric Lighting & God Rays](#volumetric-lighting--god-rays)
6. [2D Sprites in 3D World](#2d-sprites-in-3d-world)
7. [Post-Processing Effects](#post-processing-effects)
8. [Complete Environment Setup](#complete-environment-setup)
9. [Resources & References](#resources--references)

---

## What is HD-2D?

HD-2D is an art style coined and trademarked by Square Enix for Octopath Traveler (2018). It combines:

- **2D pixel art sprites** (billboard characters)
- **3D environments** with low-poly or stylized geometry
- **Modern rendering effects**: dynamic lighting, depth of field, bloom, volumetric fog
- **Tilt-shift perspective** creating a diorama/miniature effect

The original Octopath Traveler was built in Unreal Engine 4 with a team of only 6 programmers, relying heavily on UE4's built-in tools. The good news: Godot 4 has most of the features needed to replicate this style.

### Why This Style Works

The HD-2D aesthetic succeeds because:
- Depth of field blur **hides geometric simplicity**
- Pixel art sprites **carry character detail** without expensive 3D models
- Heavy post-processing creates visual **cohesion** between 2D and 3D elements
- The "miniature" look is **forgiving** of low-poly environments

---

## Key Visual Components

Based on the original Octopath Traveler technical breakdowns, the HD-2D style requires:

| Component | Purpose | Godot 4 Solution |
|-----------|---------|------------------|
| Depth of Field | Tilt-shift miniature effect | Custom shader or Camera3D DoF |
| Volumetric Lighting | God rays, atmosphere | VolumetricFog + GPU Particles |
| Bloom/Glow | Dreamy, soft lighting | WorldEnvironment Glow |
| Vignette | Focus attention, cinematic | Custom shader (not built-in) |
| Point Lights | Character shadows on environment | OmniLight3D/SpotLight3D |
| Billboard Sprites | 2D characters in 3D world | Sprite3D with billboard mode |

---

## Scene Setup

### Basic Node Structure

```
Main (Node3D)
├── WorldEnvironment
├── DirectionalLight3D (sun)
├── Camera3D
│   └── PostProcessing (ColorRect or SubViewportContainer)
├── Environment (Node3D)
│   ├── GridMap or MeshInstances (3D world)
│   └── VolumetricFogVolume (optional)
└── Characters (Node3D)
    └── Sprite3D (billboard player)
```

### WorldEnvironment Resource

Create an Environment resource with these initial settings:

```gdscript
# Basic environment setup via code (or configure in Inspector)
var env = Environment.new()

# Background
env.background_mode = Environment.BG_SKY
# Or for indoor: Environment.BG_COLOR

# Ambient Light
env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
env.ambient_light_energy = 0.3

# Tone Mapping (important for HDR look)
env.tonemap_mode = Environment.TONE_MAPPER_ACES

# SSAO (subtle depth)
env.ssao_enabled = true
env.ssao_intensity = 1.0

# Glow/Bloom
env.glow_enabled = true
env.glow_intensity = 0.3
env.glow_bloom = 0.1
env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
```

---

## Depth of Field / Tilt-Shift

This is the **most important effect** for achieving the miniature look. Godot offers multiple approaches:

### Option 1: Built-in Camera3D DoF (Simplest)

Camera3D has built-in depth of field, but it's limited for tilt-shift:

```gdscript
# On your Camera3D
camera.dof_blur_far_enabled = true
camera.dof_blur_far_distance = 10.0
camera.dof_blur_far_transition = 5.0
camera.dof_blur_amount = 0.1

camera.dof_blur_near_enabled = true
camera.dof_blur_near_distance = 2.0
camera.dof_blur_near_transition = 1.0
```

**Limitation**: This blurs based on distance from camera, not a focal plane. Works okay for some angles but isn't true tilt-shift.

### Option 2: Simple Tilt-Shift Shader (Screen-Based)

Apply to a full-screen ColorRect. Blurs top and bottom of screen regardless of depth:

```glsl
// tilt_shift_simple.gdshader
shader_type canvas_item;

uniform float limit: hint_range(0.0, 0.5) = 0.2;
uniform float blur: hint_range(0.0, 8.0) = 2.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    if (UV.y < limit) {
        float blur_amount = blur * (1.0 - (SCREEN_UV.y / limit));
        COLOR = textureLod(screen_texture, SCREEN_UV, blur_amount);
    } else if (UV.y > 1.0 - limit) {
        float blur_amount = blur * (1.0 - ((1.0 - SCREEN_UV.y) / limit));
        COLOR = textureLod(screen_texture, SCREEN_UV, blur_amount);
    } else {
        COLOR.a = 0.0;
    }
}
```

**Usage**:
1. Add a ColorRect as child of Camera3D (or CanvasLayer)
2. Set anchors to Full Rect
3. Apply ShaderMaterial with this shader
4. Adjust `limit` (0.2 = 20% blur zone) and `blur` strength

### Option 3: Depth-Based Tilt-Shift (Most Accurate)

This shader reads actual scene depth to create proper focal plane blur:

```glsl
// tilt_shift_depth.gdshader
shader_type spatial;
render_mode unshaded;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
varying mat4 CAMERA;

uniform vec3 focal_point = vec3(0.0);
uniform float DoF = 5.0;                              // Depth of field width (meters)
uniform float blur_cap: hint_range(0.0, 8.0) = 2.0;  // Max blur
uniform float blur_rate = 2.0;                        // How fast blur increases
uniform float vertical_bias = 1.0;                    // 1.0 = perpendicular to camera, 0.0 = vertical plane

void vertex() {
    // Godot 4.3+
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
    CAMERA = INV_VIEW_MATRIX;
}

float PlanePointDist(vec3 pn, vec3 pp, vec3 p) {
    float d = -(pn.x * pp.x + pn.y * pp.y + pn.z * pp.z);
    float a = abs((pn.x * p.x + pn.y * p.y + pn.z * p.z + d));
    float b = sqrt(pn.x * pn.x + pn.y * pn.y + pn.z * pn.z);
    return a / b;
}

void fragment() {
    float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
    vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
    vec4 world = CAMERA * upos;
    vec3 world_position = world.xyz / world.w;

    vec3 focal_plane_normal = focal_point - CAMERA_POSITION_WORLD;
    focal_plane_normal.y *= vertical_bias;

    float dist_to_plane = PlanePointDist(focal_plane_normal, focal_point, world_position);
    float blur_amount = clamp((dist_to_plane - DoF) / blur_rate, 0.0, blur_cap);

    vec4 color = textureLod(screen_texture, SCREEN_UV, blur_amount);
    ALBEDO = color.xyz;
}
```

**Setup**:
1. Create a MeshInstance3D with a QuadMesh
2. Follow Godot's [Full Screen Quad](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html#full-screen-quad) setup
3. Update `focal_point` from GDScript to follow your character:

```gdscript
extends MeshInstance3D

@export var target: Node3D

func _process(_delta):
    if target:
        mesh.material.set_shader_parameter("focal_point", target.global_position)
```

### Recommended Tilt-Shift Values

| Parameter | HD-2D Style | Subtle Effect |
|-----------|-------------|---------------|
| DoF | 3.0–5.0 | 8.0–15.0 |
| blur_cap | 2.0–3.0 | 1.0–1.5 |
| blur_rate | 2.0–3.0 | 4.0–5.0 |
| vertical_bias | 0.5–0.8 | 1.0 |

---

## Volumetric Lighting & God Rays

God rays are essential for the Octopath Traveler atmosphere. Godot 4 offers several approaches:

### Option 1: Built-in Volumetric Fog

Enable in WorldEnvironment:

```gdscript
env.volumetric_fog_enabled = true
env.volumetric_fog_density = 0.01
env.volumetric_fog_emission = Color(1, 1, 1)
env.volumetric_fog_emission_energy = 0.5
env.volumetric_fog_anisotropy = 0.5  # Higher = more directional
```

Then enable volumetric on your DirectionalLight3D:

```gdscript
sun.light_volumetric_fog_energy = 1.0
```

**Project Settings** (important for quality):
- `rendering/environment/volumetric_fog/volume_depth` = 128 (or higher)
- `rendering/environment/volumetric_fog/volume_size` = 128

### Option 2: GPU Particle God Rays

For more stylized, controllable rays (like Octopath):

1. Create GPUParticles3D
2. Set Process Material:
   - Direction: Downward (0, -1, 0)
   - Spread: 5–15 degrees
   - Gravity: 0 (or slight)
   - Initial Velocity: Low (0.5–2.0)
3. Use a soft gradient texture (vertical strip, alpha fade on edges)
4. Material: StandardMaterial3D with:
   - Transparency: Alpha
   - Shading Mode: Unshaded
   - Billboard Mode: Particles (Y-Billboard for rays)

### Option 3: Screen-Space God Rays Shader

For post-processing god rays from DirectionalLight:

```glsl
// god_rays_screen.gdshader (on ColorRect)
shader_type canvas_item;
render_mode unshaded, blend_add;

uniform sampler2D subviewport_tex : filter_linear;
uniform float ray_length : hint_range(0.0, 1.0) = 0.5;
uniform float ray_intensity : hint_range(0.0, 1.0) = 0.3;
uniform vec2 light_source_pos = vec2(0.5, 0.0);  // Update from code
uniform int num_samples = 64;

void fragment() {
    vec2 dir = light_source_pos - SCREEN_UV;
    float dist = length(dir);
    dir = normalize(dir) * ray_length / float(num_samples);

    vec4 color = vec4(0.0);
    vec2 uv = SCREEN_UV;

    for (int i = 0; i < num_samples; i++) {
        color += texture(subviewport_tex, uv);
        uv += dir;
    }

    color /= float(num_samples);
    COLOR = color * ray_intensity * (1.0 - dist);
}
```

---

## 2D Sprites in 3D World

### Sprite3D Setup

```gdscript
# Character setup
var sprite = Sprite3D.new()
sprite.texture = preload("res://sprites/character.png")
sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST  # Pixel art!
sprite.pixel_size = 0.01  # Adjust for your scale
```

**Inspector Settings** for Sprite3D:
- Billboard: Enabled (or Y-Billboard for partial rotation)
- Alpha Cut: Discard (for hard pixel edges) or Opaque Pre-Pass
- Texture Filter: Nearest (crucial for pixel art!)
- Shaded: Enable if you want lighting to affect sprite

### Billboard Shader with Pixel Art Support

```glsl
// billboard_pixelart.gdshader
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque;

uniform sampler2D tex : source_color, filter_nearest;
uniform bool y_billboard = true;

void vertex() {
    if (y_billboard) {
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
            vec4(0.0, 1.0, 0.0, 0.0),
            vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
            MODEL_MATRIX[3]
        );
    } else {
        MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
            INV_VIEW_MATRIX[0],
            INV_VIEW_MATRIX[1],
            INV_VIEW_MATRIX[2],
            MODEL_MATRIX[3]
        );
    }
    MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
        vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
        vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
        vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
        vec4(0.0, 0.0, 0.0, 1.0)
    );
}

void fragment() {
    vec4 color = texture(tex, UV);
    ALBEDO = color.rgb;
    ALPHA = color.a;
    ALPHA_SCISSOR_THRESHOLD = 0.5;
}
```

### Point Light for Character Shadows

Octopath adds point lights synchronized with spell effects to cast character shadows:

```gdscript
# When a spell fires, create temporary point light
var light = OmniLight3D.new()
light.light_color = Color(1.0, 0.9, 0.7)
light.light_energy = 2.0
light.omni_range = 10.0
light.shadow_enabled = true
add_child(light)

# Animate and remove
var tween = create_tween()
tween.tween_property(light, "light_energy", 0.0, 0.5)
tween.tween_callback(light.queue_free)
```

---

## Post-Processing Effects

### Vignette Shader (Not Built-In!)

Godot 4 does not have built-in vignette. Use this shader on a full-screen ColorRect:

```glsl
// vignette.gdshader
shader_type canvas_item;

uniform float vignette_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform sampler2D screen_texture : hint_screen_texture;

float vignette(vec2 uv) {
    uv *= 1.0 - uv.xy;
    float vig = uv.x * uv.y * 15.0;
    return pow(vig, vignette_intensity * vignette_opacity);
}

void fragment() {
    vec4 color = texture(screen_texture, SCREEN_UV);
    float vig = vignette(UV);
    COLOR = vec4(mix(vignette_color.rgb, color.rgb, vig), color.a);
}
```

### Blur Vignette (Combined Effect)

For the HD-2D edge blur + darkening:

```glsl
// blur_vignette.gdshader
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 5.0) = 2.0;
uniform float blur_inner : hint_range(0.0, 1.0) = 0.5;
uniform float blur_outer : hint_range(0.0, 1.0) = 0.8;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.3;

void fragment() {
    vec4 pixel_color = texture(screen_texture, SCREEN_UV);
    vec4 blur_color = textureLod(screen_texture, SCREEN_UV, blur_amount);

    float distance = length(UV - vec2(0.5));
    float blur_factor = smoothstep(blur_inner, blur_outer, distance);

    vec4 final_color = mix(pixel_color, blur_color, blur_factor);
    final_color.rgb *= 1.0 - (blur_factor * darken_amount);

    COLOR = final_color;
}
```

### Bloom/Glow Settings

In WorldEnvironment:

```gdscript
env.glow_enabled = true
env.glow_levels[0] = 0.0  # Disable or tune each level
env.glow_levels[1] = 1.0
env.glow_levels[2] = 1.0
env.glow_intensity = 0.8
env.glow_strength = 1.0
env.glow_bloom = 0.2       # Light bleeding
env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
env.glow_hdr_threshold = 1.0
env.glow_hdr_scale = 2.0
```

---

## Complete Environment Setup

### Example WorldEnvironment Configuration

```gdscript
extends WorldEnvironment

func _ready():
    var env = Environment.new()

    # === BACKGROUND ===
    env.background_mode = Environment.BG_COLOR
    env.background_color = Color(0.1, 0.1, 0.15)

    # === AMBIENT LIGHT ===
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.4, 0.45, 0.5)
    env.ambient_light_energy = 0.5

    # === TONE MAPPING ===
    env.tonemap_mode = Environment.TONE_MAPPER_ACES
    env.tonemap_exposure = 1.0
    env.tonemap_white = 6.0

    # === SSAO ===
    env.ssao_enabled = true
    env.ssao_radius = 1.0
    env.ssao_intensity = 2.0

    # === GLOW ===
    env.glow_enabled = true
    env.glow_intensity = 0.6
    env.glow_bloom = 0.15
    env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

    # === VOLUMETRIC FOG ===
    env.volumetric_fog_enabled = true
    env.volumetric_fog_density = 0.005
    env.volumetric_fog_emission = Color(1.0, 0.95, 0.9)
    env.volumetric_fog_emission_energy = 0.3
    env.volumetric_fog_anisotropy = 0.6

    environment = env
```

### DirectionalLight3D (Sun) Setup

```gdscript
extends DirectionalLight3D

func _ready():
    light_color = Color(1.0, 0.95, 0.85)  # Warm sunlight
    light_energy = 1.2
    shadow_enabled = true
    shadow_blur = 0.5
    light_volumetric_fog_energy = 1.5

    # Angle for god rays
    rotation_degrees = Vector3(-45, -30, 0)
```

---

## Performance Considerations

| Effect | Cost | Optimization |
|--------|------|--------------|
| Depth-based DoF | Medium | Lower blur_cap, reduce samples |
| Volumetric Fog | High | Reduce volume_size, volume_depth |
| God Ray Particles | Medium | Limit particle count |
| Bloom | Low | Use blend mode carefully |
| Vignette | Very Low | N/A |
| Sprite3D Billboards | Low | Use Y-Billboard when possible |

### Mobile/Web Considerations

- Use simple screen-based tilt-shift instead of depth-based
- Disable volumetric fog; use particle-based god rays
- Reduce bloom levels
- Ensure Forward+ or Mobile renderer compatibility

---

## Resources & References

### Godot Shaders

- [Depth-Based Tilt-Shift](https://godotshaders.com/shader/depth-based-tilt-shift/)
- [Tilt-Shift Shader (Minimal)](https://godotshaders.com/shader/tilt-shift-shader-minimal/)
- [Screen Space God Rays](https://godotshaders.com/shader/screen-space-god-rays-godot-4-3/)
- [Vignette Shader](https://godotshaders.com/shader/vignette-shader-for-godot-4/)
- [Billboard Sprite3D](https://godotshaders.com/shader/billboard-sprite3d-hitflash-godot-4-x/)

### Example Projects

- [SimpleHD2D (Godot 4.1)](https://github.com/GSansigolo/SimpleHD2D) - Basic HD-2D implementation
- [Gamedev Aki HD-2D Tutorial](https://ko-fi.com/s/ef3d84d009) - Paid source with god rays, billboards, shaders

### Technical Breakdowns

- [Unreal Engine: Octopath Traveler Art Style](https://www.unrealengine.com/en-US/spotlights/octopath-traveler-s-hd-2d-art-style-and-story-make-for-a-jrpg-dream-come-true)
- [HD-2D Wikipedia](https://en.wikipedia.org/wiki/HD-2D) - Technical overview of the style
- [3D Pixel Art Rendering in Godot](https://www.davidhol.land/articles/3d-pixel-art-rendering/) - Advanced techniques

### Godot Documentation

- [Environment and Post-Processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)
- [Full-Screen Quad Setup](https://docs.godotengine.org/en/stable/tutorials/shaders/advanced_postprocessing.html#full-screen-quad)
- [Sprite3D](https://docs.godotengine.org/en/stable/classes/class_sprite3d.html)

---

## Summary: Achievability in Godot

| Aspect | Difficulty | Native Support |
|--------|------------|----------------|
| Depth of Field | ⭐⭐ | Partial (custom shader recommended) |
| Tilt-Shift | ⭐⭐⭐ | No (custom shader required) |
| God Rays | ⭐⭐ | Yes (VolumetricFog) + custom options |
| Bloom | ⭐ | Yes (WorldEnvironment) |
| Vignette | ⭐⭐ | No (simple custom shader) |
| 2D in 3D | ⭐ | Yes (Sprite3D) |
| Point Light Shadows | ⭐ | Yes |

**Overall verdict**: HD-2D style is **7-8/10 achievable** with stock Godot 4, and **9/10** with the custom shaders provided in this guide. The main work is setting up the tilt-shift DoF shader and tuning your post-processing stack.

---

*Document compiled February 2026 | Godot 4.x compatible*
