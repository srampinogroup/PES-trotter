extends Node

## Emitted when parsing has progressed, around one time per line parsed.
signal pes_parse_progressed(progress: float, total: float)
signal config_loaded()
signal config_saved()
signal settings_changed(key: StringName, value)

var VERSION: String = ProjectSettings.get("application/config/version")
var IS_WEB: bool = OS.has_feature("web") \
				or OS.has_feature("web_android") \
				or OS.has_feature("web_ios")
var IS_TOUCH: bool = OS.has_feature("mobile") \
				  or OS.has_feature("web_android") \
				  or OS.has_feature("web_ios")

const ATOM_RADIUS_PATH = "res://assets/molecular_data/covalent_radius.tsv"
const ATOM_COLOR_PATH = "res://assets/molecular_data/jmol.tsv"
var ATOM_RADIUS: Dictionary[StringName, float]
var ATOM_COLOR: Dictionary[StringName, Color]

enum CriticalType {
	NONE = 0,
	MINIMUM = -1,
	MAXIMUM = 1,
	SADDLE = 2,
	MONKEY = 3,
	QUADRO = 4,
}

const CRIT_COLORS = {
	CriticalType.MINIMUM: Color.DARK_BLUE,
	CriticalType.MAXIMUM: Color.DARK_RED,
	CriticalType.SADDLE: Color.ORANGE,
	CriticalType.MONKEY: Color.DARK_GREEN,
	CriticalType.QUADRO: Color.DARK_MAGENTA,
}

const PES_EXT = "pes"
const SETTINGS_EXT = "ini"
const CONF_PATH = "user://settings.ini"

var settings := {
	&"last_demo": 0,
	&"show_beta": true,
	# PES settings
	&"x_name": "x",
	&"x_min": 0.0,
	&"x_max": 1.0,
	&"y_name": "y",
	&"y_min": 0.0,
	&"y_max": 1.0,
	&"energy_units": "Ha",
	&"energy_min": -INF,
	&"energy_max": INF,
	&"position_unit_factor": 1.0,
	&"global_scale": 1.0,
	&"map_scale_x": 1.0, # this is Z
	&"map_scale_y": 5.0, # this is height
	&"map_scale_z": 1.0, # this is X
	&"display_iso": false,
	&"iso_scale": 1.0,
	&"wtoe_exp": "(E + 1)**2",
	&"epsilon": "1e-5",
	&"show_crits": true,
	&"x_tiles_number": 1,
	&"y_tiles_number": 1,
	# App settings
	&"fly_on_start": false,
	&"always_sprint": false,
	&"touch_force_enabled": false,
	&"swap_joysticks": false,
	&"mouse_look_sensitivity": 1.0,
	&"rotate_hue": false,
	&"swap_hue": false,
	&"ui_scale": 1.0,
	&"playback_time": 5.0,
	&"playback_loop": false,
	&"playback_toandfro": false,
	&"num_sample_points": 100,
	&"ui_sounds_on": true,
	&"show_colorbars": false,
	&"show_bounds": false,
}

var PERSISTED_KEYS = settings.keys()

const TERRAIN_GRADIENT = preload("res://assets/terrain/terrain_gradient.tres")
const OCEAN_GRADIENT = preload("res://assets/terrain/ocean_gradient.tres")

var pes_path: String = ""
var pes_data: PESData = null
var pes_init_pos: InitialPositionInfos = null
var pes_criticals := []

var positive_colors: Array[Vector3]:
	get:
		return _sample_from_gradient(TERRAIN_GRADIENT)

var negative_colors: Array[Vector3]:
	get:
		return _sample_from_gradient(OCEAN_GRADIENT)

var map_scale: Vector3:
	get:
		return Vector3(settings[&"map_scale_x"],
					   settings[&"map_scale_y"],
					   settings[&"map_scale_z"])

var global_scale_3d: Vector3:
	get:
		return map_scale * settings[&"global_scale"]

## Flag to be able to reach menu once run from URL parameters
var autoload_url := true

var _theme: Theme = preload("res://assets/theme.tres")


func _ready() -> void:
	_load_atoms_features()
	load_config()


