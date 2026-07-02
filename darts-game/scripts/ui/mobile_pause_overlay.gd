extends Control

const PANEL_COLOR: Color = Color(0.055, 0.060, 0.095, 0.98)
const HEADER_COLOR: Color = Color(0.72, 0.02, 0.06, 1.0)
const ROW_A: Color = Color(0.095, 0.100, 0.145, 0.96)
const ROW_B: Color = Color(0.120, 0.115, 0.180, 0.96)
const TEXT_COLOR: Color = Color(0.98, 0.97, 0.92, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.72, 0.74, 0.95, 1.0)
const GOLD_TEXT_COLOR: Color = Color(1.0, 0.78, 0.12, 1.0)

## Enables the pause/stats overlay on Android/iOS/mobile exports.
@export var enabled_on_mobile: bool = true
## Forces the overlay on desktop for editor testing.
@export var force_enabled: bool = false

@export_group("Stats Source Paths")
## Current leg visits panel used as the source for pause stats.
@export var current_leg_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/CurrentLeg")
## Match stats panel used as the source for pause stats.
@export var match_stats_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats")

var _enabled: bool = false
var _pause_button: Button
var _backdrop: ColorRect
var _panel: ColorRect
var _title: Label
var _current_leg_title: Label
var _player_visits: Label
var _ai_visits: Label
var _stats_title: Label
var _stats_rows: Array[Array] = []
var _unpause_button: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = _should_enable()
	visible = _enabled

	if not _enabled:
		return

	add_to_group("throw_input_blocker")
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_layout()
	_set_paused_view(false)


func _notification(what: int) -> void:
	if _enabled and what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout()


func blocks_throw_input(screen_position: Vector2) -> bool:
	if not _enabled:
		return false

	if _panel != null and _panel.visible:
		return true

	return _pause_button != null and _pause_button.visible and _pause_button.get_global_rect().has_point(screen_position)


