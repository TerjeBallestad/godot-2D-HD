# Phase 3: Controls - Research

**Researched:** 2026-02-02
**Domain:** Godot 4 Navigation, Camera Controls, Input Handling
**Confidence:** HIGH

## Summary

This phase implements click-to-move character navigation using NavigationAgent3D with eased motion, and camera orbit/zoom controls using a gimbal-based camera rig. The research focused on three core domains: (1) NavigationAgent3D setup with proper distance thresholds and pathfinding around furniture, (2) smooth camera orbit with 45-degree snapping using Node3D pivot hierarchy, and (3) Godot 4 input handling for both mouse and keyboard controls.

The Godot 4 navigation system is well-documented but has known pitfalls around distance thresholds and signal timing. Camera orbit is best implemented via a two-node gimbal structure (outer Y rotation, inner X rotation). Tweens handle smooth transitions effectively with TRANS_CUBIC and EASE_IN_OUT for natural-feeling motion.

**Primary recommendation:** Use NavigationAgent3D with generous `path_desired_distance` (0.3-0.5), implement camera via Node3D gimbal hierarchy, and use Tweens with TRANS_CUBIC/EASE_IN_OUT for all smooth transitions.

## Standard Stack

The established patterns for this domain (all built into Godot 4.6):

### Core
| Component | Type | Purpose | Why Standard |
|-----------|------|---------|--------------|
| NavigationAgent3D | Node | Pathfinding and path following | Official Godot navigation system, handles obstacles |
| NavigationRegion3D | Node | Defines walkable area | Required for navigation mesh baking |
| NavigationMesh | Resource | Stores pathfinding data | Baked from scene geometry |
| CharacterBody3D | Node | Already in project | Provides move_and_slide() for physics movement |
| Tween | Class | Smooth interpolation | Built-in, handles easing naturally |
| Node3D | Node | Camera gimbal pivot | Standard approach for orbit cameras |

### Supporting
| Component | Type | Purpose | When to Use |
|-----------|------|---------|-------------|
| InputMap | Singleton | Action mapping | Define all control actions in Project Settings |
| PhysicsRayQueryParameters3D | Class | Mouse click detection | Raycast from camera to floor |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| NavigationAgent3D | Manual A* | More control, much more complexity |
| Tween for camera | lerp_angle manual | More code, same result |
| Gimbal hierarchy | Single rotating camera | Gimbal lock issues in 3D |

**Installation:** All components are built into Godot 4.6. No external dependencies.

## Architecture Patterns

### Recommended Script Structure
```
scenes/
├── character/
│   └── player_character.gd   # Extend with navigation + movement
├── interior/
│   └── interior_scene.gd     # Extend with input handling + raycast
└── camera/
    └── camera_rig.gd         # NEW: Camera gimbal controller
    └── camera_rig.tscn       # NEW: Camera hierarchy scene
```

### Pattern 1: Camera Gimbal Hierarchy
**What:** Two nested Node3D nodes with Camera3D child
**When to use:** Any 3D orbit camera
**Structure:**
```
CameraRig (Node3D)           # Rotates Y-axis only (horizontal orbit)
└── InnerGimbal (Node3D)     # Rotates X-axis only (vertical tilt)
    └── Camera3D             # Positioned at distance from pivot
```
**Example:**
```gdscript
# Source: KidsCanCode Godot 4 Recipes - Camera Gimbal
extends Node3D

@export var rotation_speed: float = PI / 2
@export_range(0.4, 3.0) var max_zoom: float = 3.0
@export_range(0.4, 3.0) var min_zoom: float = 0.4
@export_range(0.05, 1.0) var zoom_speed: float = 0.09

@onready var inner_gimbal: Node3D = $InnerGimbal
@onready var camera: Camera3D = $InnerGimbal/Camera3D

var _target_rotation: float = 0.0
var _target_zoom: float = 1.0

func _process(delta: float) -> void:
    # Smooth zoom via scale
    scale = lerp(scale, Vector3.ONE * _target_zoom, zoom_speed)

func rotate_to_angle(target_y: float, duration: float = 0.3) -> void:
    var tween = create_tween()
    tween.tween_property(self, "rotation:y", target_y, duration)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
```

