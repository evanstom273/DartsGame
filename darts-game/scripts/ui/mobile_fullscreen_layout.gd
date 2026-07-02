extends Node

const BOARD_OUTER_RADIUS: float = 415.0
const SCOREBOARD_WIDTH: float = 650.0
const SCOREBOARD_HEIGHT: float = 188.0

## Applies this layout only on Android/iOS/mobile exports.
@export var enabled_on_mobile: bool = true
## Forces the layout on desktop for editor testing.
@export var force_enabled: bool = false

@export_group("Layout")
## Top position for the compact scoreboard in the expanded canvas.
@export var scoreboard_top: float = 16.0
## Scoreboard scale used on mobile.
@export var scoreboard_scale: float = 0.86
## Largest allowed dartboard scale on mobile.
@export var maximum_board_scale: float = 1.0
## Empty space kept below the board.
@export var bottom_margin: float = 24.0
## Gap between the scoreboard and the board.
@export var scoreboard_board_gap: float = 16.0
## Gap between the checkout route and the scoreboard.
@export var checkout_route_gap: float = 24.0

@export_group("Node Paths")
## Dartboard node to center and enlarge for mobile.
@export var dartboard_path: NodePath = NodePath("../Dartboard")
## Throw controller whose board_scale must match the visible dartboard.
@export var throw_controller_path: NodePath = NodePath("../ThrowLayer")
## Desktop broadcast camera split; hidden on mobile.
@export var board_camera_zone_path: NodePath = NodePath("../BoardCameraZone")
## Main scoreboard, moved to the top center on mobile.
@export var match_scoreboard_path: NodePath = NodePath("../ScoreboardLayer/MatchScoreboard")
## Checkout route tiles, kept beside the compact scoreboard.
@export var checkout_route_path: NodePath = NodePath("../ScoreboardLayer/CheckoutRoute")
## Stats panel, hidden during mobile play.
@export var stats_panel_path: NodePath = NodePath("../ScoreboardLayer/StatsPanel")
## Procedural backdrop, retargeted to the centered board.
@export var backdrop_path: NodePath = NodePath("../BroadcastBackdrop")

var _layout_enabled: bool = false


func _ready() -> void:
	_layout_enabled = _should_apply_mobile_layout()

	if not _layout_enabled:
		return

	_apply_mobile_layout()
	_apply_mobile_layout.call_deferred()


func _notification(what: int) -> void:
	if _layout_enabled and what == NOTIFICATION_WM_SIZE_CHANGED:
		_apply_mobile_layout.call_deferred()


func _should_apply_mobile_layout() -> bool:
	if force_enabled:
		return true

	if not enabled_on_mobile:
		return false

	return OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")


func _apply_mobile_layout() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var usable_height: float = maxf(320.0, viewport_size.y - scoreboard_top - SCOREBOARD_HEIGHT * scoreboard_scale - scoreboard_board_gap - bottom_margin)
	var board_scale: float = minf(maximum_board_scale, usable_height / (BOARD_OUTER_RADIUS * 2.0))
	var board_radius: float = BOARD_OUTER_RADIUS * board_scale
	var scoreboard_position: Vector2 = Vector2((viewport_size.x - SCOREBOARD_WIDTH * scoreboard_scale) * 0.5, scoreboard_top)
	var board_position: Vector2 = Vector2(viewport_size.x * 0.5, scoreboard_top + SCOREBOARD_HEIGHT * scoreboard_scale + scoreboard_board_gap + board_radius)

	_apply_board(board_position, board_scale)
	_apply_scoreboard(scoreboard_position)
	_apply_checkout_route(scoreboard_position)
	_set_canvas_item_visible(board_camera_zone_path, false)
	_set_canvas_item_visible(stats_panel_path, false)
	_apply_backdrop(board_position)


func _apply_board(board_position: Vector2, mobile_board_scale: float) -> void:
	var throw_controller: Node = get_node_or_null(throw_controller_path)
	if throw_controller != null:
		throw_controller.set("board_scale", mobile_board_scale)
		if throw_controller.has_method("_apply_board_scale"):
			throw_controller.call("_apply_board_scale")

	var dartboard: Node2D = get_node_or_null(dartboard_path) as Node2D
	if dartboard != null:
		dartboard.position = board_position
		dartboard.set("board_scale", mobile_board_scale)


func _apply_scoreboard(scoreboard_position: Vector2) -> void:
	var match_scoreboard: Control = get_node_or_null(match_scoreboard_path) as Control
	if match_scoreboard == null:
		return

	match_scoreboard.position = scoreboard_position
	match_scoreboard.scale = Vector2.ONE * scoreboard_scale


func _apply_checkout_route(scoreboard_position: Vector2) -> void:
	var checkout_route: Control = get_node_or_null(checkout_route_path) as Control
	if checkout_route == null:
		return

	var route_width: float = checkout_route.size.x
	if route_width <= 0.0:
		route_width = 180.0

	var route_x: float = maxf(14.0, scoreboard_position.x - route_width * scoreboard_scale - checkout_route_gap)
	var player_route_top: float = scoreboard_position.y + 44.0 * scoreboard_scale
	var ai_route_top: float = scoreboard_position.y + 98.0 * scoreboard_scale

	checkout_route.position = Vector2(route_x, player_route_top)
	checkout_route.scale = Vector2.ONE * scoreboard_scale

	var scoreboard_presenter: Node = checkout_route.get_parent()
	if scoreboard_presenter != null:
		scoreboard_presenter.set("checkout_route_top", player_route_top)
		scoreboard_presenter.set("player_route_top", player_route_top)
		scoreboard_presenter.set("ai_route_top", ai_route_top)


func _apply_backdrop(board_position: Vector2) -> void:
	var backdrop: Node = get_node_or_null(backdrop_path)
	if backdrop == null:
		return

	backdrop.set("spotlight_center", board_position)
	backdrop.set("divider_x", -200.0)


func _set_canvas_item_visible(path: NodePath, is_visible: bool) -> void:
	var item: CanvasItem = get_node_or_null(path) as CanvasItem
	if item != null:
		item.visible = is_visible
