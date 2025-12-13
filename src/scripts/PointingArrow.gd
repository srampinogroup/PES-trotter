extends Node3D

@export var material: Material:
	get:
		return %Mesh.get_surface_override_material(0)
	set(value):
		%Mesh.set_surface_override_material(0, value)