### Pattern 2: Click-to-Move with NavigationAgent3D
**What:** Raycast to get floor position, set as navigation target
**When to use:** Point-and-click movement
**Example:**
```gdscript
# Source: Godot Official Docs - Ray-casting + NavigationAgents
extends CharacterBody3D

@export var move_speed: float = 1.5  # Slow/deliberate pace
@export var acceleration: float = 2.0
@export var deceleration: float = 4.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _is_moving: bool = false

func _ready() -> void:
    # Critical: Wait for NavigationServer to sync
    call_deferred("_setup_navigation")

func _setup_navigation() -> void:
    await get_tree().physics_frame
    nav_agent.path_desired_distance = 0.4
    nav_agent.target_desired_distance = 0.4

func set_movement_target(target_pos: Vector3) -> void:
    nav_agent.target_position = target_pos
    _is_moving = true

func _physics_process(delta: float) -> void:
    if not _is_moving:
        return

    if nav_agent.is_navigation_finished():
        _is_moving = false
        velocity = velocity.move_toward(Vector3.ZERO, deceleration * delta)
    else:
        var next_pos = nav_agent.get_next_path_position()
        var direction = (next_pos - global_position).normalized()
        direction.y = 0  # Keep on ground plane

        var target_velocity = direction * move_speed
        velocity = velocity.move_toward(target_velocity, acceleration * delta)

    move_and_slide()
```

### Pattern 3: Mouse Raycast to Floor
**What:** Convert mouse click to 3D world position
**When to use:** Click-to-move target detection
**Example:**
```gdscript
# Source: Godot Official Docs - Ray-casting
func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
            var target = _raycast_to_floor(event.position)
            if target:
                player.set_movement_target(target)

func _raycast_to_floor(screen_pos: Vector2) -> Variant:
    var camera = get_viewport().get_camera_3d()
    var from = camera.project_ray_origin(screen_pos)
    var to = from + camera.project_ray_normal(screen_pos) * 100.0

    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 1  # Floor layer only

    var result = space_state.intersect_ray(query)
    if result:
        return result.position
    return null
```

### Pattern 4: Smooth Eased Transitions with Tween
**What:** Use Tween for smooth camera/movement transitions
**When to use:** Animated snaps, smooth zoom
**Example:**
```gdscript
# Source: Godot Official Docs - Tween
func zoom_to(target_zoom: float, duration: float = 0.3) -> void:
    var tween = create_tween()
    tween.tween_property(self, "scale", Vector3.ONE * target_zoom, duration)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

func snap_rotation(angle_degrees: float, duration: float = 0.3) -> void:
    var target_rad = deg_to_rad(angle_degrees)
    var tween = create_tween()
    tween.tween_property(self, "rotation:y", target_rad, duration)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
```

### Anti-Patterns to Avoid
- **Setting target in _ready():** Navigation server needs time to sync. Always use `call_deferred()` and `await get_tree().physics_frame`
- **Using Euler angles for 3D rotation:** Risk of gimbal lock. Use transform interpolation or separate single-axis rotations
- **Small path_desired_distance:** Values under 0.3 can cause agents to oscillate or never reach target
- **Updating navigation target only in signals:** Path generation can halt; update in _physics_process for reliability

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pathfinding around furniture | Custom A* or steering | NavigationAgent3D + NavigationRegion3D | Handles edge cases, obstacle avoidance built-in |
| Smooth interpolation | Manual lerp with delta | Tween with set_trans/set_ease | Handles edge cases, easing curves built-in |
| Mouse-to-world position | Manual matrix math | camera.project_ray_origin/normal | Camera projection already computed |
| Orbit camera | Single node rotation | Gimbal hierarchy | Prevents gimbal lock, cleaner code |

**Key insight:** Godot 4's built-in navigation and tween systems handle the complex edge cases (path smoothing, angle wrapping, easing curves) that would require extensive testing if hand-rolled.

## Common Pitfalls

### Pitfall 1: NavigationAgent Path Not Working
**What goes wrong:** `get_next_path_position()` returns agent's own position, agent doesn't move
**Why it happens:** Navigation target set before NavigationServer syncs, or path_desired_distance too small
**How to avoid:**
1. Use `call_deferred()` for setup
2. `await get_tree().physics_frame` before setting target
3. Set `path_desired_distance` to at least 0.3
**Warning signs:** Agent vibrates in place or returns to start position

### Pitfall 2: is_navigation_finished vs is_target_reached Confusion
**What goes wrong:** Different results from these two methods
**Why it happens:** `is_navigation_finished` uses `path_desired_distance`, `is_target_reached` uses `target_desired_distance`
**How to avoid:** Set both distances to the same value, or use only `is_navigation_finished()` for movement logic
**Warning signs:** Agent stops before reaching visual destination

### Pitfall 3: Camera Gimbal Lock
**What goes wrong:** Camera flips or tilts unexpectedly during rotation
**Why it happens:** Using single-node rotation with multiple axes
**How to avoid:** Use two-node gimbal (outer Y, inner X), clamp inner rotation: `clamp(rotation.x, -1.4, -0.01)`
**Warning signs:** Camera "flips" when rotating past certain angles

