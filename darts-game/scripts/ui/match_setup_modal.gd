extends Control

const MATCH_FORMAT_LEGS: int = 0
const MATCH_FORMAT_SETS: int = 1
const START_THROWER_PLAYER: int = 0
const START_THROWER_AI: int = 1
const START_THROWER_RANDOM: int = 2
const CUSTOM_FORMAT_ID: int = 1001
const MODE_SINGLE_MATCH: int = 0
const MODE_KNOCKOUT_TOURNAMENT: int = 1
const AI_HANDLING_WATCH: int = 0
const AI_HANDLING_SKIP: int = 1

## ThrowController node that receives the selected match setup values.
@export var throw_controller_path: NodePath = NodePath("../ThrowLayer")
## TournamentController node that receives knockout tournament setup values.
@export var tournament_controller_path: NodePath = NodePath("../TournamentScreen")
## OptionButton for choosing single match or knockout tournament setup.
@export var mode_option_path: NodePath = NodePath("Panel/ModeOption")
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
## Button that starts the match with the current setup values.
@export var start_button_path: NodePath = NodePath("Panel/StartButton")
## OptionButton for tournament participant count.
@export var participant_option_path: NodePath = NodePath("Panel/ParticipantOption")
## SpinBox for tournament seed count.
@export var seed_count_path: NodePath = NodePath("Panel/SeedCount")
## OptionButton for minimum generated character level.
@export var minimum_level_option_path: NodePath = NodePath("Panel/MinimumLevelOption")
## SpinBox for tournament prize fund.
@export var prize_fund_path: NodePath = NodePath("Panel/PrizeFund")
## OptionButton for watched or skipped AI-only matches.
@export var ai_handling_option_path: NodePath = NodePath("Panel/AIHandlingOption")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_ensure_extra_controls()
	_populate_options()
	_connect_start_button()
	_hold_match_for_setup()
	visible = true


func _populate_options() -> void:
	var mode_option: OptionButton = get_node_or_null(mode_option_path) as OptionButton
	var score_option: OptionButton = get_node_or_null(score_option_path) as OptionButton
	var format_option: OptionButton = get_node_or_null(format_option_path) as OptionButton
	var best_of_option: OptionButton = get_node_or_null(best_of_option_path) as OptionButton
	var starter_option: OptionButton = get_node_or_null(starter_option_path) as OptionButton
	var custom_target: SpinBox = get_node_or_null(custom_target_path) as SpinBox
	var participant_option: OptionButton = get_node_or_null(participant_option_path) as OptionButton
	var seed_count: SpinBox = get_node_or_null(seed_count_path) as SpinBox
	var minimum_level_option: OptionButton = get_node_or_null(minimum_level_option_path) as OptionButton
	var prize_fund: SpinBox = get_node_or_null(prize_fund_path) as SpinBox
	var ai_handling_option: OptionButton = get_node_or_null(ai_handling_option_path) as OptionButton

	if mode_option != null:
		mode_option.clear()
		mode_option.add_item("Single Match", MODE_SINGLE_MATCH)
		mode_option.add_item("Knockout Tournament", MODE_KNOCKOUT_TOURNAMENT)
		_select_option_id(mode_option, MODE_SINGLE_MATCH)
		if not mode_option.item_selected.is_connected(_on_mode_changed):
			mode_option.item_selected.connect(_on_mode_changed)

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

	if participant_option != null:
		participant_option.clear()
		for participant_count in [4, 8, 16, 32, 64, 128]:
			participant_option.add_item("%d players" % participant_count, participant_count)
		_select_option_id(participant_option, 16)
		if not participant_option.item_selected.is_connected(_on_participant_count_changed):
			participant_option.item_selected.connect(_on_participant_count_changed)

	if seed_count != null:
		seed_count.min_value = 0.0
		seed_count.max_value = float(_selected_option_id(participant_option_path, 16))
		seed_count.step = 1.0
		seed_count.value = 4.0

	if minimum_level_option != null:
		minimum_level_option.clear()
		minimum_level_option.add_item("Amateur+", 0)
		minimum_level_option.add_item("County+", 1)
		minimum_level_option.add_item("Pro+", 2)
		minimum_level_option.add_item("World Class", 3)
		_select_option_id(minimum_level_option, 0)

	if prize_fund != null:
		prize_fund.min_value = 0.0
		prize_fund.max_value = 10000000.0
		prize_fund.step = 500.0
		prize_fund.value = 100000.0

	if ai_handling_option != null:
		ai_handling_option.clear()
		ai_handling_option.add_item("Watch AI games", AI_HANDLING_WATCH)
		ai_handling_option.add_item("Skip AI games", AI_HANDLING_SKIP)
		_select_option_id(ai_handling_option, AI_HANDLING_WATCH)

	_update_tournament_controls_visibility()


