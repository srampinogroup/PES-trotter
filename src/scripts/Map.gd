class_name Map
extends StaticBody3D


const ROOT_SCRIPT = preload("res://scripts/Root.gd")
const MAIN_MENU_PATH = "res://scenes/MainMenu.tscn"
#var MAIN_MENU_SCENE = load(MAIN_MENU_PATH)
const TRAJECTORY_EXT = "xyz"
const PROFILE_PATH = "user://profile." + TRAJECTORY_EXT
const UPLOADED_TRAJECTORY_PATH = "user://uploaded_trajectory." + TRAJECTORY_EXT
const DOWNLOAD_TRAJECTORY_NAME = "trajectory." + TRAJECTORY_EXT
const DEBUG_PROFILE_LOAD_SAVE = false
const SPAWN_OVERHEIGHT = 2.0
const WHEEL_SENS = 0.1
const MOL_ROT_SPEED = TAU / 5
const RAY_LENGTH = 1000.0
const MAP_COLLISION_LAYER = 1
const ANCHOR_COLLISION_LAYER = 2
#const WALLS_COLLISION_LAYER = 3
const SCALE_INCREMENT = 0.1
const FALL_RESET_THRESHOLD = 2.0
const CHART_SIZE = Vector2i(350, 320)
const CHART_SIZE_SMALL = Vector2i(250, 200)

var _is_drawing_profile := false
var _must_push_energy := false
var _profile_nodes: Array[Node3D] = []
var _profile_values: Array[Vector3]
var _clicking := false
var _mouse_was_captured := true
var _current_anchor: Node3D = null
var _is_mep := false
var _mep_start_chosen := false
var _mep_start := Vector2.ZERO
var _mep_end := Vector2.ZERO
var _is_sd := false
var _trajectory: TrajectoryData = null
var _playback_enabled := false
var _playback_paused := false
var _file_access_web: FileAccessWeb = null

var _mouse_captured : bool = true:
	get:
		return _mouse_captured
	set(value):
		_mouse_captured = value
		_update_capture_state()

# Each number corresponds to the index of the action menu item below in
# const ACTIONS
enum Visibility {
	PROFILE = 0,
	DRAWING = 1,
	ANCHORS = 5,
	MEP = 7,
	SD = 11,
	TRAJECTORY = 15,
	FLY_MODE = 17,
}

const ACTION_SEPARATOR = &"-"
var ACTIONS := [
	[&"Show energy profile", _toggle_chart, true], # PROFILE 0
	[&"Draw profile", _activate_chart, true], # DRAWING 1
	[&"Save profile", _save_profile_action],
	[&"Load profile", _load_profile_action],
	[ACTION_SEPARATOR],
	[&"Show critical points", _toggle_anchors, true], # ANCHORS 5
	[ACTION_SEPARATOR],
	[&"Show minimum energy path (MEP)", _toggle_mep, true], # MEP 7
	[&"Compute MEP", _start_mep],
	[&"MEP to profile", _mep_to_profile],
	[ACTION_SEPARATOR],
	[&"Show steepest descent (SD)", _toggle_sd, true], # SD 11
	[&"Compute SD", _steepest_descent],
	[&"SD to profile", _sd_to_profile],
	[ACTION_SEPARATOR],
	[&"Trajectory playback", _toggle_trajectory, true], # TRAJECTORY 15
	[ACTION_SEPARATOR],
	[&"Fly mode", _toggle_free_fly, true], # FLY_MODE 17
	[ACTION_SEPARATOR],
	[&"Reset position to center", _set_player_pos],
	[ACTION_SEPARATOR],
	[&"Menu", _go_to_menu],
]


func _ready() -> void:
	_mouse_captured = true
	_update_ui_from_settings()
	_connect_ui_signals()
	_scale_map()
	_set_player_pos()
	_set_frame_position()
	_setup_profiling_snake()
	_listen_to_viewport_change()
	_setup_actions_menu()
	_update_actions_check_states()
	_on_window_size_changed()
	_setup_colobars()


func _update_ui_from_settings() -> void:
	%TouchLayer.visible = (
		Globals.IS_TOUCH or Globals.settings[&"touch_force_enabled"]
	)
	%VersionLabel.text = "v%s   " % Globals.VERSION
	%MouseKeyLabel.visible = not Globals.IS_TOUCH
	%MetricsContainer.visible = Globals.settings[&"show_perf_metrics"]
	# %ChartContainer.set_ylabel("E (%s)" % Globals.settings[&"energy_units"])


