# Phase 6: Pathfinding - Research

**Researched:** 2026-02-03
**Domain:** Godot 4.6 NavigationAgent3D, NavigationRegion3D, NavMesh Timing
**Confidence:** HIGH

## Summary

This phase restores pathfinding functionality that was removed from Phase 3 due to async navmesh baking timing issues. The research focused on three core areas: (1) understanding the specific timing problem that caused pathfinding removal, (2) identifying the correct solution pattern for Godot 4.6, and (3) verifying the navmesh configuration is correct for the existing scene geometry.

The root cause has been identified: the NavigationServer requires synchronization after navmesh baking before path queries will work. The current code calls `bake_navigation_mesh()` in `_ready()` but doesn't wait for the bake to complete and the NavigationServer to sync. The player script then attempts direct movement instead of querying the NavigationAgent3D.

The existing infrastructure is almost complete - NavigationAgent3D exists on the player, NavigationRegion3D exists with a NavigationMesh configured. However, two issues need fixing: (1) wait for NavServer sync before enabling pathfinding, (2) change navmesh parsing from STATIC_COLLIDERS to MESH_INSTANCES since the GLB furniture models don't have collision shapes.

**Primary recommendation:** Use the deferred setup pattern with `await get_tree().physics_frame` after bake_finished, change navmesh to MESH_INSTANCES mode, and rewire the player script to query NavigationAgent3D instead of using direct movement.

## Standard Stack

The established components for this domain (all built into Godot 4.6):

### Core
| Component | Type | Purpose | Why Standard |
|-----------|------|---------|--------------|
| NavigationAgent3D | Node | Path following | Already exists on PlayerCharacter, official Godot navigation |
| NavigationRegion3D | Node | Defines walkable area | Already exists in interior_scene.tscn |
| NavigationMesh | Resource | Stores pathfinding data | Already configured, needs geometry_type fix |
| NavigationServer3D | Singleton | Backend synchronization | Built-in, handles map sync automatically |

### Supporting
| Component | Type | Purpose | When to Use |
|-----------|------|---------|-------------|
| bake_finished signal | Signal | Notification when navmesh bake completes | When runtime baking |
| map_changed signal | Signal | Notification when navmap syncs | Can be used but has reliability issues in 4.5+ |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Runtime baking | Editor pre-bake | Pre-bake is faster but scene is already small |
| bake_finished + physics_frame | map_changed signal | map_changed has known issues in Godot 4.5+ |
| MESH_INSTANCES parsing | Add collision shapes to furniture | More work, collision shapes not needed otherwise |

**Installation:** All components are built into Godot 4.6. No external dependencies.

## Architecture Patterns

### Current Project Structure (No Changes Needed)
```
scenes/
├── character/
│   └── player_character.gd   # Needs rewiring to use NavigationAgent3D
│   └── player_character.tscn # Has NavigationAgent3D (orphaned)
├── interior/
│   └── interior_scene.gd     # Has navmesh baking, needs timing fix
│   └── interior_scene.tscn   # Has NavigationRegion3D
```

### Pattern 1: Deferred Navigation Setup (CRITICAL)
**What:** Wait for NavigationServer sync before enabling pathfinding
**When to use:** Always when using runtime baking or scene load
**Why:** NavigationServer doesn't sync until after first physics frame
**Example:**
```gdscript
# Source: Godot Official Docs - Using NavigationAgents
# interior_scene.gd

extends Node3D

signal navigation_ready

@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D

var _navigation_initialized: bool = false

func _ready() -> void:
    if navigation_region:
        navigation_region.bake_finished.connect(_on_navigation_baked)
        navigation_region.bake_navigation_mesh()

func _on_navigation_baked() -> void:
    # Wait for NavigationServer to sync the new data
    await get_tree().physics_frame
    _navigation_initialized = true
    navigation_ready.emit()

func is_navigation_ready() -> bool:
    return _navigation_initialized
```

