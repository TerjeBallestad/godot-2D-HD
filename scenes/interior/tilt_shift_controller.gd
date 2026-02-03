extends MeshInstance3D
## Tilt-shift focal tracking controller.
## Updates shader focal_point uniform to follow player with smooth lag.

@export var player_path: NodePath
@export var focal_smoothing: float = 5.0  # Higher = faster follow
@export var focal_height_offset: float = 0.5  # Mid-body anchor

var player: Node3D
var current_focal: Vector3 = Vector3.ZERO
var shader_material: ShaderMaterial
var camera: Camera3D


func _ready() -> void:
	# Get player reference
	player = get_node_or_null(player_path)
	if not player:
		push_warning("TiltShiftController: No player found at path: " + str(player_path))
		return
	print("TiltShiftController: Found player at ", player.get_path())

	# Get camera (parent of this node)
	camera = get_parent() as Camera3D
	if not camera:
		push_error("TiltShiftController: Parent is not a Camera3D")
		return
	print("TiltShiftController: Found camera")

	# Get shader material (from surface override on MeshInstance3D)
	shader_material = get_surface_override_material(0) as ShaderMaterial
	if not shader_material:
		push_error("TiltShiftController: No ShaderMaterial found")
		return
	print("TiltShiftController: Found shader material")

	# Initialize focal point to player position
	current_focal = player.global_position + Vector3(0, focal_height_offset, 0)
	shader_material.set_shader_parameter("focal_point", current_focal)
	print("TiltShiftController: Initial focal point ", current_focal)


var debug_counter: int = 0

func _process(delta: float) -> void:
	if not player or not shader_material or not camera:
		return

	# Target: player position + height offset for mid-body anchor
	var target_focal = player.global_position + Vector3(0, focal_height_offset, 0)

	# Exponential smoothing for slight lag (frame-rate independent)
	current_focal = current_focal.lerp(target_focal, 1.0 - exp(-focal_smoothing * delta))

	shader_material.set_shader_parameter("focal_point", current_focal)

	# Pass camera matrices to shader for proper depth reconstruction
	var proj_matrix = camera.get_camera_projection()
	var view_matrix = camera.get_camera_transform()
	shader_material.set_shader_parameter("inv_proj_matrix", proj_matrix.inverse())
	shader_material.set_shader_parameter("inv_view_matrix", view_matrix)

	# Debug: print every 60 frames
	debug_counter += 1
	if debug_counter % 60 == 0:
		print("Focal: ", current_focal, " Player: ", player.global_position)


func toggle_effect() -> void:
	if shader_material:
		var current = shader_material.get_shader_parameter("enabled")
		shader_material.set_shader_parameter("enabled", !current)


func cycle_debug_mode() -> void:
	if shader_material:
		var current: int = shader_material.get_shader_parameter("debug_mode")
		var next_mode = (current + 1) % 3
		shader_material.set_shader_parameter("debug_mode", next_mode)
		var mode_names = ["off", "distance", "depth"]
		print("Debug mode: ", mode_names[next_mode])
