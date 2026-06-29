@tool
extends Node2D

const BOARD_NUMBERS = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
const CENTER = Vector2.ZERO
const START_ANGLE = -PI / 2.0
const SECTOR_ANGLE = TAU / 20.0
const SEGMENT_STEPS = 8

const INNER_BULL_RADIUS = 14.0
const OUTER_BULL_RADIUS = 35.0
const TREBLE_INNER_RADIUS = 190.0
const TREBLE_OUTER_RADIUS = 222.0
const DOUBLE_INNER_RADIUS = 318.0
const DOUBLE_OUTER_RADIUS = 350.0
const NUMBER_RING_OUTER_RADIUS = 415.0
const NUMBER_RADIUS = 384.0
const NUMBER_FONT_SIZE = 44

const BOARD_SHADOW = Color(0.0, 0.0, 0.0, 0.35)
const NUMBER_RING = Color(0.045, 0.043, 0.04)
const DARK_WEDGE = Color(0.035, 0.032, 0.029)
const LIGHT_WEDGE = Color(0.88, 0.83, 0.68)
const RED_WEDGE = Color(0.72, 0.045, 0.045)
const GREEN_WEDGE = Color(0.0, 0.48, 0.24)
const WIRE = Color(0.82, 0.80, 0.72)
const NUMBER_COLOR = Color(0.95, 0.93, 0.84)
const NUMBER_SHADOW = Color(0.0, 0.0, 0.0, 0.65)

var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	queue_redraw()


func _draw() -> void:
	if _font == null:
		_font = ThemeDB.fallback_font

	draw_circle(CENTER + Vector2(0.0, 10.0), NUMBER_RING_OUTER_RADIUS + 14.0, BOARD_SHADOW)
	draw_circle(CENTER, NUMBER_RING_OUTER_RADIUS, NUMBER_RING)

	_draw_numbered_sections()
	_draw_bull()
	_draw_wires()
	_draw_numbers()


func _draw_numbered_sections() -> void:
	for index in range(BOARD_NUMBERS.size()):
		var center_angle: float = START_ANGLE + float(index) * SECTOR_ANGLE
		var start_angle: float = center_angle - SECTOR_ANGLE * 0.5
		var end_angle: float = center_angle + SECTOR_ANGLE * 0.5
		var single_color: Color = DARK_WEDGE if index % 2 == 0 else LIGHT_WEDGE
		var scoring_color: Color = RED_WEDGE if index % 2 == 0 else GREEN_WEDGE

		_draw_ring_segment(OUTER_BULL_RADIUS, TREBLE_INNER_RADIUS, start_angle, end_angle, single_color)
		_draw_ring_segment(TREBLE_INNER_RADIUS, TREBLE_OUTER_RADIUS, start_angle, end_angle, scoring_color)
		_draw_ring_segment(TREBLE_OUTER_RADIUS, DOUBLE_INNER_RADIUS, start_angle, end_angle, single_color)
		_draw_ring_segment(DOUBLE_INNER_RADIUS, DOUBLE_OUTER_RADIUS, start_angle, end_angle, scoring_color)


func _draw_ring_segment(inner_radius: float, outer_radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points: PackedVector2Array = PackedVector2Array()

	for step in range(SEGMENT_STEPS + 1):
		var angle: float = lerp(start_angle, end_angle, float(step) / float(SEGMENT_STEPS))
		points.append(_polar(outer_radius, angle))

	for step in range(SEGMENT_STEPS, -1, -1):
		var angle: float = lerp(start_angle, end_angle, float(step) / float(SEGMENT_STEPS))
		points.append(_polar(inner_radius, angle))

	draw_colored_polygon(points, color)


func _draw_bull() -> void:
	draw_circle(CENTER, OUTER_BULL_RADIUS, GREEN_WEDGE)
	draw_circle(CENTER, INNER_BULL_RADIUS, RED_WEDGE)


func _draw_wires() -> void:
	draw_arc(CENTER, INNER_BULL_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)
	draw_arc(CENTER, OUTER_BULL_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)
	draw_arc(CENTER, TREBLE_INNER_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)
	draw_arc(CENTER, TREBLE_OUTER_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)
	draw_arc(CENTER, DOUBLE_INNER_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)
	draw_arc(CENTER, DOUBLE_OUTER_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)
	draw_arc(CENTER, NUMBER_RING_OUTER_RADIUS, 0.0, TAU, 160, WIRE, 2.5, true)

	for index in range(20):
		var boundary_angle: float = START_ANGLE - SECTOR_ANGLE * 0.5 + float(index) * SECTOR_ANGLE
		draw_line(_polar(OUTER_BULL_RADIUS, boundary_angle), _polar(DOUBLE_OUTER_RADIUS, boundary_angle), WIRE, 2.5, true)


func _draw_numbers() -> void:
	var ascent: float = _font.get_ascent(NUMBER_FONT_SIZE)
	var descent: float = _font.get_descent(NUMBER_FONT_SIZE)

	for index in range(BOARD_NUMBERS.size()):
		var number_text: String = str(BOARD_NUMBERS[index])
		var angle: float = START_ANGLE + float(index) * SECTOR_ANGLE
		var label_center: Vector2 = _polar(NUMBER_RADIUS, angle)
		var text_size: Vector2 = _font.get_string_size(number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE)
		var baseline: Vector2 = Vector2(
			label_center.x - text_size.x * 0.5,
			label_center.y + (ascent - descent) * 0.5
		)

		draw_string(_font, baseline + Vector2(3.0, 3.0), number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, NUMBER_SHADOW)
		draw_string(_font, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, NUMBER_FONT_SIZE, NUMBER_COLOR)


func _polar(radius: float, angle: float) -> Vector2:
	return CENTER + Vector2(cos(angle), sin(angle)) * radius
