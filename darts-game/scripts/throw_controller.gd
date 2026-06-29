extends Node2D

signal dart_landed(result: Dictionary)
signal visit_complete(results: Array, total: int)

const THROW_PHASE_LOCK_HEIGHT: int = 0
const THROW_PHASE_LOCK_WIDTH: int = 1
const THROW_PHASE_LANDED: int = 2
const THROW_PHASE_AI_THROWING: int = 3
const THROW_PHASE_MATCH_COMPLETE: int = 4

const THROWER_PLAYER: int = 0
const THROWER_AI: int = 1
const MATCH_FORMAT_LEGS: int = 0
const MATCH_FORMAT_SETS: int = 1
const START_THROWER_PLAYER: int = 0
const START_THROWER_AI: int = 1
const START_THROWER_RANDOM: int = 2

const BOARD_NUMBERS: Array[int] = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
const AI_DART_LABELS: Array[String] = [
	"T20", "S20", "S1",
	"T19", "S20", "S5",
	"T20", "T20", "S20",
	"S19", "S19", "S7",
	"T20", "S20", "D10",
	"T20", "S5", "S1",
	"T19", "T18", "S20",
	"S20", "S20", "S20",
]
const ROUTE_DART_LABELS: Array[String] = [
	"T20", "T19", "T18", "T17", "T16", "T15", "T14", "T13", "T12", "T11",
	"T10", "T9", "T8", "T7", "T6", "T5", "T4", "T3", "T2", "T1",
	"25",
	"S20", "S19", "S18", "S17", "S16", "S15", "S14", "S13", "S12", "S11",
	"S10", "S9", "S8", "S7", "S6", "S5", "S4", "S3", "S2", "S1",
]
const FINISH_DART_LABELS: Array[String] = [
	"D20", "D18", "D16", "D12", "D10", "D8", "D4", "D2", "D1", "BULL",
	"D19", "D17", "D15", "D14", "D13", "D11", "D9", "D7", "D6", "D5", "D3",
]

const BOARD_CENTER_FALLBACK: Vector2 = Vector2(1410.0, 540.0)
const START_ANGLE: float = -PI / 2.0
const SECTOR_ANGLE: float = TAU / 20.0
const AIM_RADIUS: float = 415.0

const INNER_BULL_RADIUS: float = 14.0
const OUTER_BULL_RADIUS: float = 35.0
const TREBLE_INNER_RADIUS: float = 190.0
const TREBLE_OUTER_RADIUS: float = 222.0
const DOUBLE_INNER_RADIUS: float = 318.0
const DOUBLE_OUTER_RADIUS: float = 350.0

const AIM_LINE_COLOR: Color = Color(0.95, 0.88, 0.42, 0.96)
const LOCKED_LINE_COLOR: Color = Color(0.64, 0.72, 1.0, 0.76)
const GUIDE_RING_COLOR: Color = Color(0.70, 0.74, 1.0, 0.16)
const PLAYER_MARKER_COLOR: Color = Color(0.94, 0.08, 0.11, 1.0)
const AI_MARKER_COLOR: Color = Color(0.40, 0.54, 1.0, 1.0)
const BUST_MARKER_COLOR: Color = Color(1.0, 0.55, 0.12, 1.0)
const MARKER_PIN_COLOR: Color = Color(0.98, 0.94, 0.72, 1.0)
const MARKER_LABEL_COLOR: Color = Color(0.98, 0.97, 0.92, 1.0)

@export var dartboard_path: NodePath = NodePath("../Dartboard")
@export var scoreboard_presenter_path: NodePath = NodePath("../ScoreboardLayer")
@export var stats_summary_modal_path: NodePath = NodePath("../StatsSummaryModal")

@export_group("Match")
@export var starting_score: int = 501
@export_enum("Legs", "Sets") var match_format: int = MATCH_FORMAT_LEGS
@export var best_of_count: int = 5
@export_enum("Player", "AI", "Random") var starting_thrower_selection: int = START_THROWER_PLAYER
@export var double_in_enabled: bool = false
@export var legs_to_win: int = 3
@export var darts_per_visit: int = 3

@export_group("Throw Feel")
@export var vertical_speed: float = 430.0
@export var horizontal_speed: float = 500.0
@export var visible_wobble_pixels: float = 8.0
@export_range(0.0, 1.0, 0.01) var control_skill: float = 0.65
@export_range(0.0, 1.0, 0.01) var pressure: float = 0.25
@export var player_turn_end_delay: float = 0.65
@export var ai_dart_interval: float = 0.62
@export var ai_turn_end_delay: float = 0.78

@export_group("Scoreboard Labels")
@export var match_title_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/Header/MatchTitle")
@export var sets_header_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/Header/SetsHeader")
@export var legs_header_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/Header/LegsHeader")
@export var score_header_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/Header/ScoreHeader")
@export var player_sets_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/PlayerRow/Sets")
@export var ai_sets_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/AIRow/Sets")
@export var player_legs_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/PlayerRow/Legs")
@export var ai_legs_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/AIRow/Legs")
@export var player_score_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/PlayerRow/Score")
@export var ai_score_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/AIRow/Score")
@export var event_name_label_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard/EventBar/EventName")

@export_group("Checkout Route")
@export var show_player_checkout_route: bool = true
@export var show_ai_checkout_route: bool = true
@export var player_route_tile_1_label_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute/TopRouteTile1/TopRouteTile1Text")
@export var player_route_tile_2_label_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute/TopRouteTile2/TopRouteTile2Text")
@export var player_route_tile_3_label_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute/TopTile/TopTileText")
@export var ai_route_tile_1_label_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute/RouteTile1/RouteTile1Text")
@export var ai_route_tile_2_label_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute/RouteTile2/RouteTile2Text")
@export var ai_route_tile_3_label_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute/RouteTile3/RouteTile3Text")

@export_group("Stats Labels")
@export var player_visits_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/CurrentLeg/PlayerVisits")
@export var ai_visits_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/CurrentLeg/AIVisits")
@export var player_average_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/AveragePlayer")
@export var ai_average_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/AverageAI")
@export var player_first_nine_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/FirstNinePlayer")
@export var ai_first_nine_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/FirstNineAI")
@export var player_checkout_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/CheckoutPlayer")
@export var ai_checkout_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/CheckoutAI")
@export var player_high_checkout_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/HighCheckoutPlayer")
@export var ai_high_checkout_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/HighCheckoutAI")
@export var player_ton_plus_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/TonPlusPlayer")
@export var ai_ton_plus_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/TonPlusAI")
@export var player_one_forty_plus_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/OneFortyPlusPlayer")
@export var ai_one_forty_plus_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/OneFortyPlusAI")
@export var player_one_eighties_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/OneEightiesPlayer")
@export var ai_one_eighties_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/OneEightiesAI")
@export var player_darts_thrown_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/DartsThrownPlayer")
@export var ai_darts_thrown_label_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel/MatchStats/DartsThrownAI")

var _phase: int = THROW_PHASE_LOCK_HEIGHT
var _phase_time: float = 0.0
var _motion_time: float = 0.0
var _landed_time: float = 0.0
var _ai_wait_time: float = 0.0
var _locked_y: float = 0.0
var _locked_x: float = 0.0
var _current_dart: int = 1
var _visit_total: int = 0
var _results: Array[Dictionary] = []
var _active_thrower: int = THROWER_PLAYER
var _first_thrower: int = THROWER_PLAYER
var _next_leg_first_thrower: int = THROWER_PLAYER
var _player_score: int = 501
var _ai_score: int = 501
var _player_legs: int = 0
var _ai_legs: int = 0
var _player_sets: int = 0
var _ai_sets: int = 0
var _player_is_in: bool = true
var _ai_is_in: bool = true
var _turn_start_score: int = 501
var _player_visit_finished: bool = false
var _ai_visit_finished: bool = false
var _visit_finalized: bool = false
var _visit_bust: bool = false
var _visit_checkout: bool = false
var _visit_started_on_checkout: bool = false
var _leg_finished: bool = false
var _leg_winner: int = THROWER_PLAYER
var _match_finished: bool = false
var _match_input_enabled: bool = true
var _waiting_for_summary_continue: bool = false
var _ai_darts_thrown: int = 0
var _ai_dart_sequence_index: int = 0

