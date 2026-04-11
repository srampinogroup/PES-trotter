class_name MinimumEnergyPath
extends Node3D

var path: Array[Vector2i] = []
var _astar_initialized := false
var _astar := AStarGrid2D.new()
var _path_points: Array[Node3D] = []
var _expression := Expression.new()


func _ready() -> void:
	visibility_changed.connect(_visibility_changed)


func _visibility_changed() -> void:
	print("> MEP visibility changed to ", visible)


func _weight_tuning(weight: float) -> float:
	#return (weight + 1) ** 2
	var wstr := Globals.settings[&"wtoe_exp"] as String
	wstr = wstr.replace("E", str(weight))
	
	var err = _expression.parse(wstr)
	if err != OK:
		return 0.0
	
	var w_raw = _expression.execute()
	return w_raw as float


func _free_path_points() -> void:
	for node in _path_points:
		node.queue_free()
	_path_points.clear()


func _ensure_astar_ready() -> void:
	if _astar_initialized:
		return
	
	_init_astar()


func _init_astar() -> void:
	var pes := Globals.pes_data
	var energies := pes.get_energies_matrix()
	var minima := []
	for ix in pes.size_x:
		minima.append(energies[ix].min())
	var min_energy: float = minima.min()
	
	_astar.region = Rect2i(0, 0, pes.size_x, pes.size_y)
	_astar.update()
	for ix in pes.size_x:
		for iy in pes.size_y:
			var e := energies[ix][iy] as float - min_energy
			var weight := _weight_tuning(e)
			_astar.set_point_weight_scale(Vector2i(ix, iy), weight)
	
	_astar_initialized = true


func _draw_path(points: Array) -> void:
	_free_path_points()
	
	for point in points:
		var point_node := %MEPTemplate.duplicate()
		point_node.position = Map.grid_coords_to_pos(Vector2(point))
		point_node.visible = true
		point_node.scale = Vector3.ONE * 0.9
		add_child(point_node)
		_path_points.append(point_node)
	
	for point in [points.front(), points.back()]:
		var point_node := %ExtremityTemplate.duplicate()
		point_node.position = Map.grid_coords_to_pos(Vector2(point))
		point_node.visible = true
		add_child(point_node)
		_path_points.append(point_node)


func compute_and_draw(start: Vector2i, end: Vector2i) -> void:
	_ensure_astar_ready()
	path = _astar.get_id_path(start, end)
	_draw_path(path)


## Returns the path as an array of new_size Vector2
func get_resample_mep(new_size: int = Globals.settings[&"num_sample_points"]) -> Array:
	var fpath: Array[Vector2] = []
	for p in path:
		fpath.append(Vector2(p))
	return Globals.resample(fpath, new_size)
