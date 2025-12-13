class_name BetaWarning
extends MarginContainer


@onready var _ui_scales := [
	[%NormalBtn, 1.0],
	[%BigBtn, 1.2],
	[%BiggerBtn, 1.5],
	[%HugeBtn, 2.0],
]


func _ready() -> void:
	visible = Globals.settings[&"show_beta"]
	%ShowOnStartButton.set_pressed_no_signal(visible)
	%ShowOnStartButton.pressed.connect(_show_beta_changed)
	%DisclaimerContents.meta_clicked.connect(OS.shell_open)
	
	for ui_scale in _ui_scales:
		var btn: Button = ui_scale[0]
		var ui_size: float = ui_scale[1]
		btn.pressed.connect(func():
			Globals.update_ui_scale(ui_size)
			Globals.settings[&"ui_scale"] = ui_size
			Globals.save_config())


func _show_beta_changed() -> void:
	Globals.settings[&"show_beta"] = %ShowOnStartButton.button_pressed
	Globals.save_config()