func _connect_start_button() -> void:
	var start_button: BaseButton = get_node_or_null(start_button_path) as BaseButton

	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)


func _hold_match_for_setup() -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)

	if throw_controller != null:
		throw_controller.call("hold_for_setup")


func _on_start_pressed() -> void:
	if _selected_option_id(mode_option_path, MODE_SINGLE_MATCH) == MODE_KNOCKOUT_TOURNAMENT:
		_start_tournament()
		return

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
		_selected_toggle_pressed(double_in_toggle_path, false)
	)
	visible = false


func _start_tournament() -> void:
	var tournament_controller: Node = get_node_or_null(tournament_controller_path)

	if tournament_controller == null:
		visible = false
		return

	tournament_controller.call("start_tournament", {
		"participant_count": _selected_option_id(participant_option_path, 16),
		"seed_count": _selected_spin_value(seed_count_path, 4),
		"minimum_level": _selected_minimum_level_name(),
		"prize_fund": _selected_spin_value(prize_fund_path, 100000),
		"watch_ai_matches": _selected_option_id(ai_handling_option_path, AI_HANDLING_WATCH) == AI_HANDLING_WATCH,
		"starting_score": _selected_option_id(score_option_path, 501),
		"match_format": _selected_option_id(format_option_path, MATCH_FORMAT_LEGS),
		"best_of_count": _selected_best_of_count(),
		"starting_thrower": _selected_option_id(starter_option_path, START_THROWER_RANDOM),
		"double_in": _selected_toggle_pressed(double_in_toggle_path, false)
	})
	visible = false


func _selected_minimum_level_name() -> String:
	match _selected_option_id(minimum_level_option_path, 0):
		1:
			return "County"
		2:
			return "Pro"
		3:
			return "World Class"
		_:
			return "Amateur"


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


func _on_mode_changed(_index: int) -> void:
	_update_tournament_controls_visibility()


func _on_participant_count_changed(_index: int) -> void:
	var seed_count: SpinBox = get_node_or_null(seed_count_path) as SpinBox

	if seed_count == null:
		return

	seed_count.max_value = float(_selected_option_id(participant_option_path, 16))
	seed_count.value = minf(seed_count.value, seed_count.max_value)


func _update_tournament_controls_visibility() -> void:
	var tournament_mode: bool = _selected_option_id(mode_option_path, MODE_SINGLE_MATCH) == MODE_KNOCKOUT_TOURNAMENT
	var tournament_nodes: Array[NodePath] = [
		"Panel/ParticipantLabel",
		participant_option_path,
		"Panel/SeedLabel",
		seed_count_path,
		"Panel/MinimumLevelLabel",
		minimum_level_option_path,
		"Panel/PrizeFundLabel",
		prize_fund_path,
		"Panel/AIHandlingLabel",
		ai_handling_option_path
	]
	var start_button: Button = get_node_or_null(start_button_path) as Button
	var title: Label = get_node_or_null("Panel/Header/Title") as Label

	for path in tournament_nodes:
		var item: CanvasItem = get_node_or_null(path) as CanvasItem

		if item != null:
			item.visible = tournament_mode

	if start_button != null:
		start_button.text = "Start Tournament" if tournament_mode else "Start Match"

	if title != null:
		title.text = "EXHIBITION SETUP"