### Pattern 2: Navigation-Aware Character Controller
**What:** Character waits for navigation before enabling pathfinding
**When to use:** Click-to-move with NavigationAgent3D
**Example:**
```gdscript
# Source: Godot Official Docs - Using NavigationAgents
# player_character.gd

extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

var _navigation_ready: bool = false
var _pending_target: Vector3 = Vector3.ZERO
var _has_pending_target: bool = false

func _ready() -> void:
    # Deferred setup to ensure scene is fully loaded
    _setup_navigation.call_deferred()

func _setup_navigation() -> void:
    # Wait for first physics frame for NavigationServer sync
    await get_tree().physics_frame
    _navigation_ready = true

    # Handle any target set before navigation was ready
    if _has_pending_target:
        navigation_agent.target_position = _pending_target
        _has_pending_target = false

func set_movement_target(target_pos: Vector3) -> void:
    if _navigation_ready:
        navigation_agent.target_position = target_pos
    else:
        # Queue target for when navigation becomes ready
        _pending_target = target_pos
        _has_pending_target = true
```

### Pattern 3: NavigationAgent3D Path Following
**What:** Query NavigationAgent3D for path and follow it
**When to use:** Every _physics_process when moving
**Example:**
```gdscript
# Source: Godot Official Docs - Using NavigationAgents
func _physics_process(delta: float) -> void:
    if not _navigation_ready:
        return

    if navigation_agent.is_navigation_finished():
        velocity = Vector3.ZERO
        return

    var next_pos = navigation_agent.get_next_path_position()
    var direction = (next_pos - global_position).normalized()
    direction.y = 0  # Keep movement horizontal

    var target_velocity = direction * MAX_SPEED
    velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)
    move_and_slide()
```

### Anti-Patterns to Avoid
- **Setting target in _ready():** Navigation map isn't synced yet. Always use `call_deferred()` + `await get_tree().physics_frame`
- **Checking is_navigation_finished() before navigation ready:** Returns true even when navigation hasn't initialized
- **Using map_changed signal in Godot 4.5+:** Has timing issues, needs two iterations to work
- **Using STATIC_COLLIDERS with GLB without collision shapes:** NavMesh won't see obstacles

## Don't Hand-Roll

Problems that look simple but have existing solutions:

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Pathfinding | Custom A* | NavigationAgent3D | Already in scene, handles edge cases |
| Navmesh sync detection | Custom timer/polling | bake_finished + physics_frame await | Official pattern, handles edge cases |
| Path smoothing | Custom bezier curves | NavigationAgent3D path_desired_distance | Built-in smoothing via waypoint skipping |
| Obstacle avoidance | Custom steering | NavigationAgent3D avoidance (if needed) | Built-in but disabled for simplicity |

**Key insight:** The infrastructure already exists in this project. The issue is purely timing and wiring - not missing functionality.

## Common Pitfalls