func _connect_ui_signals() -> void:
	UISounds.connect_sounds(%UIControl)
	
	%CollapseBtn.pressed.connect(_toggle_advanced)
	%SmallChartButton.pressed.connect(_toggle_small_chart)
	%PlayButton.pressed.connect(_play_trajectory)
	%PauseButton.pressed.connect(_pause_trajectory)
	%MenuButton.pressed.connect(_go_to_menu)
	%FPSPlayer.free_fly_toggled.connect(_free_fly_changed)
	_free_fly_changed(%FPSPlayer.free_flying)
	
	if Globals.IS_WEB:
		_file_access_web = FileAccessWeb.new()
		_file_access_web.load_started.connect(_on_traj_upload_started)
		_file_access_web.loaded.connect(_on_traj_upload_finished)
		_file_access_web.progress.connect(_on_traj_upload_progressed)
		_file_access_web.error.connect(_on_traj_upload_errored)
	else:
		%SaveProfileDialog.file_selected.connect(_save_profile)
		%LoadProfileDialog.file_selected.connect(_load_profile)


func _toggle_advanced() -> void:
	print("> toggle show advanced")
	%UIConsoleLabel.visible = not %UIConsoleLabel.visible


func _toggle_small_chart() -> void:
	print("> toggle small chart")
	%ChartContainer.visible = false
	%ChartContainer.size = (
		CHART_SIZE_SMALL if %SmallChartButton.button_pressed else CHART_SIZE
	)
	%ChartContainer.visible = true # force update chart


func _setup_profiling_snake() -> void:
	for i in range(Globals.settings[&"num_sample_points"]):
		var sphere = %SphereTemplate.duplicate()
		sphere.visible = false
		_profile_nodes.append(sphere)
		%ProfilingTrace.add_child(sphere)

	_profile_values = []


func _listen_to_viewport_change() -> void:
	get_window().set_script(ROOT_SCRIPT)
	get_window().size_changed.connect(_on_window_size_changed)


func _on_window_size_changed() -> void:
	%TouchLayer.update_viewport()
	var x_size = get_window().size.x
	#%ChartContainer.position.x = x_size - %ChartContainer.size.x
	%SubViewportContainer.position.x = x_size - %SubViewportContainer.size.x
	%FPSPlayer.update_viewport()
	%ConfigContainer.update_viewport()
	%IconsContainer.update_viewport()
	%MetricsContainer.update_viewport()
	await get_tree().create_timer(0.1).timeout
	#FIXME Godot likes to complain here about "non-equal opposite anchors".
	%MainContainer.size = get_window().size
	%PostProcessingLayer.size = get_window().size


func _setup_colobars() -> void:
	%ColorsContainer.visible = Globals.settings[&"show_colorbars"]
	
	#FIXME ducplicated code from Minimap
	var units: String = Globals.settings[&"energy_units"]
	var e_min: float = Globals.settings[&"energy_min"]
	var e_max: float = Globals.settings[&"energy_max"]
	
	%PosColorsContainer.visible = e_max > 0.0
	%NegColorsContainer.visible = e_min < 0.0
	%MaxPosLabel.text = "%.2f %s" % [e_max, units]
	%MinPosLabel.text = "%.2f" % maxf(e_min, 0.0)
	%MaxNegLabel.text = "%.2f %s" % [minf(e_max, 0.0), units]
	%MinNegLabel.text = "%.2f" % e_min


