extends PanelContainer

const MAP_SCENE_PATH = "res://scenes/Map.tscn"
const MAP_SCENE = preload(MAP_SCENE_PATH)
const DEMO_PARAM_NAME = "demo_name"
const UPLOADED_FILE_NAME = "user://uploaded." + Globals.PES_EXT
const CLIPBOARD_FILE_NAME = "user://clipboard." + Globals.PES_EXT
const RAW_FILE_NAME = "user://raw." + Globals.PES_EXT

var _pes_data: PESData = null
var _thread := Thread.new()
var _file_access_web: FileAccessWeb = null
var _url_timer: Timer


func eplog(s: String) -> void:
	var append_text = func():
		%TextEdit.text += s + "\n"
		%TextEdit.set_v_scroll(len(%TextEdit.text))
	append_text.call_deferred()
	print(s)


func _ready() -> void:
	_connect_buttons()
	
	if Globals.pes_data == null:
		%RunButton.disabled = true
		%OpenPESButton.text = "Open file... (*.%s)" % Globals.PES_EXT
	else:
		%OpenPESButton.text = "Change file... (current %s)" % \
			ProjectSettings.globalize_path(Globals.pes_path)
		%RunButton.text = "Resume"
	
	_update_visibility_from_os()
	eplog("> Ready with version " + Globals.VERSION)
	
	_process_url_params()


func _connect_buttons() -> void:
	%OpenPESButton.pressed.connect(_on_open_pes)
	%ClipboardButton.pressed.connect(_on_clipboard_pressed)
	%QuitButton.pressed.connect(_on_quit)
	%RunButton.pressed.connect(_on_run)
	Globals.pes_parse_progressed.connect(_on_pes_progressed)
	
	# Raw input popup
	%RawInputButton.pressed.connect(_on_raw_input_pressed)
	%PopupCancelButton.pressed.connect(_on_popup_cancel)
	%PopupLoadButton.pressed.connect(_on_popup_load)
	
	# Upload on web
	if Globals.IS_WEB:
		%UploadButton.pressed.connect(_on_upload_pressed)
		_file_access_web = FileAccessWeb.new()
		_file_access_web.load_started.connect(_on_upload_started)
		_file_access_web.loaded.connect(_on_upload_finished)
		_file_access_web.progress.connect(_on_upload_progressed)
		_file_access_web.error.connect(_on_upload_errored)
	
	# Demo button
	%DemoButton.pressed.connect(_on_demo_pressed)
	
	# URL loading
	%LoadURLButton.pressed.connect(_on_url_open)
	%HTTPRequest.request_completed.connect(_fetch_from_url_complete)
	_url_timer = Timer.new()
	_url_timer.wait_time = 0.5 # s
	_url_timer.timeout.connect(_url_load_progress)
	add_child(_url_timer)
	
	var fd = %FileDialog
	fd.set_filters(["*." + Globals.PES_EXT])
	fd.file_selected.connect(_on_file_selected)
	
	UISounds.connect_sounds(self)


func _on_quit() -> void:
	Globals.quit_game()


func _exit_tree() -> void:
	if _thread.is_started():
		_thread.wait_to_finish()


func _on_open_pes() -> void:
	eplog("> Open clicked")
	%FileDialog.popup_centered()
	
	
func _on_file_selected(path: String) -> void:
	%ProgressBar.indeterminate = false
	if _thread.is_started():
		_thread.wait_to_finish()
	
	eplog("> File " + path + " selected. Parsing...")
	%RunButton.text = "Run"
	_thread.start(_load_pes_async.bind(path))


func _on_pes_progressed(progress: float, total: float) -> void:
	%ProgressBar.indeterminate = false
	%ProgressBar.max_value = total
	%ProgressBar.value = progress


func _load_pes_async(path: String) -> void:
	eplog("> Parsing PES...")
	_set_progress_indeterminate.call_deferred()
	Globals.clear_PESData()
	_pes_data = null
	_pes_data = PESData.from_file(path, eplog)
	_on_pes_loaded.call_deferred(path)


