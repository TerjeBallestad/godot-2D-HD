# Phase 2: Character - Research

**Researched:** 2026-02-02
**Domain:** Godot 4 Sprite3D billboard character with pixel-art filtering, blob shadow, and scene integration
**Confidence:** HIGH

## Summary

This phase creates a player character as a pixel-art billboard sprite in the existing 3D interior scene. The research focused on Godot 4's Sprite3D/SpriteBase3D configuration for Y-axis billboarding, nearest-neighbor texture filtering for crisp pixels, and proper scene integration including blob shadows using Decal nodes.

The core approach is straightforward: Sprite3D with `billboard = BILLBOARD_FIXED_Y` rotates horizontally to face the camera while staying upright. The key considerations are texture filtering (nearest-neighbor for pixel art), alpha handling (ALPHA_CUT_OPAQUE_PREPASS for proper depth sorting with 3D objects), and lighting influence (shaded=true with modulate for subtle lighting while preserving readability).

For blob shadows, Godot 4's Decal node is the standard solution. A ShapeCast3D detects ground surfaces and positions the Decal dynamically, with alpha fading based on distance to ground. This provides the "grounded" feel without complex shadow rendering.

**Primary recommendation:** Use Sprite3D with BILLBOARD_FIXED_Y, TEXTURE_FILTER_NEAREST, and ALPHA_CUT_OPAQUE_PREPASS. Add a Decal child node for blob shadow positioned via ShapeCast3D. Enable shaded lighting but keep it subtle through modulate color.

## Standard Stack

### Core (Built into Godot 4.6)
| Node/Resource | Purpose | Why Standard |
|---------------|---------|--------------|
| Sprite3D | 2D texture display in 3D space | Built-in billboard support, texture filtering control |
| Decal | Projected texture for blob shadow | Real-time positioning, alpha control, cull_mask for targeting |
| ShapeCast3D | Ground detection for shadow placement | Multi-hit raycast, collision mask control |
| CollisionShape3D | Future character collision | Required for CharacterBody3D in Controls phase |
| CapsuleShape3D | Character collision geometry | Standard for humanoid characters, handles slopes well |