func _input(event: InputEvent) -> void:
	if (event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT):
		_clicking = event.pressed

	if Input.is_action_just_pressed(&"toggle_chart"):
		_toggle_chart()

	if _is_drawing_profile:
		if (event is InputEventMouseButton
				and event.button_index == MOUSE_BUTTON_RIGHT):
			_clear_profile()

		# dragging
		if event is InputEventMouseMotion and _clicking:
			_must_push_energy = true

	if _is_mep:
		if (event is InputEventMouseButton
				and event.button_index == MOUSE_BUTTON_LEFT
				and event.pressed):
			var aimed_object = get_pes_pos_from_laser_or_player(true)
			if aimed_object == null:
				return

			var pes_pos = aimed_object.position
			var grid_pos := pos_to_grid_coords(pes_pos)

			if not _mep_start_chosen:
				_mep_start = grid_pos
				%StartPointingArrow.visible = true
				%EndPointingArrow.visible = true
				%StartPointingArrow.position = (
					grid_coords_to_pos(grid_pos) - %MinimumEnergyPath.position
				)
				_mep_start_chosen = true
			else:
				_mep_end = grid_pos
				notify_bubble(str(_mep_start) + " to " + str(_mep_end))
				%StartPointingArrow.visible = false
				%EndPointingArrow.visible = false
				_mep_start_chosen = false
				%MinimumEnergyPath.compute_and_draw(
					Vector2i(_mep_start), Vector2i(_mep_end)
				)
				await get_tree().create_timer(0.1).timeout
				_is_mep = false
		
		%MepIcon.visible = _is_mep
	
	if Input.is_action_just_pressed(&"quit"):
		Globals.quit_game()
	
	if Input.is_action_just_pressed(&"menu"):
		_go_to_menu()
	
	if Input.is_action_pressed(&"scale_up"):
		_scale_up_or_down(SCALE_INCREMENT)
	
	if Input.is_action_pressed(&"scale_down"):
		_scale_up_or_down(-SCALE_INCREMENT)
	
	if Input.is_action_just_pressed(&"toggle_capture"):
		_mouse_captured = not _mouse_captured
	
	if Input.is_action_just_pressed(&"save_profile"):
		_save_profile_action()
		
	if Input.is_action_just_pressed(&"load_profile"):
		_load_profile_action()
	
	if Input.is_action_just_pressed(&"test_action"):
		notify_bubble("Test notification")

	if Input.is_action_just_pressed(&"start_mep"):
		_start_mep()
	
	if Input.is_action_just_pressed(&"toggle_trajectory"):
		_toggle_trajectory()
	
	if (not _is_mep and event is InputEventMouseButton
			and event.button_index == MOUSE_BUTTON_LEFT
			and event.is_released()
			and _current_anchor != null):
		%FPSPlayer.position = _current_anchor.position
		notify_bubble(
			"Teleported to " + str(pos_to_grid_coords(_current_anchor.position))
		)
		_current_anchor = null
		
		#notify_bubble(event.as_text() + "\ndouble tap: " + str(event.double_tap))
	
	var is_playback_time_down := Input.is_action_just_pressed(&"playback_time_down")
	var is_playback_time_up := Input.is_action_just_pressed(&"playback_time_up")
	if is_playback_time_down or is_playback_time_up:
		Globals.settings[&"playback_time"] += 1.0 if is_playback_time_up else -1.0
		Globals.settings[&"playback_time"] = max(1.0, Globals.settings[&"playback_time"])
		notify_bubble("Playback time set to %s s" % Globals.settings[&"playback_time"])
	
	_update_actions_check_states()


func _rotate_plate_by_key(plate_rotation: int, delta: float) -> void:
	%MolecularViewport.rotate_plate_by_angle(plate_rotation * delta * MOL_ROT_SPEED)


func _save_profile_action() -> void:
	print("> save profile action")
  
	if DEBUG_PROFILE_LOAD_SAVE:
		_save_profile(PROFILE_PATH)
		return

	_mouse_was_captured = _mouse_captured
	_mouse_captured = false	
	
	if Globals.IS_WEB:
		var contents := _trajectory_to_string().to_utf8_buffer()
		JavaScriptBridge.download_buffer(contents, DOWNLOAD_TRAJECTORY_NAME)
	else:
		%SaveProfileDialog.show()


func _load_profile_action() -> void:
	print("> load profile action")
  
	if DEBUG_PROFILE_LOAD_SAVE:
		_load_profile(PROFILE_PATH)
		return
	
	_mouse_was_captured = _mouse_captured
	_mouse_captured = false
	if Globals.IS_WEB:
		_file_access_web.open()
	else:
		%LoadProfileDialog.show()


func _update_capture_state() -> void:
	if _mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	%CursorIcon.visible = not _mouse_captured


func _physics_process(delta: float) -> void:
	_handle_mc_and_profile(delta)
	_handle_plate_rotation(delta)
	_handle_molecule_scaling(delta)
	_handle_anchor_selection(delta)
	_handle_mep(delta)
	_handle_sd(delta)
	_handle_trajectory_playback(delta)

	var alt_min: float = Globals.settings[&"energy_min"] * Globals.map_scale.y
	if (not %FPSPlayer.free_flying and %FPSPlayer.position.y
			< alt_min - FALL_RESET_THRESHOLD):
		_set_player_pos()


func get_pes_pos_from_laser_or_player(
	force_laser: bool = false, col_layer: int = MAP_COLLISION_LAYER
):
	if force_laser or %FPSPlayer.free_flying:
		var space_state = get_world_3d().direct_space_state
		#var cam = %Camera3D
		var camera: Camera3D = %FPSPlayer.camera

		var origin: Vector3
		var end: Vector3
		var target_pos: Vector2

		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			target_pos = get_viewport().get_mouse_position()
		else:
			target_pos = get_viewport().size / 2
			
		origin = camera.project_ray_origin(target_pos)
		end = origin + camera.project_ray_normal(target_pos) * RAY_LENGTH
		
		var query = PhysicsRayQueryParameters3D.create(origin, end, col_layer)
		query.collide_with_areas = true

		var result = space_state.intersect_ray(query)
		if not result.is_empty():
			return result
	else:
		return %FPSPlayer

	return null