### Pitfall 4: Raycast Not Hitting Floor
**What goes wrong:** Click-to-move doesn't work, raycast returns null
**Why it happens:** Floor lacks collision shape, or collision_mask doesn't match floor's layer
**How to avoid:**
1. Ensure StaticBody3D + CollisionShape3D on floor (already present in project)
2. Set `query.collision_mask = 1` to match floor's collision layer
**Warning signs:** Clicks do nothing, no movement occurs

### Pitfall 5: Tween Overwrites Previous Tween
**What goes wrong:** Rapid inputs cause jerky motion or ignored commands
**Why it happens:** Each `create_tween()` creates independent tween, old ones keep running
**How to avoid:** Store tween reference, call `tween.kill()` before creating new one
**Warning signs:** Laggy or unpredictable response to rapid inputs

### Pitfall 6: UI Blocks Raycasts
**What goes wrong:** Clicks on UI elements still trigger movement
**Why it happens:** `_input()` receives events before UI
**How to avoid:** Use `_unhandled_input()` instead of `_input()` for game world input
**Warning signs:** Clicking menu buttons also moves character

## Code Examples

Verified patterns from official sources:

### Complete Navigation Setup
```gdscript
# Source: Godot Official Docs - Using NavigationAgents
# player_character.gd additions

@export var move_speed: float = 1.5
@export var acceleration: float = 2.0
@export var deceleration: float = 4.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var _is_moving: bool = false

func _ready() -> void:
    call_deferred("_setup_navigation")

func _setup_navigation() -> void:
    await get_tree().physics_frame
    nav_agent.path_desired_distance = 0.4
    nav_agent.target_desired_distance = 0.4
    nav_agent.max_speed = move_speed

func set_movement_target(target_pos: Vector3) -> void:
    nav_agent.target_position = target_pos
    _is_moving = true

func _physics_process(delta: float) -> void:
    _update_shadow()  # Existing
    _update_movement(delta)  # New

func _update_movement(delta: float) -> void:
    if not _is_moving:
        # Decelerate to stop
        velocity = velocity.move_toward(Vector3.ZERO, deceleration * delta)
        if velocity.length() < 0.01:
            velocity = Vector3.ZERO
        move_and_slide()
        return

    if nav_agent.is_navigation_finished():
        _is_moving = false
        return

    var next_pos = nav_agent.get_next_path_position()
    var direction = (next_pos - global_position).normalized()
    direction.y = 0

    var target_velocity = direction * move_speed
    velocity = velocity.move_toward(target_velocity, acceleration * delta)
    move_and_slide()
```

### Camera Rig with Orbit and Zoom
```gdscript
# Source: KidsCanCode Godot 4 Recipes - Camera Gimbal
# camera_rig.gd

extends Node3D
class_name CameraRig

signal rotation_changed(angle_degrees: float)

@export var zoom_min: float = 0.5
@export var zoom_max: float = 2.0
@export var zoom_speed: float = 0.1
@export var snap_duration: float = 0.3

@onready var inner_gimbal: Node3D = $InnerGimbal
@onready var camera: Camera3D = $InnerGimbal/Camera3D

var _current_snap_index: int = 0  # 0-7 for 45-degree increments
var _target_zoom: float = 1.0
var _rotation_tween: Tween

const SNAP_ANGLES: Array[float] = [0, 45, 90, 135, 180, 225, 270, 315]

func _ready() -> void:
    _target_zoom = scale.x

func _process(delta: float) -> void:
    # Smooth zoom
    scale = lerp(scale, Vector3.ONE * _target_zoom, zoom_speed)

func rotate_left() -> void:
    _current_snap_index = (_current_snap_index - 1 + 8) % 8
    _animate_to_snap()

func rotate_right() -> void:
    _current_snap_index = (_current_snap_index + 1) % 8
    _animate_to_snap()

func _animate_to_snap() -> void:
    var target_angle = deg_to_rad(SNAP_ANGLES[_current_snap_index])

    if _rotation_tween:
        _rotation_tween.kill()

    _rotation_tween = create_tween()
    _rotation_tween.tween_property(self, "rotation:y", target_angle, snap_duration)\
        .set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

    rotation_changed.emit(SNAP_ANGLES[_current_snap_index])

func zoom_in() -> void:
    _target_zoom = clamp(_target_zoom - zoom_speed, zoom_min, zoom_max)

func zoom_out() -> void:
    _target_zoom = clamp(_target_zoom + zoom_speed, zoom_min, zoom_max)

func reset_camera() -> void:
    _current_snap_index = 0
    _target_zoom = 1.0
    _animate_to_snap()
```

