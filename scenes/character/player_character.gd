extends CharacterBody3D
## Click-to-move character controller with NavigationAgent3D pathfinding.
##
## Left-click on floor to move character. Uses NavigationAgent3D for
## pathfinding around obstacles with smooth acceleration and deceleration.

@onready var shadow_caster: ShapeCast3D = $ShadowCaster
@onready var blob_shadow: Decal = $ShadowCaster/BlobShadow
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent3D

# Movement parameters
const MAX_SPEED: float = 1.5  # Units per second (slow/deliberate)
const ACCELERATION: float = 3.0  # How fast to reach max speed
const DECELERATION: float = 4.0  # How fast to slow down near destination

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
	# Left click to move (uses _unhandled_input to avoid blocking UI)
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
	query.collision_mask = 2  # Floor collision layer only (layer 2)
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

	# Get next waypoint from NavigationAgent3D (this is the path-following)
	var next_pos = navigation_agent.get_next_path_position()
	var to_target = next_pos - global_position
	to_target.y = 0  # Keep movement horizontal
	var direction = to_target.normalized()

	# Calculate distance to final target for deceleration
	var distance_to_target = global_position.distance_to(navigation_agent.target_position)
	var decel_distance = (current_speed * current_speed) / (2.0 * DECELERATION)

	# Eased motion: accelerate at start, decelerate near end
	if distance_to_target < decel_distance:
		# Decelerate smoothly toward destination
		current_speed = maxf(current_speed - DECELERATION * delta, 0.2)
	else:
		# Accelerate up to max speed
		current_speed = minf(current_speed + ACCELERATION * delta, MAX_SPEED)

	velocity = direction * current_speed
	move_and_slide()


func _update_shadow() -> void:
	if shadow_caster.get_collision_count() > 0:
		var hit_point = shadow_caster.get_collision_point(0)
		# Position shadow at ground level with slight offset to prevent z-fighting
		blob_shadow.global_position = hit_point + Vector3(0, 0.01, 0)
		blob_shadow.visible = true
	else:
		blob_shadow.visible = false
