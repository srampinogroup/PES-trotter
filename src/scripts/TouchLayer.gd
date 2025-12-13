extends CanvasLayer


func update_viewport() -> void:
	var window_size := get_window().size
	var joystick_size: float = %RightJoystick.size.x
	%LeftJoystick.position.x = 0
	%LeftJoystick.position.y = window_size.y - joystick_size
	%RightJoystick.position.x = window_size.x - joystick_size
	%RightJoystick.position.y = window_size.y - joystick_size
	
	var reverse: bool = Globals.settings[&"swap_joysticks"]
	var move_joystick = %LeftJoystick if not reverse else %RightJoystick
	var look_joystick = %RightJoystick if not reverse else %LeftJoystick
	move_joystick.action_left = &"move_left"
	move_joystick.action_right = &"move_right"
	move_joystick.action_up = &"move_forward"
	move_joystick.action_down = &"move_backward"
	look_joystick.action_left = &"look_left"
	look_joystick.action_right = &"look_right"
	look_joystick.action_up = &"look_up"
	look_joystick.action_down = &"look_down"


func _ready() -> void:
	visibility_changed.connect(_visibility_changed)
	_visibility_changed()


func _visibility_changed() -> void:
	print("> touch layer visibility toggled to ", visible)
	%LeftJoystick.visible = visible
	%RightJoystick.visible = visible
