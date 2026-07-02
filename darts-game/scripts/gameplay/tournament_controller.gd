extends Control
class_name TournamentController

const MATCH_FORMAT_LEGS: int = 0
const MATCH_FORMAT_SETS: int = 1
const START_THROWER_PLAYER: int = 0
const START_THROWER_AI: int = 1
const START_THROWER_RANDOM: int = 2

const AI_HANDLING_WATCH: int = 0
const AI_HANDLING_SKIP: int = 1

const LEVEL_ORDER: Dictionary = {
	"Amateur": 0,
	"County": 1,
	"Pro": 2,
	"World Class": 3
}

const LEVEL_NAMES: Array[String] = ["Amateur", "County", "Pro", "World Class"]

const PANEL_COLOR: Color = Color(0.075, 0.08, 0.13, 0.98)
const FRAME_COLOR: Color = Color(0.015, 0.018, 0.03, 0.35)
const HEADER_COLOR: Color = Color(0.72, 0.02, 0.06, 1.0)
const MATCH_COLOR: Color = Color(0.10, 0.105, 0.17, 0.98)
const MATCH_COMPLETE_COLOR: Color = Color(0.15, 0.13, 0.23, 0.98)
const PLAYER_COLOR: Color = Color(0.98, 0.72, 0.18, 1.0)
const TEXT_COLOR: Color = Color(0.98, 0.97, 0.92, 1.0)
const MUTED_TEXT_COLOR: Color = Color(0.72, 0.74, 0.95, 1.0)

## ThrowController used to run watched tournament fixtures on the board.
@export var throw_controller_path: NodePath = NodePath("../ThrowLayer")
## Match setup modal hidden while the tournament bracket is open.
@export var setup_modal_path: NodePath = NodePath("../MatchSetupModal")

var _settings: Dictionary = {}
var _entrants: Array[Dictionary] = []
var _rounds: Array[Array] = []
var _current_round_index: int = 0
var _current_match_index: int = 0
var _match_in_progress: bool = false

var _panel: ColorRect
var _title_label: Label
var _meta_label: Label
var _bracket_scroll: ScrollContainer
var _bracket_grid: GridContainer
var _action_button: Button
var _skip_all_button: Button
var _close_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_screen()
	visible = false
	_connect_throw_controller()


func start_tournament(settings: Dictionary) -> void:
	_settings = settings.duplicate(true)
	_match_in_progress = false
	_generate_field()
	_generate_first_round()
	_current_round_index = 0
	_current_match_index = 0
	visible = true
	move_to_front()
	_render_bracket()
	_auto_skip_ai_matches_if_enabled()


