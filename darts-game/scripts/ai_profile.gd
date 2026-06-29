extends Resource
class_name AIProfile

## Name shown in editors/debugging for this AI preset.
@export var display_name: String = "AI"
## Lower target 3-dart average for generated visits. Actual match average can drift with variance, misses, busts, and checkout play.
@export var average_min: float = 70.0
## Upper target 3-dart average for generated visits. Values above this are still possible from hot streaks or short samples.
@export var average_max: float = 85.0
## Random visit-to-visit swing around the average band. Higher values create more streaky or erratic AI scoring.
@export var variance: float = 12.0
## Chance to land intended treble targets before pressure and miss-shape adjustments.
@export_range(0.0, 1.0, 0.01) var treble_consistency: float = 0.45
## Chance to land intended double targets before pressure and nerve adjustments.
@export_range(0.0, 1.0, 0.01) var double_consistency: float = 0.32
## Chance to land intended single targets. This keeps weaker AI from missing the whole segment constantly.
@export_range(0.0, 1.0, 0.01) var single_consistency: float = 0.82
## How well the AI holds up near doubles and match pressure. Higher means less pressure penalty.
@export_range(0.0, 1.0, 0.01) var nerve: float = 0.50
## Scoring targets considered when the AI is not on a checkout or setup shot.
@export var preferred_scoring_targets: Array[String] = ["T20", "T19", "T18"]
## Doubles the AI prefers to leave or finish on when multiple routes are plausible.
@export var preferred_checkout_doubles: Array[String] = ["D20", "D16", "D18", "D10"]