var _player_total_points: int = 0
var _ai_total_points: int = 0
var _player_darts_thrown: int = 0
var _ai_darts_thrown_total: int = 0
var _player_first_nine_points: int = 0
var _ai_first_nine_points: int = 0
var _player_first_nine_darts: int = 0
var _ai_first_nine_darts: int = 0
var _player_checkout_attempts: int = 0
var _ai_checkout_attempts: int = 0
var _player_checkout_successes: int = 0
var _ai_checkout_successes: int = 0
var _player_high_checkout: int = 0
var _ai_high_checkout: int = 0
var _player_ton_plus: int = 0
var _ai_ton_plus: int = 0
var _player_one_forty_plus: int = 0
var _ai_one_forty_plus: int = 0
var _player_one_eighties: int = 0
var _ai_one_eighties: int = 0
var _player_leg_darts: int = 0
var _ai_leg_darts: int = 0
var _player_leg_first_nine_points: int = 0
var _ai_leg_first_nine_points: int = 0
var _player_leg_first_nine_darts: int = 0
var _ai_leg_first_nine_darts: int = 0
var _player_leg_checkout_attempts: int = 0
var _ai_leg_checkout_attempts: int = 0
var _player_leg_checkout_successes: int = 0
var _ai_leg_checkout_successes: int = 0
var _player_leg_high_checkout: int = 0
var _ai_leg_high_checkout: int = 0
var _player_leg_visits: Array[int] = []
var _ai_leg_visits: Array[int] = []
var _match_leg_summaries: Array[Dictionary] = []
var _current_set_leg_summaries: Array[Dictionary] = []
var _current_set_number: int = 1
var _font: Font


func _ready() -> void:
	randomize()
	_font = ThemeDB.fallback_font
	reset_match()
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_motion_time += delta

	if not _match_input_enabled:
		queue_redraw()
		return

	if _phase == THROW_PHASE_LANDED:
		_landed_time += delta

		if _player_visit_finished and _landed_time >= player_turn_end_delay:
			if _leg_finished:
				_complete_leg(_leg_winner)
			else:
				_begin_ai_visit()
		elif not _player_visit_finished and _landed_time >= 0.55 and _current_dart <= darts_per_visit:
			_start_height_lock()
	elif _phase == THROW_PHASE_AI_THROWING:
		_process_ai_turn(delta)
	elif _phase != THROW_PHASE_MATCH_COMPLETE:
		_phase_time += delta

	queue_redraw()


func _process_ai_turn(delta: float) -> void:
	_ai_wait_time += delta

	if _ai_visit_finished:
		if _ai_wait_time >= ai_turn_end_delay:
			_finish_ai_visit()

		return

	if _ai_wait_time >= ai_dart_interval:
		_ai_wait_time = 0.0
		_throw_ai_dart()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event: InputEventMouseButton = event as InputEventMouseButton
		var pointer_position: Vector2 = to_local(get_global_mouse_position())

		if _match_input_enabled and not _match_finished and _active_thrower == THROWER_PLAYER and mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed and _is_pointer_in_throw_area(pointer_position):
			_confirm_lock()
			get_viewport().set_input_as_handled()
	elif event is InputEventKey:
		var key_event: InputEventKey = event as InputEventKey

		if key_event.pressed and not key_event.echo:
			if _match_input_enabled and not _match_finished and _active_thrower == THROWER_PLAYER and key_event.keycode == KEY_SPACE:
				_confirm_lock()
				get_viewport().set_input_as_handled()
			elif key_event.keycode == KEY_R:
				reset_match()
				get_viewport().set_input_as_handled()


func hold_for_setup() -> void:
	_match_input_enabled = false
	_match_finished = true
	_phase = THROW_PHASE_MATCH_COMPLETE
	_results.clear()
	_set_presenter_value("checkout_route_visible", false)
	queue_redraw()


func configure_match(selected_starting_score: int, selected_match_format: int, selected_best_of_count: int, selected_starting_thrower: int, selected_double_in_enabled: bool) -> void:
	starting_score = selected_starting_score
	match_format = selected_match_format
	best_of_count = selected_best_of_count
	starting_thrower_selection = selected_starting_thrower
	double_in_enabled = selected_double_in_enabled
	legs_to_win = _target_match_count()
	_match_input_enabled = true
	reset_match()


func reset_match() -> void:
	_match_input_enabled = true
	_match_finished = false
	_player_legs = 0
	_ai_legs = 0
	_player_sets = 0
	_ai_sets = 0
	_current_set_number = 1
	_waiting_for_summary_continue = false
	_next_leg_first_thrower = _starting_thrower_from_selection()
	_ai_dart_sequence_index = 0
	_match_leg_summaries.clear()
	_current_set_leg_summaries.clear()
	_hide_stats_summary_modal()
	_reset_match_stats()
	_set_static_scoreboard_labels()
	_update_leg_labels()
	_reset_leg()


func _reset_match_stats() -> void:
	_player_total_points = 0
	_ai_total_points = 0
	_player_darts_thrown = 0
	_ai_darts_thrown_total = 0
	_player_first_nine_points = 0
	_ai_first_nine_points = 0
	_player_first_nine_darts = 0
	_ai_first_nine_darts = 0
	_player_checkout_attempts = 0
	_ai_checkout_attempts = 0
	_player_checkout_successes = 0
	_ai_checkout_successes = 0
	_player_high_checkout = 0
	_ai_high_checkout = 0
	_player_ton_plus = 0
	_ai_ton_plus = 0
	_player_one_forty_plus = 0
	_ai_one_forty_plus = 0
	_player_one_eighties = 0
	_ai_one_eighties = 0


func _reset_leg() -> void:
	_player_score = starting_score
	_ai_score = starting_score
	_player_leg_darts = 0
	_ai_leg_darts = 0
	_player_leg_first_nine_points = 0
	_ai_leg_first_nine_points = 0
	_player_leg_first_nine_darts = 0
	_ai_leg_first_nine_darts = 0
	_player_leg_checkout_attempts = 0
	_ai_leg_checkout_attempts = 0
	_player_leg_checkout_successes = 0
	_ai_leg_checkout_successes = 0
	_player_leg_high_checkout = 0
	_ai_leg_high_checkout = 0
	_player_is_in = not double_in_enabled
	_ai_is_in = not double_in_enabled
	_player_leg_visits.clear()
	_ai_leg_visits.clear()
	_leg_finished = false
	_leg_winner = THROWER_PLAYER
	_first_thrower = _next_leg_first_thrower
	_update_scoreboard_scores()
	_update_current_leg_labels()
	_update_stats_labels()
	_set_presenter_value("first_thrower", _first_thrower)

	if _first_thrower == THROWER_AI:
		_begin_ai_visit()
	else:
		_begin_player_visit()


func _begin_player_visit() -> void:
	_reset_visit_state(THROWER_PLAYER)
	_phase = THROW_PHASE_LOCK_HEIGHT
	_set_active_thrower(THROWER_PLAYER)


func _begin_ai_visit() -> void:
	_reset_visit_state(THROWER_AI)
	_phase = THROW_PHASE_AI_THROWING
	_ai_wait_time = 0.0
	_ai_darts_thrown = 0
	_ai_visit_finished = false
	_set_active_thrower(THROWER_AI)


