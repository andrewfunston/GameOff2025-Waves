extends Node

@export var grid: GridManager
@export var tile_map: TileMap
@export var units: Node
@export var player: CharacterBody2D
@export var cursor_node: Node2D
@export var phase_label: Label
@export var board_generator: Node
@export var camera: Camera2D

const MIN_ENEMY_DIST: int = 3
const MAX_TRIES: int = 200

enum Phase { MOVE1, FIRE, MOVE2, ENEMY }
var phase: Phase = Phase.MOVE1

var enemy_last_known_player_cell: Vector2i = Vector2i(-1, -1)
var revealed_enemies: Array[Node2D] = []

func _ready() -> void:
	randomize()

	# 1) Generate board (if you have a generator node)
	if board_generator and board_generator.has_method("generate_board"):
		board_generator.call("generate_board")
	elif board_generator and board_generator.has_method("generate"):
		board_generator.call("generate")

	# 2) Wait one frame so TileMap updates used rect / drawing
	await get_tree().process_frame

	# 3) Recenter camera after map exists
	if camera and camera.has_method("recenter"):
		camera.call("recenter")

	# 4) Spawn units onto grid
	_spawn_player_and_enemy()

	_print_phase()

func _spawn_player_and_enemy() -> void:
	if grid == null or tile_map == null or player == null or units == null:
		push_error("TurnController: assign grid/tile_map/player/units in Inspector.")
		return

	# wipe occupancy
	grid.occupied.clear()

	# --- spawn player anywhere ---
	var player_cell: Vector2i = _random_cell()
	grid.register_unit(player, player_cell)

	# --- find enemy node ---
	var enemy_node: Node2D = null
	if units.has_node("Enemy"):
		enemy_node = units.get_node("Enemy") as Node2D
	else:
		var enemies := get_tree().get_nodes_in_group("enemies")
		if enemies.size() > 0:
			enemy_node = enemies[0] as Node2D

	if enemy_node == null:
		push_error("TurnController: couldn't find Enemy (Units/Enemy) or group 'enemies'.")
		return

	if not enemy_node.is_in_group("enemies"):
		enemy_node.add_to_group("enemies")

	# --- spawn enemy far enough away ---
	var enemy_cell: Vector2i = _random_cell_far_from(player_cell, MIN_ENEMY_DIST)
	grid.register_unit(enemy_node, enemy_cell)

func _random_cell() -> Vector2i:
	var w: int = grid.board_size.x
	var h: int = grid.board_size.y
	return Vector2i(randi_range(0, w - 1), randi_range(0, h - 1))

func _random_cell_far_from(from_cell: Vector2i, min_dist: int) -> Vector2i:
	var best: Vector2i = _random_cell()
	var best_dist: int = -1

	for i in range(MAX_TRIES):
		var c: Vector2i = _random_cell()
		if not grid.is_empty(c):
			continue

		var d: int = abs(c.x - from_cell.x) + abs(c.y - from_cell.y)
		if d >= min_dist:
			return c

		if d > best_dist:
			best_dist = d
			best = c

	return best

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var c := mouse_to_cell()
		if c == Vector2i(-1, -1):
			return

		_update_cursor(c)

		match phase:
			Phase.MOVE1:
				if _try_move_player_to(c):
					phase = Phase.FIRE
					_print_phase()

			Phase.FIRE:
				_fire_mortar(c)
				phase = Phase.MOVE2
				_print_phase()

			Phase.MOVE2:
				if _try_move_player_to(c):
					phase = Phase.ENEMY
					_enemy_turn()
					phase = Phase.MOVE1
					_print_phase()

func mouse_to_cell() -> Vector2i:
	if tile_map == null:
		return Vector2i(-1, -1)

	var local := tile_map.get_local_mouse_position()
	var c := tile_map.local_to_map(local)

	if not grid.in_bounds(c):
		return Vector2i(-1, -1)

	return c

func _try_move_player_to(c: Vector2i) -> bool:
	var ok: bool = grid.move_unit_one_step(player, c)
	if not ok:
		return false
	_update_cursor(player.get("cell"))
	return true

func _fire_mortar(target: Vector2i) -> void:
	enemy_last_known_player_cell = player.get("cell")

	if grid.occupied.has(target):
		var u: Variant = grid.occupied[target]
		if u is Node2D and (u as Node2D).is_in_group("enemies"):
			grid.occupied.erase(target)
			(u as Node2D).queue_free()

	_reveal_enemies_near(target, 1)

func _reveal_enemies_near(center: Vector2i, radius: int) -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Node2D
		if not is_instance_valid(enemy):
			continue

		var ec: Vector2i = enemy.get("cell")
		if abs(ec.x - center.x) <= radius and abs(ec.y - center.y) <= radius:
			var spr := enemy.get_node_or_null("Sprite2D")
			if spr:
				spr.visible = true
			revealed_enemies.append(enemy)

func _enemy_turn() -> void:
	_hide_all_enemies()
	revealed_enemies.clear()

	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Node2D
		if not is_instance_valid(enemy):
			continue

		var from: Vector2i = enemy.get("cell")
		var next := _enemy_choose_step(from)
		if next != from:
			grid.move_unit_one_step(enemy, next)

	enemy_last_known_player_cell = Vector2i(-1, -1)

func _enemy_choose_step(from: Vector2i) -> Vector2i:
	var options: Array[Vector2i] = grid.neighbors4(from)
	options.shuffle()

	for to in options:
		if grid.is_empty(to):
			return to

	return from

func _hide_all_enemies() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var enemy := e as Node2D
		if not is_instance_valid(enemy):
			continue
		var spr := enemy.get_node_or_null("Sprite2D")
		if spr:
			spr.visible = false

func _update_cursor(c: Vector2i) -> void:
	if cursor_node:
		cursor_node.global_position = grid.cell_to_world(c)

func _print_phase() -> void:
	var t := ""
	match phase:
		Phase.MOVE1: t = "MOVE 1: click adjacent tile"
		Phase.FIRE:  t = "FIRE: click a target tile"
		Phase.MOVE2: t = "MOVE 2: click adjacent tile"
	if phase_label:
		phase_label.text = t
	print(t)
