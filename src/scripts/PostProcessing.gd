extends ColorRect

const POST_PROCESS_MAT = preload("res://assets/post_process/post_process_shader_mat.tres")

func _ready() -> void:
	for p in [&"rotate_hue", &"swap_hue"]:
		POST_PROCESS_MAT.set_shader_parameter(p, Globals.settings[p])
