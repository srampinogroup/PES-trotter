extends Label

@export var visible_time: float = 1.5
@export var fade_time: float = 0.5
var _timer: Timer
var _tween: Tween


func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = visible_time
	_timer.one_shot = true
	_timer.timeout.connect(_initiate_fade)
	add_child(_timer)


func display_message(message: String) -> void:
	if _tween:
		_tween.kill()
		_timer.stop()
	
	text = message
	modulate.a = 1.0
	_timer.start()


func _initiate_fade() -> void:
	_tween = get_tree().create_tween()
	_tween.tween_property(self, "modulate:a", 0.0, fade_time)
	_tween.play()
	await _tween.finished
	_tween.kill()
	_tween = null
