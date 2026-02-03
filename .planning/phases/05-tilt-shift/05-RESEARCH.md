# Phase 5: Tilt-Shift - Research

**Researched:** 2026-02-03
**Domain:** Godot 4 depth-based blur shaders, post-processing, focal tracking
**Confidence:** MEDIUM

## Summary

Implementing depth-based tilt-shift in Godot 4 requires a spatial shader that samples both the screen texture and depth buffer. The standard approach uses a fullscreen quad (MeshInstance3D) with a spatial shader in `render_mode unshaded`. The depth buffer is accessed via `hint_depth_texture`, linearized using `INV_PROJECTION_MATRIX`, then converted to world-space distance from a focal point.

The blur technique presents a critical architectural decision: Godot 4's spatial shaders have limited mipmap support for `hint_screen_texture` (mipmaps work well in Vulkan but had issues in OpenGL Compatibility, now fixed with PR #78168). For the HD-2D miniature look with subtle blur, the `textureLod()` approach with `filter_linear_mipmap` provides adequate quality with good performance. For subtle bokeh quality on highlights, a weighted radial sampling pattern can enhance the effect without excessive performance cost.

The focal tracking system requires GDScript to update the shader's `focal_point` uniform each frame based on the player's global position, with smoothing via `lerp()` to create the lagged focal movement.

**Primary recommendation:** Use spatial shader with `textureLod()` mipmap blur, MeshInstance3D fullscreen quad as camera child, and GDScript focal tracking with exponential smoothing.

## Standard Stack

The established approach for Godot 4 depth-based tilt-shift:

### Core
| Component | Type | Purpose | Why Standard |
|-----------|------|---------|--------------|
| `hint_depth_texture` | Sampler uniform | Access depth buffer | Official Godot 4 depth access method |
| `hint_screen_texture` | Sampler uniform | Access rendered scene | Official Godot 4 screen texture access |
| `filter_linear_mipmap` | Sampler hint | Enable mipmap blur via textureLod | Efficient blur without multi-pass |
| MeshInstance3D + QuadMesh | Node | Fullscreen shader quad | Official Godot post-processing pattern |
| Spatial shader | Shader type | Access depth + screen textures | Only shader type with depth buffer access |

### Supporting
| Component | Type | Purpose | When to Use |
|-----------|------|---------|-------------|
| `INV_PROJECTION_MATRIX` | Built-in | Linearize depth values | Convert raw depth to view-space Z |
| `INV_VIEW_MATRIX` | Built-in | World position reconstruction | Calculate world-space distance |
| `lerp()` / GDScript | Function | Focal point smoothing | Lagged focal tracking |
| `smoothstep()` | Function | Ease falloff curve | Smooth blur transition |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| textureLod mipmap blur | Box blur kernel | Higher quality but 16+ samples per pixel vs 1 |
| textureLod mipmap blur | Multi-pass Gaussian | Best quality but requires SubViewport complexity |
| Spatial shader quad | CompositorEffect | More flexible but requires GLSL, breaks transparent objects |
| Single-pass | Two-pass blur | Better quality blur but double the shader overhead |

**No installation required** - all components are built into Godot 4.

## Architecture Patterns

### Recommended Node Structure
```
InteriorScene
├── ... (existing nodes)
├── PostProcessing (CanvasLayer, layer=100)
│   └── Vignette (ColorRect) # Existing
└── TiltShiftQuad (MeshInstance3D) # NEW - child of CameraRig/InnerGimbal/Camera3D
    └── mesh: QuadMesh (2x2, flip_faces=true)
    └── material: ShaderMaterial (tilt_shift.gdshader)
```

**Note:** The tilt-shift quad MUST be a child of Camera3D (or positioned at camera child origin) so it always fills the view. The vignette stays on CanvasLayer since it's 2D screen-space overlay.

### Pattern 1: Fullscreen Spatial Shader Quad
**What:** MeshInstance3D with 2x2 QuadMesh displaying a spatial shader that samples screen/depth
**When to use:** Any post-processing requiring depth buffer access
**Example:**
```gdscript
# Source: https://github.com/godotengine/godot-docs-user-notes/discussions/42
extends MeshInstance3D

func _ready():
    # QuadMesh setup: size 2x2, flip_faces=true
    var quad = QuadMesh.new()
    quad.size = Vector2(2, 2)
    quad.flip_faces = true
    mesh = quad

    # Position slightly in front of camera near plane
    position = Vector3(0, 0, -0.1)

    # Extra cull margin prevents culling at edges
    extra_cull_margin = 16384
```