### Input Action Setup (project.godot additions)
```ini
; Add to [input] section or via Project Settings > Input Map
camera_rotate_left={
    "deadzone": 0.2,
    "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":81,"key_label":0,"unicode":113,"location":0,"echo":false,"script":null)]
}
camera_rotate_right={
    "deadzone": 0.2,
    "events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"location":0,"echo":false,"script":null)]
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Navigation2DServer | NavigationServer3D unified | Godot 4.0 | Single API for 2D/3D navigation |
| SceneTree.create_tween() | Node.create_tween() | Godot 4.0 | Tween auto-binds to node lifecycle |
| KinematicBody3D | CharacterBody3D | Godot 4.0 | velocity is now a property, not return value |

**Deprecated/outdated:**
- `Navigation` node: Replaced by NavigationServer3D singleton
- `move_and_slide(velocity)`: Now just `move_and_slide()`, velocity is a property
- `Tween` as scene node: Now created via `create_tween()` method

## Discretionary Recommendations

Based on CONTEXT.md, these are at Claude's discretion:

### Click-to-Move Mouse Button
**Recommendation:** Use LEFT CLICK for movement

**Rationale:**
- Left click is the primary action button, matches user expectation
- Right click is already assigned to camera orbit (drag)
- Avoids conflict with existing right-click orbit control
- Standard convention in point-and-click games (Diablo, Baldur's Gate, etc.)

### Camera Orbit Pivot Point
**Recommendation:** Pivot around ROOM CENTER (static point)

**Rationale:**
- User goal is "evaluating the HD-2D scene" - room-centric view better serves this
- Player-following pivot would cause disorienting shifts when player moves
- Static pivot provides predictable camera behavior during evaluation
- Can set pivot to approximate room center (Vector3(0, 0, 0) based on current scene layout)
- The slow, contemplative movement means player rarely leaves view anyway

**Implementation detail:** The CameraRig should be positioned at scene origin, not parented to player.

## Open Questions

Things that couldn't be fully resolved:

1. **NavigationMesh baking with imported GLB models**
   - What we know: NavigationRegion3D can parse mesh instances or static colliders
   - What's unclear: Whether existing GLB furniture will be recognized as obstacles without explicit collision shapes
   - Recommendation: Test with `parsed_geometry_type = PARSED_GEOMETRY_STATIC_COLLIDERS` first; if furniture not detected, switch to `PARSED_GEOMETRY_MESH_INSTANCES`

2. **Right-click drag orbit threshold**
   - What we know: User wants right-click drag for orbit
   - What's unclear: Minimum drag distance before orbit activates (to distinguish from accidental movement)
   - Recommendation: Implement 5-10 pixel threshold before orbit begins

## Sources

### Primary (HIGH confidence)
- [Godot Official Docs - Using NavigationAgents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html)
- [Godot Official Docs - NavigationAgent3D Class](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html)
- [Godot Official Docs - Ray-casting](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html)
- [Godot Official Docs - Tween Class](https://docs.godotengine.org/en/stable/classes/class_tween.html)
- [KidsCanCode Godot 4 Recipes - Camera Gimbal](https://kidscancode.org/godot_recipes/4.x/3d/camera_gimbal/index.html)

### Secondary (MEDIUM confidence)
- [KidsCanCode Godot 4 Recipes - CharacterBody3D Movement](https://kidscancode.org/godot_recipes/4.x/3d/characterbody3d_examples/index.html)
- [GoTut - Tweens in Godot 4](https://www.gotut.net/tweens-in-godot-4/)
- [DanielTPerry.me - 3D Navigation in Godot](https://www.danieltperry.me/post/godot-navigation/)

### Tertiary (LOW confidence)
- [GitHub Issue - NavigationAgent3D target_reached behavior](https://github.com/godotengine/godot/issues/106291) - documents known behavioral differences
- [Godot Forum - NavigationAgent3D common issues](https://forum.godotengine.org/t/problems-with-navigationagent3d/67516)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All components are built-in Godot 4, well-documented
- Architecture patterns: HIGH - Gimbal pattern and NavigationAgent3D usage verified in official docs
- Pitfalls: MEDIUM - Most from community reports, but consistent across multiple sources
- Discretionary recommendations: MEDIUM - Based on game design conventions, not official guidance

**Research date:** 2026-02-02
**Valid until:** 60 days (Godot 4.6 is stable release, patterns unlikely to change soon)
