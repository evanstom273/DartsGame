extends Control

const HEADER_COLOR: Color = Color(0.01, 0.012, 0.02, 1.0)
const ROW_COLOR: Color = Color(0.075, 0.08, 0.13, 0.96)
const ALT_ROW_COLOR: Color = Color(0.095, 0.10, 0.16, 0.96)
const WIN_ROW_COLOR: Color = Color(0.15, 0.13, 0.23, 0.96)
const TEXT_COLOR: Color = Color(0.98, 0.97, 0.92, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.72, 0.74, 0.95, 1.0)
const GOLD_TEXT_COLOR: Color = Color(0.96, 0.72, 0.18, 1.0)
const SUMMARY_ROW_HEIGHT: float = 28.0
const BREAKDOWN_ROW_HEIGHT: float = 26.0

## Label that displays MATCH COMPLETE or SET COMPLETE.
@export var title_label_path: NodePath = NodePath("Panel/Header/Title")
## Label that displays rule summary and match score metadata.
@export var meta_label_path: NodePath = NodePath("Panel/MetaText")
## GridContainer populated with aggregate match/set stats.
@export var summary_table_path: NodePath = NodePath("Panel/SummaryTable")
## GridContainer populated with the per-leg throw breakdown rows.
@export var breakdown_table_path: NodePath = NodePath("Panel/BreakdownScroll/BreakdownTable")
## Button used to close the modal or advance to the next set.
@export var continue_button_path: NodePath = NodePath("Panel/ContinueButton")
## Throw controller called when a set summary should continue into the next set.
@export var throw_controller_path: NodePath = NodePath("../ThrowLayer")

var _continue_match: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_connect_continue_button()
	visible = false


func show_summary(title: String, stats_text: String, breakdown_text: String, continue_match: bool) -> void:
	var fallback_stats: Array[Dictionary] = [
		{"label": "SUMMARY", "player": stats_text, "ai": ""}
	]
	var fallback_breakdown: Array[Dictionary] = [
		{"leg": "", "thrower": "", "visits": breakdown_text, "stats": "", "won": false}
	]

	show_summary_data(title, "", fallback_stats, fallback_breakdown, continue_match)


func show_summary_data(title: String, meta_text: String, stats_rows: Array[Dictionary], breakdown_rows: Array[Dictionary], continue_match: bool) -> void:
	_continue_match = continue_match
	_set_label_text(title_label_path, title)
	_set_label_text(meta_label_path, meta_text)
	_populate_summary_table(stats_rows)
	_populate_breakdown_table(breakdown_rows)
	_set_continue_button_text("Next Set" if continue_match else "Close")
	visible = true
	move_to_front()


func _connect_continue_button() -> void:
	var continue_button: BaseButton = get_node_or_null(continue_button_path) as BaseButton

	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)


func _on_continue_pressed() -> void:
	visible = false

	if not _continue_match:
		return

	var throw_controller: Node = get_node_or_null(throw_controller_path)

	if throw_controller != null:
		throw_controller.call("continue_after_summary")


func _set_label_text(path: NodePath, value: String) -> void:
	var label: Label = get_node_or_null(path) as Label

	if label != null:
		label.text = value