func _reset_visit_state(thrower: int) -> void:
	_phase_time = 0.0
	_landed_time = 0.0
	_locked_y = 0.0
	_locked_x = 0.0
	_current_dart = 1
	_visit_total = 0
	_turn_start_score = _score_for_thrower(thrower)
	_player_visit_finished = false
	_ai_visit_finished = false
	_visit_finalized = false
	_visit_bust = false
	_visit_checkout = false
	_visit_started_on_checkout = _is_thrower_in(thrower) and _checkout_route_for_score(_turn_start_score, darts_per_visit).size() > 0
	_results.clear()
	queue_redraw()


func _complete_leg(winner: int) -> void:
	_record_completed_leg(winner)

	if winner == THROWER_PLAYER:
		_player_legs += 1
	else:
		_ai_legs += 1

	_update_leg_labels()
	_next_leg_first_thrower = THROWER_AI if _next_leg_first_thrower == THROWER_PLAYER else THROWER_PLAYER

	if match_format == MATCH_FORMAT_SETS:
		if _player_legs >= _legs_to_win_current_set() or _ai_legs >= _legs_to_win_current_set():
			_complete_set(winner)

			if _player_sets >= _target_match_count() or _ai_sets >= _target_match_count():
				_complete_match(winner)
				_show_stats_summary("MATCH COMPLETE", _match_leg_summaries, false)
				return

			_show_set_complete_summary(winner)
			return

		_reset_leg()
		return

	if _player_legs >= _target_match_count() or _ai_legs >= _target_match_count():
		_complete_match(winner)
		_show_stats_summary("MATCH COMPLETE", _match_leg_summaries, false)
		return

	_reset_leg()


func _complete_set(winner: int) -> void:
	if winner == THROWER_PLAYER:
		_player_sets += 1
	else:
		_ai_sets += 1

	_update_leg_labels()


func _complete_match(winner: int) -> void:
	_player_score = starting_score
	_ai_score = starting_score
	_match_finished = true
	_phase = THROW_PHASE_MATCH_COMPLETE
	_results.clear()
	_set_active_thrower(winner)
	_update_scoreboard_scores()
	_update_on_nine_badges()
	_set_presenter_value("checkout_route_visible", false)

	var winner_name: String = "PLAYER" if winner == THROWER_PLAYER else "AI"

	if match_format == MATCH_FORMAT_SETS:
		_set_label_text(match_title_label_path, "%s WINS %d-%d" % [winner_name, _player_sets, _ai_sets])
	else:
		_set_label_text(match_title_label_path, "%s WINS %d-%d" % [winner_name, _player_legs, _ai_legs])

	_set_label_text(event_name_label_path, "MATCH COMPLETE - PRESS R")


func _show_set_complete_summary(winner: int) -> void:
	_waiting_for_summary_continue = true
	_match_input_enabled = false
	_match_finished = true
	_phase = THROW_PHASE_MATCH_COMPLETE
	_results.clear()
	_set_active_thrower(winner)
	_set_presenter_value("checkout_route_visible", false)

	var winner_name: String = _thrower_name(winner)

	_set_label_text(match_title_label_path, "%s WINS SET %d" % [winner_name, _current_set_number])
	_set_label_text(event_name_label_path, "SET COMPLETE")
	_show_stats_summary("SET %d COMPLETE" % _current_set_number, _current_set_leg_summaries, true)


func continue_after_summary() -> void:
	if not _waiting_for_summary_continue:
		return

	_waiting_for_summary_continue = false
	_match_input_enabled = true
	_match_finished = false
	_player_legs = 0
	_ai_legs = 0
	_current_set_number += 1
	_current_set_leg_summaries.clear()
	_set_static_scoreboard_labels()
	_update_leg_labels()
	_reset_leg()


func _record_completed_leg(winner: int) -> void:
	var player_visits: Array[int] = _copy_int_array(_player_leg_visits)
	var ai_visits: Array[int] = _copy_int_array(_ai_leg_visits)
	var leg_number: int = _player_legs + _ai_legs + 1

	if match_format == MATCH_FORMAT_LEGS:
		leg_number = _match_leg_summaries.size() + 1

	var summary: Dictionary = {
		"set_number": _current_set_number,
		"leg_number": leg_number,
		"winner": winner,
		"player_visits": player_visits,
		"ai_visits": ai_visits,
		"player_points": _sum_visits(player_visits),
		"ai_points": _sum_visits(ai_visits),
		"player_darts": _player_leg_darts,
		"ai_darts": _ai_leg_darts,
		"player_first_nine_points": _player_leg_first_nine_points,
		"ai_first_nine_points": _ai_leg_first_nine_points,
		"player_first_nine_darts": _player_leg_first_nine_darts,
		"ai_first_nine_darts": _ai_leg_first_nine_darts,
		"player_checkout_attempts": _player_leg_checkout_attempts,
		"ai_checkout_attempts": _ai_leg_checkout_attempts,
		"player_checkout_successes": _player_leg_checkout_successes,
		"ai_checkout_successes": _ai_leg_checkout_successes,
		"player_high_checkout": _player_leg_high_checkout,
		"ai_high_checkout": _ai_leg_high_checkout,
		"player_ton_plus": _count_visits_at_least(player_visits, 100),
		"ai_ton_plus": _count_visits_at_least(ai_visits, 100),
		"player_one_forty_plus": _count_visits_at_least(player_visits, 140),
		"ai_one_forty_plus": _count_visits_at_least(ai_visits, 140),
		"player_one_eighties": _count_visits_equal(player_visits, 180),
		"ai_one_eighties": _count_visits_equal(ai_visits, 180)
	}

	_match_leg_summaries.append(summary)
	_current_set_leg_summaries.append(summary)


func _show_stats_summary(title: String, summaries: Array[Dictionary], continue_match: bool) -> void:
	var modal: Node = get_node_or_null(stats_summary_modal_path)

	if modal == null:
		if continue_match:
			continue_after_summary()

		return

	if modal.has_method("show_summary_data"):
		modal.call("show_summary_data", title, _summary_meta_text(summaries), _summary_stats_rows(summaries), _summary_breakdown_rows(summaries), continue_match)
	else:
		modal.call("show_summary", title, _summary_stats_text(summaries), _summary_breakdown_text(summaries), continue_match)


func _hide_stats_summary_modal() -> void:
	var modal: CanvasItem = get_node_or_null(stats_summary_modal_path) as CanvasItem

	if modal != null:
		modal.visible = false


func _summary_stats_text(summaries: Array[Dictionary]) -> String:
	var lines: PackedStringArray = PackedStringArray()

	lines.append(_summary_meta_text(summaries))

	for row_value in _summary_stats_rows(summaries):
		var row: Dictionary = row_value as Dictionary

		lines.append("%s: PLAYER %s | AI %s" % [str(row["label"]), str(row["player"]), str(row["ai"])])

	return "\n".join(lines)


func _summary_meta_text(summaries: Array[Dictionary]) -> String:
	var stats: Dictionary = _aggregate_summary_stats(summaries)
	var player_legs_won: int = int(stats["player_legs_won"])
	var ai_legs_won: int = int(stats["ai_legs_won"])
	var entry_rule: String = "Double in" if double_in_enabled else "Straight in"
	var format_text: String = "Best of %d %s" % [best_of_count, "sets" if match_format == MATCH_FORMAT_SETS else "legs"]

	return "%d start | %s | Double out | %s | Legs: PLAYER %d - %d AI" % [starting_score, entry_rule, format_text, player_legs_won, ai_legs_won]


