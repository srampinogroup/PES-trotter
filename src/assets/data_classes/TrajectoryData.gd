class_name TrajectoryData
extends Resource


class ParsedTrajLine:
	var total: int
	var i: int
	var x: float
	var y: float
	var energy: float


	func _to_string() -> String:
		return "total: %d i: %d x: %f y: %f E: %f" % [total, i, x, y, energy]


	static func from_string(line: String) -> ParsedTrajLine:
		line = line.replace("\t", " ")
		var splits = line.split(" ", false)
		var tl := ParsedTrajLine.new()
		tl.total = int(splits[1])
		tl.i = int(splits[3])
		tl.x = float(splits[5])
		tl.y = float(splits[7])
		tl.energy = float(splits[9])
		return tl

var name := ""
var grid_pos_list: Array[Vector2] = []
var configurations: Array[MoleculeConfiguration] = []


func add_point(pes_pos: Vector2) -> void:
	grid_pos_list.append(pes_pos)


func _to_string() -> String:
	var s := ""
	var total := len(grid_pos_list)
	for i in total:
		var grid_pos := grid_pos_list[i]
		var pes_pos := Map.grid_coords_to_pes_coords(grid_pos)
		var ix_dic := Map.grid_coords_to_indices(grid_pos)
		var mc := Map.indices_to_config(ix_dic["ix"], ix_dic["weights"])
		var atom_num := len(mc.positions)
		s += str(atom_num) + "\n"
		var tl := ParsedTrajLine.new()
		tl.i = i
		tl.total = total
		tl.x = pes_pos.x
		tl.y = pes_pos.y
		tl.energy = mc.energy
		s += str(tl) + "\n"
		for pos in mc.positions:
			s += str(pos) + "\n"
	
	return s


static func from_string(s: String) -> TrajectoryData:
	var td := TrajectoryData.new()
	
	var lines := s.split("\n")
	var atom_count := int(lines[0])
	var first_traj_line := ParsedTrajLine.from_string(lines[1])
	
	var line_cursor := 0
	for i in first_traj_line.total:
		var mc := MoleculeConfiguration.new()
		line_cursor += 1
		var parsed_line := ParsedTrajLine.from_string(lines[line_cursor])
		mc.energy = parsed_line.energy
		var pes_pos := Vector2(parsed_line.x, parsed_line.y)
		td.grid_pos_list.push_front(Map.pes_coords_to_grid_coords(pes_pos))
		line_cursor += 1
		
		for j in range(0, atom_count):
			var atom_position := AtomPosition.from_string(lines[line_cursor])
			mc.positions.push_back(atom_position)
			line_cursor += 1
		
		td.configurations.push_front(mc)
	
	return td
