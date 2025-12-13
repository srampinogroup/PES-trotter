class_name FPSPlayer
extends CharacterBody3D

signal free_fly_toggled(flying: bool)

const WALK_SPEED = 5.0
const JUMP_SPEED = 5.0
const SPRINT_MULT = 3.0
const LOOK_SENSITIVITY_MULT = 0.005
const JOY_SPEED = 10.0
const MAX_LOOK_ANGLE = deg_to_rad(90)
const DOUBLETAP_MAX_TIME = 0.5 # seconds
var GRAVITY: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var camera: Camera3D = %Camera

var free_flying := false
var sprinting := false

var altitude: float:
	get:
		return position.y
	set(value):
		position.y = value

var yaw: float:
	get:
		return rotation.y
	set(value):
		rotation.y = value

var pitch: float:
	get:
		return camera.rotation.x
	set(value):
		camera.rotation.x = value

var _last_tap := 0.0


func _ready() -> void:
	free_flying = not Globals.settings[&"fly_on_start"]
	toggle_free_fly()


func _input(event: InputEvent) -> void:
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			set_rotation_target(event.relative)
	
	if Input.is_action_just_pressed(&"toggle_collision"):
		toggle_free_fly()
	
	if is_on_floor():
		if Input.is_action_just_pressed(&"move_up"):
			_jump()
	
		## This is handling of custom double tap since Godot's built-in does not
		## work if you already have your other finger on the screen, like on the
		## joystick for example.
		if Globals.IS_TOUCH and event is InputEventScreenTouch and event.pressed:
			if _last_tap < DOUBLETAP_MAX_TIME:
				_jump()
			else:
				_last_tap = 0.0


func _physics_process(delta):
	_last_tap += delta
	var look_input := Input.get_vector(&"look_left", &"look_right", &"look_up", &"look_down")
	set_rotation_target(look_input * JOY_SPEED)

	sprinting = (Input.is_action_pressed(&"sprint")
		!= Globals.settings[&"always_sprint"])
	var speed := WALK_SPEED
	if sprinting:
		speed *= SPRINT_MULT
	
	var move_input := Input.get_vector(&"move_left", &"move_right",
									   &"move_forward", &"move_backward")
	if free_flying:
		var flight_input := Input.get_axis(&"move_down", &"move_up")
		var forward := camera.global_transform.basis.z
		var right := transform.basis.x
		# var up = camera.global_transform.basis.y
		var up := Vector3.UP
		velocity = forward * move_input.y
		velocity += right * move_input.x
		velocity += up * flight_input
		velocity = velocity.normalized() * speed
	else:
		var move_dir = global_basis * Vector3(move_input.x, 0, move_input.y)
		velocity.y += -GRAVITY * delta
		velocity.x = move_dir.x
		velocity.z = move_dir.z
		var y := velocity.y
		velocity.y = 0
		velocity = velocity.normalized() * speed
		velocity.y = y

	move_and_slide()


func _jump() -> void:
	velocity.y = JUMP_SPEED


func set_rotation_target(mouse_motion: Vector2):
	var look_sensitivity: float = (LOOK_SENSITIVITY_MULT
		* Globals.settings[&"mouse_look_sensitivity"])
	rotate_y(-mouse_motion.x * look_sensitivity)
	camera.rotate_x(-mouse_motion.y * look_sensitivity)
	camera.rotation.x = clampf(camera.rotation.x, -MAX_LOOK_ANGLE, MAX_LOOK_ANGLE)


func toggle_free_fly() -> bool:
	free_flying = not free_flying
	%Collision.disabled = free_flying
	free_fly_toggled.emit(free_flying)
	return free_flying


func update_viewport() -> void:
	%Crosshair.size = get_window().size