func _summary_stats_rows(summaries: Array[Dictionary]) -> Array[Dictionary]:
	var stats: Dictionary = _aggregate_summary_stats(summaries)
	var rows: Array[Dictionary] = []

	rows.append({
		"label": "Legs won",
		"player": str(int(stats["player_legs_won"])),
		"ai": str(int(stats["ai_legs_won"]))
	})
	rows.append({
		"label": "3 dart average",
		"player": _format_average(int(stats["player_points"]), int(stats["player_darts"])),
		"ai": _format_average(int(stats["ai_points"]), int(stats["ai_darts"]))
	})
	rows.append({
		"label": "First 9 average",
		"player": _format_average(int(stats["player_first_nine_points"]), int(stats["player_first_nine_darts"])),
		"ai": _format_average(int(stats["ai_first_nine_points"]), int(stats["ai_first_nine_darts"]))
	})
	rows.append({
		"label": "Checkout %",
		"player": _format_checkout(int(stats["player_checkout_successes"]), int(stats["player_checkout_attempts"])),
		"ai": _format_checkout(int(stats["ai_checkout_successes"]), int(stats["ai_checkout_attempts"]))
	})
	rows.append({
		"label": "High checkout",
		"player": _format_high_checkout(int(stats["player_high_checkout"])),
		"ai": _format_high_checkout(int(stats["ai_high_checkout"]))
	})
	rows.append({
		"label": "100+",
		"player": str(int(stats["player_ton_plus"])),
		"ai": str(int(stats["ai_ton_plus"]))
	})
	rows.append({
		"label": "140+",
		"player": str(int(stats["player_one_forty_plus"])),
		"ai": str(int(stats["ai_one_forty_plus"]))
	})
	rows.append({
		"label": "180s",
		"player": str(int(stats["player_one_eighties"])),
		"ai": str(int(stats["ai_one_eighties"]))
	})
	rows.append({
		"label": "Darts thrown",
		"player": str(int(stats["player_darts"])),
		"ai": str(int(stats["ai_darts"]))
	})

	return rows


func _summary_breakdown_rows(summaries: Array[Dictionary]) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []

	for summary in summaries:
		var player_won: bool = int(summary["winner"]) == THROWER_PLAYER
		var ai_won: bool = not player_won
		var leg_title: String = "L%d" % int(summary["leg_number"])

		if match_format == MATCH_FORMAT_SETS:
			leg_title = "S%d L%d" % [int(summary["set_number"]), int(summary["leg_number"])]

		rows.append({
			"leg": leg_title,
			"thrower": "PLAYER",
			"visits": _summary_visits_text(summary, "player_visits"),
			"darts": str(int(summary["player_darts"])),
			"avg": _format_average(int(summary["player_points"]), int(summary["player_darts"])),
			"checkout": _format_checkout(int(summary["player_checkout_successes"]), int(summary["player_checkout_attempts"])),
			"won": player_won
		})
		rows.append({
			"leg": "",
			"thrower": "AI",
			"visits": _summary_visits_text(summary, "ai_visits"),
			"darts": str(int(summary["ai_darts"])),
			"avg": _format_average(int(summary["ai_points"]), int(summary["ai_darts"])),
			"checkout": _format_checkout(int(summary["ai_checkout_successes"]), int(summary["ai_checkout_attempts"])),
			"won": ai_won
		})

	return rows


func _aggregate_summary_stats(summaries: Array[Dictionary]) -> Dictionary:
	var stats: Dictionary = {
		"player_points": 0,
		"ai_points": 0,
		"player_darts": 0,
		"ai_darts": 0,
		"player_first_nine_points": 0,
		"ai_first_nine_points": 0,
		"player_first_nine_darts": 0,
		"ai_first_nine_darts": 0,
		"player_checkout_attempts": 0,
		"ai_checkout_attempts": 0,
		"player_checkout_successes": 0,
		"ai_checkout_successes": 0,
		"player_high_checkout": 0,
		"ai_high_checkout": 0,
		"player_ton_plus": 0,
		"ai_ton_plus": 0,
		"player_one_forty_plus": 0,
		"ai_one_forty_plus": 0,
		"player_one_eighties": 0,
		"ai_one_eighties": 0,
		"player_legs_won": 0,
		"ai_legs_won": 0
	}

	for summary in summaries:
		stats["player_points"] = int(stats["player_points"]) + int(summary["player_points"])
		stats["ai_points"] = int(stats["ai_points"]) + int(summary["ai_points"])
		stats["player_darts"] = int(stats["player_darts"]) + int(summary["player_darts"])
		stats["ai_darts"] = int(stats["ai_darts"]) + int(summary["ai_darts"])
		stats["player_first_nine_points"] = int(stats["player_first_nine_points"]) + int(summary["player_first_nine_points"])
		stats["ai_first_nine_points"] = int(stats["ai_first_nine_points"]) + int(summary["ai_first_nine_points"])
		stats["player_first_nine_darts"] = int(stats["player_first_nine_darts"]) + int(summary["player_first_nine_darts"])
		stats["ai_first_nine_darts"] = int(stats["ai_first_nine_darts"]) + int(summary["ai_first_nine_darts"])
		stats["player_checkout_attempts"] = int(stats["player_checkout_attempts"]) + int(summary["player_checkout_attempts"])
		stats["ai_checkout_attempts"] = int(stats["ai_checkout_attempts"]) + int(summary["ai_checkout_attempts"])
		stats["player_checkout_successes"] = int(stats["player_checkout_successes"]) + int(summary["player_checkout_successes"])
		stats["ai_checkout_successes"] = int(stats["ai_checkout_successes"]) + int(summary["ai_checkout_successes"])
		stats["player_high_checkout"] = maxi(int(stats["player_high_checkout"]), int(summary["player_high_checkout"]))
		stats["ai_high_checkout"] = maxi(int(stats["ai_high_checkout"]), int(summary["ai_high_checkout"]))
		stats["player_ton_plus"] = int(stats["player_ton_plus"]) + int(summary["player_ton_plus"])
		stats["ai_ton_plus"] = int(stats["ai_ton_plus"]) + int(summary["ai_ton_plus"])
		stats["player_one_forty_plus"] = int(stats["player_one_forty_plus"]) + int(summary["player_one_forty_plus"])
		stats["ai_one_forty_plus"] = int(stats["ai_one_forty_plus"]) + int(summary["ai_one_forty_plus"])
		stats["player_one_eighties"] = int(stats["player_one_eighties"]) + int(summary["player_one_eighties"])
		stats["ai_one_eighties"] = int(stats["ai_one_eighties"]) + int(summary["ai_one_eighties"])

		if int(summary["winner"]) == THROWER_PLAYER:
			stats["player_legs_won"] = int(stats["player_legs_won"]) + 1
		else:
			stats["ai_legs_won"] = int(stats["ai_legs_won"]) + 1

	return stats


func _summary_breakdown_text(summaries: Array[Dictionary]) -> String:
	var lines: PackedStringArray = PackedStringArray()

	if summaries.size() <= 0:
		return "No legs completed."

	for summary in summaries:
		var leg_title: String = "L%d" % int(summary["leg_number"])

		if match_format == MATCH_FORMAT_SETS:
			leg_title = "S%d L%d" % [int(summary["set_number"]), int(summary["leg_number"])]

		lines.append("%s - Winner: %s" % [leg_title, _thrower_name(int(summary["winner"]))])
		lines.append("PLAYER: %s | darts %d | avg %s | checkout %s" % [
			_summary_visits_text(summary, "player_visits"),
			int(summary["player_darts"]),
			_format_average(int(summary["player_points"]), int(summary["player_darts"])),
			_format_checkout(int(summary["player_checkout_successes"]), int(summary["player_checkout_attempts"]))
		])
		lines.append("AI: %s | darts %d | avg %s | checkout %s" % [
			_summary_visits_text(summary, "ai_visits"),
			int(summary["ai_darts"]),
			_format_average(int(summary["ai_points"]), int(summary["ai_darts"])),
			_format_checkout(int(summary["ai_checkout_successes"]), int(summary["ai_checkout_attempts"]))
		])
		lines.append("")

	return "\n".join(lines)