func _on_pes_loaded(pes_path: String) -> void:
	eplog("PES parsed, grid is %d x %d:" % [_pes_data.size_x, _pes_data.size_y])
	Globals.pes_path = pes_path
	Globals.pes_data = _pes_data
	var energies := Array(_pes_data.energies)
	Globals.settings[&"energy_min"] = energies.min()
	Globals.settings[&"energy_max"] = energies.max()
	Globals.pes_init_pos = InitialPositionInfos.new()
	Globals.pes_init_pos.pes_pos = 0.5 * Vector2(_pes_data.size_x - 1,
												 _pes_data.size_y - 1)
	Globals.pes_criticals.clear()
	
	eplog("First configuration is:")
	eplog("\n".join(_pes_data.configurations[0]))
	
	# FIXME will fail if ".pes" contained in path
	var path_settings = pes_path.replacen(
		"." + Globals.PES_EXT,
		"." + Globals.SETTINGS_EXT,
	)
	if FileAccess.file_exists(path_settings):
		Globals.load_config(path_settings)
		#%"PES settings".setup_already_there_values()
		#%"App settings".setup_already_there_values()
		eplog("> loaded demo config from " + path_settings)
	
	%"PES settings".setup_minimap()
	
	%OpenPESButton.text = "Open new file... (current: %s)" % pes_path
	%RunButton.text = "Run"
	%RunButton.disabled = false
	%ProgressBar.indeterminate = false
	eplog("> all done.")


func _on_clipboard_pressed() -> void:
	eplog("> Clipboard pressed")
	var clipboard := DisplayServer.clipboard_get()
	eplog("%d bytes from clipboard received" % len(clipboard))
	var local_file := FileAccess.open(CLIPBOARD_FILE_NAME, FileAccess.WRITE)
	local_file.store_string(clipboard)
	_load_pes_async.call_deferred(CLIPBOARD_FILE_NAME)
	local_file = null


func _on_raw_input_pressed() -> void:
	eplog("> Raw input popup open")
	%PastePopupPanel.show()


func _on_popup_cancel() -> void:
	eplog("> Popup cancel")
	%PastePopupPanel.hide()
	
	
func _on_popup_load() -> void:
	eplog("> Popup load")
	
	var file_contents: String = %PopupTextEdit.text
	eplog("%d bytes from pasted contents" % len(file_contents))
	var local_file := FileAccess.open(RAW_FILE_NAME, FileAccess.WRITE)
	local_file.store_string(file_contents)
	%ProgressBar.indeterminate = false
	_load_pes_async.call_deferred(RAW_FILE_NAME)
	
	%PastePopupPanel.hide()
	
	
func _on_upload_pressed() -> void:
	eplog("> Upload button pressed")
	if OS.get_name() != "Web":
		eplog("*** Can only upload on Web version.")
		return
	
	_file_access_web.open()


func _on_upload_started(file_name: String) -> void:
	eplog("> Starting uploading " + file_name)
	%ProgressBar.indeterminate = false


func _on_upload_finished(
		file_name: String,
		type: String,
		base64_data: String,
	) -> void:
	eplog("> Uploading of " + file_name + " finished")
	var contents := Marshalls.base64_to_raw(base64_data)
	eplog("File %s of type %s received (%s bytes)" %
		  [file_name, type, len(contents)])
	
	_load_from_bytes(contents)


func _set_progress_indeterminate() -> void:
	if get_node_or_null("%ProgressBar"):
		%ProgressBar.indeterminate = true


func _on_upload_progressed(current_bytes: int, total_bytes: int) -> void:
	%ProgressBar.indeterminate = false
	%ProgressBar.max_value = total_bytes
	%ProgressBar.value = current_bytes


func _on_upload_errored() -> void:
	eplog("ERROR: Something went wrong during upload. Try again?")