func _handle_mc_and_profile(_delta: float) -> void:
	var aimed_object = null
	if _playback_enabled:
		aimed_object = %TrajectoryPath.follower
		_must_push_energy = false
	else:
		aimed_object = get_pes_pos_from_laser_or_player(_is_drawing_profile)
		if aimed_object == null:
			return
	
	var pes_pos: Vector3 = aimed_object.position
	var grid_pos := pos_to_grid_coords(pes_pos)
	var ix_dic := grid_coords_to_indices(grid_pos)
	var mc := indices_to_config(ix_dic[&"ix"], ix_dic[&"weights"])
	%PointerSphere.position = pes_pos
	
	if mc == null:
		return

	var pes_coords := grid_coords_to_pes_coords(grid_pos)
	
	var x_name: String = Globals.settings[&"x_name"]
	var y_name: String = Globals.settings[&"y_name"]
	var units: String = Globals.settings[&"energy_units"]
	%EnergyCoordsLabel.text = ""
	%EnergyCoordsLabel.text += "%s: %.3f\n" % [x_name, pes_coords.x]
	%EnergyCoordsLabel.text += "%s: %.3f\n" % [y_name, pes_coords.y]
	%EnergyCoordsLabel.text += "E: %.3f %s" % [mc.energy, units]

	if _is_drawing_profile and not %TrajectoryPath.visible:
		if _must_push_energy:
			%ChartContainer.push(mc.energy)
			var profile_pos:= pes_pos
			#profile_pos.x -= %ProfilingTrace.position.x
			#profile_pos.z -= %ProfilingTrace.position.z
			_profile_values.push_back(profile_pos)
			if len(_profile_values) > Globals.settings[&"num_sample_points"]:
				_profile_values.pop_front()
			_update_profile()
			_must_push_energy = false
	
	%UIConsoleLabel.text = ""
	%UIConsoleLabel.text += "%.v + %.2v\n" % [ix_dic[&"ix"], ix_dic[&"weights"]]
	%UIConsoleLabel.text += "Scale is %.2v\n" % Globals.global_scale_3d
	%UIConsoleLabel.text += str(mc)
	%MolecularViewport.mode = MolecularViewport.Mode.PES
	%MolecularViewport.trajectory_name = ""
	%MolecularViewport.mc = mc


func _handle_plate_rotation(delta: float) -> void:
	var plate_rotation := 0
	if Input.is_action_pressed(&"plate_left"):
		plate_rotation -= 1
	if Input.is_action_pressed(&"plate_right"):
		plate_rotation += 1

	if plate_rotation != 0:
		_rotate_plate_by_key(plate_rotation, delta)


func _handle_molecule_scaling(_delta: float) -> void:
	#TODO use delta (or not)
	var mol_scale := %MolecularViewport.mol_scale as float
	if Input.is_action_just_pressed(&"zoom_in"):
		mol_scale *= (1 + WHEEL_SENS)
	if Input.is_action_just_pressed(&"zoom_out"):
		mol_scale *= (1 - WHEEL_SENS)

	%MolecularViewport.apply_scale(mol_scale)


func _handle_anchor_selection(_delta: float) -> void:
	_reset_anchor_selection()
	var aimed_object = get_pes_pos_from_laser_or_player(true, ANCHOR_COLLISION_LAYER)
	if aimed_object == null:
		_current_anchor = null
		return

	aimed_object.collider.material.metallic = 0.0
	_current_anchor = aimed_object.collider


func _reset_anchor_selection() -> void:
	for ball in %Anchors.get_children():
		ball.material.metallic = 1.0


func _handle_mep(_delta: float) -> void:
	if not _is_mep:
		return

	var aimed_object = get_pes_pos_from_laser_or_player(_is_mep)
	if aimed_object:
		%EndPointingArrow.position = (aimed_object.position
									  - %MinimumEnergyPath.position)


static func pos_to_grid_coords(pos3d: Vector3) -> Vector2:
	pos3d /= Globals.global_scale_3d
	var size := Vector2(Globals.pes_data.size_x, Globals.pes_data.size_y)
	var pos2d := Vector2(pos3d.x, pos3d.z)
	return pos2d + size / 2


static func grid_coords_to_pos(grid_coords: Vector2) -> Vector3:
	var size := Vector2(Globals.pes_data.size_x, Globals.pes_data.size_y)
	#var size3d := Vector3(size.x, 0, size.y)
	# FIXME these next two lines do not make sense
	grid_coords -= size / 2.0 #+ Vector2(1, 1) * -0.25
	var ix_dic = grid_coords_to_indices(grid_coords + size / 2.0)
	var energy := indices_to_energy(ix_dic[&"ix"], ix_dic[&"weights"])
	return (Vector3(grid_coords.x, energy, grid_coords.y)
			* Globals.global_scale_3d)


