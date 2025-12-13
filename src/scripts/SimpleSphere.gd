class_name SimpleSphere
extends StaticBody3D


@export var material: Material:
	get:
		return %MeshInstance3D.mesh.material
	set(value):
		%MeshInstance3D.mesh.material = value


func duplicate_with_mesh(flags: int = 15) -> SimpleSphere:
	var sphere := duplicate(flags)
	%MeshInstance3D.mesh = %MeshInstance3D.mesh.duplicate()
	return sphere
