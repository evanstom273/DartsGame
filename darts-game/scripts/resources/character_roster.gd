extends RefCounted
class_name CharacterRoster

const CHARACTERS_PER_COUNTRY: int = 16

const LEVELS: Array[Dictionary] = [
	{
		"name": "Amateur",
		"min": 0.0,
		"max": 30.0,
		"template": "res://characters/presets/ai_amateur.tres"
	},
	{
		"name": "County",
		"min": 30.0,
		"max": 60.0,
		"template": "res://characters/presets/ai_county.tres"
	},
	{
		"name": "Pro",
		"min": 60.0,
		"max": 90.0,
		"template": "res://characters/presets/ai_pro.tres"
	},
	{
		"name": "World Class",
		"min": 80.0,
		"max": 105.0,
		"template": "res://characters/presets/ai_world_class.tres"
	}
]

const NATION_NAMES: Array[String] = [
	"England",
	"Scotland",
	"Wales",
	"N Ireland",
	"Ireland",
	"Netherlands",
	"Germany",
	"Austria",
	"Oceania",
	"US",
	"Canada",
	"Mexico",
	"Japan",
	"Belgium",
	"France",
	"Italy",
	"Portugal",
	"Poland",
	"Spain",
	"Switzerland",
	"Czech Republic",
	"Croatia",
	"Slovenia",
	"Latvia",
	"Lithuania",
	"Sweden",
	"Denmark",
	"Finland",
	"Norway",
	"Singapore",
	"China",
	"Philippines"
]


static func generate_default_roster() -> Array[CharacterResource]:
	var roster: Array[CharacterResource] = []
	var character_number: int = 1

	for nation_index in range(NATION_NAMES.size()):
		for country_character_index in range(CHARACTERS_PER_COUNTRY):
			var level_index: int = (character_number - 1) % LEVELS.size()
			var character: CharacterResource = _build_character(character_number, nation_index, level_index)

			roster.append(character)
			character_number += 1

	return roster


static func random_character(roster: Array[CharacterResource]) -> CharacterResource:
	if roster.is_empty():
		return CharacterResource.new()

	return roster[randi() % roster.size()]


static func _build_character(character_number: int, nation_index: int, level_index: int) -> CharacterResource:
	var level: Dictionary = LEVELS[level_index]
	var template: CharacterResource = load(str(level["template"])) as CharacterResource
	var character: CharacterResource = CharacterResource.new()

	if template != null:
		_copy_character_tuning(template, character)
	else:
		character.average_min = float(level["min"])
		character.average_max = float(level["max"])

	character.home_nation = nation_index as CharacterResource.CharacterNation
	character.display_name = "Char %d (%s)" % [
		character_number,
		str(level["name"])
	]

	return character


static func _copy_character_tuning(source: CharacterResource, target: CharacterResource) -> void:
	target.average_min = source.average_min
	target.average_max = source.average_max
	target.variance = source.variance
	target.nerve = source.nerve
	target.treble_consistency = source.treble_consistency
	target.double_consistency = source.double_consistency
	target.single_consistency = source.single_consistency
	target.preferred_scoring_targets = source.preferred_scoring_targets.duplicate()
	target.preferred_checkout_doubles = source.preferred_checkout_doubles.duplicate()
	target.maximum_appetite = source.maximum_appetite
	target.heavy_scoring_bias = source.heavy_scoring_bias
	target.opening_phase_bias = source.opening_phase_bias
	target.nine_darter_appetite = source.nine_darter_appetite
	target.preferred_checkout_routes = source.preferred_checkout_routes.duplicate(true)
	target.vertical_speed = source.vertical_speed
	target.horizontal_speed = source.horizontal_speed
	target.visible_wobble_pixels = source.visible_wobble_pixels
	target.line_chaos_strength = source.line_chaos_strength
	target.post_lock_drift_pixels = source.post_lock_drift_pixels
	target.post_lock_drift_duration = source.post_lock_drift_duration
	target.fatigue_per_dart = source.fatigue_per_dart
	target.control_skill = source.control_skill
	target.pressure = source.pressure