### Pattern 2: Depth Buffer Linearization
**What:** Convert raw depth (0-1 non-linear) to linear view-space Z distance
**When to use:** Any depth-based effect (DoF, fog, outlines)
**Example:**
```glsl
// Source: https://github.com/godotengine/godot-docs-user-notes/discussions/42
float depth_raw = texture(depth_texture, SCREEN_UV).x;
vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
position_view.xyz /= position_view.w;
float linear_depth = -position_view.z;  // Positive distance from camera
```

### Pattern 3: World Position from Depth
**What:** Reconstruct world-space position from depth for spherical distance calculation
**When to use:** Focal plane distance calculation (user decision: spherical shape)
**Example:**
```glsl
// Source: https://godotshaders.com/shader/depth-based-tilt-shift/
vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth_raw, 1.0);
vec4 world = INV_VIEW_MATRIX * upos;
vec3 world_position = world.xyz / world.w;
float dist_to_focal = distance(world_position, focal_point);
```

### Pattern 4: Smoothed Focal Point Tracking
**What:** GDScript updates shader focal_point with exponential smoothing
**When to use:** Lagged focal following (user decision)
**Example:**
```gdscript
# Source: Standard exponential smoothing pattern
var current_focal: Vector3 = Vector3.ZERO
const FOCAL_SMOOTHING: float = 5.0  # Higher = faster follow

func _process(delta: float) -> void:
    var target_focal = player.global_position + Vector3(0, 0.5, 0)  # Mid-body anchor
    current_focal = current_focal.lerp(target_focal, 1.0 - exp(-FOCAL_SMOOTHING * delta))
    shader_material.set_shader_parameter("focal_point", current_focal)
```

### Anti-Patterns to Avoid
- **CanvasLayer for depth effects:** Canvas shaders cannot access depth buffer - must use spatial shader
- **Quad at origin:** Will be culled by camera near plane - position at -0.1 Z
- **Hard-coded screen size:** Use `SCREEN_UV` and `VIEWPORT_SIZE` for resolution independence
- **Blur without depth check:** Objects at screen edges may have invalid depth - reduce blur near edges

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Depth linearization | Custom depth math | `INV_PROJECTION_MATRIX` pattern | Handles projection correctly, works with any FOV |
| Mipmap blur | Manual Gaussian kernel | `textureLod(screen_texture, UV, lod)` | One sample vs 16+, leverages GPU mipmap hardware |
| Smooth transitions | Linear interpolation | `smoothstep(edge0, edge1, x)` | Built-in Hermite curve, handles edge cases |
| Frame-rate independent smoothing | `delta * factor` | `lerp(a, b, 1.0 - exp(-factor * delta))` | Consistent behavior at any frame rate |
| Focal point easing | Custom easing math | `lerp()` with exponential decay | Well-understood, tunable with single parameter |

**Key insight:** The textureLod approach leverages GPU mipmap generation which is highly optimized. A hand-rolled box blur requires 9-25+ texture samples per pixel; textureLod requires 1. For the subtle HD-2D diorama blur (not heavy bokeh), this quality/performance tradeoff is correct.

## Common Pitfalls

### Pitfall 1: Depth Buffer Coordinates
**What goes wrong:** Raw depth values are non-linear; objects appear to blur wrong
**Why it happens:** Depth buffer stores `z/w` not linear distance; perspective projection is non-linear
**How to avoid:** Always linearize depth using `INV_PROJECTION_MATRIX` pattern
**Warning signs:** Blur appears to "pop" rather than fade, near objects over-blurred

### Pitfall 2: Transparent Objects Not Captured
**What goes wrong:** Characters with alpha (Sprite3D) don't appear in tilt-shift effect
**Why it happens:** Post-processing spatial shaders render after opaque but BEFORE transparent pass
**How to avoid:** Sprite3D with `alpha_cut = 2` (ALPHA_SCISSOR) writes to depth buffer and is treated as opaque
**Warning signs:** Character appears un-blurred or "cut out" from scene
**Note:** Project already uses `alpha_scissor_threshold = 0.5` on player sprite - this is correct

### Pitfall 3: Quad Culled by Camera
**What goes wrong:** Tilt-shift effect disappears at certain camera angles
**Why it happens:** MeshInstance3D at origin gets culled by camera near plane (0.05)
**How to avoid:** Position quad at `z = -0.1` and set `extra_cull_margin = 16384`
**Warning signs:** Effect flickers or disappears when camera moves

