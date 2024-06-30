extends CanvasLayer

var alpha := 0.0
var fading_in := false
var fading_out := false
var _speed := 100.0
var _callback := _void


func _void() -> void:
	return


func start_fade_in(speed: float = 100.0, callback: Callable = _void) -> void:
	alpha = 255.0
	fading_in = true
	fading_out = false
	_speed = speed
	_callback = callback

func start_fade_out(speed: float = 100.0, callback: Callable = _void) -> void:
	alpha = 0.0
	fading_out = true
	fading_in = false
	_speed = speed
	_callback = callback

func _process(delta: float) -> void:
	if fading_in:
		alpha -= _speed * delta
		if alpha < 0.0:
			alpha = 0.0
			fading_in = false
			_callback.call()
	if fading_out:
		alpha += _speed * delta
		if alpha > 255.0:
			alpha = 255.0
			fading_out = false
			_callback.call()
	$ColorRect.color = Color8(0, 0, 0, int(alpha))
