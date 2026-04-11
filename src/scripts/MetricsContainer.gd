extends MarginContainer

func update_viewport() -> void:
	position.x = get_window().size.x - size.x


func _physics_process(_delta: float) -> void:
	%MetricsLabel.text = "FPS: %f\n" % Engine.get_frames_per_second()
	
	var mems = {
		"Mem now (MB)": Performance.MEMORY_STATIC,
		"Mem max (MB)": Performance.MEMORY_STATIC_MAX,
		"GPU mem (MB)": Performance.RENDER_VIDEO_MEM_USED,
	}
	
	for k in mems:
		var monitor_val = Performance.get_monitor(mems[k])
		monitor_val /= 1e6 # to MB
		%MetricsLabel.text += "%s: %f\n" % [k, monitor_val]
