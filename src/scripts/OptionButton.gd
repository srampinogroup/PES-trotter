## Read from the demo directories, and populate the option list with PES files.
class_name DemoOptionButton extends OptionButton

const DEMO_DIR = "res://demo_pes/"
const TEST_DIR = "res://test_pes/"
const PES_EXT = ".pes"


var _len_demos: int


func _ready() -> void:
	_add_from_dir(DEMO_DIR)
	_len_demos = item_count
	
	if DirAccess.dir_exists_absolute(TEST_DIR):
		_add_from_dir(TEST_DIR)
	
	selected = Globals.settings[&"last_demo"]
	item_selected.connect(_update_config)


func _add_from_dir(path: String) -> void:
	for demo_file in DirAccess.get_files_at(path):
		if demo_file.ends_with(PES_EXT):
			add_item(demo_file)


func _update_config(selected_ix: int) -> void:
	Globals.settings[&"last_demo"] = selected_ix
	Globals.save_config()
	print("> last demo updated to ", selected_ix)


func get_selected_path() -> String:
	var dir := DEMO_DIR if selected < _len_demos else TEST_DIR
	return dir + get_item_text(selected)
