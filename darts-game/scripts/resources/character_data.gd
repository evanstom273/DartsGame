extends Resource
class_name CharacterResource

enum CharacterNation { ENGLAND, SCOTLAND, WALES, N_IRELAND, IRELAND, NETHERLANDS, GERMANY, AUSTRIA, OCEANIA, US, CANADA, MEXICO, JAPAN, BELGIUM, FRANCE, ITALY, PORTUGAL, POLAND, SPAIN, SWITZERLAND, CZECH_REPUBLIC, CROATIA, SLOVENIA, LATVIA, LITHUANIA, SWEDEN, DENMARK, FINLAND, NORWAY, SINGAPORE, CHINA, PHILIPPINES, CUSTOM }
enum CharacterGender { MALE, FEMALE }

@export_group("Identity")
@export var display_name: String = "Player"
@export var home_nation: CharacterNation = CharacterNation.ENGLAND
@export var gender: CharacterGender = CharacterGender.MALE

@export_group("Average / Ability")
@export var average_min: float = 60.0
@export var average_max: float = 90.0
@export var variance: float = 8.0
@export var nerve: float = 0.5

@export_group("AI Accuracy")
@export_range(0.0, 1.0, 0.01) var treble_consistency: float = 0.4
@export_range(0.0, 1.0, 0.01) var double_consistency: float = 0.3
@export_range(0.0, 1.0, 0.01) var single_consistency: float = 0.8
@export var preferred_scoring_targets: Array[String] = ["T20", "T19", "T18"]
@export var preferred_checkout_doubles: Array[String] = ["D20", "D16", "D18", "D10"]

@export_group("Scoring Personality")
## Multiplier for deliberate 180 attempts while scoring heavily.
@export_range(0.0, 2.0, 0.01) var maximum_appetite: float = 1.0
## Multiplier for 140+ style pressure and treble-first scoring.
@export_range(0.0, 2.0, 0.01) var heavy_scoring_bias: float = 1.0
## Multiplier for stronger first-nine scoring pushes.
@export_range(0.0, 2.0, 0.01) var opening_phase_bias: float = 1.0
## Chance multiplier for chasing a nine-darter after a 180 start.
@export_range(0.0, 2.0, 0.01) var nine_darter_appetite: float = 1.0

@export_group("Checkout Personality")
## Exact checkout habits by score, for example {121: ["T17", "T20", "D5"]}.
@export var preferred_checkout_routes: Dictionary = {}

@export_group("Human Throw Feel")
@export var vertical_speed: float = 680.0
@export var horizontal_speed: float = 790.0
@export var visible_wobble_pixels: float = 1.6
@export var line_chaos_strength: float = 1.9
@export var post_lock_drift_pixels: float = 9.0
@export var post_lock_drift_duration: float = 0.16
@export var fatigue_per_dart: float = 0.46
@export_range(0.0, 1.0, 0.01) var control_skill: float = 0.18
@export_range(0.0, 1.0, 0.01) var pressure: float = 0.52
