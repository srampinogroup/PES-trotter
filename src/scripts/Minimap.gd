extends GridContainer


@export var x_label: String:
	get:
		return %XLabel.text
	set(value):
		%XLabel.text = value

@export var y_label: String:
	get:
		return %YLabel.text
	set(value):
		%YLabel.text = value


func _ready() -> void:
	update_labels()


func update_texture_from_pes() -> void:
	%MapRect.update_texture_from_pes()
	var units: String = Globals.settings[&"energy_units"]
	var e_min: float = %MapRect.e_min
	var e_max: float = %MapRect.e_max
	%PosContainer.visible = e_max > 0.0
	%NegContainer.visible = e_min < 0.0
	%MaxPosLabel.text = "%.2f %s" % [e_max, units]
	%MinPosLabel.text = "%.2f" % maxf(e_min, 0.0)
	%MaxNegLabel.text = "%.2f %s" % [minf(e_max, 0.0), units]
	%MinNegLabel.text = "%.2f" % e_min


func update_minimap_pos() -> void:
	%MapRect.update_minimap_pos()


func compute_critical_points() -> void:
	CriticalPoints.compute_critical_points()
	%MapRect.display_current_crits()


func update_crits_visibility() -> void:
	%MapRect.update_crits_visibility()


func update_labels() -> void:
	x_label = Globals.settings[&"y_name"]
	y_label = Globals.settings[&"x_name"]


func update_aspect_ratio() -> void:
	%MapRect.update_aspect_ratio()
