extends CharacterBody3D
## Click-to-move character controller with eased motion.
##
## Left-click on floor to move character. Uses direct movement with
## smooth acceleration and deceleration.

@onready var shadow_caster: ShapeCast3D = $ShadowCaster
@onready var blob_shadow: Decal = $ShadowCaster/BlobShadow

# Movement parameters
const MAX_SPEED: float = 1.5  # Units per second (slow/deliberate)
const ACCELERATION: float = 3.0  # How fast to reach max speed
const DECELERATION: float = 4.0  # How fast to slow down near destination
const ARRIVAL_THRESHOLD: float = 0.1  # Distance to consider "arrived"

var current_speed: float = 0.0
var is_moving: bool = false
var target_position: Vector3 = Vector3.ZERO


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.position)


func _handle_click(screen_pos: Vector2) -> void:
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
	target_position = target_pos
	target_position.y = global_position.y  # Keep same height
	is_moving = true


func _physics_process(delta: float) -> void:
	_update_shadow()
	_update_movement(delta)


func _update_movement(delta: float) -> void:
	if not is_moving:
		return

	var to_target = target_position - global_position
	to_target.y = 0
	var distance_to_target = to_target.length()

	if distance_to_target < ARRIVAL_THRESHOLD:
		is_moving = false
		current_speed = 0.0
		velocity = Vector3.ZERO
		return

	var direction = to_target.normalized()

	# Eased motion: accelerate at start, decelerate near end
	var decel_distance = (current_speed * current_speed) / (2.0 * DECELERATION)

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
