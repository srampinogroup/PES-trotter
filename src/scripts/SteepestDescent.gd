class_name SteepestDescent
extends Node3D

var path: Array[Vector2i] = []
var _node_pool: Array[Node3D] = []


func _get_neighbors_with_center(point: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	for i in [-1, 0, 1]:
		for j in [-1, 0, 1]:
			var x = point.x + i
			if x < 0 or x >= Globals.pes_data.size_x:
				continue
			var y = point.y + j
			if y < 0 or y >= Globals.pes_data.size_y:
				continue
			neighbors.append(Vector2i(x, y))
	
	return neighbors


func _compute_path(start_point: Vector2i) -> void:
	path.clear()
	var point := start_point
	
	while true:
		path.append(point)
		var neighbors := _get_neighbors_with_center(point)
		
		var min_energy := INF
		var min_point: Vector2i
		
		for neighbor in neighbors:
			var energy = Globals.pes_data.get_energy(neighbor.x, neighbor.y)
			if energy < min_energy:
				min_energy = energy
				min_point = neighbor
		
		if min_point == point:
			break
		
		point = min_point


func _hide_pool() -> void:
	for node in _node_pool:
		node.visible = false


func _ensure_pool_filled(n: int) -> void:
	for i in range(len(_node_pool), n):
		var point_node = %SDTemplate.duplicate()
		_node_pool.append(point_node)
		add_child(point_node)


func _draw_path() -> void:
	_hide_pool()
	_ensure_pool_filled(len(path))
	
	for i in len(path):
		var point := path[i]
		var point_node := _node_pool[i]
		point_node.position = Map.grid_coords_to_pos(Vector2(point))
		point_node.visible = true


func compute_and_draw(start_point: Vector2i) -> void:
	_compute_path(start_point)
	_draw_path()


func get_resample_sd_path(new_size: int = Globals.settings[&"num_sample_points"]) -> Array:
	var fpath: Array[Vector2] = []
	for p in path:
		fpath.append(Vector2(p))
	return Globals.resample(fpath, new_size)
