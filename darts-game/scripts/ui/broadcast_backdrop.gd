@tool
extends Node2D

const DEFAULT_SCREEN_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const GRADIENT_BANDS: int = 44

## Enables the subtle arena LED shimmer, haze drift, and spotlight breathing during gameplay.
@export var motion_enabled: bool = true:
	set(value):
		motion_enabled = value
		queue_redraw()

## Allows backdrop motion to animate while viewing the scene in the Godot editor.
@export var preview_motion_in_editor: bool = false:
	set(value):
		preview_motion_in_editor = value
		queue_redraw()

## Main cool arena accent used for LED ribbons, haze, and board-side lighting.
@export var accent_color_primary: Color = Color(0.28, 0.34, 0.95, 1.0):
	set(value):
		accent_color_primary = value
		queue_redraw()

## Secondary violet accent blended into the arena lighting and camera split glow.
@export var accent_color_secondary: Color = Color(0.56, 0.28, 0.88, 1.0):
	set(value):
		accent_color_secondary = value
		queue_redraw()

## Center of the warm board spotlight in 1920x1080 canvas coordinates.
@export var spotlight_center: Vector2 = Vector2(1410.0, 540.0):
	set(value):
		spotlight_center = value
		queue_redraw()

## X coordinate of the broadcast split between scoreboard side and board camera side.
@export var divider_x: float = 900.0:
	set(value):
		divider_x = value
		queue_redraw()

var _motion_time: float = 0.0
var _canvas_size: Vector2 = DEFAULT_SCREEN_SIZE


func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	if not _should_animate():
		return

	_motion_time += delta
	queue_redraw()


func _draw() -> void:
	var phase: float = _motion_time if _should_animate() else 0.0
	var visible_size: Vector2 = get_viewport().get_visible_rect().size
	var window_size: Vector2 = Vector2(DisplayServer.window_get_size())
	_canvas_size = Vector2(
		maxf(DEFAULT_SCREEN_SIZE.x, maxf(visible_size.x, window_size.x)),
		maxf(DEFAULT_SCREEN_SIZE.y, maxf(visible_size.y, window_size.y))
	)

	_draw_arena_gradient()
	_draw_far_led_ribbons(phase)
	_draw_stage_truss()
	_draw_light_beams(phase)
	_draw_crowd_silhouettes(phase)
	_draw_haze(phase)
	_draw_board_spotlight(phase)
	_draw_camera_split()
	_draw_vignette()


func _should_animate() -> bool:
	return motion_enabled and (not Engine.is_editor_hint() or preview_motion_in_editor)


func _draw_arena_gradient() -> void:
	for band in range(GRADIENT_BANDS):
		var amount: float = float(band) / float(GRADIENT_BANDS - 1)
		var y: float = amount * _canvas_size.y
		var height: float = _canvas_size.y / float(GRADIENT_BANDS) + 1.0
		var center_lift: float = sin(amount * PI) * 0.030
		var lower_falloff: float = amount * 0.018
		var color: Color = Color(
			0.010 + accent_color_secondary.r * center_lift,
			0.012 + accent_color_primary.g * center_lift,
			0.022 + accent_color_primary.b * center_lift - lower_falloff,
			1.0
		)

		draw_rect(Rect2(Vector2(0.0, y), Vector2(_canvas_size.x, height)), color, true)

	draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(divider_x, _canvas_size.y)), Color(0.0, 0.0, 0.0, 0.10), true)
	draw_rect(Rect2(Vector2(divider_x, 0.0), Vector2(_canvas_size.x - divider_x, _canvas_size.y)), _with_alpha(accent_color_primary, 0.020), true)


