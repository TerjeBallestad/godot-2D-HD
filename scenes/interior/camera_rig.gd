extends Node3D
## Camera gimbal with orbit rotation (45-degree snapping) and zoom controls.
## Pivots around room center for consistent scene evaluation.

@onready var inner_gimbal: Node3D = $InnerGimbal
@onready var camera: Camera3D = $InnerGimbal/Camera3D

# Orbit settings
const SNAP_ANGLE: float = 45.0  # Degrees per snap position
const ORBIT_TRANSITION_TIME: float = 0.3  # Seconds for smooth snap

# Zoom settings
const ZOOM_MIN: float = 3.0  # Closest zoom (character ~1/3 screen)
const ZOOM_MAX: float = 8.0  # Furthest zoom
const ZOOM_STEP: float = 0.5  # Per scroll/key press
const ZOOM_TRANSITION_TIME: float = 0.15  # Seconds for smooth zoom

# Default values for reset
const DEFAULT_ROTATION: float = 45.0  # degrees
const DEFAULT_ZOOM: float = 5.0  # camera distance

# State
var current_snap_index: int = 1  # 0-7 for 8 positions (starting at 45 degrees)
var current_zoom: float = 5.0
var orbit_tween: Tween = null
var zoom_tween: Tween = null

# Drag state
var is_dragging: bool = false
var drag_start_rotation: float = 0.0
var drag_start_mouse: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Set initial state
	rotation_degrees.y = DEFAULT_ROTATION
	current_zoom = DEFAULT_ZOOM
	camera.position.z = current_zoom


func _unhandled_input(event: InputEvent) -> void:
	# Keyboard rotation and zoom using direct key checks
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_Q:
				_rotate_camera(-1)
			KEY_E:
				_rotate_camera(1)
			KEY_EQUAL, KEY_KP_ADD:  # + key
				_zoom_camera(-ZOOM_STEP)  # Negative = closer
			KEY_MINUS, KEY_KP_SUBTRACT:  # - key
				_zoom_camera(ZOOM_STEP)  # Positive = farther
			KEY_R:  # Reset
				_reset_camera()

	# Mouse wheel zoom
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			_zoom_camera(-ZOOM_STEP)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			_zoom_camera(ZOOM_STEP)

		# Right-click drag for orbit
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				is_dragging = true
				drag_start_rotation = rotation_degrees.y
				drag_start_mouse = event.position
			else:
				is_dragging = false
				_snap_to_nearest_angle()

	# Mouse motion for drag orbit
	if event is InputEventMouseMotion and is_dragging:
		var delta_x = event.position.x - drag_start_mouse.x
		# Sensitivity: 360 degrees per screen width
		var screen_width = get_viewport().get_visible_rect().size.x
		var rotation_delta = (delta_x / screen_width) * 360.0
		rotation_degrees.y = drag_start_rotation - rotation_delta


func _rotate_camera(direction: int) -> void:
	# direction: -1 for left (Q), +1 for right (E)
	current_snap_index = (current_snap_index + direction) % 8
	if current_snap_index < 0:
		current_snap_index = 7

	var target_rotation = current_snap_index * SNAP_ANGLE
	_animate_rotation(target_rotation)


func _snap_to_nearest_angle() -> void:
	# Find nearest 45-degree snap position
	var current_rotation = fmod(rotation_degrees.y, 360.0)
	if current_rotation < 0:
		current_rotation += 360.0

	current_snap_index = int(round(current_rotation / SNAP_ANGLE)) % 8
	var target_rotation = current_snap_index * SNAP_ANGLE

	# Handle wrap-around for smooth animation
	var diff = target_rotation - rotation_degrees.y
	if diff > 180:
		target_rotation -= 360
	elif diff < -180:
		target_rotation += 360

	_animate_rotation(target_rotation)


func _animate_rotation(target_degrees: float) -> void:
	# Kill existing tween to allow immediate redirect
	if orbit_tween:
		orbit_tween.kill()

	orbit_tween = create_tween()
	orbit_tween.set_ease(Tween.EASE_IN_OUT)
	orbit_tween.set_trans(Tween.TRANS_CUBIC)
	orbit_tween.tween_property(self, "rotation_degrees:y", target_degrees, ORBIT_TRANSITION_TIME)


func _zoom_camera(delta: float) -> void:
	var target_zoom = clampf(current_zoom + delta, ZOOM_MIN, ZOOM_MAX)
	if target_zoom == current_zoom:
		return

	current_zoom = target_zoom
	_animate_zoom(target_zoom)


func _animate_zoom(target_distance: float) -> void:
	if zoom_tween:
		zoom_tween.kill()

	zoom_tween = create_tween()
	zoom_tween.set_ease(Tween.EASE_IN_OUT)
	zoom_tween.set_trans(Tween.TRANS_CUBIC)
	zoom_tween.tween_property(camera, "position:z", target_distance, ZOOM_TRANSITION_TIME)


func _reset_camera() -> void:
	current_snap_index = 1  # 45 degrees
	current_zoom = DEFAULT_ZOOM

	# Animate both rotation and zoom
	_animate_rotation(DEFAULT_ROTATION)
	_animate_zoom(DEFAULT_ZOOM)
