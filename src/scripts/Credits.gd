class_name Credits
extends MarginContainer


func _ready() -> void:
	%InfoContents.meta_clicked.connect(OS.shell_open)
