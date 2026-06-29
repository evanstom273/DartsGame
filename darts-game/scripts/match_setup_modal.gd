extends Control

const MATCH_FORMAT_LEGS: int = 0
const MATCH_FORMAT_SETS: int = 1
const START_THROWER_PLAYER: int = 0
const START_THROWER_AI: int = 1
const START_THROWER_RANDOM: int = 2
const CUSTOM_FORMAT_ID: int = 1001
const PLAYER_DIFFICULTY_AMATEUR: int = 0
const PLAYER_DIFFICULTY_COUNTY: int = 1
const PLAYER_DIFFICULTY_PRO: int = 2
const PLAYER_DIFFICULTY_WORLD_CLASS: int = 3
const AI_PROFILE_AMATEUR_ID: int = 0
const AI_PROFILE_COUNTY_ID: int = 1
const AI_PROFILE_PRO_ID: int = 2
const AI_PROFILE_WORLD_CLASS_ID: int = 3

## ThrowController node that receives the selected match setup values.
@export var throw_controller_path: NodePath = NodePath("../ThrowLayer")
## OptionButton for selecting 301 or 501 starting score.
@export var score_option_path: NodePath = NodePath("Panel/ScoreOption")
## OptionButton for selecting legs mode or sets mode.
@export var format_option_path: NodePath = NodePath("Panel/FormatOption")
## OptionButton for preset match length or custom first-to mode.
@export var best_of_option_path: NodePath = NodePath("Panel/BestOfOption")
## SpinBox used when FORMAT LENGTH is set to Custom first to.
@export var custom_target_path: NodePath = NodePath("Panel/CustomTarget")
## OptionButton for Player, AI, or Random starting thrower.
@export var starter_option_path: NodePath = NodePath("Panel/StarterOption")
## CheckBox that enables double-in rules before scoring can begin.
@export var double_in_toggle_path: NodePath = NodePath("Panel/DoubleInToggle")
## OptionButton for visible player difficulty preset.
@export var player_difficulty_option_path: NodePath = NodePath("Panel/PlayerDifficultyOption")
## OptionButton for selecting the AIProfile resource preset.
@export var ai_profile_option_path: NodePath = NodePath("Panel/AIProfileOption")
## Button that starts the match with the current setup values.
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
	var custom_target: SpinBox = get_node_or_null(custom_target_path) as SpinBox
	var player_difficulty_option: OptionButton = get_node_or_null(player_difficulty_option_path) as OptionButton
	var ai_profile_option: OptionButton = get_node_or_null(ai_profile_option_path) as OptionButton

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
		best_of_option.add_item("Custom first to", CUSTOM_FORMAT_ID)
		_select_option_id(best_of_option, 5)

	if custom_target != null:
		custom_target.min_value = 1.0
		custom_target.max_value = 50.0
		custom_target.step = 1.0
		custom_target.value = 6.0

	if starter_option != null:
		starter_option.clear()
		starter_option.add_item("Player starts", START_THROWER_PLAYER)
		starter_option.add_item("AI starts", START_THROWER_AI)
		starter_option.add_item("Random", START_THROWER_RANDOM)
		_select_option_id(starter_option, START_THROWER_PLAYER)

	if player_difficulty_option != null:
		player_difficulty_option.clear()
		player_difficulty_option.add_item("Amateur", PLAYER_DIFFICULTY_AMATEUR)
		player_difficulty_option.add_item("County", PLAYER_DIFFICULTY_COUNTY)
		player_difficulty_option.add_item("Pro", PLAYER_DIFFICULTY_PRO)
		player_difficulty_option.add_item("World Class", PLAYER_DIFFICULTY_WORLD_CLASS)
		_select_option_id(player_difficulty_option, PLAYER_DIFFICULTY_COUNTY)

	if ai_profile_option != null:
		ai_profile_option.clear()
		ai_profile_option.add_item("Amateur", AI_PROFILE_AMATEUR_ID)
		ai_profile_option.add_item("County", AI_PROFILE_COUNTY_ID)
		ai_profile_option.add_item("Pro", AI_PROFILE_PRO_ID)
		ai_profile_option.add_item("World Class", AI_PROFILE_WORLD_CLASS_ID)
		_select_option_id(ai_profile_option, AI_PROFILE_COUNTY_ID)


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
		_selected_best_of_count(),
		_selected_option_id(starter_option_path, START_THROWER_PLAYER),
		_selected_toggle_pressed(double_in_toggle_path, false),
		_selected_option_id(player_difficulty_option_path, PLAYER_DIFFICULTY_COUNTY),
		_selected_ai_profile_path()
	)
	visible = false


func _selected_option_id(path: NodePath, fallback: int) -> int:
	var option: OptionButton = get_node_or_null(path) as OptionButton

	if option == null:
		return fallback

	return option.get_selected_id()


func _selected_best_of_count() -> int:
	var selected_id: int = _selected_option_id(best_of_option_path, 5)

	if selected_id != CUSTOM_FORMAT_ID:
		return selected_id

	var target_count: int = maxi(1, _selected_spin_value(custom_target_path, 6))

	return target_count * 2 - 1


func _selected_spin_value(path: NodePath, fallback: int) -> int:
	var spin_box: SpinBox = get_node_or_null(path) as SpinBox

	if spin_box == null:
		return fallback

	return int(spin_box.value)


func _selected_ai_profile_path() -> String:
	var selected_id: int = _selected_option_id(ai_profile_option_path, AI_PROFILE_COUNTY_ID)

	match selected_id:
		AI_PROFILE_AMATEUR_ID:
			return "res://ai_amateur.tres"
		AI_PROFILE_PRO_ID:
			return "res://ai_pro.tres"
		AI_PROFILE_WORLD_CLASS_ID:
			return "res://ai_world_class.tres"
		_:
			return "res://ai_county.tres"


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