func _summary_visits_text(summary: Dictionary, key: String) -> String:
	var raw_visits: Array = summary[key] as Array
	var visits: Array[int] = []

	for value in raw_visits:
		visits.append(int(value))

	return _join_visits(visits)


func _copy_int_array(source: Array[int]) -> Array[int]:
	var copy: Array[int] = []

	for value in source:
		copy.append(value)

	return copy


func _sum_visits(visits: Array[int]) -> int:
	var total: int = 0

	for value in visits:
		total += value

	return total


func _count_visits_at_least(visits: Array[int], threshold: int) -> int:
	var count: int = 0

	for value in visits:
		if value >= threshold:
			count += 1

	return count


func _count_visits_equal(visits: Array[int], target: int) -> int:
	var count: int = 0

	for value in visits:
		if value == target:
			count += 1

	return count


func _join_visits(visits: Array[int]) -> String:
	if visits.size() <= 0:
		return "-"

	var parts: PackedStringArray = PackedStringArray()

	for value in visits:
		parts.append(str(value))

	return ", ".join(parts)


func _thrower_name(thrower: int) -> String:
	return "PLAYER" if thrower == THROWER_PLAYER else "AI"


func _target_match_count() -> int:
	return int(floor(float(best_of_count) / 2.0)) + 1


func _legs_to_win_current_set() -> int:
	return 2


func _starting_thrower_from_selection() -> int:
	if starting_thrower_selection == START_THROWER_AI:
		return THROWER_AI

	if starting_thrower_selection == START_THROWER_RANDOM:
		if randi() % 2 == 0:
			return THROWER_PLAYER

		return THROWER_AI

	return THROWER_PLAYER


func _confirm_lock() -> void:
	if _phase == THROW_PHASE_LOCK_HEIGHT:
		_locked_y = _get_current_y()
		_phase = THROW_PHASE_LOCK_WIDTH
		_phase_time = 0.0
	elif _phase == THROW_PHASE_LOCK_WIDTH:
		_locked_x = _get_current_x()
		_land_player_dart(Vector2(_locked_x, _locked_y))


func _is_pointer_in_throw_area(pointer_position: Vector2) -> bool:
	var board_center: Vector2 = _board_local_to_overlay(Vector2.ZERO)

	return pointer_position.distance_to(board_center) <= AIM_RADIUS + 28.0


func _start_height_lock() -> void:
	_phase = THROW_PHASE_LOCK_HEIGHT
	_phase_time = 0.0
	_landed_time = 0.0


func _land_player_dart(local_position: Vector2) -> void:
	var result: Dictionary = _score_position(local_position)

	result["thrower"] = THROWER_PLAYER
	var is_bust: bool = _apply_result_to_score(THROWER_PLAYER, result)

	_results.append(result)
	_visit_total += int(result["counted_score"])
	dart_landed.emit(result)
	_record_dart_progress(THROWER_PLAYER, result, is_bust)
	_current_dart += 1
	_phase_time = 0.0
	_landed_time = 0.0

	if is_bust:
		_visit_bust = true
	elif _player_score == 0:
		_visit_checkout = true
		_leg_finished = true
		_leg_winner = THROWER_PLAYER

	if is_bust or _player_score == 0 or _current_dart > darts_per_visit:
		_player_visit_finished = true
		_finalize_visit(THROWER_PLAYER)

	_phase = THROW_PHASE_LANDED
	_update_all_live_labels()


func _throw_ai_dart() -> void:
	var target_label: String = _next_ai_target_label()
	var local_position: Vector2 = _local_position_for_target_label(target_label, _ai_darts_thrown)
	var result: Dictionary = _score_position(local_position)

	result["target_label"] = target_label
	result["thrower"] = THROWER_AI
	var is_bust: bool = _apply_result_to_score(THROWER_AI, result)

	_results.append(result)
	_visit_total += int(result["counted_score"])
	dart_landed.emit(result)
	_record_dart_progress(THROWER_AI, result, is_bust)
	_ai_darts_thrown += 1

	if is_bust:
		_visit_bust = true
	elif _ai_score == 0:
		_visit_checkout = true
		_leg_finished = true
		_leg_winner = THROWER_AI

	if is_bust or _ai_score == 0 or _ai_darts_thrown >= darts_per_visit:
		_ai_visit_finished = true
		_ai_wait_time = 0.0
		_finalize_visit(THROWER_AI)

	_update_all_live_labels()


func _finish_ai_visit() -> void:
	if _leg_finished:
		_complete_leg(_leg_winner)
		return

	_begin_player_visit()


func _apply_result_to_score(thrower: int, result: Dictionary) -> bool:
	var current_score: int = _score_for_thrower(thrower)

	result["counted_score"] = 0

	if double_in_enabled and not _is_thrower_in(thrower):
		if _is_legal_checkout(result):
			_set_thrower_in(thrower, true)
		else:
			result["is_not_in"] = true
			result["is_bust"] = false
			_update_scoreboard_scores()
			return false

	var is_bust: bool = _is_bust(current_score, result)

	result["is_bust"] = is_bust

	if is_bust:
		_set_score_for_thrower(thrower, _turn_start_score)
		_update_scoreboard_scores()
		return true

	var next_score: int = current_score - int(result["score"])

	result["counted_score"] = int(result["score"])
	_set_score_for_thrower(thrower, next_score)
	_update_scoreboard_scores()
	return false


func _is_bust(current_score: int, result: Dictionary) -> bool:
	var next_score: int = current_score - int(result["score"])

	if next_score < 0 or next_score == 1:
		return true

	if next_score == 0 and not _is_legal_checkout(result):
		return true

	return false


func _is_legal_checkout(result: Dictionary) -> bool:
	return int(result["multiplier"]) == 2 and not bool(result["is_miss"])


func _record_dart_progress(thrower: int, result: Dictionary, is_bust: bool) -> void:
	var dart_score: int = int(result["counted_score"])

	if thrower == THROWER_PLAYER:
		_player_darts_thrown += 1
		_player_leg_darts += 1

		if _player_leg_darts <= 9:
			_player_first_nine_darts += 1
			_player_leg_first_nine_darts += 1

			if not is_bust:
				_player_first_nine_points += dart_score
				_player_leg_first_nine_points += dart_score
	else:
		_ai_darts_thrown_total += 1
		_ai_leg_darts += 1

		if _ai_leg_darts <= 9:
			_ai_first_nine_darts += 1
			_ai_leg_first_nine_darts += 1

			if not is_bust:
				_ai_first_nine_points += dart_score
				_ai_leg_first_nine_points += dart_score


func _finalize_visit(thrower: int) -> void:
	if _visit_finalized:
		return

	_visit_finalized = true

	var counted_total: int = 0 if _visit_bust else _visit_total

	if thrower == THROWER_PLAYER:
		_player_leg_visits.append(counted_total)
		_player_total_points += counted_total

		if _visit_started_on_checkout or _visit_checkout:
			_player_checkout_attempts += 1
			_player_leg_checkout_attempts += 1

		if _visit_checkout:
			_player_checkout_successes += 1
			_player_leg_checkout_successes += 1
			_player_high_checkout = maxi(_player_high_checkout, _turn_start_score)
			_player_leg_high_checkout = maxi(_player_leg_high_checkout, _turn_start_score)

		_record_visit_thresholds(THROWER_PLAYER, counted_total)
	else:
		_ai_leg_visits.append(counted_total)
		_ai_total_points += counted_total

		if _visit_started_on_checkout or _visit_checkout:
			_ai_checkout_attempts += 1
			_ai_leg_checkout_attempts += 1

		if _visit_checkout:
			_ai_checkout_successes += 1
			_ai_leg_checkout_successes += 1
			_ai_high_checkout = maxi(_ai_high_checkout, _turn_start_score)
			_ai_leg_high_checkout = maxi(_ai_leg_high_checkout, _turn_start_score)

		_record_visit_thresholds(THROWER_AI, counted_total)

	visit_complete.emit(_results.duplicate(), counted_total)
	_update_current_leg_labels()
	_update_stats_labels()