func _draw_far_led_ribbons(phase: float) -> void:
	for row in range(4):
		var y: float = 104.0 + float(row) * 72.0
		var row_alpha: float = 0.030 + float(row) * 0.006
		var panel_height: float = 16.0 if row % 2 == 0 else 12.0

		draw_rect(Rect2(Vector2(0.0, y), Vector2(_canvas_size.x, panel_height)), _with_alpha(accent_color_primary, row_alpha), true)

		for segment in range(30):
			var shimmer: float = (sin(float(segment) * 0.87 + phase * 1.15 + float(row) * 0.7) + 1.0) * 0.5
			var x: float = -70.0 + float(segment) * 72.0 + fmod(phase * 8.0 + float(row) * 18.0, 72.0)
			var segment_color: Color = accent_color_primary.lerp(accent_color_secondary, shimmer)
			var alpha: float = 0.018 + shimmer * 0.045

			draw_rect(Rect2(Vector2(x, y + 2.0), Vector2(46.0, panel_height - 4.0)), _with_alpha(segment_color, alpha), true)

	draw_rect(Rect2(Vector2(0.0, 248.0), Vector2(divider_x - 44.0, 394.0)), _with_alpha(accent_color_secondary, 0.018), true)
	draw_rect(Rect2(Vector2(34.0, 262.0), Vector2(divider_x - 112.0, 1.0)), _with_alpha(accent_color_primary, 0.080), true)
	draw_rect(Rect2(Vector2(34.0, 638.0), Vector2(divider_x - 112.0, 1.0)), _with_alpha(accent_color_secondary, 0.060), true)


func _draw_stage_truss() -> void:
	var truss_color: Color = _with_alpha(Color(0.62, 0.66, 1.0, 1.0), 0.075)
	var dark_truss_color: Color = Color(0.0, 0.0, 0.0, 0.20)

	draw_line(Vector2(0.0, 168.0), Vector2(_canvas_size.x, 96.0), dark_truss_color, 3.0, true)
	draw_line(Vector2(0.0, 174.0), Vector2(_canvas_size.x, 102.0), truss_color, 1.0, true)
	draw_line(Vector2(0.0, 706.0), Vector2(_canvas_size.x, 758.0), Color(0.0, 0.0, 0.0, 0.17), 3.0, true)
	draw_line(Vector2(0.0, 712.0), Vector2(_canvas_size.x, 764.0), _with_alpha(accent_color_primary, 0.050), 1.0, true)

	for index in range(15):
		var x: float = 36.0 + float(index) * 142.0
		draw_line(Vector2(x, 150.0), Vector2(x + 92.0, 114.0), _with_alpha(accent_color_secondary, 0.045), 1.0, true)
		draw_line(Vector2(x + 92.0, 114.0), Vector2(x + 142.0, 148.0), _with_alpha(accent_color_primary, 0.040), 1.0, true)

	for index in range(10):
		var x: float = divider_x + 70.0 + float(index) * 104.0
		draw_line(Vector2(x, 0.0), Vector2(x - 210.0, _canvas_size.y), Color(0.0, 0.0, 0.0, 0.055), 1.0, true)


func _draw_light_beams(phase: float) -> void:
	for index in range(5):
		var shift: float = sin(phase * 0.22 + float(index) * 1.1) * 46.0
		var origin_x: float = divider_x + 150.0 + float(index) * 184.0
		var target: Vector2 = spotlight_center + Vector2(shift, -10.0 + float(index % 2) * 38.0)
		var beam_color: Color = accent_color_primary.lerp(accent_color_secondary, float(index) / 4.0)
		var points: PackedVector2Array = PackedVector2Array()

		points.append(Vector2(origin_x - 36.0, 0.0))
		points.append(Vector2(origin_x + 62.0, 0.0))
		points.append(target + Vector2(120.0, 560.0))
		points.append(target + Vector2(-150.0, 560.0))
		draw_colored_polygon(points, _with_alpha(beam_color, 0.020))

	for index in range(3):
		var sweep: float = sin(phase * 0.18 + float(index) * 1.7)
		var x: float = 130.0 + float(index) * 250.0 + sweep * 42.0
		var points: PackedVector2Array = PackedVector2Array()

		points.append(Vector2(x - 24.0, 0.0))
		points.append(Vector2(x + 58.0, 0.0))
		points.append(Vector2(x + 250.0, _canvas_size.y))
		points.append(Vector2(x + 90.0, _canvas_size.y))
		draw_colored_polygon(points, _with_alpha(accent_color_secondary, 0.014))


