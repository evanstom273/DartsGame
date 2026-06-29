@tool
extends Control

const THROWER_PLAYER: int = 0
const THROWER_AI: int = 1
const INACTIVE_ROW_COLOR: Color = Color(0.74, 0.76, 0.86, 1.0)
const HIDDEN_BADGE_COLOR: Color = Color(1.0, 1.0, 1.0, 0.0)

@export_enum("Player", "AI") var active_thrower: int = THROWER_PLAYER:
	set(value):
		if active_thrower == value:
			return

		active_thrower = value
		_refresh_ui()

@export_enum("Player", "AI") var first_thrower: int = THROWER_PLAYER:
	set(value):
		if first_thrower == value:
			return

		first_thrower = value
		_refresh_ui()

@export_enum("Player", "AI") var checkout_route_thrower: int = THROWER_PLAYER:
	set(value):
		if checkout_route_thrower == value:
			return

		checkout_route_thrower = value
		_refresh_ui()

@export var player_on_nine: bool = false:
	set(value):
		if player_on_nine == value:
			return

		player_on_nine = value
		_refresh_ui()

@export var ai_on_nine: bool = false:
	set(value):
		if ai_on_nine == value:
			return

		ai_on_nine = value
		_refresh_ui()

@export var checkout_route_visible: bool = false:
	set(value):
		if checkout_route_visible == value:
			return

		checkout_route_visible = value
		_refresh_ui()

@export var pulse_enabled: bool = true
@export var checkout_route_path: NodePath = NodePath("CheckoutRoute")
@export var player_row_path: NodePath = NodePath("MatchScoreboard/PlayerRow")
@export var ai_row_path: NodePath = NodePath("MatchScoreboard/AIRow")
@export var player_first_icon_path: NodePath = NodePath("MatchScoreboard/PlayerRow/FirstThrowIcon")
@export var ai_first_icon_path: NodePath = NodePath("MatchScoreboard/AIRow/FirstThrowIcon")
@export var player_current_icon_path: NodePath = NodePath("MatchScoreboard/PlayerRow/CurrentThrowIcon")
@export var ai_current_icon_path: NodePath = NodePath("MatchScoreboard/AIRow/CurrentThrowIcon")
@export var player_nine_badge_path: NodePath = NodePath("MatchScoreboard/PlayerRow/NineDartBadge")
@export var ai_nine_badge_path: NodePath = NodePath("MatchScoreboard/AIRow/NineDartBadge")
@export var checkout_route_top: float = 296.0
@export var player_route_top: float = 296.0
@export var ai_route_top: float = 350.0

var _pulse_time: float = 0.0


func _ready() -> void:
	_refresh_ui()


func _process(delta: float) -> void:
	if not pulse_enabled:
		return

	_pulse_time += delta
	_refresh_motion()


func _refresh_ui() -> void:
	if not is_inside_tree():
		return

	_set_visible(checkout_route_path, checkout_route_visible)
	_set_visible(player_first_icon_path, first_thrower == THROWER_PLAYER)
	_set_visible(ai_first_icon_path, first_thrower == THROWER_AI)
	_set_visible(player_current_icon_path, active_thrower == THROWER_PLAYER)
	_set_visible(ai_current_icon_path, active_thrower == THROWER_AI)
	_set_visible(player_nine_badge_path, player_on_nine)
	_set_visible(ai_nine_badge_path, ai_on_nine)
	_position_checkout_route()
	_refresh_motion()


func _refresh_motion() -> void:
	if not is_inside_tree():
		return

	var pulse: float = (sin(_pulse_time * 2.6) + 1.0) * 0.5
	var active_strength: float = 0.94 + pulse * 0.06
	var route_strength: float = 0.90 + pulse * 0.10
	var badge_strength: float = 0.78 + pulse * 0.22

	_set_modulate(player_row_path, Color(active_strength, active_strength, active_strength, 1.0) if active_thrower == THROWER_PLAYER else INACTIVE_ROW_COLOR)
	_set_modulate(ai_row_path, Color(active_strength, active_strength, active_strength, 1.0) if active_thrower == THROWER_AI else INACTIVE_ROW_COLOR)
	_set_modulate(checkout_route_path, Color(route_strength, route_strength, route_strength, 1.0) if checkout_route_visible else HIDDEN_BADGE_COLOR)
	_set_modulate(player_nine_badge_path, Color(1.0, 0.76, 0.18, badge_strength) if player_on_nine else HIDDEN_BADGE_COLOR)
	_set_modulate(ai_nine_badge_path, Color(1.0, 0.76, 0.18, badge_strength) if ai_on_nine else HIDDEN_BADGE_COLOR)


func _set_visible(path: NodePath, is_visible: bool) -> void:
	var item: CanvasItem = get_node_or_null(path) as CanvasItem

	if item != null:
		item.visible = is_visible


func _position_checkout_route() -> void:
	var route: Control = get_node_or_null(checkout_route_path) as Control

	if route == null:
		return

	var route_height: float = route.offset_bottom - route.offset_top
	var target_top: float = checkout_route_top

	route.offset_top = target_top
	route.offset_bottom = target_top + route_height


func _set_modulate(path: NodePath, color: Color) -> void:
	var item: CanvasItem = get_node_or_null(path) as CanvasItem

	if item != null:
		item.modulate = color