func _record_visit_thresholds(thrower: int, counted_total: int) -> void:
	if counted_total >= 100:
		if thrower == THROWER_PLAYER:
			_player_ton_plus += 1
		else:
			_ai_ton_plus += 1

	if counted_total >= 140:
		if thrower == THROWER_PLAYER:
			_player_one_forty_plus += 1
		else:
			_ai_one_forty_plus += 1

	if counted_total == 180:
		if thrower == THROWER_PLAYER:
			_player_one_eighties += 1
		else:
			_ai_one_eighties += 1


func _score_for_thrower(thrower: int) -> int:
	return _player_score if thrower == THROWER_PLAYER else _ai_score


func _set_score_for_thrower(thrower: int, score: int) -> void:
	if thrower == THROWER_PLAYER:
		_player_score = score
	else:
		_ai_score = score


func _is_thrower_in(thrower: int) -> bool:
	return _player_is_in if thrower == THROWER_PLAYER else _ai_is_in


func _set_thrower_in(thrower: int, is_in: bool) -> void:
	if thrower == THROWER_PLAYER:
		_player_is_in = is_in
	else:
		_ai_is_in = is_in


func _set_static_scoreboard_labels() -> void:
	if match_format == MATCH_FORMAT_SETS:
		_set_label_text(match_title_label_path, "Round 1 - Best of %d Sets" % best_of_count)
		_set_label_text(sets_header_label_path, "Sets")
	else:
		_set_label_text(match_title_label_path, "Round 1 - Best of %d Legs" % best_of_count)
		_set_label_text(sets_header_label_path, "")

	_set_label_text(legs_header_label_path, "Legs")
	_set_label_text(score_header_label_path, "Score")
	_set_label_text(event_name_label_path, "%d GAME%s" % [starting_score, " - DOUBLE IN" if double_in_enabled else ""])


func _update_all_live_labels() -> void:
	_update_scoreboard_scores()
	_update_leg_labels()
	_update_current_leg_labels()
	_update_stats_labels()
	_update_on_nine_badges()
	_update_checkout_route()


func _update_scoreboard_scores() -> void:
	_set_label_text(player_score_label_path, str(_player_score))
	_set_label_text(ai_score_label_path, str(_ai_score))


func _update_leg_labels() -> void:
	_set_label_text(player_legs_label_path, str(_player_legs))
	_set_label_text(ai_legs_label_path, str(_ai_legs))

	if match_format == MATCH_FORMAT_SETS:
		_set_label_text(player_sets_label_path, str(_player_sets))
		_set_label_text(ai_sets_label_path, str(_ai_sets))
	else:
		_set_label_text(player_sets_label_path, "")
		_set_label_text(ai_sets_label_path, "")


func _update_current_leg_labels() -> void:
	_set_label_text(player_visits_label_path, _format_leg_visits(_player_leg_visits))
	_set_label_text(ai_visits_label_path, _format_leg_visits(_ai_leg_visits))


func _update_stats_labels() -> void:
	_set_label_text(player_average_label_path, _format_average(_player_total_points, _player_darts_thrown))
	_set_label_text(ai_average_label_path, _format_average(_ai_total_points, _ai_darts_thrown_total))
	_set_label_text(player_first_nine_label_path, _format_average(_player_first_nine_points, _player_first_nine_darts))
	_set_label_text(ai_first_nine_label_path, _format_average(_ai_first_nine_points, _ai_first_nine_darts))
	_set_label_text(player_checkout_label_path, _format_checkout(_player_checkout_successes, _player_checkout_attempts))
	_set_label_text(ai_checkout_label_path, _format_checkout(_ai_checkout_successes, _ai_checkout_attempts))
	_set_label_text(player_high_checkout_label_path, _format_high_checkout(_player_high_checkout))
	_set_label_text(ai_high_checkout_label_path, _format_high_checkout(_ai_high_checkout))
	_set_label_text(player_ton_plus_label_path, str(_player_ton_plus))
	_set_label_text(ai_ton_plus_label_path, str(_ai_ton_plus))
	_set_label_text(player_one_forty_plus_label_path, str(_player_one_forty_plus))
	_set_label_text(ai_one_forty_plus_label_path, str(_ai_one_forty_plus))
	_set_label_text(player_one_eighties_label_path, str(_player_one_eighties))
	_set_label_text(ai_one_eighties_label_path, str(_ai_one_eighties))
	_set_label_text(player_darts_thrown_label_path, str(_player_darts_thrown))
	_set_label_text(ai_darts_thrown_label_path, str(_ai_darts_thrown_total))


func _update_on_nine_badges() -> void:
	var player_on_nine: bool = _player_is_in and _is_on_nine_darter(_player_score, _player_leg_darts)
	var ai_on_nine: bool = _ai_is_in and _is_on_nine_darter(_ai_score, _ai_leg_darts)

	_set_presenter_value("player_on_nine", player_on_nine)
	_set_presenter_value("ai_on_nine", ai_on_nine)


func _is_on_nine_darter(score: int, leg_darts: int) -> bool:
	var darts_remaining: int = 9 - leg_darts
	var route_darts: int = darts_remaining

	if route_darts > darts_per_visit:
		route_darts = darts_per_visit

	var route: Array[String] = _checkout_route_for_score(score, route_darts)

	return not _match_finished and darts_remaining >= 1 and darts_remaining <= 3 and route.size() > 0 and route.size() <= darts_remaining


func _update_checkout_route() -> void:
	var player_route: Array[String] = []
	var ai_route: Array[String] = []

	if show_player_checkout_route and _player_is_in:
		player_route = _checkout_route_for_score(_player_score, _darts_remaining_for_route(THROWER_PLAYER))

	if show_ai_checkout_route and _ai_is_in:
		ai_route = _checkout_route_for_score(_ai_score, _darts_remaining_for_route(THROWER_AI))

	var player_route_visible: bool = not _match_finished and player_route.size() > 0
	var ai_route_visible: bool = not _match_finished and ai_route.size() > 0

	_set_route_row_texts(player_route_tile_1_label_path, player_route_tile_2_label_path, player_route_tile_3_label_path, player_route, player_route_visible)
	_set_route_row_texts(ai_route_tile_1_label_path, ai_route_tile_2_label_path, ai_route_tile_3_label_path, ai_route, ai_route_visible)
	_set_presenter_value("checkout_route_visible", player_route_visible or ai_route_visible)


func _darts_remaining_for_route(thrower: int) -> int:
	if thrower == THROWER_PLAYER and _active_thrower == THROWER_PLAYER:
		return maxi(0, darts_per_visit - (_current_dart - 1))

	if thrower == THROWER_AI and _active_thrower == THROWER_AI:
		return maxi(0, darts_per_visit - _ai_darts_thrown)

	return darts_per_visit


func _format_leg_visits(visits: Array[int]) -> String:
	var cells: PackedStringArray = PackedStringArray()

	for index in range(5):
		if index < visits.size():
			cells.append(str(visits[index]))
		else:
			cells.append("-")

	return "        ".join(cells)


