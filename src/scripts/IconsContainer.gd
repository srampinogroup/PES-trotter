extends MarginContainer

func update_viewport() -> void:
	position = get_window().size - Vector2i(size)