### Pitfall 1: NavMesh Not Ready on First Frame
**What goes wrong:** `get_next_path_position()` returns agent's own position, path queries return empty
**Why it happens:** NavigationServer syncs maps each physics frame, first frame hasn't synced yet
**How to avoid:**
1. Use `call_deferred()` for setup
2. `await get_tree().physics_frame` before setting target or querying paths
3. Check `NavigationServer3D.map_get_iteration_id(agent.get_navigation_map()) != 0` if needed
**Warning signs:** Character doesn't move, or moves to wrong position on first click
**Source:** [Godot Forum - NavigationServer map query failed](https://github.com/godotengine/godot/issues/84677)

### Pitfall 2: Furniture Not Creating NavMesh Obstacles
**What goes wrong:** NavMesh ignores furniture, character paths through tables/chairs
**Why it happens:** GLB models imported without collision shapes, navmesh set to STATIC_COLLIDERS
**How to avoid:**
1. Change `geometry_parsed_geometry_type` to `0` (MESH_INSTANCES)
2. Or add StaticBody3D with collision shapes to each furniture piece
**Warning signs:** NavMesh has no holes around furniture in debug view
**Source:** [Godot Docs - Using navigation meshes](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationmeshes.html)

### Pitfall 3: Bake Before Scene Fully Loaded
**What goes wrong:** Navmesh incomplete, missing furniture obstacles
**Why it happens:** `bake_navigation_mesh()` called before scene nodes exist
**How to avoid:** Use `call_deferred()` or await scene loaded before baking
**Warning signs:** Navmesh shape doesn't match expected walkable area

### Pitfall 4: Path Desired Distance Too Small
**What goes wrong:** Agent oscillates, never reaches waypoints, or skips to end
**Why it happens:** `path_desired_distance` smaller than movement step per frame
**How to avoid:** Set `path_desired_distance` to at least 0.3 (already configured)
**Warning signs:** Agent vibrates in place or teleports
**Source:** [Godot Forum - get_next_path_position returns current position](https://forum.godotengine.org/t/get-next-path-position-returns-current-position/60753)

### Pitfall 5: Godot 4.5+ map_changed Signal Issues
**What goes wrong:** Navigation seems ready but paths still empty
**Why it happens:** In Godot 4.5+, `map_changed` needs two iterations before navigation works
**How to avoid:** Use `bake_finished` + `await physics_frame` pattern instead
**Warning signs:** Works in 4.4 but breaks in 4.5+
**Source:** [Godot Forum - When precisely are navigation regions ready](https://forum.godotengine.org/t/when-precisely-are-navigation-regions-ready-to-use/127533)

## Code Examples

Verified patterns from official sources:

### Complete Navigation Setup (Recommended)
```gdscript
# Source: Godot Official Docs - Using NavigationAgents
# player_character.gd - COMPLETE REWRITE

extends CharacterBody3D
## Click-to-move character controller with NavigationAgent3D pathfinding.

@onready var shadow_caster: ShapeCast3D = $ShadowCaster
@onready var blob_shadow: Decal = $ShadowCaster/BlobShadow
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Movement parameters (unchanged from original)
const MAX_SPEED: float = 1.5
const ACCELERATION: float = 3.0
const DECELERATION: float = 4.0

var current_speed: float = 0.0
var is_moving: bool = false
var _navigation_ready: bool = false

func _ready() -> void:
    # Deferred setup to ensure NavigationServer has synced
    _setup_navigation.call_deferred()

func _setup_navigation() -> void:
    # Wait for first physics frame so NavigationServer can sync
    await get_tree().physics_frame
    _navigation_ready = true

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            _handle_click(event.position)

func _handle_click(screen_pos: Vector2) -> void:
    if not _navigation_ready:
        return  # Ignore clicks until navigation is ready

    var camera = get_viewport().get_camera_3d()
    if not camera:
        return

    var from = camera.project_ray_origin(screen_pos)
    var to = from + camera.project_ray_normal(screen_pos) * 100.0

    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collision_mask = 2  # Floor collision layer only
    query.collide_with_areas = false

    var result = space_state.intersect_ray(query)
    if result:
        _set_movement_target(result.position)

func _set_movement_target(target_pos: Vector3) -> void:
    navigation_agent.target_position = target_pos
    is_moving = true

func _physics_process(delta: float) -> void:
    _update_shadow()
    _update_movement(delta)

func _update_movement(delta: float) -> void:
    if not _navigation_ready or not is_moving:
        return

    if navigation_agent.is_navigation_finished():
        is_moving = false
        current_speed = 0.0
        velocity = Vector3.ZERO
        return

    # Get next waypoint from NavigationAgent3D
    var next_pos = navigation_agent.get_next_path_position()
    var to_target = next_pos - global_position
    to_target.y = 0  # Keep movement horizontal
    var direction = to_target.normalized()

    # Calculate distance to final target for deceleration
    var distance_to_target = global_position.distance_to(navigation_agent.target_position)
    var decel_distance = (current_speed * current_speed) / (2.0 * DECELERATION)

    # Eased motion: accelerate at start, decelerate near end
    if distance_to_target < decel_distance:
        current_speed = maxf(current_speed - DECELERATION * delta, 0.2)
    else:
        current_speed = minf(current_speed + ACCELERATION * delta, MAX_SPEED)

    velocity = direction * current_speed
    move_and_slide()

func _update_shadow() -> void:
    if shadow_caster.get_collision_count() > 0:
        var hit_point = shadow_caster.get_collision_point(0)
        blob_shadow.global_position = hit_point + Vector3(0, 0.01, 0)
        blob_shadow.visible = true
    else:
        blob_shadow.visible = false
```

### NavMesh Configuration Fix
```
# interior_scene.tscn - NavigationMesh resource change

[sub_resource type="NavigationMesh" id="NavigationMesh_1"]
geometry_parsed_geometry_type = 0  # Changed from 1 to 0 (MESH_INSTANCES)
cell_size = 0.1
cell_height = 0.1
agent_height = 1.0
agent_radius = 0.3
```

### Optional: Pre-bake NavMesh (Alternative Approach)
Instead of runtime baking, the navmesh can be pre-baked in the editor:
1. Select NavigationRegion3D in Scene dock
2. Click "Bake NavMesh" in top toolbar
3. Save scene (navmesh data stored in .tscn)
4. Remove `bake_navigation_mesh()` call from interior_scene.gd

This avoids runtime baking timing issues entirely but requires re-baking when furniture layout changes.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| await physics_frame only | bake_finished + physics_frame | Godot 4.3+ | More reliable timing |
| map_changed signal | bake_finished + physics_frame | Godot 4.5 | map_changed has issues |
| STATIC_COLLIDERS for navmesh | MESH_INSTANCES for imported models | N/A | Better compatibility with GLB |

**Deprecated/outdated:**
- Relying solely on `map_changed` signal (unreliable in 4.5+)
- Assuming navigation works in `_ready()` without waiting

## Open Questions

Things that couldn't be fully resolved:

1. **Pre-bake vs Runtime Bake Decision**
   - What we know: Both work, pre-bake is simpler timing-wise
   - What's unclear: Whether user wants to modify furniture layout without editor
   - Recommendation: Use runtime baking since it's already implemented, just fix timing

2. **Navigation Debug Visibility**
   - What we know: NavigationAgent3D has `debug_enabled = true` in scene
   - What's unclear: Whether debug visualization should remain in final version
   - Recommendation: Keep during development, disable before release

## Sources

### Primary (HIGH confidence)
- [Godot Official Docs - Using NavigationAgents](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationagents.html) - Setup patterns, timing requirements
- [Godot Official Docs - Using navigation meshes](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_using_navigationmeshes.html) - Navmesh configuration
- [Godot Official Docs - 3D navigation overview](https://docs.godotengine.org/en/stable/tutorials/navigation/navigation_introduction_3d.html) - Architecture overview
- [GitHub - godot-docs navigation_using_navigationagents.rst](https://raw.githubusercontent.com/godotengine/godot-docs/master/tutorials/navigation/navigation_using_navigationagents.rst) - Raw documentation

### Secondary (MEDIUM confidence)
- [Godot Forum - NavigationAgent3D get_next_path_position not working](https://forum.godotengine.org/t/solved-navigationagent3d-get-next-path-position-is-not-working/91973) - Verified path_desired_distance solution
- [GitHub Issue - NavigationServer map query failed](https://github.com/godotengine/godot/issues/84677) - First frame sync issue documentation
- [Godot Forum - When precisely are navigation regions ready](https://forum.godotengine.org/t/when-precisely-are-navigation-regions-ready-to-use/127533) - Godot 4.5+ timing changes

### Tertiary (LOW confidence)
- [Godot Forum - NavMap not loading fast enough](https://forum.godotengine.org/t/navmap-not-loading-fast-enough/129623) - Confirms ongoing 4.5.1 timing issues

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All components already exist in project
- Architecture patterns: HIGH - Official docs confirm deferred setup pattern
- Pitfalls: HIGH - Multiple community sources confirm timing issues
- NavMesh configuration: MEDIUM - Needs validation that MESH_INSTANCES parses GLB correctly

**Research date:** 2026-02-03
**Valid until:** 60 days (Godot 4.6 patterns are stable)

## Key Changes Required

Summary of what needs to change from current state:

| File | Change | Reason |
|------|--------|--------|
| `interior_scene.tscn` | `geometry_parsed_geometry_type = 0` | GLB furniture has no collision shapes |
| `player_character.gd` | Add `_navigation_ready` flag and deferred setup | Wait for NavServer sync |
| `player_character.gd` | Replace direct movement with `navigation_agent.get_next_path_position()` | Actually use pathfinding |
| `interior_scene.gd` | Optionally remove runtime baking (or keep with timing fix) | Timing reliability |