func _should_enable() -> bool:
	if force_enabled:
		return true

	if not enabled_on_mobile:
		return false

	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func _build() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.0, 0.0, 0.0, 0.66)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_panel = ColorRect.new()
	_panel.color = PANEL_COLOR
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var header := ColorRect.new()
	header.name = "Header"
	header.color = HEADER_COLOR
	_panel.add_child(header)

	_title = _make_label("PAUSED", 28, TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	header.add_child(_title)

	_current_leg_title = _make_label("CURRENT LEG", 18, MUTED_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_panel.add_child(_current_leg_title)

	_player_visits = _make_label("", 19, TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_panel.add_child(_player_visits)

	_ai_visits = _make_label("", 19, TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_panel.add_child(_ai_visits)

	_stats_title = _make_label("MATCH STATS", 18, MUTED_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_panel.add_child(_stats_title)

	for index in range(9):
		var row_back := ColorRect.new()
		row_back.color = ROW_A if index % 2 == 0 else ROW_B
		_panel.add_child(row_back)

		var name_label := _make_label("", 16, TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		var player_label := _make_label("", 16, TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
		var ai_label := _make_label("", 16, TEXT_COLOR, HORIZONTAL_ALIGNMENT_CENTER)
		_panel.add_child(name_label)
		_panel.add_child(player_label)
		_panel.add_child(ai_label)
		_stats_rows.append([row_back, name_label, player_label, ai_label])

	_pause_button = Button.new()
	_pause_button.text = "II"
	_pause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_button.add_theme_font_size_override("font_size", 24)
	_pause_button.pressed.connect(_on_pause_pressed)
	add_child(_pause_button)

	_unpause_button = Button.new()
	_unpause_button.text = "Unpause"
	_unpause_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_unpause_button.add_theme_font_size_override("font_size", 20)
	_unpause_button.pressed.connect(_on_unpause_pressed)
	_panel.add_child(_unpause_button)


func _layout() -> void:
	if _pause_button == null:
		return

	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	size = viewport_size

	_backdrop.position = Vector2.ZERO
	_backdrop.size = viewport_size

	_pause_button.position = Vector2(viewport_size.x - 92.0, 18.0)
	_pause_button.size = Vector2(68.0, 58.0)

	var panel_width: float = minf(1180.0, viewport_size.x - 96.0)
	var panel_height: float = minf(820.0, viewport_size.y - 86.0)
	_panel.position = Vector2((viewport_size.x - panel_width) * 0.5, (viewport_size.y - panel_height) * 0.5)
	_panel.size = Vector2(panel_width, panel_height)

	var header: ColorRect = _panel.get_node("Header") as ColorRect
	header.position = Vector2.ZERO
	header.size = Vector2(panel_width, 60.0)
	_title.position = Vector2(26.0, 0.0)
	_title.size = Vector2(panel_width - 52.0, 60.0)

	_current_leg_title.position = Vector2(30.0, 84.0)
	_current_leg_title.size = Vector2(panel_width - 60.0, 28.0)
	_player_visits.position = Vector2(30.0, 122.0)
	_player_visits.size = Vector2(panel_width - 60.0, 30.0)
	_ai_visits.position = Vector2(30.0, 158.0)
	_ai_visits.size = Vector2(panel_width - 60.0, 30.0)

	_stats_title.position = Vector2(30.0, 214.0)
	_stats_title.size = Vector2(panel_width - 60.0, 28.0)

	var row_top: float = 252.0
	var row_height: float = minf(42.0, maxf(34.0, (panel_height - row_top - 92.0) / 9.0))
	for index in range(_stats_rows.size()):
		var row: Array = _stats_rows[index]
		var y: float = row_top + float(index) * row_height
		var row_back: ColorRect = row[0] as ColorRect
		var name_label: Label = row[1] as Label
		var player_label: Label = row[2] as Label
		var ai_label: Label = row[3] as Label

		row_back.position = Vector2(30.0, y)
		row_back.size = Vector2(panel_width - 60.0, row_height - 4.0)
		name_label.position = Vector2(44.0, y)
		name_label.size = Vector2(panel_width * 0.45, row_height - 4.0)
		player_label.position = Vector2(panel_width * 0.52, y)
		player_label.size = Vector2(panel_width * 0.20, row_height - 4.0)
		ai_label.position = Vector2(panel_width * 0.74, y)
		ai_label.size = Vector2(panel_width * 0.20, row_height - 4.0)

	_unpause_button.position = Vector2(panel_width - 248.0, panel_height - 64.0)
	_unpause_button.size = Vector2(218.0, 44.0)


func _set_paused_view(is_open: bool) -> void:
	_backdrop.visible = is_open
	_panel.visible = is_open
	_pause_button.visible = not is_open
	mouse_filter = Control.MOUSE_FILTER_STOP if is_open else Control.MOUSE_FILTER_IGNORE


func _on_pause_pressed() -> void:
	_refresh_stats()
	get_tree().paused = true
	_set_paused_view(true)


func _on_unpause_pressed() -> void:
	get_tree().paused = false
	_set_paused_view(false)


func _refresh_stats() -> void:
	var current_leg: Node = get_node_or_null(current_leg_path)
	var match_stats: Node = get_node_or_null(match_stats_path)

	_player_visits.text = "%s: %s" % [_label_text(current_leg, "PlayerLabel", "PLAYER"), _label_text(current_leg, "PlayerVisits", "-")]
	_ai_visits.text = "%s: %s" % [_label_text(current_leg, "AILabel", "AI"), _label_text(current_leg, "AIVisits", "-")]

	var player_header: String = _label_text(match_stats, "Header/PlayerColumn", "PLAYER")
	var ai_header: String = _label_text(match_stats, "Header/AIColumn", "AI")
	var rows: Array[Array] = [
		["STAT", player_header, ai_header],
		["3 DART AVG", _label_text(match_stats, "AveragePlayer", "0.00"), _label_text(match_stats, "AverageAI", "0.00")],
		["FIRST 9 AVG", _label_text(match_stats, "FirstNinePlayer", "0.00"), _label_text(match_stats, "FirstNineAI", "0.00")],
		["CHECKOUT %", _label_text(match_stats, "CheckoutPlayer", "0% (0/0)"), _label_text(match_stats, "CheckoutAI", "0% (0/0)")],
		["HIGH CHECKOUT", _label_text(match_stats, "HighCheckoutPlayer", "-"), _label_text(match_stats, "HighCheckoutAI", "-")],
		["100+", _label_text(match_stats, "TonPlusPlayer", "0"), _label_text(match_stats, "TonPlusAI", "0")],
		["140+", _label_text(match_stats, "OneFortyPlusPlayer", "0"), _label_text(match_stats, "OneFortyPlusAI", "0")],
		["180S", _label_text(match_stats, "OneEightiesPlayer", "0"), _label_text(match_stats, "OneEightiesAI", "0")],
		["DARTS THROWN", _label_text(match_stats, "DartsThrownPlayer", "0"), _label_text(match_stats, "DartsThrownAI", "0")],
	]

	for index in range(_stats_rows.size()):
		var row: Array = _stats_rows[index]
		var name_label: Label = row[1] as Label
		var player_label: Label = row[2] as Label
		var ai_label: Label = row[3] as Label
		var values: Array = rows[index]

		name_label.text = str(values[0])
		player_label.text = str(values[1])
		ai_label.text = str(values[2])

		var color: Color = MUTED_TEXT_COLOR if index == 0 else TEXT_COLOR
		name_label.add_theme_color_override("font_color", color)
		player_label.add_theme_color_override("font_color", GOLD_TEXT_COLOR if index == 0 else TEXT_COLOR)
		ai_label.add_theme_color_override("font_color", GOLD_TEXT_COLOR if index == 0 else TEXT_COLOR)


func _label_text(parent: Node, child_path: String, fallback: String) -> String:
	if parent == null:
		return fallback

	var label: Label = parent.get_node_or_null(child_path) as Label
	if label == null:
		return fallback

	return label.text


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
