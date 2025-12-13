class_name AppSettings
extends VBoxContainer


@onready var FIELD_SETTING_MAP := [
	[%TouchCheck, &"touch_force_enabled"],
	[%SwapJoysticksBtn, &"swap_joysticks"],
	[%FlyCheck, &"fly_on_start"],
	[%AlwaysSprintChk, &"always_sprint"],
	[%LookSensitivityBox, &"mouse_look_sensitivity"],
	[%RotateHueChk, &"rotate_hue"],
	[%SwapHueChk, &"swap_hue"],
	[%UIScaleBox, &"ui_scale"],
	[%PlaybackTimeBox, &"playback_time"],
	[%PlaybackLoopCheck, &"playback_loop"],
	[%PlaybackToAndFroCheck, &"playback_toandfro"],
	[%MaxPointsBox, &"num_sample_points"],
	[%SoundsOnChk, &"ui_sounds_on"],
	[%ShowColorbarsChk, &"show_colorbars"],
	[%BondVisibilityCheck, &"show_bounds"],
]


func _ready() -> void:
	Globals.connect_fields_changes(FIELD_SETTING_MAP)
	visibility_changed.connect(setup_already_there_values)
	%UIScaleBox.value_changed.connect(Globals.update_ui_scale)
	
	_connect_sensitivity_slider_and_box()
	_update_slider(Globals.settings[&"mouse_look_sensitivity"])


func _connect_sensitivity_slider_and_box() -> void:
	%LookSensitivitySlider.value_changed.connect(_update_box)
	%LookSensitivityBox.value_changed.connect(_update_slider)


func _update_box(value: float) -> void:
	%LookSensitivityBox.set_value(value)


func _update_slider(value: float) -> void:
	%LookSensitivitySlider.set_value_no_signal(value)


func setup_already_there_values() -> void:
	Globals.setup_already_there_values(FIELD_SETTING_MAP)
	Globals.update_ui_scale(Globals.settings[&"ui_scale"])