## Just splits the float into (int, float)
static func grid_coords_to_indices(grid_coords: Vector2) -> Dictionary:
	var ix = floor(grid_coords)
	var weights = grid_coords - ix
	return {&"ix": Vector2i(ix), &"weights": weights}


static func grid_coords_to_pes_coords(grid_pos: Vector2) -> Vector2:
	var scaling := Vector2(Globals.pes_data.size_x, Globals.pes_data.size_y)
	var x_min := Globals.settings[&"x_min"] as float
	var x_max := Globals.settings[&"x_max"] as float
	var y_min := Globals.settings[&"y_min"] as float
	var y_max := Globals.settings[&"y_max"] as float
	
	var actual = grid_pos / scaling
	actual.x *= x_max - x_min
	actual.y *= y_max - y_min
	actual.x += x_min
	actual.y += y_min
	
	# Apply tiling settings; note the x/y swap
	var y_tnum := Globals.settings[&"x_tiles_number"] as int
	var x_tnum := Globals.settings[&"y_tiles_number"] as int
	if x_tnum > 1:
		actual.x = fmod(actual.x * x_tnum, x_max)
	if y_tnum > 1:
		actual.y = fmod(actual.y * y_tnum, y_max)
	
	return actual


static func pes_coords_to_grid_coords(pes_pos: Vector2) -> Vector2:
	#NOTE: tiling not supported, the grid coords will be confined to first tile.
	var scaling := Vector2(Globals.pes_data.size_x, Globals.pes_data.size_y)
	var x_min := Globals.settings[&"x_min"] as float
	var x_max := Globals.settings[&"x_max"] as float
	var y_min := Globals.settings[&"y_min"] as float
	var y_max := Globals.settings[&"y_max"] as float
	
	var grid_pos := pes_pos
	grid_pos.x -= x_min
	grid_pos.y -= y_min
	grid_pos.x /= x_max - x_min
	grid_pos.y /= y_max - y_min
	return grid_pos * scaling


static func indices_to_energy(ix: Vector2i, weights: Vector2) -> float:
	if (ix.x < 0 or ix.x >= Globals.pes_data.size_x
			or ix.y < 0 or ix.y >= Globals.pes_data.size_y):
		return 0.0
	
	var e00 := Globals.pes_data.get_energy(ix.x, ix.y)
	if (ix.x == Globals.pes_data.size_x - 1
			or ix.y == Globals.pes_data.size_y - 1):
		return e00
	
	var e10 := Globals.pes_data.get_energy(ix.x + 1, ix.y + 0)
	var e01 := Globals.pes_data.get_energy(ix.x + 0, ix.y + 1)
	var e11 := Globals.pes_data.get_energy(ix.x + 1, ix.y + 1)
	
	return Globals.bilerpf(Vector4(e00, e01, e10, e11), weights)


static func indices_to_config(ix: Vector2i, weights: Vector2) -> MoleculeConfiguration:
	if (ix.x < 0 or ix.x >= Globals.pes_data.size_x
			or ix.y < 0 or ix.y >= Globals.pes_data.size_y):
		return MoleculeConfiguration.INVALID
	
	var mc00 := Globals.pes_data.get_configuration(ix.x, ix.y)
	# FIXME: quick hack to avoid crash on border
	if (ix.x == Globals.pes_data.size_x - 1
			or ix.y == Globals.pes_data.size_y - 1):
		return mc00
	
	var mc10 := Globals.pes_data.get_configuration(ix.x + 1, ix.y + 0)
	var mc01 := Globals.pes_data.get_configuration(ix.x + 0, ix.y + 1)
	var mc11 := Globals.pes_data.get_configuration(ix.x + 1, ix.y + 1)
	
	var mc = mc00
	mc.energy = Globals.bilerpf(
		Vector4(mc00.energy, mc01.energy, mc10.energy, mc11.energy),
		weights
	)
	
	for ipos in len(mc.positions):
		for ixyz in range(3):
			mc.positions[ipos].position[ixyz] = Globals.bilerpf(
				Vector4(
					mc00.positions[ipos].position[ixyz],
					mc01.positions[ipos].position[ixyz],
					mc10.positions[ipos].position[ixyz],
					mc11.positions[ipos].position[ixyz],
				),
				weights)
	
	return mc


func _scale_map() -> void:
	%CollisionShape3D.scale = Globals.global_scale_3d
	%ShaderPlane.scale = Globals.global_scale_3d
	%ArrowFrame.scale = Vector3.ONE * Globals.global_scale_3d.length()
	
	var size_x := Globals.pes_data.size_x
	var size_y := Globals.pes_data.size_y
	var offset_xneg := -size_x * Globals.global_scale_3d.x * 0.5
	var offset_xpos := (size_x - 2) * Globals.global_scale_3d.x * 0.5
	var offset_yneg := -size_y * Globals.global_scale_3d.z * 0.5
	var offset_ypos := (size_y - 2) * Globals.global_scale_3d.z * 0.5
	%WallBottom.position.x = offset_xneg
	%WallTop.position.x = offset_xpos
	%WallLeft.position.z = offset_yneg
	%WallRight.position.z = offset_ypos
	
	_set_frame_position()
	_update_terrain_shader()


