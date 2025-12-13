extends Resource
class_name AtomPosition


var atom: String
var position: Vector3


static func from_string(line: String) -> AtomPosition:
	var splits = line.replace("\t", " ").split(" ", false)
	var atom_position = AtomPosition.new()
	atom_position.atom = splits[0]
	atom_position.position = Vector3.ZERO
	for i in range(3):
		atom_position.position[i] = float(splits[i + 1])
	return atom_position


func _to_string() -> String:
	return atom + " " + str(position.x) + " " \
		+ str(position.y) + " " + str(position.z)
