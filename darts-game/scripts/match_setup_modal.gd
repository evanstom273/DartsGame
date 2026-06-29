extends Control

const MATCH_FORMAT_LEGS: int = 0
const MATCH_FORMAT_SETS: int = 1
const START_THROWER_PLAYER: int = 0
const START_THROWER_AI: int = 1
const START_THROWER_RANDOM: int = 2

@export var throw_controller_path: NodePath = NodePath("../ThrowLayer")
@export var score_option_path: NodePath = NodePath("Panel/ScoreOption")
@export var format_option_path: NodePath = NodePath("Panel/FormatOption")
@export var best_of_option_path: NodePath = NodePath("Panel/BestOfOption")
@export var starter_option_path: NodePath = NodePath("Panel/StarterOption")
@export var double_in_toggle_path: NodePath = NodePath("Panel/DoubleInToggle")
@export var start_button_path: NodePath = NodePath("Panel/StartButton")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_populate_options()
	_connect_start_button()
	_hold_match_for_setup()
	visible = true


func _populate_options() -> void:
	var score_option: OptionButton = get_node_or_null(score_option_path) as OptionButton
	var format_option: OptionButton = get_node_or_null(format_option_path) as OptionButton
	var best_of_option: OptionButton = get_node_or_null(best_of_option_path) as OptionButton
	var starter_option: OptionButton = get_node_or_null(starter_option_path) as OptionButton

	if score_option != null:
		score_option.clear()
		score_option.add_item("301", 301)
		score_option.add_item("501", 501)
		_select_option_id(score_option, 501)

	if format_option != null:
		format_option.clear()
		format_option.add_item("Legs", MATCH_FORMAT_LEGS)
		format_option.add_item("Sets", MATCH_FORMAT_SETS)
		_select_option_id(format_option, MATCH_FORMAT_LEGS)

	if best_of_option != null:
		best_of_option.clear()
		best_of_option.add_item("Best of 5", 5)
		best_of_option.add_item("Best of 7", 7)
		best_of_option.add_item("Best of 9", 9)
		_select_option_id(best_of_option, 5)

	if starter_option != null:
		starter_option.clear()
		starter_option.add_item("Player starts", START_THROWER_PLAYER)
		starter_option.add_item("AI starts", START_THROWER_AI)
		starter_option.add_item("Random", START_THROWER_RANDOM)
		_select_option_id(starter_option, START_THROWER_PLAYER)


func _connect_start_button() -> void:
	var start_button: BaseButton = get_node_or_null(start_button_path) as BaseButton

	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)


func _hold_match_for_setup() -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)

	if throw_controller != null:
		throw_controller.call("hold_for_setup")


func _on_start_pressed() -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)

	if throw_controller == null:
		visible = false
		return

	throw_controller.call(
		"configure_match",
		_selected_option_id(score_option_path, 501),
		_selected_option_id(format_option_path, MATCH_FORMAT_LEGS),
		_selected_option_id(best_of_option_path, 5),
		_selected_option_id(starter_option_path, START_THROWER_PLAYER),
		_selected_toggle_pressed(double_in_toggle_path, false)
	)
	visible = false


func _selected_option_id(path: NodePath, fallback: int) -> int:
	var option: OptionButton = get_node_or_null(path) as OptionButton

	if option == null:
		return fallback

	return option.get_selected_id()


func _selected_toggle_pressed(path: NodePath, fallback: bool) -> bool:
	var button: BaseButton = get_node_or_null(path) as BaseButton

	if button == null:
		return fallback

	return button.button_pressed


func _select_option_id(option: OptionButton, id: int) -> void:
	for index in range(option.get_item_count()):
		if option.get_item_id(index) == id:
			option.select(index)
			return
