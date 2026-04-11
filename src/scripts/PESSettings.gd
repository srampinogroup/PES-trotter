class_name PESSettings
extends VBoxContainer

const DEFAULT_WTOE = "(E + 1)**2"
const WEB_SETTINGS_NAME = "user://settings." + Globals.SETTINGS_EXT

var _expression := Expression.new()
var _file_access_web: FileAccessWeb = null

@onready var FIELD_SETTING_MAP := [
	[%FieldXName, &"y_name"],
	[%FieldXMin, &"y_min"],
	[%FieldXMax, &"y_max"],
	[%FieldYName, &"x_name"],
	[%FieldYMin, &"x_min"],
	[%FieldYMax, &"x_max"],
	[%EnergyUnitsBox, &"energy_units"],
	[%MinEnergyBox, &"energy_min"],
	[%MaxEnergyBox, &"energy_max"],
	[%PositionUnitBox, &"position_unit_factor"],
	[%GlobalScaleBox, &"global_scale"],
	[%FieldScaleX, &"map_scale_x"],
	[%FieldScaleY, &"map_scale_y"],
	[%FieldScaleZ, &"map_scale_z"],
	[%IsoCheck, &"display_iso"],
	[%IsoBox, &"iso_scale"],
	[%EtoWBox, &"wtoe_exp"],
	[%EpsilonBox, &"epsilon"],
	[%ShowCritsChk, &"show_crits"],
	[%XTilesBox, &"x_tiles_number"],
	[%YTilesBox, &"y_tiles_number"],
]


func _ready() -> void:
	Globals.connect_fields_changes(FIELD_SETTING_MAP)
	%ComputeCriticalButton.pressed.connect(%Minimap.compute_critical_points)
	Globals.settings_changed.connect(_on_settings_changed)
	visibility_changed.connect(setup_already_there_values)
	
	%EtoWBox.text_changed.connect(_etow_changed)
	%EpsilonBox.text_changed.connect(_epsilon_changed)
	%ShowCritsChk.pressed.connect(_toggle_crits_visibility)
	%EnergyUnitsBox.text_changed.connect(_energy_units_changed)
	%IsoCheck.pressed.connect(_iso_check_changed)
	%EtoWResetButton.pressed.connect(_reset_wtoe)
	%Minimap.update_minimap_pos()
	
	%ImportBtn.pressed.connect(_on_import)
	%ExportBtn.pressed.connect(_on_export)
	var filters := ["*." + Globals.SETTINGS_EXT]
	%ImportFileDialog.set_filters(filters)
	%ExportFileDialog.set_filters(filters)
	%ImportFileDialog.file_selected.connect(Globals.load_config)
	%ExportFileDialog.file_selected.connect(_on_export_selected)
	Globals.config_loaded.connect(setup_already_there_values)
	
	if Globals.IS_WEB:
		_file_access_web = FileAccessWeb.new()
		_file_access_web.loaded.connect(_on_upload_finished)
		_file_access_web.error.connect(_on_upload_errored)


func setup_already_there_values() -> void:
	if not visible:
		return
	
	Globals.setup_already_there_values(FIELD_SETTING_MAP)
	_energy_units_changed(Globals.settings[&"energy_units"])
	_iso_check_changed()
	Globals.update_ui_scale(Globals.settings[&"ui_scale"])
	%Minimap.update_texture_from_pes()
	%Minimap.update_minimap_pos()


func setup_minimap() -> void:
	%Minimap.update_texture_from_pes()
	%Minimap.compute_critical_points()
	%Minimap.update_labels()
	%Minimap.update_aspect_ratio()
	%Minimap.update_minimap_pos()


func _etow_changed(wstr: String) -> void:
	const EXAMPLE_ENERGY = 0.8
	const ENERGY_VAR_NAME = "E"
	
	print("> E to weight changed to ", wstr)
	if wstr == "":
		wstr = DEFAULT_WTOE
	
	var example_str = wstr.replace(ENERGY_VAR_NAME, str(EXAMPLE_ENERGY))
	var err := _expression.parse(example_str)
	if err != OK:
		%EtoWResult.text = _expression.get_error_text()
		return
	
	var parsed := str(_expression.execute())
	%EtoWResult.text = parsed
	Globals.settings[&"wtoe_exp"] = wstr


func _epsilon_changed(eps: String) -> void:
	print("> epsilon changed")
	if eps == "":
		eps = "1e-5"
	
	var err = _expression.parse(eps)
	if err != OK:
		%EpsilonLabel.text = _expression.get_error_text()
		return
	
	var parsed = _expression.execute()
	if parsed == null:
		return
	
	%EpsilonLabel.text = str(parsed as float)
	Globals.settings[&"epsilon"] = eps
	Globals.settings_changed.emit(&"epsilon", eps)


func _toggle_crits_visibility() -> void:
	print("> toggle critical points visibility")
	%Minimap.update_crits_visibility()


func _on_settings_changed(_key: StringName, _value) -> void:
	%Minimap.update_labels()
	%Minimap.update_aspect_ratio()


func _energy_units_changed(units: String) -> void:
	%IsoBox.suffix = units
	%Minimap.update_texture_from_pes()


func _iso_check_changed() -> void:
	%IsoBox.editable = %IsoCheck.button_pressed


func _reset_wtoe() -> void:
	%EtoWBox.text = DEFAULT_WTOE
	_etow_changed(%EtoWBox.text)
	Globals.save_config()


func _on_import() -> void:
	print("> import settings")
	%LogLabel.text = ""
	if Globals.IS_WEB:
		_file_access_web.open("*." + Globals.SETTINGS_EXT)
	else:
		%ImportFileDialog.show()


func _on_export() -> void:
	print("> export settings")
	var basename := Globals.pes_path.get_basename() if Globals.pes_path else ""
	if Globals.IS_WEB:
		_on_export_selected(WEB_SETTINGS_NAME)
		var buffer := FileAccess.get_file_as_bytes(WEB_SETTINGS_NAME)
		JavaScriptBridge.download_buffer(buffer, basename + "." + Globals.SETTINGS_EXT)
	else:
		%ExportFileDialog.current_file = basename
		%ExportFileDialog.show()


func _on_export_selected(path: String) -> void:
	var cf := ConfigFile.new()
	
	for keyval in FIELD_SETTING_MAP:
		var key: StringName = keyval[1]
		cf.set_value("main", key, Globals.settings[key])
	
	cf.save(path)


func _on_upload_finished(
		file_name: String,
		type: String,
		base64_data: String
	) -> void:
	print("> Uploading of " + file_name + " finished")
	var contents := Marshalls.base64_to_raw(base64_data)
	print("File %s of type %s received (%s bytes)" %
		  [file_name, type, len(contents)])
	
	var local_file := FileAccess.open(WEB_SETTINGS_NAME, FileAccess.WRITE)
	local_file.store_buffer(contents)
	local_file = null
	
	Globals.load_config(WEB_SETTINGS_NAME)


func _on_upload_errored() -> void:
	var msg := "ERROR: Something went wrong during upload. Try again?"
	print(msg)
	%LogLabel.text = msg