### Supporting
| Node/Resource | Purpose | When to Use |
|---------------|---------|-------------|
| Node3D | Character container | Organizing sprite + shadow + collision as single entity |
| CharacterBody3D | Physics-enabled character | Only if collision needed this phase (Claude's discretion) |

### Not Needed This Phase
| Feature | Why Not |
|---------|---------|
| AnimatedSprite3D | Single static frame only (animation in Controls phase) |
| Custom billboard shader | Built-in BILLBOARD_FIXED_Y handles Y-axis billboarding |
| Real shadow casting | Blob shadow provides grounding without rendering cost |
| SpotLight3D for shadow | User specified simple blob shadow approach |

## Architecture Patterns

### Recommended Scene Structure
```
PlayerCharacter (Node3D or CharacterBody3D)
├── Sprite (Sprite3D)
│   └── [character texture]
├── ShadowCaster (ShapeCast3D)
│   └── BlobShadow (Decal)
│       └── [shadow texture]
└── CollisionShape (CollisionShape3D)  # Optional this phase
    └── CapsuleShape3D
```

**Key organization:**
- Parent node at foot position (sprite origin at bottom)
- Sprite3D offset so feet touch ground
- ShapeCast3D casts downward to find ground
- Decal positioned at ground hit point

### Pattern 1: Y-Axis Billboard Sprite
**What:** Sprite rotates horizontally to face camera but stays perpendicular to floor
**When to use:** Characters, NPCs, any upright 2D elements in 3D space
**Configuration:**

```gdscript
# Source: Godot SpriteBase3D documentation
extends Sprite3D

func _ready() -> void:
    # Billboard mode - Y-axis only (horizontal rotation, stays upright)
    billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

    # Pixel art filtering - CRITICAL for crisp pixels
    texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST

    # Alpha handling - Opaque Pre-Pass for best depth sorting
    alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS

    # Lighting - subtle influence from scene lights
    shaded = true

    # Visibility from both sides (camera orbits around)
    double_sided = true

    # Scale: pixel_size controls world scale of sprite
    # 0.01 = 1 pixel = 0.01 world units (100 pixels = 1 unit)
    pixel_size = 0.01  # Adjust based on asset resolution

    # Subtle color tint to slightly mute lighting effect
    modulate = Color(0.95, 0.95, 0.95, 1.0)
```

### Pattern 2: Blob Shadow with Decal
**What:** Circular shadow projected onto ground surfaces, positioned dynamically
**When to use:** Any dynamic object needing grounding visual without real shadows
**Configuration:**

```gdscript
# Source: The Godot Barn snippet + Godot Decal documentation
extends ShapeCast3D

@export var shadow: Decal
@export var min_distance: float = 0.5  # Fade distance
@export var max_distance: float = 5.0  # Max raycast range

@onready var _initial_alpha: float = shadow.modulate.a

func _ready() -> void:
    # Configure raycast direction (straight down)
    target_position = Vector3(0, -max_distance, 0)

    # Decal configuration
    shadow.size = Vector3(0.5, 1.0, 0.5)  # Width, depth, height of projection
    shadow.cull_mask = 1  # Only project on default layer (ground/furniture)

func _physics_process(_delta: float) -> void:
    if get_collision_count() > 0:
        var hit_point = get_collision_point(0)
        var distance = global_position.distance_to(hit_point)

        # Position shadow at ground level
        shadow.global_position = hit_point

        # Fade shadow based on height (closer to ground = more visible)
        if distance < min_distance:
            shadow.modulate.a = lerp(0.0, _initial_alpha, distance / min_distance)
        else:
            shadow.modulate.a = _initial_alpha
    else:
        # No ground found - hide shadow
        shadow.modulate.a = 0.0
```

### Pattern 3: Collision Shape for Future Movement
**What:** Capsule collision shape ready for CharacterBody3D integration
**When to use:** If preparing collision for Controls phase
**Configuration:**

```gdscript
# Source: Godot collision best practices
# Note: CollisionShape3D must be direct child of physics body

# Capsule dimensions for human-scale character
var capsule = CapsuleShape3D.new()
capsule.radius = 0.25  # ~0.5m diameter
capsule.height = 0.8   # Total height including radius caps

# Position collision shape centered on character
# If sprite origin is at feet, offset capsule up
collision_shape.position.y = capsule.height / 2 + capsule.radius
```

### Anti-Patterns to Avoid
- **Full billboard (BILLBOARD_ENABLED):** Sprite tilts with camera, breaks "standing on floor" illusion
- **ALPHA_CUT_DISABLED:** Transparency sorting issues with 3D objects, sprite may render behind furniture
- **ALPHA_CUT_DISCARD:** Hard jagged edges on semi-transparent pixels
- **shaded=false with no modulate:** Sprite looks "flat" and pasted onto scene
- **Real shadow casting from sprites:** Complex, inconsistent results with billboarded geometry
- **Decal without cull_mask:** Shadow projects onto character itself, walls, everything

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Y-axis billboard | Custom look_at() script | `billboard = BILLBOARD_FIXED_Y` | Built-in handles edge cases, camera changes |
| Blob shadow | Sprite3D on ground plane | Decal node | Projects onto uneven surfaces, proper depth |
| Ground detection | Manual raycast | ShapeCast3D | Multi-collision handling, shape-based detection |
| Pixel filtering | Import settings only | `texture_filter = NEAREST` on Sprite3D | Per-node control, overrides project defaults |
| Depth sorting | render_priority tweaking | ALPHA_CUT_OPAQUE_PREPASS | Handles occlusion with 3D objects properly |

**Key insight:** Godot 4's built-in Sprite3D billboard modes handle the matrix math for billboarding correctly. Custom GDScript solutions exist but add complexity and edge cases (camera changes, steep angles) that the built-in handles automatically.

## Common Pitfalls

### Pitfall 1: Blurry Pixel Art on Sprite3D
**What goes wrong:** Sprite appears smoothed/interpolated despite project-level nearest-neighbor setting
**Why it happens:** Sprite3D has its own texture_filter property that can override project settings
**How to avoid:**
- Always set `texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST` on the Sprite3D node
- Verify in inspector: Sprite3D > Texture Filter = "Nearest"
- Check imported texture: Import dock > Filter = false
**Warning signs:** Pixel edges appear soft, anti-aliased, or "smeared"

### Pitfall 2: Sprite Renders Behind 3D Objects
**What goes wrong:** Character sprite appears behind furniture or walls it should be in front of
**Why it happens:** Default ALPHA_CUT_DISABLED treats sprite as transparent, sorted incorrectly
**How to avoid:**
- Use `alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS`
- This renders opaque pixels in depth prepass, ensuring proper occlusion
**Warning signs:** Character "phases through" objects, Z-fighting flicker

### Pitfall 3: Sprite Origin at Center Causes Floating
**What goes wrong:** Character appears to hover above ground
**Why it happens:** Default sprite origin is center; Y-position places center at ground level
**How to avoid:**
- Set sprite offset so origin is at feet: `offset = Vector2(0, sprite_height / 2)`
- Or position parent Node3D with sprite offset in child
**Warning signs:** Character shadow appears directly under character but feet don't touch ground

### Pitfall 4: Blob Shadow Projects on Character
**What goes wrong:** Shadow texture appears on the character sprite itself
**Why it happens:** Decal cull_mask includes layer the sprite is on
**How to avoid:**
- Put character sprite on a dedicated visual layer (e.g., layer 2)
- Set Decal `cull_mask` to only include ground layers (layer 1)
- Or exclude character layer from decal projection
**Warning signs:** Dark circular artifact overlapping character, especially visible from above

### Pitfall 5: Billboard Foreshortening at Steep Angles
**What goes wrong:** Y-billboard sprite looks squished when camera looks steeply down
**Why it happens:** Y-billboard only rotates horizontally; vertical camera angle causes perspective foreshortening
**How to avoid:**
- Limit camera pitch angle to reasonable range (user's camera is ~35 degrees - acceptable)
- Current scene camera angle is well within safe range
- If steeper angles needed, consider custom shader or full billboard with constraints
**Warning signs:** Sprite appears shorter/compressed when camera tilts far down

### Pitfall 6: Lighting Makes Pixel Art Unreadable
**What goes wrong:** Scene lighting drastically changes sprite colors, losing pixel art clarity
**Why it happens:** shaded=true applies full lighting calculations to sprite
**How to avoid:**
- Keep shaded=true for integration but use modulate to reduce intensity
- modulate of ~0.9-0.95 (slightly dim base color) + scene lighting = subtle effect
- Alternatively, use custom shader with clamped light influence
**Warning signs:** Sprite looks dramatically different in light vs shadow areas, colors shift

## Code Examples

### Complete Character Setup Script
```gdscript
# Source: Synthesized from Godot documentation and HD-2D requirements
# Attach to root Node3D (or CharacterBody3D for collision)
extends Node3D

@export var character_texture: Texture2D
@export var shadow_texture: Texture2D
@export var character_scale: float = 0.95  # Slightly smaller than realistic

var sprite: Sprite3D
var shadow_caster: ShapeCast3D
var blob_shadow: Decal

func _ready() -> void:
    _setup_sprite()
    _setup_blob_shadow()

    # Spawn at room center (adjust per scene)
    global_position = Vector3(0, 0, 0)

func _setup_sprite() -> void:
    sprite = Sprite3D.new()
    sprite.name = "CharacterSprite"

    # Texture
    sprite.texture = character_texture

    # Billboard - Y-axis only (stays upright)
    sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y

    # Pixel art settings
    sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS

    # Rendering
    sprite.shaded = true
    sprite.double_sided = true
    sprite.modulate = Color(0.95, 0.95, 0.95, 1.0)  # Subtle lighting

    # Scale (slightly smaller per user decision)
    sprite.pixel_size = 0.01 * character_scale

    # Offset so feet are at origin (assuming standard sprite with feet at bottom)
    # Adjust based on actual sprite dimensions
    var tex_height = character_texture.get_height() if character_texture else 64
    sprite.offset = Vector2(0, tex_height / 2.0)

    add_child(sprite)

func _setup_blob_shadow() -> void:
    # Shadow raycaster
    shadow_caster = ShapeCast3D.new()
    shadow_caster.name = "ShadowCaster"
    shadow_caster.target_position = Vector3(0, -5, 0)  # Cast downward
    shadow_caster.collision_mask = 1  # Ground layer only

    # Blob shadow decal
    blob_shadow = Decal.new()
    blob_shadow.name = "BlobShadow"
    blob_shadow.texture_albedo = shadow_texture
    blob_shadow.size = Vector3(0.4, 2.0, 0.4)  # Shadow size
    blob_shadow.cull_mask = 1  # Only project on ground layer
    blob_shadow.modulate = Color(0, 0, 0, 0.4)  # Semi-transparent black
    blob_shadow.albedo_mix = 1.0
    blob_shadow.normal_fade = 0.5  # Fade on angled surfaces

    shadow_caster.add_child(blob_shadow)
    add_child(shadow_caster)

func _physics_process(_delta: float) -> void:
    _update_blob_shadow()

func _update_blob_shadow() -> void:
    if shadow_caster.get_collision_count() > 0:
        var hit_point = shadow_caster.get_collision_point(0)
        var distance = global_position.distance_to(hit_point)

        # Position at ground
        blob_shadow.global_position = hit_point
        blob_shadow.global_position.y += 0.01  # Slight offset to prevent z-fighting

        # Fade based on height (optional refinement)
        var max_alpha = 0.4
        var fade_start = 0.3
        if distance < fade_start:
            blob_shadow.modulate.a = lerp(0.0, max_alpha, distance / fade_start)
        else:
            blob_shadow.modulate.a = max_alpha
    else:
        blob_shadow.modulate.a = 0.0
```

### Minimal Sprite3D Setup (Scene File Style)
```gdscript
# For adding via editor or minimal script
extends Sprite3D

func _ready() -> void:
    billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
    texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
    alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
    shaded = true
    double_sided = true
    pixel_size = 0.0095  # ~95% scale
```

### Simple Blob Shadow Texture (Procedural)
```gdscript
# Create a simple gradient circle texture for blob shadow
# Can use pre-made texture instead
func create_blob_shadow_texture(size: int = 64) -> ImageTexture:
    var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
    var center = Vector2(size / 2.0, size / 2.0)
    var radius = size / 2.0

    for x in range(size):
        for y in range(size):
            var dist = Vector2(x, y).distance_to(center)
            var alpha = 1.0 - clamp(dist / radius, 0.0, 1.0)
            alpha = alpha * alpha  # Squared falloff for softer edge
            image.set_pixel(x, y, Color(0, 0, 0, alpha))

    return ImageTexture.create_from_image(image)
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Custom billboard shader | Built-in BILLBOARD_FIXED_Y | Godot 4.0 | No shader needed for Y-axis billboard |
| Sprite3D on ground for shadow | Decal node | Godot 4.0 | Projects on uneven surfaces, better blending |
| Manual raycast for ground | ShapeCast3D | Godot 4.0 | Multi-hit, shape-based detection |
| Single alpha cut mode | Four modes (Disabled/Discard/OpaquePrepass/Hash) | Godot 4.0 | Better depth sorting options |

**Recent in Godot 4.x:**
- Alpha hash mode added (spatially-deterministic dithering for transparency)
- Improved depth prepass performance
- Decal nodes fully integrated with Forward+ renderer

**Deprecated/outdated:**
- Custom look_at() for billboarding: Built-in handles it better
- Sprite3D for ground-projected shadows: Use Decal instead

## Open Questions

### Claude's Discretion Items (Research Findings)

1. **Edge case handling for steep camera angles**
   - What we know: Y-billboard causes foreshortening when camera looks steeply down
   - Current scene: Camera is ~35 degrees down - well within acceptable range
   - Recommendation: No special handling needed. If user adds steeper camera mode later, consider custom shader with limited Y-rotation or camera angle clamping.

2. **Collision setup for later phases**
   - What we know: CharacterBody3D requires CollisionShape3D as direct child
   - Recommendation: **YES, add basic collision shape this phase.** CapsuleShape3D centered on character, properly sized. Makes Controls phase cleaner - collision is ready, just needs move_and_slide logic.

3. **Depth sorting approach for proper occlusion**
   - What we know: ALPHA_CUT_OPAQUE_PREPASS handles most cases; render_priority is limited (0-255)
   - Recommendation: Use ALPHA_CUT_OPAQUE_PREPASS. If issues arise with specific furniture, put character on dedicated visual layer and adjust render order. Standard approach works for HD-2D style.

4. **Post-processing inclusion (bloom, color grading)**
   - What we know: User disabled post-processing in Phase 1 (preferred clarity over blur). Current WorldEnvironment has glow disabled.
   - Recommendation: **No post-processing for sprites specifically.** WorldEnvironment effects apply to entire scene including sprites automatically. Since user disabled glow/SSAO, sprite will render cleanly. If bloom is re-enabled later, it will naturally affect bright sprite areas.

## Sources

### Primary (HIGH confidence)
- [Godot SpriteBase3D Documentation](https://docs.godotengine.org/en/stable/classes/class_spritebase3d.html) - Properties: billboard, texture_filter, alpha_cut, shaded, pixel_size
- [Godot Decal Documentation](https://docs.godotengine.org/en/stable/classes/class_decal.html) - Properties: size, cull_mask, modulate, albedo_mix, normal_fade
- [The Godot Barn - 3D Blob Shadow Snippet](https://thegodotbarn.com/contributions/snippet/243/3d-blob-shadow) - ShapeCast3D + Decal pattern for blob shadows
- [GDQuest Pixel Art Setup Guide](https://www.gdquest.com/library/pixel_art_setup_godot4/) - Nearest-neighbor filtering configuration

### Secondary (MEDIUM confidence)
- [Godot Using Decals Tutorial](https://docs.godotengine.org/en/stable/tutorials/3d/using_decals.html) - Blob shadow use case, layer configuration
- [Godot Shaders - Billboard Sprite3D Hitflash](https://godotshaders.com/shader/billboard-sprite3d-hitflash-godot-4-x/) - Y-billboard shader implementation reference
- [Godot Forum - Sprite3D Transparency Sorting](https://forum.godotengine.org/t/sprite3dz-transparency-sorting-issue-and-alternatives-for-this-approach/106885) - Alpha cut mode comparison

### Tertiary (LOW confidence)
- [Godot Forum - Sprite3D Lighting Discussions](https://forum.godotengine.org/t/how-to-use-directionallight3d-to-cast-a-shadow-onto-a-sprite3d-without-compromising-color-consistency/75930) - Lighting influence on sprites
- [GitHub - Godot Proposals #3986](https://github.com/godotengine/godot-proposals/issues/3986) - Sprite3D depth sorting limitations

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All nodes are built-in Godot 4.6 features, well-documented
- Architecture patterns: HIGH - Billboard and Decal patterns from official docs and verified community snippets
- Pitfalls: HIGH - Common issues well-documented in forums and GitHub issues
- Code examples: MEDIUM - Synthesized from official properties, pattern verified but exact values may need tuning

**Research date:** 2026-02-02
**Valid until:** 2026-03-02 (30 days - Godot 4.6 is stable release)