### Pitfall 4: Screen Edge Artifacts
**What goes wrong:** Blur artifacts appear at screen edges, especially when blurring heavily
**Why it happens:** Depth buffer has no data outside viewport; blur samples invalid areas
**How to avoid:** Reduce blur amount near screen edges using UV-based falloff
**Warning signs:** Dark halos or stretched pixels at viewport boundaries
**Example fix:**
```glsl
// User decision: reduce blur at scene edges
vec2 edge_dist = min(SCREEN_UV, 1.0 - SCREEN_UV);
float edge_factor = smoothstep(0.0, 0.1, min(edge_dist.x, edge_dist.y));
blur_amount *= edge_factor;
```

### Pitfall 5: Blur Banding
**What goes wrong:** Visible steps/bands in blur gradient instead of smooth transition
**Why it happens:** Insufficient precision in distance calculation or too-sharp falloff curve
**How to avoid:** Use `smoothstep()` for transitions; ensure float precision in uniforms
**Warning signs:** Visible rings around focal point

### Pitfall 6: Performance on Integrated GPUs
**What goes wrong:** Frame rate drops significantly when tilt-shift is enabled
**Why it happens:** Screen texture sampling is expensive; each textureLod still samples full mipchain
**How to avoid:** Keep blur_cap low (2.0-3.0 max for subtle effect); provide debug toggle
**Warning signs:** FPS drops from 60 to 30 when effect enabled
**Note:** User decided on "subtle blur" - this naturally limits performance impact

## Code Examples

Verified patterns from official sources and community:

### Complete Tilt-Shift Shader
```glsl
// Source: Adapted from https://godotshaders.com/shader/depth-based-tilt-shift/
// and https://github.com/godotengine/godot-docs-user-notes/discussions/42
shader_type spatial;
render_mode unshaded, fog_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture, filter_linear_mipmap;
uniform sampler2D depth_texture : hint_depth_texture;

uniform vec3 focal_point = vec3(0.0, 0.5, 0.0);
uniform float focus_distance : hint_range(0.5, 5.0) = 1.5;  // Wide focus zone
uniform float blur_max : hint_range(0.0, 4.0) = 2.0;  // Subtle blur cap
uniform float blur_transition : hint_range(0.5, 5.0) = 2.0;  // Smooth gradient
uniform bool enabled = true;

void vertex() {
    POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
    if (!enabled) {
        ALBEDO = texture(screen_texture, SCREEN_UV).rgb;
        return;
    }

    // Reconstruct world position from depth
    float depth_raw = texture(depth_texture, SCREEN_UV).x;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
    vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    position_view.xyz /= position_view.w;
    vec4 world = INV_VIEW_MATRIX * position_view;
    vec3 world_position = world.xyz / world.w;

    // Spherical distance from focal point (user decision)
    float dist_to_focal = distance(world_position, focal_point);

    // Smooth ease falloff (user decision: smooth curve, slow start)
    float blur_factor = smoothstep(focus_distance, focus_distance + blur_transition, dist_to_focal);
    float blur_amount = blur_factor * blur_max;

    // Reduce blur at screen edges (user decision)
    vec2 edge_dist = min(SCREEN_UV, 1.0 - SCREEN_UV);
    float edge_factor = smoothstep(0.0, 0.1, min(edge_dist.x, edge_dist.y));
    blur_amount *= edge_factor;

    // Sample with mipmap blur
    vec3 color = textureLod(screen_texture, SCREEN_UV, blur_amount).rgb;

    ALBEDO = color;
}
```

### Focal Tracking Controller
```gdscript
# Source: Standard exponential smoothing pattern
extends MeshInstance3D
## Tilt-shift depth blur controller.
## Updates focal point to follow player with smooth lag.

@export var player_path: NodePath
@export var focal_smoothing: float = 5.0  # Higher = faster follow
@export var focal_height_offset: float = 0.5  # Mid-body anchor

var player: Node3D
var current_focal: Vector3 = Vector3.ZERO
var shader_material: ShaderMaterial

func _ready() -> void:
    player = get_node(player_path)
    shader_material = mesh.surface_get_material(0) as ShaderMaterial

    # Initialize focal point at player position
    if player:
        current_focal = player.global_position + Vector3(0, focal_height_offset, 0)
        shader_material.set_shader_parameter("focal_point", current_focal)

func _process(delta: float) -> void:
    if not player:
        return

    var target_focal = player.global_position + Vector3(0, focal_height_offset, 0)

    # Exponential smoothing for frame-rate independent lag
    current_focal = current_focal.lerp(target_focal, 1.0 - exp(-focal_smoothing * delta))

    shader_material.set_shader_parameter("focal_point", current_focal)
```