func _read_simple_tsv(path: String) -> Array[PackedStringArray]:
	var lines: Array[PackedStringArray] = []
	var file := FileAccess.open(path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if line.begins_with("#") or line.is_empty():
			continue
		
		lines.append(line.split(" ", false))
	
	return lines


## Read from TSV files the covalent radius and color for each atoms.
## Populate ATOM_RADIUS and ATOM_COLOR.
func _load_atoms_features() -> void:
	var radii := _read_simple_tsv(ATOM_RADIUS_PATH)
	for radius in radii:
		ATOM_RADIUS[radius[1]] = float(radius[2])
	
	var colors := _read_simple_tsv(ATOM_COLOR_PATH)
	for color in colors:
		ATOM_COLOR[color[1]] = Color.html(color[2])


func _sample_from_gradient(gradient: Gradient, n: int = 100) -> Array[Vector3]:
	var colors: Array[Vector3] = []
	for i in range(n):
		var color := gradient.sample(float(i) / n)
		colors.append(Vector3(color.r, color.g, color.b))
	
	return colors


func set_parse_progress(progress: float, total: float) -> void:
	pes_parse_progressed.emit(progress, total)


func load_config(path: String = CONF_PATH) -> void:
	print("> loading config file " + path)
	var cf := ConfigFile.new()
	var err := cf.load(path)
	if err != OK:
		printerr("Cannot read config, error ", error_string(err))
	
	for key in PERSISTED_KEYS:
		settings[key] = cf.get_value("main", key, settings[key])
	
	config_loaded.emit()


func save_config(path: String = CONF_PATH) -> void:
	var cf := ConfigFile.new()
	
	for key in PERSISTED_KEYS:
		cf.set_value("main", key, settings[key])
	
	cf.save(path)
	print("> saved config to ", path)
	config_saved.emit()


## Ensure memory is cleared before loading new data.
func clear_PESData() -> void:
	pes_data = null

## Bilinear version of godot lerpf.
##          x →
## p01 +-----------+ p11
##     |   |       |
##     |---p-------| y ↑
##     |   |       |
## p00 +-----------+ p10
## The square param Vector4 is in this order, value at: p00, p01, p10, p11.
## Return the bilinearly interpolated value at point p. Weights are in order
## weight for x axis then y axis. They can be viewed as the coordinates of p
## inside the square ([0, 0] is p00, [1, 0] is p10...).
## Erwan Privat 2025, public domain
func bilerpf(square: Vector4, weights: Vector2) -> float:
	# values for when y is varying
	var vx0 := lerpf(square[0], square[1], weights[1])
	var vx1 := lerpf(square[2], square[3], weights[1])
	
	# lerp for when x is varying
	return lerpf(vx0, vx1, weights[0])


func quit_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()


## Resamples array input to fit in new_size sized array.
func resample(input: Array, new_size: int) -> Array:
	var output := []
	
	if input.is_empty():
		return output
	
	output.resize(new_size)
	
	var old_size := len(input)
	if old_size == 1 or new_size == 1:
		output.fill(input[0])
		return output
	
	output[0] = input[0]
	output[-1] = input[-1]
	
	for i in range(1, new_size - 1):
		var new_index := float(i * (old_size - 1)) / (new_size - 1)
		var ix := int(floor(new_index))
		var weight := new_index - ix
		output[i] = lerp(input[ix], input[ix + 1], weight)
	
	return output


func update_ui_scale(value) -> void:
	const DEFAULT_FONT_SIZE = 16
	const DEFAULT_HEADER_SIZE = 20
	_theme.default_base_scale = value
	_theme.default_font_size = int(DEFAULT_FONT_SIZE * value)
	_theme.set_font_size(&"font_size", &"HeaderMedium", int(DEFAULT_HEADER_SIZE * value))


## Parses GET parameters of the search fragment of a URL
## (everything after and including "?")
func parse_url_params(search_fragment: String) -> Dictionary[String, String]:
	if search_fragment.is_empty():
		return {}
	
	# Remove potential question mark at start
	if search_fragment[0] == "?":
		search_fragment = search_fragment.substr(1)
	
	# Remove potential tag
	var hash_pos := search_fragment.find("#")
	if hash_pos >= 0:
		search_fragment = search_fragment.substr(0, hash_pos)
	
	var params: Dictionary[String, String] = {}
	var splits := search_fragment.split("&", false)
	for pair in splits:
		var unpaired := pair.split("=", true, 1)
		params.set(unpaired[0], unpaired[1])
	
	return params


## Populate controls with value in settings. The `fields_map` parameter is a
## list of size 2 arrays containing the Control and the setting name.
func setup_already_there_values(fields_map: Array) -> void:
	for field_tuple in fields_map:
		var field: Control = field_tuple[0]
		var key: StringName = field_tuple[1]
		
		if field is LineEdit:
			(field as LineEdit).text = settings[key]
		elif field is SpinBox:
			(field as SpinBox).set_value_no_signal(settings[key])
		elif field is Button:
			(field as Button).set_pressed_no_signal(settings[key])
		else:
			assert(false, "Unrecognized field type: %s" % field.get_class())


## Connect controls changed to update the settings.
func connect_fields_changes(fields_map: Array) -> void:
	for field_tuple in fields_map:
		var field = field_tuple[0]
		var key: StringName = field_tuple[1]
		if field is LineEdit:
			(field as LineEdit).text_changed.connect(
				func(value: String) -> void:
					settings[key] = value
					save_config()
					settings_changed.emit(key, value)
			)
		elif field is SpinBox:
			(field as SpinBox).value_changed.connect(
				func(value: float) -> void:
					settings[key] = value
					save_config()
					settings_changed.emit(key, value)
			)
		elif field is CheckButton:
			(field as CheckButton).pressed.connect(
				func() -> void:
					var value = field.button_pressed
					settings[key] = value
					save_config()
					settings_changed.emit(key, value)
			)
		else:
			assert(false, "not supposed to have this control in the grid")
