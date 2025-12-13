# https://github.com/webnetweaver/GodotHeightmap2mesh
extends CollisionShape3D

const TERRAIN_SHADER = preload("res://assets/terrain/terrain_shader.tres")


## Return the PES clamped between the  min and max energies in settings.
func _get_clamped_energies() -> Array[float]:
	var energies: Array[float] = []
	var pes := Globals.pes_data
	var ne := pes.energies.size()
	energies.resize(ne)
	
	for i in ne:
		energies[i] = clampf(pes.energies[i],
							 Globals.settings[&"energy_min"],
							 Globals.settings[&"energy_max"])
	
	return energies


## Build the mesh from the PES data. Also create the collision shape.
func _ready() -> void:
	var width := Globals.pes_data.size_x
	var depth := Globals.pes_data.size_y
	
	if width < 2 || depth < 2:
		return
	
	var half_width: float = width * 0.5
	var half_depth: float = depth * 0.5
	
	var heights := _get_clamped_energies()
	var heightmap_points := []
	
	for j in depth:
		var z_delta := -half_depth + j
		for i in width:
			var x_delta := -half_width + i
			var height := heights[j * width + i]
			heightmap_points.push_back(Vector3(x_delta, height, z_delta))
		
	#Generate triangle vertices and uvs
	var vertices := PackedVector3Array()
	var heightmap_ix := 0
	var reverse_triangles := false
	
	while true:
		vertices.push_back(heightmap_points[heightmap_ix])
		if not reverse_triangles:
			vertices.push_back(heightmap_points[heightmap_ix + 1])
			vertices.push_back(heightmap_points[heightmap_ix + width])
			vertices.push_back(heightmap_points[heightmap_ix + width])
			vertices.push_back(heightmap_points[heightmap_ix + 1])
			vertices.push_back(heightmap_points[heightmap_ix + width + 1])
		else:
			vertices.push_back(heightmap_points[heightmap_ix + width])
			vertices.push_back(heightmap_points[heightmap_ix - 1])
			vertices.push_back(heightmap_points[heightmap_ix - 1])
			vertices.push_back(heightmap_points[heightmap_ix + width])
			vertices.push_back(heightmap_points[heightmap_ix + width - 1])
		
		heightmap_ix += 1 if not reverse_triangles else -1
		
		if not reverse_triangles:
			if heightmap_ix == (width * (depth - 1) - 1):
				break;
			
			if (heightmap_ix + 1) % width == 0:
				reverse_triangles = true
				heightmap_ix += width
		else:
			if (heightmap_ix + (width - 1)) == (width * (depth - 1) - 1):
				break;
			
			if heightmap_ix % width == 0:
				reverse_triangles = false
				heightmap_ix += width
	
	heightmap_points.clear()
	
	var arrays: Array = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	var arr_mesh := ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var st: SurfaceTool = SurfaceTool.new()
	st.create_from(arr_mesh, 0)
	st.generate_normals()
	#st.generate_tangents()
	arr_mesh = st.commit()
	st = null
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = arr_mesh
	arr_mesh = null
	
	#NOTE this takes mem
	mesh_inst.create_trimesh_collision()
	mesh_inst.material_override = TERRAIN_SHADER

	add_child(mesh_inst)


func update_shader_parameters() -> void:
	var min_height: float = Globals.settings[&"energy_min"] * Globals.global_scale_3d.y
	var max_height: float = Globals.settings[&"energy_max"] * Globals.global_scale_3d.y
	var display_iso: float = Globals.settings[&"display_iso"]
	var iso_scale: float = Globals.settings[&"iso_scale"] * Globals.global_scale_3d.y
	TERRAIN_SHADER.set_shader_parameter(&"y_min", min_height)
	TERRAIN_SHADER.set_shader_parameter(&"y_max", max_height)
	TERRAIN_SHADER.set_shader_parameter(&"pos_colors", Globals.positive_colors)
	TERRAIN_SHADER.set_shader_parameter(&"neg_colors", Globals.negative_colors)
	TERRAIN_SHADER.set_shader_parameter(&"y_min", min_height)
	TERRAIN_SHADER.set_shader_parameter(&"y_max", max_height)
	TERRAIN_SHADER.set_shader_parameter(&"display_iso", display_iso)
	TERRAIN_SHADER.set_shader_parameter(&"iso_scale", iso_scale)
