extends Node3D


const CLICK_STREAM = preload("res://assets/sounds/click.wav")

var _audio_player := AudioStreamPlayer.new()


func _ready() -> void:
	_audio_player.stream = CLICK_STREAM
	add_child(_audio_player)


## Recursively connect button to maka a sound.
func connect_sounds(node: Node) -> void:
	for child in node.get_children():
		#if child is Button:
		if child.has_signal(&"pressed"):
			child.pressed.connect(play_ui_sound)
		
		connect_sounds(child)


func play_ui_sound(_dummy = 0) -> void:
	if not Globals.settings[&"ui_sounds_on"]:
		return
	
	_audio_player.stop()
	_audio_player.play()