func _populate_summary_table(rows: Array[Dictionary]) -> void:
	var table: GridContainer = get_node_or_null(summary_table_path) as GridContainer

	if table == null:
		return

	table.columns = 3
	_clear_children(table)
	_add_cell(table, "STAT", 388.0, SUMMARY_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 14, HORIZONTAL_ALIGNMENT_LEFT)
	_add_cell(table, "PLAYER", 210.0, SUMMARY_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 14, HORIZONTAL_ALIGNMENT_CENTER)
	_add_cell(table, "AI", 210.0, SUMMARY_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 14, HORIZONTAL_ALIGNMENT_CENTER)

	var row_index: int = 0

	for row_value in rows:
		var row: Dictionary = row_value as Dictionary
		var row_color: Color = ROW_COLOR if row_index % 2 == 0 else ALT_ROW_COLOR

		_add_cell(table, str(row.get("label", "")), 388.0, SUMMARY_ROW_HEIGHT, row_color, TEXT_COLOR, 15, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell(table, str(row.get("player", "")), 210.0, SUMMARY_ROW_HEIGHT, row_color, TEXT_COLOR, 15, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell(table, str(row.get("ai", "")), 210.0, SUMMARY_ROW_HEIGHT, row_color, TEXT_COLOR, 15, HORIZONTAL_ALIGNMENT_CENTER)
		row_index += 1


func _populate_breakdown_table(rows: Array[Dictionary]) -> void:
	var table: GridContainer = get_node_or_null(breakdown_table_path) as GridContainer

	if table == null:
		return

	table.columns = 6
	_clear_children(table)
	_add_cell(table, "LEG", 82.0, BREAKDOWN_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_CENTER)
	_add_cell(table, "THROWER", 118.0, BREAKDOWN_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_LEFT)
	_add_cell(table, "VISITS", 642.0, BREAKDOWN_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_LEFT)
	_add_cell(table, "DARTS", 84.0, BREAKDOWN_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_CENTER)
	_add_cell(table, "AVG", 106.0, BREAKDOWN_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_CENTER)
	_add_cell(table, "CO", 246.0, BREAKDOWN_ROW_HEIGHT, HEADER_COLOR, MUTED_TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_LEFT)

	var row_index: int = 0

	for row_value in rows:
		var row: Dictionary = row_value as Dictionary
		var won_leg: bool = bool(row.get("won", false))
		var row_color: Color = WIN_ROW_COLOR if won_leg else (ROW_COLOR if row_index % 2 == 0 else ALT_ROW_COLOR)
		var name_color: Color = GOLD_TEXT_COLOR if won_leg else TEXT_COLOR
		var stats_text: String = str(row.get("stats", ""))

		_add_cell(table, str(row.get("leg", "")), 82.0, BREAKDOWN_ROW_HEIGHT, row_color, TEXT_COLOR, 14, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell(table, str(row.get("thrower", "")), 118.0, BREAKDOWN_ROW_HEIGHT, row_color, name_color, 14, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell(table, str(row.get("visits", "")), 642.0, BREAKDOWN_ROW_HEIGHT, row_color, TEXT_COLOR, 14, HORIZONTAL_ALIGNMENT_LEFT)
		_add_cell(table, _stat_part(stats_text, 0), 84.0, BREAKDOWN_ROW_HEIGHT, row_color, TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell(table, _stat_part(stats_text, 1), 106.0, BREAKDOWN_ROW_HEIGHT, row_color, TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_CENTER)
		_add_cell(table, _stat_part(stats_text, 2), 246.0, BREAKDOWN_ROW_HEIGHT, row_color, TEXT_COLOR, 13, HORIZONTAL_ALIGNMENT_LEFT)
		row_index += 1


func _add_cell(table: GridContainer, text: String, width: float, height: float, background_color: Color, font_color: Color, font_size: int, alignment: HorizontalAlignment) -> void:
	var cell: ColorRect = ColorRect.new()

	cell.custom_minimum_size = Vector2(width, height)
	cell.color = background_color
	table.add_child(cell)

	var label: Label = Label.new()

	label.text = text
	label.clip_text = true
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", font_color)
	label.add_theme_font_size_override("font_size", font_size)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.offset_left = 8.0
	label.offset_right = -8.0
	cell.add_child(label)


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _stat_part(stats_text: String, part_index: int) -> String:
	var parts: PackedStringArray = stats_text.split("  ")

	if part_index < 0 or part_index >= parts.size():
		return ""

	return parts[part_index]


func _set_continue_button_text(value: String) -> void:
	var button: Button = get_node_or_null(continue_button_path) as Button

	if button != null:
		button.text = value
