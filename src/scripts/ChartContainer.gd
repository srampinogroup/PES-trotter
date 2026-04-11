class_name ChartContainer
extends PanelContainer

var energy_profile: Array[float]

var _f: Function
var _ylabel: String #FIXME not used until rotation of label implemented
var _num_points: int


func _ready() -> void:
	_num_points = Globals.settings[&"num_sample_points"]
	energy_profile = []
	
	var cp := ChartProperties.new()
	cp.max_samples = _num_points
	cp.colors.background = Color.TRANSPARENT
	cp.colors.frame = Color("#161a1d")
	cp.colors.grid = Color("#283442")
	cp.colors.ticks = Color("#283442")
	cp.colors.text = Color.WHITE_SMOKE
	cp.draw_bounding_box = false
	cp.x_scale = 1
	#cp.y_label = _ylabel
	cp.y_label = "E"
	cp.show_x_label = false
	
	var zero_arr := []
	zero_arr.resize(_num_points)
	zero_arr.fill(0.0)
	
	_f = Function.new(range(_num_points), zero_arr, "PES profile", {
		color = Color("#36a2eb"),
		marker = Function.Marker.NONE,
		type = Function.Type.AREA,
		interpolation = Function.Interpolation.LINEAR
	})
	
	%Chart.plot([_f] as Array[Function], cp)
	
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if not visible:
		return
	
	update_plot.call_deferred()


func update_plot() -> void:
	for i in range(min(_num_points, len(energy_profile))):
		_f.set_point(i, float(i), energy_profile[i])
	
	%Chart.queue_redraw()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"toggle_chart"):
		visible = !visible


func push(energy: float) -> void:
	energy_profile.push_back(energy)
	if len(energy_profile) > _num_points:
		energy_profile.pop_front()
	
	update_plot()


func clear() -> void:
	for i in range(len(energy_profile)):
		_f.set_point(i, float(i), 0.0)
	
	energy_profile.clear()
	update_plot()


##FIXME Not used
func set_ylabel(lbl: String) -> void:
	_ylabel = lbl
