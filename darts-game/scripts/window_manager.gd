extends Node

const WINDOWED_SIZE: Vector2i = Vector2i(1280, 720)

var _windowed_size: Vector2i = WINDOWED_SIZE
var _windowed_position: Vector2i = Vector2i.ZERO


func _ready() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		_capture_windowed_state()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()


func _toggle_fullscreen() -> void:
	var current_mode: int = DisplayServer.window_get_mode()

	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(_windowed_size)
		DisplayServer.window_set_position(_windowed_position)
		return

	_capture_windowed_state()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _capture_windowed_state() -> void:
	var current_size: Vector2i = DisplayServer.window_get_size()

	if current_size.x > 0 and current_size.y > 0:
		_windowed_size = current_size
	else:
		_windowed_size = WINDOWED_SIZE

	_windowed_position = DisplayServer.window_get_position()