func _build_screen() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	offset_right = 1920.0
	offset_bottom = 1080.0

	var backdrop := ColorRect.new()
	backdrop.name = "Backdrop"
	backdrop.color = Color(0.0, 0.0, 0.0, 0.62)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)

	_panel = ColorRect.new()
	_panel.name = "Panel"
	_panel.color = PANEL_COLOR
	_panel.position = Vector2(92.0, 78.0)
	_panel.size = Vector2(1736.0, 924.0)
	add_child(_panel)

	var frame := ColorRect.new()
	frame.name = "Frame"
	frame.color = FRAME_COLOR
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.add_child(frame)

	var header := ColorRect.new()
	header.name = "Header"
	header.color = HEADER_COLOR
	header.size = Vector2(1736.0, 62.0)
	_panel.add_child(header)

	_title_label = _make_label("KNOCKOUT TOURNAMENT", 28, TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_title_label.position = Vector2(28.0, 0.0)
	_title_label.size = Vector2(1160.0, 62.0)
	header.add_child(_title_label)

	_meta_label = _make_label("", 16, MUTED_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_meta_label.position = Vector2(30.0, 84.0)
	_meta_label.size = Vector2(1380.0, 34.0)
	_panel.add_child(_meta_label)

	_bracket_scroll = ScrollContainer.new()
	_bracket_scroll.name = "BracketScroll"
	_bracket_scroll.position = Vector2(30.0, 132.0)
	_bracket_scroll.size = Vector2(1676.0, 690.0)
	_bracket_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_bracket_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_panel.add_child(_bracket_scroll)

	_bracket_grid = GridContainer.new()
	_bracket_grid.name = "BracketGrid"
	_bracket_grid.columns = 1
	_bracket_grid.add_theme_constant_override("h_separation", 18)
	_bracket_grid.add_theme_constant_override("v_separation", 12)
	_bracket_scroll.add_child(_bracket_grid)

	_action_button = _make_button("Watch Next")
	_action_button.position = Vector2(1236.0, 846.0)
	_action_button.size = Vector2(210.0, 46.0)
	_action_button.pressed.connect(_on_next_match_pressed)
	_panel.add_child(_action_button)

	_skip_all_button = _make_button("Skip AI Matches")
	_skip_all_button.position = Vector2(986.0, 846.0)
	_skip_all_button.size = Vector2(220.0, 46.0)
	_skip_all_button.pressed.connect(_on_skip_ai_matches_pressed)
	_panel.add_child(_skip_all_button)

	_close_button = _make_button("Close")
	_close_button.position = Vector2(1476.0, 846.0)
	_close_button.size = Vector2(230.0, 46.0)
	_close_button.pressed.connect(_on_close_pressed)
	_panel.add_child(_close_button)


func _connect_throw_controller() -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)

	if throw_controller != null and throw_controller.has_signal("match_complete"):
		throw_controller.connect("match_complete", _on_board_match_complete)


func _generate_field() -> void:
	_entrants.clear()

	var participant_count: int = int(_settings.get("participant_count", 16))
	var seed_count: int = clampi(int(_settings.get("seed_count", 4)), 0, participant_count)
	var min_level: String = str(_settings.get("minimum_level", "Amateur"))
	var roster: Array[CharacterResource] = CharacterRoster.generate_default_roster()
	var filtered_roster: Array[CharacterResource] = _filter_roster_by_level(roster, min_level)
	var human_profile: CharacterResource = CharacterRoster.random_character(filtered_roster)

	_entrants.append(_make_entrant(0, human_profile, true))

	while _entrants.size() < participant_count:
		var profile: CharacterResource = CharacterRoster.random_character(filtered_roster)

		if _profile_already_used(profile):
			continue

		_entrants.append(_make_entrant(_entrants.size(), profile, false))

	_entrants.sort_custom(_sort_entrants_by_strength)

	for index in range(_entrants.size()):
		_entrants[index]["seed"] = index + 1 if index < seed_count else 0

	_entrants = _seeded_draw_order(_entrants, seed_count)


func _filter_roster_by_level(roster: Array[CharacterResource], min_level: String) -> Array[CharacterResource]:
	var filtered: Array[CharacterResource] = []
	var min_index: int = int(LEVEL_ORDER.get(min_level, 0))

	for profile in roster:
		if _level_index_for_profile(profile) >= min_index:
			filtered.append(profile)

	if filtered.is_empty():
		return roster

	return filtered


func _level_index_for_profile(profile: CharacterResource) -> int:
	if profile == null:
		return 0

	var midpoint: float = (profile.average_min + profile.average_max) * 0.5

	if midpoint >= 92.0:
		return 3
	if midpoint >= 65.0:
		return 2
	if midpoint >= 30.0:
		return 1

	return 0


func _make_entrant(id: int, profile: CharacterResource, is_human: bool) -> Dictionary:
	return {
		"id": id,
		"profile": profile,
		"is_human": is_human,
		"seed": 0,
		"prize": 0,
		"eliminated_in": ""
	}


func _profile_already_used(profile: CharacterResource) -> bool:
	for entrant in _entrants:
		if entrant.get("profile") == profile:
			return true

	return false


func _sort_entrants_by_strength(a: Dictionary, b: Dictionary) -> bool:
	return _profile_strength(a.get("profile")) > _profile_strength(b.get("profile"))


func _profile_strength(profile: CharacterResource) -> float:
	if profile == null:
		return 0.0

	return (profile.average_min + profile.average_max) * 0.5


func _seeded_draw_order(entrants: Array[Dictionary], seed_count: int) -> Array[Dictionary]:
	var field_size: int = entrants.size()
	var ordered: Array = []
	var seeded_positions: Array[int] = _seed_positions(field_size)
	var unseeded: Array[Dictionary] = []
	var final_order: Array[Dictionary] = []

	ordered.resize(field_size)

	for index in range(entrants.size()):
		if index < seed_count:
			ordered[seeded_positions[index]] = entrants[index]
		else:
			unseeded.append(entrants[index])

	unseeded.shuffle()

	for index in range(field_size):
		if not (ordered[index] is Dictionary) or (ordered[index] as Dictionary).is_empty():
			ordered[index] = unseeded.pop_front()

	for value in ordered:
		final_order.append(value as Dictionary)

	return final_order


func _seed_positions(field_size: int) -> Array[int]:
	var positions: Array[int] = [0]

	while positions.size() < field_size:
		var next_positions: Array[int] = []
		var mirror: int = positions.size() * 2 - 1

		for position in positions:
			next_positions.append(position)
			next_positions.append(mirror - position)

		positions = next_positions

	return positions


func _generate_first_round() -> void:
	_rounds.clear()
	var first_round: Array[Dictionary] = []

	for index in range(0, _entrants.size(), 2):
		first_round.append(_make_match(0, first_round.size(), _entrants[index], _entrants[index + 1]))

	_rounds.append(first_round)


func _make_match(round_index: int, match_index: int, entrant_a: Dictionary, entrant_b: Dictionary) -> Dictionary:
	return {
		"round": round_index,
		"index": match_index,
		"a": entrant_a,
		"b": entrant_b,
		"winner": {},
		"loser": {},
		"scoreline": "",
		"complete": false,
		"watched": false
	}


func _render_bracket() -> void:
	_clear_children(_bracket_grid)
	_bracket_grid.columns = _rounds.size()
	_title_label.text = _tournament_title()
	_meta_label.text = _tournament_meta_text()

	for round_index in range(_rounds.size()):
		var column := VBoxContainer.new()
		column.custom_minimum_size = Vector2(300.0, 0.0)
		column.add_theme_constant_override("separation", 10)
		_bracket_grid.add_child(column)

		var round_label := _make_label(_round_name(round_index), 18, MUTED_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		round_label.custom_minimum_size = Vector2(300.0, 32.0)
		column.add_child(round_label)

		for match_value in _rounds[round_index]:
			var match_data: Dictionary = match_value as Dictionary
			column.add_child(_make_match_card(match_data))

	_update_action_buttons()


func _make_match_card(match_data: Dictionary) -> Control:
	var card := ColorRect.new()
	card.custom_minimum_size = Vector2(300.0, 92.0)
	card.color = MATCH_COMPLETE_COLOR if bool(match_data.get("complete", false)) else MATCH_COLOR

	var entrant_a: Dictionary = match_data["a"] as Dictionary
	var entrant_b: Dictionary = match_data["b"] as Dictionary

	var a_label := _make_label(_entrant_label(entrant_a), 15, _entrant_color(entrant_a, match_data), HORIZONTAL_ALIGNMENT_LEFT)
	a_label.position = Vector2(10.0, 8.0)
	a_label.size = Vector2(280.0, 26.0)
	card.add_child(a_label)

	var b_label := _make_label(_entrant_label(entrant_b), 15, _entrant_color(entrant_b, match_data), HORIZONTAL_ALIGNMENT_LEFT)
	b_label.position = Vector2(10.0, 34.0)
	b_label.size = Vector2(280.0, 26.0)
	card.add_child(b_label)

	var score_label := _make_label(str(match_data.get("scoreline", "Awaiting match")), 13, MUTED_TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	score_label.position = Vector2(10.0, 62.0)
	score_label.size = Vector2(280.0, 24.0)
	card.add_child(score_label)

	return card


func _entrant_label(entrant: Dictionary) -> String:
	var profile: CharacterResource = entrant.get("profile") as CharacterResource
	var name: String = profile.display_name if profile != null else "TBC"
	var seed: int = int(entrant.get("seed", 0))

	if bool(entrant.get("is_human", false)):
		name = "PLAYER (%s)" % _level_name_for_profile(profile)

	if seed > 0:
		name = "(%d) %s" % [seed, name]

	if bool(entrant.get("is_human", false)):
		name = "%s  YOU" % name

	return name


func _level_name_for_profile(profile: CharacterResource) -> String:
	var level_index: int = clampi(_level_index_for_profile(profile), 0, LEVEL_NAMES.size() - 1)
	return LEVEL_NAMES[level_index]


func _entrant_color(entrant: Dictionary, match_data: Dictionary) -> Color:
	if bool(entrant.get("is_human", false)):
		return PLAYER_COLOR

	if bool(match_data.get("complete", false)):
		var winner: Dictionary = match_data.get("winner", {}) as Dictionary

		if int(winner.get("id", -1)) == int(entrant.get("id", -2)):
			return TEXT_COLOR

		return Color(0.52, 0.53, 0.62, 1.0)

	return TEXT_COLOR


func _update_action_buttons() -> void:
	var next_match: Dictionary = _next_pending_match()
	var complete: bool = _is_tournament_complete()

	_action_button.disabled = next_match.is_empty() or complete
	_skip_all_button.disabled = complete

	if complete:
		_action_button.text = "Complete"
		_skip_all_button.text = "Tournament Done"
	else:
		_action_button.text = "Watch Next"
		_skip_all_button.text = "Skip AI Matches"


func _on_next_match_pressed() -> void:
	if _match_in_progress:
		return

	var match_data: Dictionary = _next_pending_match()

	if match_data.is_empty():
		return

	_start_board_match(match_data, _match_has_human(match_data))


func _on_skip_ai_matches_pressed() -> void:
	if _match_in_progress:
		return

	_skip_ai_matches_until_human_or_complete()
	_render_bracket()


func _skip_ai_matches_until_human_or_complete() -> void:
	while true:
		var match_data: Dictionary = _next_pending_match()

		if match_data.is_empty() or _match_has_human(match_data):
			break

		_resolve_simulated_match(match_data)


func _auto_skip_ai_matches_if_enabled() -> void:
	if bool(_settings.get("watch_ai_matches", true)):
		return

	_skip_ai_matches_until_human_or_complete()
	_render_bracket()


func _on_close_pressed() -> void:
	visible = false
	var setup_modal: CanvasItem = get_node_or_null(setup_modal_path) as CanvasItem

	if setup_modal != null:
		setup_modal.visible = true


func _start_board_match(match_data: Dictionary, human_controls: bool) -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)

	if throw_controller == null:
		_resolve_simulated_match(match_data)
		_render_bracket()
		return

	_match_in_progress = true
	visible = false

	var human_slot: String = _human_slot_for_match(match_data)
	var board_player_slot: String = human_slot if human_slot != "" else "a"
	var board_ai_slot: String = _opposite_slot(board_player_slot)
	var board_player_entrant: Dictionary = _entrant_for_slot(match_data, board_player_slot)
	var board_ai_entrant: Dictionary = _entrant_for_slot(match_data, board_ai_slot)
	var board_player_profile: CharacterResource = board_player_entrant.get("profile") as CharacterResource
	var board_ai_profile: CharacterResource = board_ai_entrant.get("profile") as CharacterResource
	var human_controls_enabled: bool = human_controls and human_slot != ""
	var context: Dictionary = {
		"round": int(match_data["round"]),
		"index": int(match_data["index"]),
		"match": match_data,
		"human_slot": human_slot,
		"board_player_slot": board_player_slot,
		"board_ai_slot": board_ai_slot
	}

	_log_match_launch(match_data, board_player_slot, board_ai_slot, human_controls_enabled)

	throw_controller.call(
		"configure_match_with_profiles",
		board_player_profile,
		board_ai_profile,
		int(_settings.get("starting_score", 501)),
		int(_settings.get("match_format", MATCH_FORMAT_LEGS)),
		int(_settings.get("best_of_count", 5)),
		int(_settings.get("starting_thrower", START_THROWER_RANDOM)),
		bool(_settings.get("double_in", false)),
		human_controls_enabled,
		false,
		context
	)


func _on_board_match_complete(result: Dictionary) -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)
	var context: Dictionary = result.get("context", {}) as Dictionary

	if not context.has("match"):
		return

	var match_data: Dictionary = context["match"] as Dictionary
	var winner_side: int = int(result.get("winner", 0))
	var board_player_slot: String = str(context.get("board_player_slot", "a"))
	var board_ai_slot: String = str(context.get("board_ai_slot", _opposite_slot(board_player_slot)))
	var winner_slot: String = board_player_slot if winner_side == 0 else board_ai_slot
	var loser_slot: String = _opposite_slot(winner_slot)
	var winner: Dictionary = _entrant_for_slot(match_data, winner_slot)
	var loser: Dictionary = _entrant_for_slot(match_data, loser_slot)
	var board_player_score: int = int(result.get("player_legs", 0))
	var board_ai_score: int = int(result.get("ai_legs", 0))

	if int(_settings.get("match_format", MATCH_FORMAT_LEGS)) == MATCH_FORMAT_SETS:
		board_player_score = int(result.get("player_sets", board_player_score))
		board_ai_score = int(result.get("ai_sets", board_ai_score))

	var score_a: int = board_player_score if board_player_slot == "a" else board_ai_score
	var score_b: int = board_ai_score if board_player_slot == "a" else board_player_score

	_log_match_result(match_data, winner_slot, board_player_slot, board_ai_slot, score_a, score_b)
	_complete_match(match_data, winner, loser, "%d-%d" % [score_a, score_b], true)
	_match_in_progress = false

	if throw_controller != null and throw_controller.has_method("hold_for_setup"):
		throw_controller.call("hold_for_setup")

	visible = true
	move_to_front()
	_render_bracket()
	_auto_skip_ai_matches_if_enabled()


func _resolve_simulated_match(match_data: Dictionary) -> void:
	var entrant_a: Dictionary = match_data["a"] as Dictionary
	var entrant_b: Dictionary = match_data["b"] as Dictionary
	var profile_a: CharacterResource = entrant_a.get("profile") as CharacterResource
	var profile_b: CharacterResource = entrant_b.get("profile") as CharacterResource
	var target: int = int(floor(float(int(_settings.get("best_of_count", 5))) / 2.0)) + 1
	var score_a: int = 0
	var score_b: int = 0

	while score_a < target and score_b < target:
		if _simulate_leg(profile_a, profile_b) == 0:
			score_a += 1
		else:
			score_b += 1

	var winner: Dictionary = entrant_a if score_a > score_b else entrant_b
	var loser: Dictionary = entrant_b if score_a > score_b else entrant_a

	_complete_match(match_data, winner, loser, "%d-%d sim" % [score_a, score_b], false)


func _simulate_leg(profile_a: CharacterResource, profile_b: CharacterResource) -> int:
	var score_a: int = int(_settings.get("starting_score", 501))
	var score_b: int = int(_settings.get("starting_score", 501))
	var turn: int = randi() % 2
	var guard: int = 0

	while guard < 80:
		guard += 1
		var profile: CharacterResource = profile_a if turn == 0 else profile_b
		var current_score: int = score_a if turn == 0 else score_b
		var visit: int = _simulate_visit(profile, current_score)

		if visit == current_score and _is_checkout_visit(profile, current_score):
			return turn

		var next_score: int = current_score - visit

		if next_score < 2:
			turn = 1 - turn
			continue

		if turn == 0:
			score_a = next_score
		else:
			score_b = next_score

		turn = 1 - turn

	return 0 if _profile_strength(profile_a) >= _profile_strength(profile_b) else 1


func _simulate_visit(profile: CharacterResource, current_score: int) -> int:
	if profile == null:
		return 45

	if current_score <= 170 and _checkout_chance(profile, current_score) > randf():
		return current_score

	var average: float = randf_range(profile.average_min, profile.average_max)
	var swing: float = randf_range(-profile.variance, profile.variance)
	var hot_bonus: float = randf_range(20.0, 55.0) if randf() < profile.maximum_appetite * 0.06 else 0.0
	var visit: int = clampi(int(round(average + swing + hot_bonus)), 0, 180)

	if current_score - visit == 1 or current_score - visit < 0:
		visit = clampi(current_score - 2, 0, 180)

	return visit


func _checkout_chance(profile: CharacterResource, score: int) -> float:
	if score < 2 or score > 170:
		return 0.0

	var route_penalty: float = 0.34 if score > 100 else 0.0
	return clampf(profile.double_consistency * profile.nerve - route_penalty, 0.02, 0.78)


func _is_checkout_visit(profile: CharacterResource, score: int) -> bool:
	return score >= 2 and score <= 170 and randf() < _checkout_chance(profile, score)


func _complete_match(match_data: Dictionary, winner: Dictionary, loser: Dictionary, scoreline: String, watched: bool) -> void:
	match_data["winner"] = winner
	match_data["loser"] = loser
	match_data["scoreline"] = scoreline
	match_data["complete"] = true
	match_data["watched"] = watched
	_assign_loser_prize(loser, _placing_label_for_round(int(match_data["round"])))
	_advance_winner(match_data, winner)


func _advance_winner(match_data: Dictionary, winner: Dictionary) -> void:
	var round_index: int = int(match_data["round"])
	var match_index: int = int(match_data["index"])

	if _rounds[round_index].size() == 1:
		_assign_winner_prize(winner)
		return

	var next_round_index: int = round_index + 1

	if _rounds.size() <= next_round_index:
		_rounds.append([])

	var next_match_index: int = int(floor(float(match_index) / 2.0))

	while _rounds[next_round_index].size() <= next_match_index:
		_rounds[next_round_index].append(_make_match(next_round_index, _rounds[next_round_index].size(), {}, {}))

	var next_match: Dictionary = _rounds[next_round_index][next_match_index]

	if match_index % 2 == 0:
		next_match["a"] = winner
	else:
		next_match["b"] = winner


func _assign_loser_prize(loser: Dictionary, placing_label: String) -> void:
	var breakdown: Dictionary = _prize_breakdown()
	loser["eliminated_in"] = placing_label
	loser["prize"] = int(breakdown.get(placing_label, 0))


func _assign_winner_prize(winner: Dictionary) -> void:
	var breakdown: Dictionary = _prize_breakdown()
	winner["eliminated_in"] = "Winner"
	winner["prize"] = int(breakdown.get("Winner", 0))


func _prize_breakdown() -> Dictionary:
	var data := TournamentData.new()
	data.participant_count = float(int(_settings.get("participant_count", 16)))
	data.seeded_player_count = float(int(_settings.get("seed_count", 4)))
	data.tournament_total_prize = int(_settings.get("prize_fund", 100000))
	data.tournament_type = TournamentData.TournamentType.KNOCKOUT
	data.bye_policy = TournamentData.ByePolicy.REQUIRE_POWER_OF_TWO
	return data.prize_breakdown()


func _placing_label_for_round(round_index: int) -> String:
	var remaining_players: int = int(_settings.get("participant_count", 16)) / int(pow(2.0, round_index))

	match remaining_players:
		2:
			return "Runner-up"
		4:
			return "Semi-finalists"
		8:
			return "Quarter-finalists"
		_:
			return "Last %d" % remaining_players


func _next_pending_match() -> Dictionary:
	for round_value in _rounds:
		var round_matches: Array = round_value as Array

		for match_value in round_matches:
			var match_data: Dictionary = match_value as Dictionary

			if bool(match_data.get("complete", false)):
				continue

			var entrant_a: Dictionary = match_data.get("a", {}) as Dictionary
			var entrant_b: Dictionary = match_data.get("b", {}) as Dictionary

			if entrant_a.is_empty() or entrant_b.is_empty():
				return {}

			return match_data

	return {}


func _entrant_for_slot(match_data: Dictionary, slot: String) -> Dictionary:
	var normalized_slot: String = "b" if slot == "b" else "a"
	return match_data.get(normalized_slot, {}) as Dictionary


func _opposite_slot(slot: String) -> String:
	return "a" if slot == "b" else "b"


func _human_slot_for_match(match_data: Dictionary) -> String:
	if _entrant_is_human(_entrant_for_slot(match_data, "a")):
		return "a"

	if _entrant_is_human(_entrant_for_slot(match_data, "b")):
		return "b"

	return ""


func _entrant_is_human(entrant: Dictionary) -> bool:
	return bool(entrant.get("is_human", false))


func _entrant_debug_name(entrant: Dictionary) -> String:
	var profile: CharacterResource = entrant.get("profile") as CharacterResource
	var name: String = profile.display_name if profile != null else "TBC"

	if _entrant_is_human(entrant):
		name = "PLAYER (%s)" % _level_name_for_profile(profile)

	return name


func _log_match_launch(match_data: Dictionary, board_player_slot: String, board_ai_slot: String, human_controls_enabled: bool) -> void:
	var human_slot: String = _human_slot_for_match(match_data)
	var entrant_a: Dictionary = _entrant_for_slot(match_data, "a")
	var entrant_b: Dictionary = _entrant_for_slot(match_data, "b")

	if bool(human_controls_enabled) and human_slot == "":
		push_warning("Tournament tried to enable human controls for a match with no human entrant.")

	print("Tournament launch R%d M%d | human_slot=%s | board_player_slot=%s | board_ai_slot=%s | controls=%s | A=%s human=%s | B=%s human=%s" % [
		int(match_data.get("round", 0)) + 1,
		int(match_data.get("index", 0)) + 1,
		human_slot if human_slot != "" else "none",
		board_player_slot.to_upper(),
		board_ai_slot.to_upper(),
		str(human_controls_enabled),
		_entrant_debug_name(entrant_a),
		str(_entrant_is_human(entrant_a)),
		_entrant_debug_name(entrant_b),
		str(_entrant_is_human(entrant_b))
	])


func _log_match_result(match_data: Dictionary, winner_slot: String, board_player_slot: String, board_ai_slot: String, score_a: int, score_b: int) -> void:
	var winner: Dictionary = _entrant_for_slot(match_data, winner_slot)

	print("Tournament result R%d M%d | winner_slot=%s | winner=%s human=%s | board_player_slot=%s | board_ai_slot=%s | scoreline A-B=%d-%d" % [
		int(match_data.get("round", 0)) + 1,
		int(match_data.get("index", 0)) + 1,
		winner_slot.to_upper(),
		_entrant_debug_name(winner),
		str(_entrant_is_human(winner)),
		board_player_slot.to_upper(),
		board_ai_slot.to_upper(),
		score_a,
		score_b
	])


func _match_has_human(match_data: Dictionary) -> bool:
	return _human_slot_for_match(match_data) != ""


func _is_tournament_complete() -> bool:
	if _rounds.is_empty():
		return false

	var final_round: Array = _rounds[_rounds.size() - 1]

	return final_round.size() == 1 and bool((final_round[0] as Dictionary).get("complete", false))


func _round_name(round_index: int) -> String:
	var remaining: int = int(_settings.get("participant_count", 16)) / int(pow(2.0, round_index))

	match remaining:
		2:
			return "FINAL"
		4:
			return "SEMI-FINALS"
		8:
			return "QUARTER-FINALS"
		_:
			return "LAST %d" % remaining


func _tournament_title() -> String:
	if _is_tournament_complete():
		var final_match: Dictionary = (_rounds[_rounds.size() - 1][0]) as Dictionary
		var winner: Dictionary = final_match.get("winner", {}) as Dictionary
		var profile: CharacterResource = winner.get("profile") as CharacterResource
		var winner_name: String = profile.display_name if profile != null else "Winner"
		return "%s WINS" % winner_name.to_upper()

	return "KNOCKOUT TOURNAMENT"


func _tournament_meta_text() -> String:
	return "%d players | %d seeds | Min %s | Prize %s | %s AI games" % [
		int(_settings.get("participant_count", 16)),
		int(_settings.get("seed_count", 4)),
		str(_settings.get("minimum_level", "Amateur")),
		_format_money(int(_settings.get("prize_fund", 100000))),
		"Watch" if bool(_settings.get("watch_ai_matches", true)) else "Skip"
	]


func _format_money(value: int) -> String:
	var text: String = str(value)
	var parts: PackedStringArray = PackedStringArray()

	while text.length() > 3:
		parts.insert(0, text.substr(text.length() - 3, 3))
		text = text.substr(0, text.length() - 3)

	parts.insert(0, text)
	return "$%s" % ",".join(parts)


func _make_label(text: String, font_size: int, color: Color, alignment: HorizontalAlignment) -> Label:
	var label := Label.new()
	label.text = text
	label.clip_text = true
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_size_override("font_size", 18)
	return button


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
