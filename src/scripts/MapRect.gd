class_name MapRect
extends TextureRect

const CROSS_TEXTURE = preload("res://assets/icons/cross.png")
const CROSS_SIZE = 15 * Vector2.ONE # px
const MINIMAP_SMALL_SIDE_SIZE = 300 # px

var e_min: float
var e_max: float

var _criticals_crosses: Array[Control] = []
var _click := false


func _ready() -> void:
	if Globals.pes_data != null:
		size.x *= float(Globals.pes_data.size_x) / Globals.pes_data.size_y
	
	visibility_changed.connect(_visibility_changed)
	update_aspect_ratio()
	update_crits_visibility()


func _visibility_changed() -> void:
	if not is_visible_in_tree():
		return
	if Globals.pes_data == null:
		return
	
	update_texture_from_pes()
	update_minimap_pos()
	await get_tree().create_timer(0.01).timeout
	display_current_crits()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_click = event.pressed
	
	if _click and event is InputEventMouseMotion or event is InputEventMouseButton:
		var norm_pos := _pix_to_norm(event.position)
		_set_init_pos_from_norm(norm_pos)
		get_viewport().set_input_as_handled()


func _set_init_pos_from_norm(norm_pos: Vector2) -> void:
	var inmap_pix := Vector2(_norm_to_pix(norm_pos))
	%PosMarker.position = inmap_pix - %PosMarker.size / 2
	var pes_pos := _norm_to_pes(norm_pos)
	%CoordsLabel.text = str(pes_pos)
	
	Globals.pes_init_pos.pes_pos = Vector2(pes_pos.x, pes_pos.y)


## Technically the same code as the shader. Might reuse it.
func update_texture_from_pes() -> void:
	var pes := Globals.pes_data
	if pes == null:
		return
	
	e_min = +INF
	e_max = -INF
	for e in pes.energies:
		if e < e_min:
			e_min = e
		if e > e_max:
			e_max = e
	
	e_min = maxf(e_min, Globals.settings[&"energy_min"])
	e_max = minf(e_max, Globals.settings[&"energy_max"])
	
	var energies_2d := pes.get_energies_matrix()
	
	#NOTE swap of x and y
	var image := Image.create_empty(
		len(energies_2d[0]), len(energies_2d), false, Image.FORMAT_RGBA8
	)
	image.fill(Color.WHITE)
	
	const TERRAIN = Globals.TERRAIN_GRADIENT
	const OCEAN = Globals.OCEAN_GRADIENT
	
	for ix in len(energies_2d):
		for iy in len(energies_2d[0]):
			var e: float = energies_2d[ix][iy]
			var terrain_color: Color
			
			if e > e_max:
				terrain_color = Color.TRANSPARENT
			elif e_min >= 0.0 or e_max <= 0.0:
				var gradient := TERRAIN if e_min >= 0.0 else OCEAN
				var norm_e := (e - e_min) / (e_max - e_min)
				terrain_color = gradient.sample(norm_e)
			elif e >= 0.0:
				terrain_color = TERRAIN.sample(e / e_max)
			else:
				terrain_color = OCEAN.sample(e / e_min)
			
			var map_pos := _pes_to_texture(ix, iy, len(energies_2d))
			#image.set_pixel(map_pos.x, map_pos.y, _post_process(terrain_color))
			image.set_pixel(map_pos.x, map_pos.y, terrain_color)
	
	var im_tex := ImageTexture.create_from_image(image)
	texture = im_tex
	_free_crosses()


func update_minimap_pos() -> void:
	if Globals.pes_init_pos == null:
		Globals.pes_init_pos = InitialPositionInfos.new()
		_set_init_pos_from_norm(Vector2(0.5, 0.5))
	
	var pos := Globals.pes_init_pos.pes_pos
	%PosMarker.position = _pes_to_pix(pos) - %PosMarker.size * 0.5
	print('> Updated minimap pos to ', pos)


## Keep units, only make 1 pixel per grid point texture
func _pes_to_texture(pes_x: int, pes_y: int, pes_size_x: int) -> Vector2i:
	var tex_pos := Vector2i.ZERO
	if Globals.pes_data == null:
		return tex_pos
	
	# Switch x/y and flip H
	tex_pos.x = pes_y
	tex_pos.y = pes_size_x - 1 - pes_x
	return tex_pos


## UI pixels to normalized coords
func _pix_to_norm(pix_pos: Vector2i) -> Vector2:
	var norm_pos := Vector2(pix_pos) / size
	norm_pos.x = clampf(norm_pos.x, 0.0, 1.0)
	norm_pos.y = clampf(norm_pos.y, 0.0, 1.0)
	return norm_pos


## Normalized coords to UI pixels
func _norm_to_pix(norm_pos: Vector2) -> Vector2i:
	#norm_pos.y = 1.0 - norm_pos.y
	return Vector2i(int(norm_pos.x * size.x), int(norm_pos.y * size.y))


## Normalized map coords to 2-D PES coords
func _norm_to_pes(norm_pos: Vector2) -> Vector2:
	var pd := Globals.pes_data
	var pes_coords := Vector2.ZERO
	if pd == null:
		return pes_coords
	
	# Switch x/y and unflip H
	pes_coords.x = pd.size_x - 1 - norm_pos.y * (pd.size_x - 1)
	pes_coords.y = norm_pos.x * (pd.size_y - 1)
	return pes_coords


## 2-D PES coords to normalized map coords
func _pes_to_norm(pes_pos: Vector2) -> Vector2:
	var pd := Globals.pes_data
	var norm_pos := Vector2.ZERO
	if pd == null:
		return norm_pos
	
	# Switch x/y and flip H
	norm_pos.x = pes_pos.y / (pd.size_y - 1)
	norm_pos.y = (pd.size_x - 1 - pes_pos.x) / (pd.size_x - 1)
	return norm_pos


func _pes_to_pix(pes_pos: Vector2) -> Vector2:
	return _norm_to_pix(_pes_to_norm(pes_pos))


func _free_crosses() -> void:
	for cross in _criticals_crosses:
		cross.queue_free()
	_criticals_crosses.clear()


func display_current_crits() -> void:
	_free_crosses()
	for xycrit in Globals.pes_criticals:
		var ix = xycrit[0]
		var iy = xycrit[1]
		var crit = xycrit[2]
		var cross := TextureRect.new()
		cross.texture = CROSS_TEXTURE
		cross.modulate = Globals.CRIT_COLORS[crit]
		cross.position = _pes_to_pix(Vector2(ix, iy)) - CROSS_SIZE * 0.5
		_criticals_crosses.append(cross)
		%CritsContainer.add_child(cross)


func update_crits_visibility() -> void:
	%CritsContainer.visible = Globals.settings[&"show_crits"]


func update_aspect_ratio() -> void:
	var sx: float = Globals.global_scale_3d.z
	var sy: float = Globals.global_scale_3d.x
	
	if sx == 0.0 or sy == 0.0:
		return
		
	custom_minimum_size.x = MINIMAP_SMALL_SIDE_SIZE
	custom_minimum_size.y = MINIMAP_SMALL_SIDE_SIZE * sy / sx
	await get_tree().create_timer(0.01).timeout
	display_current_crits()
