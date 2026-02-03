extends MeshInstance3D
## Tilt-shift focal tracking controller.
## Updates shader focal_point uniform to follow player with smooth lag.

@export var player_path: NodePath
@export var focal_smoothing: float = 5.0  # Higher = faster follow
@export var focal_height_offset: float = 0.5  # Mid-body anchor

var player: Node3D
var current_focal: Vector3 = Vector3.ZERO
var shader_material: ShaderMaterial


func _ready() -> void:
	# Get player reference
	player = get_node_or_null(player_path)
	if not player:
		push_warning("TiltShiftController: No player found at path")
		return

	# Get shader material (surface 0 of QuadMesh)
	shader_material = mesh.surface_get_material(0) as ShaderMaterial
	if not shader_material:
		push_error("TiltShiftController: No ShaderMaterial found")
		return

	# Initialize focal point to player position
	current_focal = player.global_position + Vector3(0, focal_height_offset, 0)
	shader_material.set_shader_parameter("focal_point", current_focal)


func _process(delta: float) -> void:
	if not player or not shader_material:
		return

	# Target: player position + height offset for mid-body anchor
	var target_focal = player.global_position + Vector3(0, focal_height_offset, 0)

	# Exponential smoothing for slight lag (frame-rate independent)
	current_focal = current_focal.lerp(target_focal, 1.0 - exp(-focal_smoothing * delta))

	shader_material.set_shader_parameter("focal_point", current_focal)


func toggle_effect() -> void:
	if shader_material:
		var current = shader_material.get_shader_parameter("enabled")
		shader_material.set_shader_parameter("enabled", !current)
