extends CharacterBody3D
## Minimal character controller with blob shadow positioning.
## Movement and animation will be added in Controls phase.

@onready var shadow_caster: ShapeCast3D = $ShadowCaster
@onready var blob_shadow: Decal = $ShadowCaster/BlobShadow

func _physics_process(_delta: float) -> void:
	_update_shadow()

func _update_shadow() -> void:
	if shadow_caster.get_collision_count() > 0:
		var hit_point = shadow_caster.get_collision_point(0)
		# Position shadow at ground level with slight offset to prevent z-fighting
		blob_shadow.global_position = hit_point + Vector3(0, 0.01, 0)
		blob_shadow.visible = true
	else:
		blob_shadow.visible = false