func _ensure_extra_controls() -> void:
	var panel: Control = get_node_or_null("Panel") as Control

	if panel == null:
		return

	_ensure_label(panel, "ModeLabel", "MODE", Vector2(54.0, 76.0))
	_ensure_option(panel, "ModeOption", Vector2(310.0, 72.0))
	_move_existing_match_controls()
	_ensure_label(panel, "ParticipantLabel", "PARTICIPANTS", Vector2(54.0, 490.0))
	_ensure_option(panel, "ParticipantOption", Vector2(310.0, 486.0))
	_ensure_label(panel, "SeedLabel", "SEEDS", Vector2(54.0, 542.0))
	_ensure_spin(panel, "SeedCount", Vector2(310.0, 538.0))
	_ensure_label(panel, "MinimumLevelLabel", "MIN LEVEL", Vector2(54.0, 594.0))
	_ensure_option(panel, "MinimumLevelOption", Vector2(310.0, 590.0))
	_ensure_label(panel, "PrizeFundLabel", "PRIZE FUND", Vector2(54.0, 646.0))
	_ensure_spin(panel, "PrizeFund", Vector2(310.0, 642.0))
	_ensure_label(panel, "AIHandlingLabel", "AI GAMES", Vector2(54.0, 698.0))
	_ensure_option(panel, "AIHandlingOption", Vector2(310.0, 694.0))

	var start_button: Control = get_node_or_null(start_button_path) as Control

	if start_button != null:
		start_button.position = Vector2(352.0, 744.0)


func _move_existing_match_controls() -> void:
	var move_map: Dictionary = {
		"Panel/ScoreLabel": 128.0,
		"Panel/ScoreOption": 124.0,
		"Panel/FormatLabel": 180.0,
		"Panel/FormatOption": 176.0,
		"Panel/BestOfLabel": 232.0,
		"Panel/BestOfOption": 228.0,
		"Panel/CustomTargetLabel": 284.0,
		"Panel/CustomTarget": 280.0,
		"Panel/StarterLabel": 336.0,
		"Panel/StarterOption": 332.0,
		"Panel/DoubleInLabel": 388.0,
		"Panel/DoubleInToggle": 382.0
	}

	for path in move_map.keys():
		var control: Control = get_node_or_null(path) as Control

		if control != null:
			control.position.y = float(move_map[path])

	var hint: Control = get_node_or_null("Panel/SetsHint") as Control

	if hint != null:
		hint.position.y = 436.0


func _ensure_label(parent: Control, node_name: String, text: String, position: Vector2) -> void:
	if parent.get_node_or_null(node_name) != null:
		return

	var label := Label.new()
	label.name = node_name
	label.text = text
	label.position = position
	label.size = Vector2(206.0, 34.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.76, 0.78, 0.95, 1.0))
	label.add_theme_font_size_override("font_size", 18)
	parent.add_child(label)


func _ensure_option(parent: Control, node_name: String, position: Vector2) -> void:
	if parent.get_node_or_null(node_name) != null:
		return

	var option := OptionButton.new()
	option.name = node_name
	option.position = position
	option.size = Vector2(256.0, 42.0)
	option.add_theme_font_size_override("font_size", 18)
	parent.add_child(option)


func _ensure_spin(parent: Control, node_name: String, position: Vector2) -> void:
	if parent.get_node_or_null(node_name) != null:
		return

	var spin := SpinBox.new()
	spin.name = node_name
	spin.position = position
	spin.size = Vector2(256.0, 42.0)
	parent.add_child(spin)