func _format_average(points: int, darts: int) -> String:
	if darts <= 0:
		return "0.00"

	var average: float = float(points) * 3.0 / float(darts)

	return "%.2f" % average


func _format_checkout(successes: int, attempts: int) -> String:
	if attempts <= 0:
		return "0% (0/0)"

	var percentage: int = int(round(float(successes) * 100.0 / float(attempts)))

	return "%d%% (%d/%d)" % [percentage, successes, attempts]


func _format_high_checkout(value: int) -> String:
	if value <= 0:
		return "-"

	return str(value)


func _set_label_text(path: NodePath, value: String) -> void:
	var label: Label = get_node_or_null(path) as Label

	if label != null:
		label.text = value


func _set_route_row_texts(path_1: NodePath, path_2: NodePath, path_3: NodePath, route: Array[String], row_visible: bool) -> void:
	var slot_1_text: String = ""
	var slot_2_text: String = ""
	var slot_3_text: String = ""

	if row_visible and route.size() == 1:
		slot_3_text = route[0]
	elif row_visible and route.size() == 2:
		slot_2_text = route[0]
		slot_3_text = route[1]
	elif row_visible and route.size() >= 3:
		slot_1_text = route[0]
		slot_2_text = route[1]
		slot_3_text = route[2]

	_set_route_tile_text(path_1, slot_1_text, slot_1_text != "")
	_set_route_tile_text(path_2, slot_2_text, slot_2_text != "")
	_set_route_tile_text(path_3, slot_3_text, slot_3_text != "")


func _set_route_tile_text(path: NodePath, value: String, is_visible: bool) -> void:
	var label: Label = get_node_or_null(path) as Label

	if label == null:
		return

	label.text = value

	var tile: CanvasItem = label.get_parent() as CanvasItem

	if tile != null:
		tile.visible = is_visible


func _set_active_thrower(thrower: int) -> void:
	_active_thrower = thrower
	_set_presenter_value("active_thrower", thrower)
	_update_checkout_route()
	_update_on_nine_badges()


func _set_presenter_value(property_name: StringName, value: Variant) -> void:
	var presenter: Node = get_node_or_null(scoreboard_presenter_path)

	if presenter != null:
		presenter.set(property_name, value)


func _next_ai_target_label() -> String:
	if double_in_enabled and not _ai_is_in:
		return "D20"

	var route: Array[String] = _checkout_route_for_score(_ai_score, maxi(0, darts_per_visit - _ai_darts_thrown))

	if route.size() > 0:
		return route[0]

	var target_label: String = AI_DART_LABELS[_ai_dart_sequence_index % AI_DART_LABELS.size()]

	_ai_dart_sequence_index += 1
	return target_label


func _checkout_route_for_score(score: int, max_darts: int = 3) -> Array[String]:
	var no_route: Array[String] = []

	if max_darts <= 0 or score < 2 or score > 170 or _is_bogey_checkout(score):
		return no_route

	var direct_finish: String = _finish_label_for_score(score)

	if direct_finish != "":
		return _make_route(direct_finish)

	if max_darts < 2:
		return no_route

	for finish_label in FINISH_DART_LABELS:
		var one_dart_setup_score: int = score - _score_for_label(finish_label)

		if one_dart_setup_score <= 0:
			continue

		for setup_label in ROUTE_DART_LABELS:
			if _score_for_label(setup_label) == one_dart_setup_score:
				return _make_route(setup_label, finish_label)

	if max_darts < 3:
		return no_route

	for finish_label_two in FINISH_DART_LABELS:
		var two_dart_setup_score: int = score - _score_for_label(finish_label_two)

		if two_dart_setup_score <= 1:
			continue

		for first_setup_label in ROUTE_DART_LABELS:
			var remaining_setup_score: int = two_dart_setup_score - _score_for_label(first_setup_label)

			if remaining_setup_score <= 0:
				continue

			for second_setup_label in ROUTE_DART_LABELS:
				if _score_for_label(second_setup_label) == remaining_setup_score:
					return _make_route(first_setup_label, second_setup_label, finish_label_two)

	return no_route


func _is_bogey_checkout(score: int) -> bool:
	return score == 169 or score == 168 or score == 166 or score == 165 or score == 163 or score == 162 or score == 159


func _finish_label_for_score(score: int) -> String:
	if score == 50:
		return "BULL"

	if score >= 2 and score <= 40 and score % 2 == 0:
		return "D%d" % int(score / 2)

	return ""


func _score_for_label(label: String) -> int:
	if label == "BULL":
		return 50

	if label == "25":
		return 25

	if label == "MISS" or label.length() < 2:
		return 0

	var multiplier_label: String = label.substr(0, 1)
	var segment: int = int(label.substr(1))

	if multiplier_label == "D":
		return segment * 2

	if multiplier_label == "T":
		return segment * 3

	return segment


func _make_route(first: String, second: String = "", third: String = "") -> Array[String]:
	var route: Array[String] = []

	route.append(first)

	if second != "":
		route.append(second)

	if third != "":
		route.append(third)

	return route


func _local_position_for_target_label(target_label: String, dart_number: int) -> Vector2:
	if target_label == "BULL":
		return Vector2(4.0, -3.0)

	if target_label == "25":
		return Vector2(22.0, 5.0)

	if target_label == "MISS":
		return Vector2(386.0, 42.0)

	var multiplier_label: String = target_label.substr(0, 1)
	var segment: int = int(target_label.substr(1))
	var segment_index: int = BOARD_NUMBERS.find(segment)

	if segment_index < 0:
		return Vector2.ZERO

	var angle: float = START_ANGLE + float(segment_index) * SECTOR_ANGLE + _ai_angle_offset(dart_number)
	var radius: float = _ai_radius_for_multiplier(multiplier_label, dart_number)

	return Vector2(cos(angle), sin(angle)) * radius


func _ai_angle_offset(dart_number: int) -> float:
	return sin(float(_ai_dart_sequence_index + dart_number) * 1.7) * 0.035


func _ai_radius_for_multiplier(multiplier_label: String, dart_number: int) -> float:
	var radius_wobble: float = sin(float(_ai_dart_sequence_index + dart_number) * 1.13)

	if multiplier_label == "D":
		return 334.0 + radius_wobble * 3.0

	if multiplier_label == "T":
		return 206.0 + radius_wobble * 5.0

	return 260.0 + radius_wobble * 10.0


func _score_position(local_position: Vector2) -> Dictionary:
	var radius: float = local_position.length()
	var global_position: Vector2 = _board_local_to_global(local_position)

	if radius > DOUBLE_OUTER_RADIUS:
		return {
			"label": "MISS",
			"score": 0,
			"segment": 0,
			"multiplier": 0,
			"local_position": local_position,
			"global_position": global_position,
			"is_miss": true,
			"is_bull": false
		}

	if radius <= INNER_BULL_RADIUS:
		return {
			"label": "BULL",
			"score": 50,
			"segment": 25,
			"multiplier": 2,
			"local_position": local_position,
			"global_position": global_position,
			"is_miss": false,
			"is_bull": true
		}

	if radius <= OUTER_BULL_RADIUS:
		return {
			"label": "25",
			"score": 25,
			"segment": 25,
			"multiplier": 1,
			"local_position": local_position,
			"global_position": global_position,
			"is_miss": false,
			"is_bull": true
		}

	var segment_index: int = _segment_index_for_angle(atan2(local_position.y, local_position.x))
	var segment: int = BOARD_NUMBERS[segment_index]
	var multiplier: int = _multiplier_for_radius(radius)
	var label_prefix: String = "S"

	if multiplier == 2:
		label_prefix = "D"
	elif multiplier == 3:
		label_prefix = "T"

	return {
		"label": "%s%d" % [label_prefix, segment],
		"score": segment * multiplier,
		"segment": segment,
		"multiplier": multiplier,
		"local_position": local_position,
		"global_position": global_position,
		"is_miss": false,
		"is_bull": false
	}


