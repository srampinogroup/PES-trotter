extends Resource
class_name MoleculeConfiguration


const INVALID = null

@export var energy: float
@export var positions: Array


func _to_string() -> String:
	return _to_bbcode()


func _to_bbcode() -> String:
	var units: String = Globals.settings[&"energy_units"]
	return "Energy: [b]%f %s[/b]\n" % [energy, units] \
		+ "\n".join(positions.map(_pos_to_bbcode))


func _pos_to_bbcode(pos: AtomPosition) -> String:
	var color: Color = Globals.ATOM_COLOR.get(pos.atom, Color.ORANGE_RED)
	var ch := color.to_html()
	
	return "[color=%s]%s[/color] %.3v" % [ch, pos.atom, pos.position]
