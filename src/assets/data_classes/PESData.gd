class_name PESData


var size_x: int
var size_y: int
var energies: PackedFloat32Array
var configurations: Array[Array] # Array[Array[AtomPosition]]
var parse_successful: bool = false


class ParsedGridLine:
	var size_x: int
	var size_y: int
	var i: int
	var j: int
	var energy: float
	
	static func from_string(line: String) -> ParsedGridLine:
		var splits = line.split(" ", false)
		var gl := ParsedGridLine.new()
		gl.size_x = int(splits[3])
		gl.size_y = int(splits[1])
		gl.i = int(splits[7])
		gl.j = int(splits[5])
		gl.energy = float(splits[9])
		return gl


static func from_file(path: String, logger: Callable = print) -> PESData:
	var file := FileAccess.open(path, FileAccess.READ)
	assert(file != null, "cannot open file")
	
	var file_len := file.get_length()
	
	var num_atoms = int(file.get_line())
	logger.call("Num atoms: " + str(num_atoms))
	var line := file.get_line()
	logger.call("Found first grid line:")
	logger.call(line)

	var gl := ParsedGridLine.from_string(line)
	var pes := PESData.new(gl.size_x, gl.size_y)
	pes.set_energy(gl.i, gl.j, gl.energy)
	
	var line_number = 2
	while not line.is_empty():
		line = file.get_line()
		line_number += 1
		
		if line_number % (num_atoms + 2) == 1:
			continue # skip atom numbers
		
		if line_number % (num_atoms + 2) == 2:
			gl = ParsedGridLine.from_string(line)
			pes.set_energy(gl.i, gl.j, gl.energy)
			continue
			
		var atom_position := AtomPosition.from_string(line)
		pes.add_position(gl.i, gl.j, atom_position)
		
		Globals.pes_parse_progressed.emit.call_deferred(file.get_position(), file_len)
	
	if line_number == (num_atoms + 2) * gl.size_x * gl.size_y + 1:
		# More sanity checks might be useful here.
		pes.parse_successful = true
	else:
		logger.call("WARNING: your PES file seems to be ill-formed. "
				  + "The application might have unexpected behavior.")
	
	return pes


func _init(sx: int, sy: int) -> void:
	size_x = sx
	size_y = sy
	energies.resize(size_x * size_y)
	energies.fill(0)
	configurations.resize(size_x * size_y)
	# configurations.fill([]) # NOTE Same behavior as in python, all arrays share the same ref
	for i in range(size_x * size_y):
		configurations[i] = [].duplicate()


func _get_index(i: int, j: int) -> int:
	return j * size_x + i


func get_energy(i: int, j: int) -> float:
	return energies[_get_index(i, j)]


func get_energies_matrix() -> Array:
	var emat := []
	for x in range(size_x):
		var row := []
		for y in range(size_y):
			row.append(get_energy(x, y))
		emat.append(row)
	return emat


func set_energy(i: int, j: int, energy: float) -> void:
	energies[_get_index(i, j)] = energy


func add_position(i: int, j: int, atom_position: AtomPosition) -> void:
	configurations[_get_index(i, j)].append(atom_position)


func get_configuration(i: int, j: int) -> MoleculeConfiguration:
	var mc := MoleculeConfiguration.new()
	mc.energy = get_energy(i, j)
	mc.positions = configurations[_get_index(i, j)]
	return mc