func _draw_crowd_silhouettes(phase: float) -> void:
	draw_rect(Rect2(Vector2(0.0, 790.0), Vector2(_canvas_size.x, 290.0)), Color(0.0, 0.0, 0.0, 0.20), true)

	for index in range(74):
		var x: float = -28.0 + float(index) * 27.0
		var wave: float = (sin(float(index) * 0.74 + phase * 0.12) + 1.0) * 0.5
		var head_y: float = 820.0 + wave * 38.0
		var height: float = 74.0 + wave * 44.0
		var width: float = 15.0 + float(index % 4) * 2.0
		var shade: float = 0.010 + wave * 0.018

		draw_rect(Rect2(Vector2(x - width * 0.5, head_y + 13.0), Vector2(width, height)), Color(0.0, 0.0, 0.0, 0.28 + shade), true)
		draw_circle(Vector2(x, head_y), 8.0 + float(index % 3), Color(0.0, 0.0, 0.0, 0.34 + shade))

	for index in range(14):
		var side_y: float = 210.0 + float(index) * 44.0
		var left_alpha: float = 0.045 + float(index % 3) * 0.010
		var right_alpha: float = 0.035 + float(index % 4) * 0.008

		draw_rect(Rect2(Vector2(0.0, side_y), Vector2(115.0, 22.0)), Color(0.0, 0.0, 0.0, left_alpha), true)
		draw_rect(Rect2(Vector2(_canvas_size.x - 120.0, side_y + 12.0), Vector2(120.0, 18.0)), Color(0.0, 0.0, 0.0, right_alpha), true)


func _draw_haze(phase: float) -> void:
	for index in range(6):
		var drift_x: float = sin(phase * 0.10 + float(index) * 1.3) * 54.0
		var drift_y: float = cos(phase * 0.08 + float(index) * 0.9) * 24.0
		var center: Vector2 = Vector2(250.0 + float(index) * 285.0 + drift_x, 380.0 + float(index % 3) * 96.0 + drift_y)
		var haze_color: Color = accent_color_primary.lerp(accent_color_secondary, float(index % 4) / 3.0)

		draw_circle(center, 210.0 + float(index % 3) * 48.0, _with_alpha(haze_color, 0.011))


func _draw_board_spotlight(phase: float) -> void:
	var breathe: float = (sin(phase * 0.55) + 1.0) * 0.5 if _should_animate() else 0.45
	var warm_alpha: float = 0.040 + breathe * 0.014

	draw_circle(spotlight_center, 790.0 + breathe * 18.0, _with_alpha(accent_color_primary, 0.030))
	draw_circle(spotlight_center, 620.0 + breathe * 14.0, _with_alpha(accent_color_secondary, 0.032))
	draw_circle(spotlight_center, 520.0 + breathe * 10.0, Color(0.21, 0.15, 0.07, warm_alpha))
	draw_circle(spotlight_center, 378.0 + breathe * 8.0, Color(0.34, 0.25, 0.10, 0.035 + breathe * 0.012))
	draw_circle(spotlight_center + Vector2(0.0, 260.0), 640.0, Color(0.0, 0.0, 0.0, 0.15))


func _draw_camera_split() -> void:
	if divider_x < 0.0:
		return

	draw_rect(Rect2(Vector2(divider_x - 56.0, 0.0), Vector2(56.0, _canvas_size.y)), Color(0.0, 0.0, 0.0, 0.16), true)
	draw_rect(Rect2(Vector2(divider_x, 0.0), Vector2(78.0, _canvas_size.y)), _with_alpha(accent_color_primary, 0.040), true)
	draw_rect(Rect2(Vector2(divider_x - 1.0, 0.0), Vector2(2.0, _canvas_size.y)), _with_alpha(Color(0.80, 0.84, 1.0, 1.0), 0.22), true)
	draw_rect(Rect2(Vector2(divider_x + 2.0, 0.0), Vector2(18.0, _canvas_size.y)), _with_alpha(accent_color_secondary, 0.030), true)


func _draw_vignette() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(_canvas_size.x, 128.0)), Color(0.0, 0.0, 0.0, 0.30), true)
	draw_rect(Rect2(Vector2(0.0, _canvas_size.y - 170.0), Vector2(_canvas_size.x, 170.0)), Color(0.0, 0.0, 0.0, 0.34), true)
	draw_rect(Rect2(Vector2.ZERO, Vector2(150.0, _canvas_size.y)), Color(0.0, 0.0, 0.0, 0.24), true)
	draw_rect(Rect2(Vector2(_canvas_size.x - 155.0, 0.0), Vector2(155.0, _canvas_size.y)), Color(0.0, 0.0, 0.0, 0.22), true)


func _with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
