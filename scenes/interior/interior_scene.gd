class_name InteriorScene
extends Node3D
## Main interior scene controller for HD-2D rendering prototype.
##
## This script manages the interior scene and can be extended for
## scene transitions, camera control, and lighting adjustments.

@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D


func _ready() -> void:
	# Bake navigation mesh on scene load for click-to-move pathfinding
	if navigation_region:
		navigation_region.bake_navigation_mesh()


func _process(_delta: float) -> void:
	pass
