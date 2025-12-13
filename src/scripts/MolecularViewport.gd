class_name MolecularViewport
extends SubViewport

enum Mode {PES, TRAJECTORY}

const MODE_COLORS = {
	Mode.PES: Color.WHITE,
	Mode.TRAJECTORY: Color.ROYAL_BLUE,
}

const SENSITIVITY_ROT = Vector2.ONE * 0.01
const ANGULAR_ACCELERATION = 5.0
const ANGULAR_INERTIA = 10.0
const MAX_BOND_RAD = 0.1
const RAD_REDUCTION = 0.8
const BOND_RAD_REDUCTION = 0.4

var mc: MoleculeConfiguration
var spheres: Array[MeshInstance3D]
var cylinders: Array
var mol_scale := 1.0

var mode: Mode:
	get:
		return mode
	set(value):
		mode = value
		var mat: StandardMaterial3D = %PlateMesh.material
		mat.albedo_color = MODE_COLORS[mode]

var trajectory_name: String:
	get:
		return %TrajectoryLabel.text
	set(value):
		%TrajectoryLabel.text = value

var _mol_root := Node3D.new()
var _angular_velocity := 0.0
var _dragging := false
var _last_event = null


func _generate_test_conf() -> MoleculeConfiguration:
	var mc_ := MoleculeConfiguration.new()
	mc_.positions = [
		AtomPosition.from_string("H 0 0.5 0"),
		AtomPosition.from_string("O -1 0 0"),
		AtomPosition.from_string("O 1 0 0"),
	]
	return mc_


func _ready() -> void:
	if Globals.pes_data == null: # Standalone test
		mc = _generate_test_conf()
	else:
		mc = Globals.pes_data.get_configuration(0, 0)
	
	add_child(_mol_root)
	
	for i in len(mc.positions):
		var pos: AtomPosition = mc.positions[i]
		var sphere := SphereMesh.new()
		var rad: float = Globals.ATOM_RADIUS.get(pos.atom, 1)
		rad *= BOND_RAD_REDUCTION if Globals.settings[&"show_bounds"] else RAD_REDUCTION
		sphere.radius = rad
		sphere.height = 2 * rad
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Globals.ATOM_COLOR.get(pos.atom, _random_color())
		sphere.material = mat
		var node := MeshInstance3D.new()
		node.mesh = sphere
		node.position = pos.position * Globals.settings[&"position_unit_factor"]
		spheres.append(node)
		_mol_root.add_child(node)
	
		if Globals.settings[&"show_bounds"]:
			for j in i:
				var cylinder := MeshInstance3D.new()
				var mesh := CylinderMesh.new()
				mesh.height = 1.0
				mesh.top_radius = 0.1
				mesh.bottom_radius = 0.1
				cylinder.mesh = mesh
				cylinder.rotation.x = PI * 0.5
				
				var cylinder_pivot := Node3D.new()
				cylinder_pivot.add_child(cylinder)
				cylinders.append([i, j, cylinder_pivot])
				_mol_root.add_child(cylinder_pivot)

	%Slider.value_changed.connect(apply_scale)


func _physics_process(delta: float) -> void:
	for i in len(mc.positions):
		spheres[i].position = mc.positions[i].position
		spheres[i].position *= Globals.settings[&"position_unit_factor"]
	
	if Globals.settings[&"show_bounds"]:
		for tup in cylinders:
			var i: int = tup[0]
			var j: int = tup[1]
			var cylinder: Node3D = tup[2]
			var i_pos: AtomPosition = mc.positions[i]
			var j_pos: AtomPosition = mc.positions[j]
			cylinder.position = (i_pos.position + j_pos.position) * 0.5
			cylinder.position *= Globals.settings[&"position_unit_factor"]
			var dist := i_pos.position.distance_to(j_pos.position)
			var rad1: float = Globals.ATOM_RADIUS[i_pos.atom]
			var rad2: float = Globals.ATOM_RADIUS[j_pos.atom]
			var bond := clampf(1 - 0.5 * (dist - rad1 - rad2), 0.0, 1.0)
			cylinder.get_child(0).mesh.height = dist
			cylinder.get_child(0).mesh.top_radius = bond * MAX_BOND_RAD
			cylinder.get_child(0).mesh.bottom_radius = bond * MAX_BOND_RAD
			cylinder.look_at(j_pos.position
							 * Globals.settings[&"position_unit_factor"])
	
	rotate_plate_by_angle(_angular_velocity * delta)
	_angular_velocity = lerpf(_angular_velocity, 0.0, ANGULAR_INERTIA * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
		if _dragging:
			_angular_velocity = 0
	
	if event is InputEventMouseMotion and _dragging:
		rotate_plate_by_angle(-event.relative.x * SENSITIVITY_ROT.x)
		tilt_molecule_by_angle(event.relative.y * SENSITIVITY_ROT.y)
		_last_event = event
	
	if event is InputEventScreenDrag:
		# Yes, same code. Prevents doubling rotation when emulating touch from mouse.
		rotate_plate_by_angle(-event.relative.x * SENSITIVITY_ROT.x)
		tilt_molecule_by_angle(event.relative.y * SENSITIVITY_ROT.y)
		_last_event = event
	
	if not _dragging and _last_event != null:
		_angular_velocity = -_last_event.screen_relative.x * ANGULAR_ACCELERATION
		_last_event = null
	
	get_tree().create_timer(0.1).timeout.connect(func (): _last_event = null)


func _random_color() -> Color:
	return Color.from_rgba8(randi_range(0, 255),
							randi_range(0, 255),
							randi_range(0, 255))


func rotate_plate_by_angle(angle: float) -> void:
	%Pivot.rotation.y += angle
	

func tilt_molecule_by_angle(angle: float) -> void:
	_mol_root.rotate_x(angle)


func apply_move_rotation(motion: Vector2) -> void:
	rotate_plate_by_angle(motion.x)
	tilt_molecule_by_angle(motion.y)


func apply_scale(amount: float) -> void:
	mol_scale = amount
	_mol_root.scale = mol_scale * Vector3.ONE
	%Slider.set_value_no_signal(mol_scale)
	
	get_viewport().set_input_as_handled()
