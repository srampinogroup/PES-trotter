extends MarginContainer

const EXTRA_MARGIN = 40 # px

func update_viewport() -> void:
	size.y = get_window().size.y - EXTRA_MARGIN
