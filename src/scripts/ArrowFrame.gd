class_name ArrowFrame
extends Node3D


@onready var x_label: String:
	get:
		return (%XText.mesh as TextMesh).text
	set(label):
		(%XText.mesh as TextMesh).text = label

@onready var y_label: String:
	get:
		return (%ZText.mesh as TextMesh).text
	set(label):
		(%ZText.mesh as TextMesh).text = label

@export var override_material: Material#:
	#set(material):
		#%XText.mesh.override_material = material
		#%ZText.mesh.override_material = material


func _ready() -> void:
	%XText.mesh.material = override_material
	%ZText.mesh.material = override_material
	$CSGSphere3D.material = override_material
	$XArrow/XCone.material = override_material
	$XArrow/XCylinder.material = override_material
	$ZArrow/ZCone.material = override_material
	$ZArrow/ZCylinder.material = override_material
