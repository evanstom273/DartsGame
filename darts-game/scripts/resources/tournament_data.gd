extends Resource
class_name TournamentData

enum TournamentType {
	KNOCKOUT,
	LEAGUE,
	GROUP_STAGE_KNOCKOUT,
	LEAGUE_PLAYOFF
}

enum MatchFormat {
	LEGS,
	SETS
}

enum StartingScore {
	SCORE_301 = 301,
	SCORE_501 = 501
}

enum StarterRule {
	ALTERNATE,
	HIGHER_SEED,
	LOWER_SEED,
	RANDOM
}

enum SeedingMode {
	NONE,
	SEEDED_DRAW,
	FIXED_BRACKET
}

enum PairingMode {
	RANDOM_DRAW,
	SEEDED_VS_UNSEEDED,
	BRACKET_SEED_ORDER
}

enum ByePolicy {
	AUTO_BYES,
	REQUIRE_POWER_OF_TWO,
	PRELIMINARY_ROUND
}

enum LeagueSchedule {
	SINGLE_ROUND_ROBIN,
	DOUBLE_ROUND_ROBIN
}

enum PrizeSplitType {
	WINNER_HEAVY,
	BALANCED,
	FLATTER
}

@export_group("Tournament Details")
## Display name used in menus, scoreboards, and summaries.
@export var tournament_name: String = ""
## Broad event structure used by the tournament controller.
@export var tournament_type: TournamentType = TournamentType.KNOCKOUT
## Slider-friendly participant count. Runtime helpers cast it to an integer.
@export_range(2, 128, 1) var participant_count: float = 32
## Number of ranked/seeded players protected by the draw.
@export_range(0, 32, 1) var seeded_player_count: float = 8
## Full tournament prize fund. Per-round payouts are generated from this unless custom prizes are enabled.
@export_range(500, 1000000, 500) var tournament_total_prize: int = 100000

@export_group("Entrants")
## Optional display names for fixed exhibition fields. Empty names can be filled by generated AI entrants.
@export var entrant_names: Array[String] = []
## Optional character resources mapped to entrants by index later.
@export var entrant_ai_profiles: Array[CharacterResource] = []
## If true, one generated entrant is flagged as the human player and that flag follows them through the draw.
@export var include_human_player: bool = true

@export_group("Draw and Seeding")
## How seeded players are handled when fixtures are generated.
@export var seeding_mode: SeedingMode = SeedingMode.SEEDED_DRAW
## How first-round pairs or league fixtures are ordered.
@export var pairing_mode: PairingMode = PairingMode.SEEDED_VS_UNSEEDED
## How non-power-of-two knockout fields are handled.
@export var bye_policy: ByePolicy = ByePolicy.AUTO_BYES
## Require pairable fields for formats that generate head-to-head fixtures.
@export var require_even_pairs: bool = true
## Random seed for repeatable exhibition draws. Use 0 for fresh random draws.
@export var draw_seed: int = 0

@export_group("Match Rules")
## 301 or 501 starting score for every leg.
@export var starting_score: StartingScore = StartingScore.SCORE_501
## Default match format for the event.
@export var match_format: MatchFormat = MatchFormat.LEGS
## Slider-friendly best-of count. Helpers coerce it to odd best-of values.
@export_range(1, 31, 1) var match_best_of: float = 11
## Set play uses first to 3 legs per set by default.
@export_range(1, 9, 1) var legs_to_win_set: float = 3
## PDC Grand Prix style entry rule.
@export var double_in_enabled: bool = false
## Darts standard checkout rule. Keep true unless building alternate modes.
@export var double_out_enabled: bool = true
## Who starts the first leg of a fixture.
@export var starter_rule: StarterRule = StarterRule.ALTERNATE
## Alternate first thrower between legs.
@export var alternate_starter_each_leg: bool = true

@export_group("Round Overrides")
## Optional longer semi-final best-of value. 0 means use match_best_of.
@export_range(0, 41, 1) var semi_final_best_of: float = 0
## Optional longer final best-of value. 0 means use match_best_of.
@export_range(0, 61, 1) var final_best_of: float = 0
## Optional match format override for the final.
@export var final_match_format: MatchFormat = MatchFormat.LEGS