func _segment_index_for_angle(angle: float) -> int:
	var shifted_angle: float = fposmod(angle - (START_ANGLE - SECTOR_ANGLE * 0.5), TAU)
	var segment_index: int = int(floor(shifted_angle / SECTOR_ANGLE))

	return clampi(segment_index, 0, BOARD_NUMBERS.size() - 1)


func _multiplier_for_radius(radius: float) -> int:
	if radius >= DOUBLE_INNER_RADIUS and radius <= DOUBLE_OUTER_RADIUS:
		return 2

	if radius >= TREBLE_INNER_RADIUS and radius <= TREBLE_OUTER_RADIUS:
		return 3

	return 1


func _draw() -> void:
	if _font == null:
		_font = ThemeDB.fallback_font

	_draw_aim_guides()
	_draw_dart_markers()


func _draw_aim_guides() -> void:
	if _phase == THROW_PHASE_AI_THROWING or _phase == THROW_PHASE_MATCH_COMPLETE:
		return

	var board_center: Vector2 = _board_local_to_overlay(Vector2.ZERO)

	draw_arc(board_center, AIM_RADIUS, 0.0, TAU, 160, GUIDE_RING_COLOR, 1.5, true)

	if _phase == THROW_PHASE_LOCK_HEIGHT:
		var current_y: float = _get_current_y()
		var half_width: float = _safe_axis_limit(current_y)
		var y: float = board_center.y + current_y

		draw_line(Vector2(board_center.x - half_width, y), Vector2(board_center.x + half_width, y), AIM_LINE_COLOR, 3.0, true)
		_draw_edge_marker(Vector2(board_center.x - half_width, y), Vector2(-1.0, 0.0))
		_draw_edge_marker(Vector2(board_center.x + half_width, y), Vector2(1.0, 0.0))
	elif _phase == THROW_PHASE_LOCK_WIDTH:
		var current_x: float = _get_current_x()
		var half_height: float = _safe_axis_limit(current_x)
		var locked_y: float = board_center.y + _locked_y
		var x: float = board_center.x + current_x

		draw_line(Vector2(board_center.x - _safe_axis_limit(_locked_y), locked_y), Vector2(board_center.x + _safe_axis_limit(_locked_y), locked_y), LOCKED_LINE_COLOR, 2.0, true)
		draw_line(Vector2(x, board_center.y - half_height), Vector2(x, board_center.y + half_height), AIM_LINE_COLOR, 3.0, true)
		_draw_crosshair(Vector2(x, locked_y), AIM_LINE_COLOR)
	elif _phase == THROW_PHASE_LANDED:
		_draw_crosshair(_board_local_to_overlay(Vector2(_locked_x, _locked_y)), LOCKED_LINE_COLOR)


func _draw_edge_marker(position: Vector2, direction: Vector2) -> void:
	var normal: Vector2 = Vector2(-direction.y, direction.x)
	var points: PackedVector2Array = PackedVector2Array()

	points.append(position)
	points.append(position - direction * 18.0 + normal * 7.0)
	points.append(position - direction * 18.0 - normal * 7.0)
	draw_colored_polygon(points, AIM_LINE_COLOR)


func _draw_crosshair(position: Vector2, color: Color) -> void:
	draw_line(position + Vector2(-15.0, 0.0), position + Vector2(15.0, 0.0), color, 2.5, true)
	draw_line(position + Vector2(0.0, -15.0), position + Vector2(0.0, 15.0), color, 2.5, true)
	draw_circle(position, 5.0, color)


func _draw_dart_markers() -> void:
	for index in range(_results.size()):
		var result: Dictionary = _results[index]
		var local_position: Vector2 = result["local_position"] as Vector2
		var marker_position: Vector2 = _board_local_to_overlay(local_position)
		var tail_direction: Vector2 = Vector2(-0.72, -0.42).normalized()
		var tail_end: Vector2 = marker_position + tail_direction * 30.0
		var marker_color: Color = _marker_color_for_result(result)

		draw_line(marker_position, tail_end, Color(0.08, 0.08, 0.10, 0.92), 4.0, true)
		draw_circle(marker_position, 6.0, marker_color)
		draw_circle(marker_position, 2.5, MARKER_PIN_COLOR)
		_draw_small_text(str(index + 1), marker_position + Vector2(10.0, -10.0), 14, MARKER_LABEL_COLOR)


func _marker_color_for_result(result: Dictionary) -> Color:
	if result.has("is_bust") and bool(result["is_bust"]):
		return BUST_MARKER_COLOR

	if result.has("thrower") and int(result["thrower"]) == THROWER_AI:
		return AI_MARKER_COLOR

	return PLAYER_MARKER_COLOR


func _draw_small_text(text: String, baseline: Vector2, font_size: int, color: Color) -> void:
	draw_string(_font, baseline, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _get_current_y() -> float:
	var base_y: float = _triangle_sweep(_phase_time, _effective_vertical_speed(), AIM_RADIUS)
	var wobble: float = _visible_wobble(0.0)

	return clampf(base_y + wobble, -AIM_RADIUS, AIM_RADIUS)


func _get_current_x() -> float:
	var limit: float = _safe_axis_limit(_locked_y)
	var base_x: float = _triangle_sweep(_phase_time, _effective_horizontal_speed(), limit)
	var wobble: float = _visible_wobble(1.7)

	return clampf(base_x + wobble, -limit, limit)


func _triangle_sweep(time: float, speed: float, radius: float) -> float:
	var span: float = radius * 2.0
	var cycle: float = span * 2.0
	var travelled: float = fposmod(time * speed, cycle)

	if travelled <= span:
		return -radius + travelled

	return radius - (travelled - span)


func _visible_wobble(offset: float) -> float:
	var skill_penalty: float = 1.0 - clampf(control_skill, 0.0, 1.0)
	var pressure_bonus: float = clampf(pressure, 0.0, 1.0)
	var amount: float = visible_wobble_pixels * (0.50 + skill_penalty * 0.80 + pressure_bonus * 1.20)
	var slow_wobble: float = sin(_motion_time * 3.2 + offset) * amount
	var fine_wobble: float = sin(_motion_time * 7.1 + offset * 1.9) * amount * 0.28

	return slow_wobble + fine_wobble


func _effective_vertical_speed() -> float:
	var speed_scale: float = 1.15 + clampf(pressure, 0.0, 1.0) * 0.55 - clampf(control_skill, 0.0, 1.0) * 0.35

	return maxf(90.0, vertical_speed * speed_scale)


func _effective_horizontal_speed() -> float:
	var speed_scale: float = 1.10 + clampf(pressure, 0.0, 1.0) * 0.50 - clampf(control_skill, 0.0, 1.0) * 0.30

	return maxf(90.0, horizontal_speed * speed_scale)


func _safe_axis_limit(axis_value: float) -> float:
	var remaining: float = maxf(0.0, AIM_RADIUS * AIM_RADIUS - axis_value * axis_value)

	return sqrt(remaining)


func _board_local_to_overlay(local_position: Vector2) -> Vector2:
	var dartboard: Node2D = get_node_or_null(dartboard_path) as Node2D

	if dartboard == null:
		return BOARD_CENTER_FALLBACK + local_position

	return to_local(dartboard.to_global(local_position))


func _board_local_to_global(local_position: Vector2) -> Vector2:
	var dartboard: Node2D = get_node_or_null(dartboard_path) as Node2D

	if dartboard == null:
		return BOARD_CENTER_FALLBACK + local_position

	return dartboard.to_global(local_position)