func _set_player_pos() -> void:
	var init_pos := Globals.pes_init_pos
	var pos := grid_coords_to_pos(init_pos.pes_pos)
	if init_pos.flying:
		pos.y = init_pos.altitude
	else:
		pos.y += SPAWN_OVERHEIGHT
	
	%FPSPlayer.free_flying = not init_pos.flying
	%FPSPlayer.toggle_free_fly()
	%FPSPlayer.position = pos
	%FPSPlayer.yaw = init_pos.camera_yaw
	%FPSPlayer.pitch = init_pos.camera_pitch
	
	print("> Player position set to ", %FPSPlayer.position)


func _set_frame_position() -> void:
	const MARGIN_FACTOR = 1.9
	const FIXED_MARGIN = -2.0
	var map_scale := Globals.global_scale_3d
	var arrow_frame := %ArrowFrame as ArrowFrame
	var grid_size := (
		sqrt(Globals.pes_data.size_x * Globals.pes_data.size_y)
		* sqrt(map_scale.x * map_scale.z)
	)
	arrow_frame.position.x = (
		FIXED_MARGIN - Globals.pes_data.size_x / MARGIN_FACTOR * map_scale.x
	)
	arrow_frame.position.z = (
		FIXED_MARGIN - Globals.pes_data.size_y / MARGIN_FACTOR * map_scale.z
	)
	arrow_frame.scale = grid_size * Vector3.ONE / 10
	arrow_frame.x_label = Globals.settings[&"x_name"]
	arrow_frame.y_label = Globals.settings[&"y_name"]


func _update_profile() -> void:
	var num_points = Globals.settings[&"num_sample_points"]
	
	for i in range(min(num_points, len(_profile_values))):
		var val_i := _profile_values[i]
		_profile_nodes[i].position = val_i
		_profile_nodes[i].visible = true
		if val_i == _profile_values[i - 1]:
			continue


func _toggle_chart(force_on: bool = false) -> void:
	print("> toggle chart")
	var was_visible: bool = %ProfilingTrace.visible
	if force_on:
		was_visible = false
	
	%PointerSphere.visible = !was_visible
	%ProfilingTrace.visible = !was_visible
	%ChartContainer.visible = !was_visible
	
	if was_visible:
		_activate_chart(true) # true means force off


