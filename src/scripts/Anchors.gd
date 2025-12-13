extends Node3D

const VISIBLE_COL_LAYER = 2
const INVISIBLE_COL_LAYER = 32

var _anchors: Array[Node3D] = []
var _anchors_initialized := false

func _ready() -> void:
	visibility_changed.connect(_visibility_changed)

func _ensure_anchors_initialized() -> void:
	if _anchors_initialized:
		return
	
	_init_anchors()

func _init_anchors() -> void:
	_clear_anchors()
	for crit in Globals.pes_criticals:
		var material := StandardMaterial3D.new()
		material.albedo_color = Globals.CRIT_COLORS[crit[2]]
		
		var anchor_node: SimpleSphere = %AnchorTemplate.duplicate_with_mesh()
		var grid_pos := Vector2(crit[0], crit[1])
		anchor_node.position = Map.grid_coords_to_pos(grid_pos)
		anchor_node.material = material
		anchor_node.visible = true
		add_child(anchor_node)
	
	_anchors_initialized = true
	_visibility_changed()
	print('> %d anchors set up' % len(Globals.pes_criticals))


func _clear_anchors() -> void:
	for anchor in _anchors:
		anchor.queue_free()
	_anchors.clear()

func _visibility_changed() -> void:
	print('> anchors toggled to ', visible)
	
	if visible:
		_ensure_anchors_initialized()
	
	for child in get_children():
		child.set_collision_layer_value(VISIBLE_COL_LAYER, visible)
		child.set_collision_layer_value(INVISIBLE_COL_LAYER, not visible)