@export_group("Groups and Leagues")
## Number of groups for group-stage events.
@export_range(1, 32, 1) var group_count: float = 4
## Players qualifying from each group into the knockout stage.
@export_range(1, 8, 1) var qualifiers_per_group: float = 2
## League schedule style.
@export var league_schedule: LeagueSchedule = LeagueSchedule.SINGLE_ROUND_ROBIN
## Number of players entering playoffs from a league table.
@export_range(2, 16, 1) var playoff_qualifier_count: float = 4
## Points awarded for a league fixture win.
@export_range(1, 5, 1) var league_points_for_win: float = 2
## Tie-breaker priority after points: leg difference, legs won, then head-to-head.
@export var use_standard_league_tiebreakers: bool = true

@export_group("Prize Money")
## Automatic prize curve used when custom_prize_breakdown is empty or disabled.
@export var prize_split_type: PrizeSplitType = PrizeSplitType.WINNER_HEAVY
## If true, players losing in the opening round still receive prize money.
@export var pay_all_participants: bool = true
## If true, use custom_prize_breakdown exactly as entered.
@export var use_custom_prize_breakdown: bool = false
## Optional manual per-player prize values by placing label, for example {"Winner": 50000, "Runner-up": 25000}.
@export var custom_prize_breakdown: Dictionary = {}


func participant_total() -> int:
	return maxi(2, int(round(participant_count)))


func seeded_total() -> int:
	return clampi(int(round(seeded_player_count)), 0, participant_total())


func match_starting_score() -> int:
	return int(starting_score)


func default_best_of_count() -> int:
	return _odd_count(match_best_of)


func legs_per_set() -> int:
	return maxi(1, int(round(legs_to_win_set)))


func target_to_win_match(best_of_value: float = -1.0) -> int:
	var best_of: int = default_best_of_count() if best_of_value < 0.0 else _odd_count(best_of_value)

	return int(floor(float(best_of) / 2.0)) + 1


func uses_knockout_bracket() -> bool:
	return tournament_type == TournamentType.KNOCKOUT or tournament_type == TournamentType.GROUP_STAGE_KNOCKOUT or tournament_type == TournamentType.LEAGUE_PLAYOFF


func uses_league_table() -> bool:
	return tournament_type == TournamentType.LEAGUE or tournament_type == TournamentType.LEAGUE_PLAYOFF


func uses_group_stage() -> bool:
	return tournament_type == TournamentType.GROUP_STAGE_KNOCKOUT


func group_total() -> int:
	if not uses_group_stage():
		return 0

	return clampi(int(round(group_count)), 1, participant_total())


func qualifiers_per_group_total() -> int:
	if not uses_group_stage():
		return 0

	return maxi(1, int(round(qualifiers_per_group)))


func playoff_total() -> int:
	if tournament_type != TournamentType.LEAGUE_PLAYOFF:
		return 0

	return clampi(int(round(playoff_qualifier_count)), 2, participant_total())


func final_best_of_count() -> int:
	if final_best_of <= 0.0:
		return default_best_of_count()

	return _odd_count(final_best_of)


func semi_final_best_of_count() -> int:
	if semi_final_best_of <= 0.0:
		return default_best_of_count()

	return _odd_count(semi_final_best_of)


func prize_breakdown() -> Dictionary:
	if use_custom_prize_breakdown and not custom_prize_breakdown.is_empty():
		return custom_prize_breakdown.duplicate(true)

	if tournament_type == TournamentType.LEAGUE:
		return _league_prize_breakdown()

	return _knockout_prize_breakdown()


func validate() -> PackedStringArray:
	var issues: PackedStringArray = PackedStringArray()
	var participants: int = participant_total()
	var seeds: int = seeded_total()

	if tournament_name.strip_edges() == "":
		issues.append("Tournament name is empty.")

	if require_even_pairs and participants % 2 != 0:
		issues.append("Participant count should be even for pair generation.")

	if seeds > participants:
		issues.append("Seeded player count cannot exceed participant count.")

	if tournament_type == TournamentType.KNOCKOUT and bye_policy == ByePolicy.REQUIRE_POWER_OF_TWO and not _is_power_of_two(participants):
		issues.append("Knockout participant count must be a power of two for this bye policy.")

	if uses_group_stage():
		var groups: int = group_total()

		if participants % groups != 0:
			issues.append("Participant count should divide evenly into groups.")

		if qualifiers_per_group_total() * groups < 2:
			issues.append("Group qualifiers must produce at least two knockout players.")

	if tournament_type == TournamentType.LEAGUE_PLAYOFF and playoff_total() % 2 != 0:
		issues.append("League playoff qualifier count should be even.")

	if tournament_total_prize <= 0:
		issues.append("Tournament total prize must be greater than zero.")

	return issues