func _on_run() -> void:
	eplog("> loading map...")
	%ProgressBar.indeterminate = true
	%RunButton.text = "Loading..."
	ResourceLoader.load_threaded_request(MAP_SCENE_PATH)


func _process(_delta: float) -> void:
	var progress = []
	var status := ResourceLoader.load_threaded_get_status(MAP_SCENE_PATH, progress)
	
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_IN_PROGRESS:
		%RunButton.text = "Loading..."
		_on_pes_progressed(progress[0] * 100, 100)
	
	if status == ResourceLoader.ThreadLoadStatus.THREAD_LOAD_LOADED:
		%RunButton.text = "Resume"
		var map_scene := ResourceLoader.load_threaded_get(MAP_SCENE_PATH)
		get_tree().change_scene_to_packed(map_scene)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed(&"quit"):
		Globals.quit_game()
	
	if Input.is_action_just_pressed(&"menu") and Globals.pes_data != null:
		_on_run()
 

func _on_demo_pressed() -> void:
	%ProgressBar.indeterminate = true
	if _thread.is_started():
		_thread.wait_to_finish()
	
	var path: String = %DemoOptionButton.get_selected_path()
	
	await get_tree().create_timer(0.1).timeout
	if Globals.IS_WEB:
		_load_pes_async.call_deferred(path)
	else:
		_thread.start(_load_pes_async.bind(path))

func _on_url_open() -> void:
	var url := %FieldURL.text as String
	eplog("> Open URL pressed with URL %s" % url)
	#FIXME check if this block main thread
	var error = %HTTPRequest.request(url)
	if error != OK:
		var err_str := "An error occurred in the HTTP request (%d: %s)." %\
					   [error, error_string(error)]
		eplog(err_str)
		push_error(err_str)
	
	_url_timer.start()


func _fetch_from_url_complete(_result, response_code, _headers, body) -> void:
	eplog("Fetched from %s:" % %FieldURL.text)
	
	_url_timer.stop()
	
	if response_code != HTTPClient.RESPONSE_OK:
		var err := "Unable to load file from provided URL. (error %d)" %\
					response_code
		eplog(err)
		push_error(err)
	
	_load_from_bytes(body)
	%RunButton.text = "Run"
	eplog("Loaded, you can press run")
	

func _load_from_bytes(bytes: PackedByteArray) -> void:
	var local_file := FileAccess.open(UPLOADED_FILE_NAME, FileAccess.WRITE)
	local_file.store_buffer(bytes)
	local_file = null
	_load_pes_async.call_deferred(UPLOADED_FILE_NAME)


func _url_load_progress() -> void:
	var bs = %HTTPRequest.get_body_size()
	if bs >= 0:
		%ProgressBar.indeterminate = false
		%ProgressBar.value = %HTTPRequest.get_downloaded_bytes()
		%ProgressBar.max_value = bs
	else:
		%ProgressBar.indeterminate = true


func _update_visibility_from_os() -> void:
	var is_web := Globals.IS_WEB
	%NativeOnly.visible = not is_web
	%WebOnly.visible = is_web
	%QuitButton.visible = not is_web


func _process_url_params() -> void:
	if not Globals.autoload_url:
		return
	
	if not Globals.IS_WEB:
		return
	
	var window := JavaScriptBridge.get_interface("window")
	var params := Globals.parse_url_params(window.location.search)
	eplog("> URL parameters are %s" % params)
	
	var demo_name: String = params.get(DEMO_PARAM_NAME, "")
	if not demo_name:
		return
	
	var dob: DemoOptionButton = %DemoOptionButton
	var selected_index := -1
	for i in dob.item_count:
		if dob.get_item_text(i) == demo_name:
			selected_index = i
			break
	
	if selected_index >= 0:
		dob.selected = selected_index
		_load_pes_async(dob.get_selected_path())
		_on_run()
	
	Globals.autoload_url = false