func _activate_chart(force_off: bool = false) -> void:
	print("> activate chart")
	if force_off:
		_is_drawing_profile = false
	else:
		_is_drawing_profile = !_is_drawing_profile
	
	if _is_drawing_profile:
		_toggle_chart(true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	_clicking = false
	%ChartIcon.visible = _is_drawing_profile


func _go_to_menu() -> void:
	print("> go to to menu")
	
	var fps_player: FPSPlayer = %FPSPlayer
	var player_pos := fps_player.position
	var last_pos := pos_to_grid_coords(player_pos)
	last_pos = clamp(last_pos, Vector2.ZERO,
			Vector2(Globals.pes_data.size_x - 1, Globals.pes_data.size_y - 1))
	Globals.pes_init_pos.pes_pos = last_pos
	Globals.pes_init_pos.flying = fps_player.free_flying
	Globals.pes_init_pos.altitude = fps_player.altitude
	Globals.pes_init_pos.camera_yaw = fps_player.yaw
	Globals.pes_init_pos.camera_pitch = fps_player.pitch
	print("> last known pos: ", last_pos)
	
	_mouse_captured = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
	#get_tree().change_scene_to_packed(MAIN_MENU_SCENE)


func _scale_up_or_down(increment: float) -> void:
	Globals.settings[&"global_scale"] = (
		maxf(Globals.settings[&"global_scale"] + increment, 0.01)
	)
	_scale_map()


func _clear_profile() -> void:
	print("> clear profile")
	_profile_values.clear()
	%ChartContainer.clear()
	for sphere in _profile_nodes:
		sphere.position = Vector3.ZERO
		sphere.visible = false


func _show_profile(path: Array) -> void:
	_clear_profile()
	for p in path:
		var pes_pos := grid_coords_to_pos(p)
		_profile_values.push_back(pes_pos)
		pes_pos.y /= Globals.map_scale.y
		%ChartContainer.energy_profile.push_back(pes_pos.y)
		if len(_profile_values) > Globals.settings[&"num_sample_points"]:
			_profile_values.pop_front()
	
	_update_profile()
	_toggle_chart(true)
	await get_tree().create_timer(0.1).timeout
	%ChartContainer.update_plot()


func _save_profile(path: String) -> void:
	print("> save profile")
	
	if _profile_values.is_empty():
		notify_bubble("Nothing to save")
		return
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(_trajectory_to_string())
	notify_bubble("File saved to " + ProjectSettings.globalize_path(path))

	_mouse_captured = _mouse_was_captured


func _trajectory_to_string() -> String:
	var traj := TrajectoryData.new()
	for prof_v in _profile_values:
		var v := pos_to_grid_coords(prof_v)
		traj.add_point(v)
	
	return str(traj)


func _load_profile(path: String) -> void:
	print("> load profile")
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		notify_bubble("No energy profile found")
		return
		
	_trajectory = TrajectoryData.from_string(file.get_as_text())
	if not _trajectory:
		notify_bubble("Error while parsing file")
		return
	
	_trajectory.name = path.get_file().get_basename()
	
	_profile_values.clear()
	%ChartContainer.energy_profile.clear()
	var grid_positions := Globals.resample(
		_trajectory.grid_pos_list,
		Globals.settings[&"num_sample_points"]
	)
	
	for grid_pos in grid_positions:
		var pos := grid_coords_to_pos(grid_pos)
		_profile_values.push_front(pos)
		%ChartContainer.energy_profile.push_front(pos.y / Globals.global_scale_3d.y)
	
	_update_profile()
	_mouse_captured = _mouse_was_captured
	notify_bubble("Trajectory loaded from " + ProjectSettings.globalize_path(path))
	_toggle_chart(true)


func notify_bubble(message: String) -> void:
	%NotificationBubble.display_message(message)


func _setup_actions_menu() -> void:
	var am := %ActionMenuButton
	for i in range(len(ACTIONS)):
		if ACTIONS[i][0] == ACTION_SEPARATOR:
			am.get_popup().add_separator()
		else:
			if len(ACTIONS[i]) > 2 and ACTIONS[i][2]:
				am.get_popup().add_check_item(ACTIONS[i][0], i)
			else:
				am.get_popup().add_item(ACTIONS[i][0], i)
	
	am.get_popup().id_pressed.connect(_action_pressed)


func _update_actions_check_states() -> void:
	var pop: PopupMenu = %ActionMenuButton.get_popup()
	pop.set_item_checked(Visibility.PROFILE, %ChartContainer.visible)
	pop.set_item_checked(Visibility.DRAWING, _is_drawing_profile)
	pop.set_item_checked(Visibility.ANCHORS, %Anchors.visible)
	pop.set_item_checked(Visibility.MEP, %MinimumEnergyPath.visible)
	pop.set_item_checked(Visibility.SD, %SteepestDescent.visible)
	pop.set_item_checked(Visibility.TRAJECTORY, _playback_enabled)
	pop.set_item_checked(Visibility.FLY_MODE, %FPSPlayer.free_flying)


func _action_pressed(id: int) -> void:
	print("> touch menu pressed ", ACTIONS[id])
	UISounds.play_ui_sound()
	ACTIONS[id][1].call()
	if get_viewport():
		get_viewport().set_input_as_handled()
	_clicking = false
	_update_actions_check_states()


func _toggle_free_fly() -> void:
	print("> toggle fly mode")
	%FPSPlayer.toggle_free_fly()


func _free_fly_changed(flying: bool) -> void:
	%WalkIcon.visible = not flying
	%FlyIcon.visible = flying


func _toggle_anchors() -> void:
	print("> toggle anchors visibility")
	%Anchors.visible = not %Anchors.visible


func _toggle_mep(force_on: bool = false) -> void:
	print("> toggle MEP visibility")
	if force_on:
		%MinimumEnergyPath.visible = true
	else:
		%MinimumEnergyPath.visible = not %MinimumEnergyPath.visible
	
	if not %MinimumEnergyPath.visible:
		_mouse_captured = false
	
	%MepIcon.visible = %MinimumEnergyPath.visible


func _start_mep() -> void:
	print("> start MEP")
	_toggle_mep(true)
	_is_mep = %MinimumEnergyPath.visible
	_mouse_captured = not _is_mep


func _mep_to_profile() -> void:
	var mep: MinimumEnergyPath = %MinimumEnergyPath
	var path := mep.get_resample_mep()
	_show_profile(path)
	_is_drawing_profile = false
	_clicking = false
	mep.visible = false


func _toggle_sd(force_on: bool = false) -> void:
	print("> toggle sd visibility")
	
	var sd_visible = %SteepestDescent.visible
	%SteepestDescent.visible = force_on or not sd_visible


func _steepest_descent() -> void:
	print("> steepest descent")
	_toggle_sd(true)
	_is_sd = true
	%SDArrow.visible = true
	_mouse_captured = false


func _confirm_sd() -> void:
	%SDArrow.visible = false
	var aimed_object = get_pes_pos_from_laser_or_player(true)
	if aimed_object:
		%SteepestDescent.compute_and_draw(
			pos_to_grid_coords(aimed_object.position)
		)
		_is_sd = false


func _handle_sd(_delta: float) -> void:
	if not _is_sd:
		return
	
	var aimed_object = get_pes_pos_from_laser_or_player(true)
	if aimed_object:
		%SDArrow.position = aimed_object.position
		%SteepestDescent.compute_and_draw(
			pos_to_grid_coords(aimed_object.position)
		)
	
	if _clicking:
		_confirm_sd()


func _sd_to_profile() -> void:
	var sd: SteepestDescent = %SteepestDescent
	var path := sd.get_resample_sd_path()
	_show_profile(path)
	_is_drawing_profile = false
	_clicking = false
	sd.visible = false


func _toggle_trajectory() -> void:
	%TrajectoryPath.follower.loop = Globals.settings[&"playback_loop"]
	var curve := %TrajectoryPath.curve as Curve3D
	curve.clear_points()
	
	for prof_val in _profile_values:
		curve.add_point(prof_val)
		
	if %TrajectoryPath.is_empty():
		notify_bubble("No profile to follow.")
		print("> trajectory playback cancelled; nothing to play back")
		return
	
	_playback_paused = false
	_playback_enabled = not _playback_enabled
	%TrajectoryPath.visible = _playback_enabled
	%SliderContainer.visible = _playback_enabled
	%TrajectoryPath.follower.progress_ratio = 0.0
	%PlaySlider.value = 0.0
	
	print("> toggled trajectory playback to ", _playback_enabled)


func _play_trajectory() -> void:
	_playback_enabled = false
	_toggle_trajectory()


func _pause_trajectory() -> void:
	_playback_paused = true


func _handle_trajectory_playback(delta: float) -> void:
	if not _playback_enabled or _profile_values.is_empty():
		return
	
	var follower := %TrajectoryPath.follower as PathFollow3D
	
	if _playback_paused:
		follower.progress_ratio = %PlaySlider.value
	else:
		follower.progress_ratio += delta / Globals.settings[&"playback_time"]
		%PlaySlider.value = follower.progress_ratio
	
	%TrajectoryPath.visible = %FPSPlayer.free_flying
	if not %FPSPlayer.free_flying:
		%FPSPlayer.position = %TrajectoryPath.follower.position
	
	if _trajectory:
		_override_configuration(follower.progress_ratio)


## Replace the configuration from the position/laser by the one from the
## trajectory file.
func _override_configuration(progress_ratio: float) -> void:
	%MolecularViewport.mode = MolecularViewport.Mode.TRAJECTORY
	%MolecularViewport.trajectory_name = _trajectory.name
	%MolecularViewport.mc = _compute_mc_from_trajectory(progress_ratio)


func _compute_mc_from_trajectory(progress_ratio: float) -> MoleculeConfiguration:
	var n_points := len(_trajectory.configurations)
	var param := progress_ratio * (n_points - 1)
	var ix := floori(param)
	var weight := param - ix
	if ix == n_points - 1:
		ix = n_points - 2
		weight = 1.0
	
	var mc0 := _trajectory.configurations[ix]
	var mc1 := _trajectory.configurations[ix + 1]
	mc0.energy = lerpf(mc0.energy, mc1.energy, weight)
	for i in len(mc0.positions):
		mc0.positions[i].position = lerp(
			mc0.positions[i].position, mc1.positions[i].position, weight
		)
	return mc0


func _update_terrain_shader() -> void:
	%CollisionShape3D.update_shader_parameters()


func _on_traj_upload_started() -> void:
	print("> Trajectory upload started")


func _on_traj_upload_finished(file_name: String, _type: String,
						 	  base64_data: String) -> void:
	print("> Trajectory upload finished: ", file_name)
	notify_bubble("Upload finished: %s" % file_name)
	var contents := Marshalls.base64_to_raw(base64_data)
	
	var local_file := FileAccess.open(UPLOADED_TRAJECTORY_PATH, FileAccess.WRITE)
	local_file.store_buffer(contents)
	local_file = null
	_load_profile(UPLOADED_TRAJECTORY_PATH)


func _on_traj_upload_progressed(current_bytes: int, total_bytes: int) -> void:
	notify_bubble("Uploading... %d / %d" % [current_bytes, total_bytes])


func _on_traj_upload_errored() -> void:
	print("> Trajectory upload failed")
	notify_bubble("Upload failed; try again?")
