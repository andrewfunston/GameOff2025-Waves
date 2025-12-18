extends Node
class_name GridManager

@export var tile_map: TileMap
@export var board_size: Vector2i = Vector2i(5, 5)

var occupied: Dictionary = {}

const DIRS4: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
]

func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < board_size.x and c.y < board_size.y

func is_empty(c: Vector2i) -> bool:
	return in_bounds(c) and not occupied.has(c)

func is_adjacent4(a: Vector2i, b: Vector2i) -> bool:
	var dx: int = abs(a.x - b.x)
	var dy: int = abs(a.y - b.y)
	return (dx + dy) == 1

func neighbors4(c: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS4:
		var n := c + d
		if in_bounds(n):
			out.append(n)
	return out

func cell_to_world(c: Vector2i) -> Vector2:
	# center of tile in GLOBAL space
	var local := tile_map.map_to_local(c)
	local += tile_map.tile_set.tile_size * 0.5
	return tile_map.to_global(local)

func register_unit(u: Node2D, c: Vector2i) -> void:
	u.set("cell", c)
	occupied[c] = u
	u.global_position = cell_to_world(c)



func move_unit_one_step(u: Node2D, target: Vector2i) -> bool:
	if u == null:
		return false

	var from: Vector2i = u.get("cell")
	if not in_bounds(target):
		return false
	if not is_adjacent4(from, target):
		return false
	if not is_empty(target):
		return false

	occupied.erase(from)
	occupied[target] = u
	u.set("cell", target)
	u.global_position = cell_to_world(target)
	return true