### QuadMesh Setup
```gdscript
# Source: Godot docs, validated in discussions
func _create_fullscreen_quad() -> void:
    var quad = QuadMesh.new()
    quad.size = Vector2(2, 2)
    quad.flip_faces = true
    mesh = quad

    # Position in front of near plane
    position = Vector3(0, 0, -0.1)

    # Prevent culling
    extra_cull_margin = 16384

    # Load shader material
    var mat = ShaderMaterial.new()
    mat.shader = preload("res://shaders/tilt_shift.gdshader")
    mesh.surface_set_material(0, mat)
```

### Debug Toggle Integration
```gdscript
# Add to tilt_shift controller or input handler
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed:
        if event.keycode == KEY_T:  # T for Tilt-shift toggle
            var enabled = shader_material.get_shader_parameter("enabled")
            shader_material.set_shader_parameter("enabled", !enabled)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `DEPTH_TEXTURE` built-in | `hint_depth_texture` uniform | Godot 4.0 | Must declare sampler uniform |
| `SCREEN_TEXTURE` built-in | `hint_screen_texture` uniform | Godot 4.0 | Must declare sampler uniform |
| OpenGL blocky mipmaps | Gaussian approximation | Godot 4.3 (PR #78168) | Better blur quality in Compatibility |
| Standard Z depth (0=near) | Reverse Z depth (1=near) | Godot 4.3 | Better precision, no shader change needed |

**Deprecated/outdated:**
- `DEPTH_TEXTURE` and `SCREEN_TEXTURE` as built-ins: Use uniform samplers with hints
- `texture()` for blur: Use `textureLod()` with explicit LOD parameter for blur control

## Open Questions

Things that couldn't be fully resolved:

1. **Bokeh highlight spreading**
   - What we know: User wants "subtle bokeh quality on highlights"
   - What's unclear: textureLod produces simple blur, not shaped bokeh
   - Recommendation: For subtle effect, textureLod is sufficient. If more pronounced bokeh needed, add weighted radial sampling for bright pixels only (threshold > 1.0 for HDR highlights)

2. **Stop behavior for focal tracking**
   - Claude's discretion area
   - Recommendation: Use continuous easing (no special stop behavior). When player stops, focal point continues easing toward final position then naturally settles. This feels more cinematic than instant stop.

3. **Exact smoothing values**
   - Claude's discretion area
   - Recommendation: Start with `focal_smoothing = 5.0` (perceptible lag without feeling sluggish). Tune during evaluation if needed.

4. **Screen border depth edge cases**
   - Claude's discretion area
   - Recommendation: Use UV-based edge falloff (reduce blur to 0 at screen edges). Simple and effective.

## Sources

### Primary (HIGH confidence)
- [Godot Docs User Notes - Post Processing Discussion](https://github.com/godotengine/godot-docs-user-notes/discussions/42) - Complete spatial shader setup, depth linearization
- [Godot Shaders - Depth-based Tilt-shift](https://godotshaders.com/shader/depth-based-tilt-shift/) - MIT licensed reference implementation

### Secondary (MEDIUM confidence)
- [Godot Shaders - Dynamic Depth of Field](https://godotshaders.com/shader/dynamic-depth-of-field/) - GDScript focal tracking pattern
- [Godot Shaders - Circle Bokeh Blur](https://godotshaders.com/shader/circle-bokeh-blur/) - Radial sampling pattern if bokeh enhancement needed
- [GitHub - ttencate/blur_godot4](https://github.com/ttencate/blur_godot4) - Two-pass Gaussian alternative
- [Godot GitHub PR #78168](https://github.com/godotengine/godot/pull/78168) - Gaussian mipmap fix for Compatibility renderer

### Tertiary (LOW confidence)
- [Godot Shaders - Interpolation Snippet](https://godotshaders.com/snippet/interpolation/) - smoothstep documentation
- WebSearch results for general Godot 4 shader practices

## Metadata

**Confidence breakdown:**
- Standard stack: MEDIUM - Well-documented patterns, but spatial shader mipmap behavior has known edge cases
- Architecture: HIGH - MeshInstance3D quad pattern is official Godot recommendation
- Depth access: HIGH - INV_PROJECTION_MATRIX pattern verified in multiple sources
- Focal tracking: MEDIUM - Standard exponential smoothing, specific values need tuning
- Pitfalls: MEDIUM - Collected from forum discussions and GitHub issues

**Research date:** 2026-02-03
**Valid until:** 30 days (stable Godot 4 rendering patterns)
