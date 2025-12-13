class_name ChartContainer
extends PanelContainer

var energy_profile: Array[float]

var _f: Function
var _ylabel: String
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


## FIXME useless?
func _get_param_range() -> float:
	var x_min = Globals.settings[&"x_min"] as float
	var x_max = Globals.settings[&"x_max"] as float
	var y_min = Globals.settings[&"y_min"] as float
	var y_max = Globals.settings[&"y_max"] as float
	
	return sqrt((x_max - x_min) * (y_max - y_min))


func _physics_process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	
	#NOTE optimization possible here: redraw only if needed
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


func clear() -> void:
	for i in range(len(energy_profile)):
		_f.set_point(i, float(i), 0.0)
	
	energy_profile.clear()


func set_ylabel(lbl: String) -> void:
	_ylabel = lbl