func _knockout_prize_breakdown() -> Dictionary:
	var participants: int = participant_total()
	var labels: Array[String] = _knockout_prize_labels(participants)
	var weights: Array[float] = _prize_weights(labels.size())
	var breakdown: Dictionary = {}
	var remaining_prize: int = tournament_total_prize
	var paid_players_remaining: int = 0

	for label in labels:
		paid_players_remaining += _placing_count_for_label(label, participants)

	for index in range(labels.size()):
		var label: String = labels[index]
		var placing_count: int = _placing_count_for_label(label, participants)
		var per_player_prize: int = 0

		if index == labels.size() - 1:
			per_player_prize = int(floor(float(remaining_prize) / float(maxi(1, placing_count))))
		else:
			var round_total: int = int(round(float(tournament_total_prize) * weights[index]))
			per_player_prize = int(floor(float(round_total) / float(maxi(1, placing_count))))
			remaining_prize -= per_player_prize * placing_count
			paid_players_remaining -= placing_count

		breakdown[label] = per_player_prize

	return breakdown


func _league_prize_breakdown() -> Dictionary:
	var participants: int = participant_total()
	var labels: Array[String] = []
	var weights: Array[float] = _league_weights(participants)
	var breakdown: Dictionary = {}
	var remaining_prize: int = tournament_total_prize

	for position in range(1, participants + 1):
		labels.append(_ordinal(position))

	for index in range(labels.size()):
		var prize: int = 0

		if index == labels.size() - 1:
			prize = remaining_prize
		else:
			prize = int(round(float(tournament_total_prize) * weights[index]))
			remaining_prize -= prize

		breakdown[labels[index]] = prize

	return breakdown


func _knockout_prize_labels(participants: int) -> Array[String]:
	var labels: Array[String] = ["Winner", "Runner-up"]
	var placing_size: int = 2

	while placing_size < participants:
		placing_size *= 2

		if placing_size == 4:
			labels.append("Semi-finalists")
		elif placing_size == 8:
			labels.append("Quarter-finalists")
		else:
			labels.append("Last %d" % placing_size)

	if not pay_all_participants and labels.size() > 2:
		labels.remove_at(labels.size() - 1)

	return labels


func _placing_count_for_label(label: String, participants: int) -> int:
	match label:
		"Winner":
			return 1
		"Runner-up":
			return 1
		"Semi-finalists":
			return 2
		"Quarter-finalists":
			return 4
		_:
			var number_text: String = label.replace("Last ", "")
			var round_size: int = int(number_text)

			return maxi(1, mini(participants, round_size) / 2)


func _prize_weights(label_count: int) -> Array[float]:
	var base_weights: Array[float] = []

	match prize_split_type:
		PrizeSplitType.BALANCED:
			base_weights = [0.24, 0.16, 0.18, 0.18, 0.14, 0.10]
		PrizeSplitType.FLATTER:
			base_weights = [0.18, 0.13, 0.16, 0.19, 0.19, 0.15]
		_:
			base_weights = [0.32, 0.18, 0.18, 0.14, 0.10, 0.08]

	return _normalised_weights(base_weights, label_count)


func _league_weights(participants: int) -> Array[float]:
	var weights: Array[float] = []
	var total_weight: float = 0.0

	for index in range(participants):
		var weight: float = pow(float(participants - index), 1.35)
		weights.append(weight)
		total_weight += weight

	for index in range(weights.size()):
		weights[index] = weights[index] / maxf(0.001, total_weight)

	return weights


func _normalised_weights(base_weights: Array[float], label_count: int) -> Array[float]:
	var weights: Array[float] = []
	var total: float = 0.0

	for index in range(label_count):
		var weight: float = base_weights[min(index, base_weights.size() - 1)]
		weights.append(weight)
		total += weight

	for index in range(weights.size()):
		weights[index] = weights[index] / maxf(0.001, total)

	return weights


func _odd_count(value: float) -> int:
	var count: int = maxi(1, int(round(value)))

	if count % 2 == 0:
		count += 1

	return count


func _is_power_of_two(value: int) -> bool:
	return value > 0 and (value & (value - 1)) == 0


func _ordinal(value: int) -> String:
	var suffix: String = "th"
	var mod_100: int = value % 100

	if mod_100 < 11 or mod_100 > 13:
		match value % 10:
			1:
				suffix = "st"
			2:
				suffix = "nd"
			3:
				suffix = "rd"

	return "%d%s" % [value, suffix]
