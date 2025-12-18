extends Camera2D

@export var tile_map: TileMap
@export var board_size: Vector2i = Vector2i(5, 5)

func _ready() -> void:
	make_current()
	await get_tree().process_frame
	recenter()

func recenter() -> void:
	if tile_map == null or tile_map.tile_set == null:
		push_error("Camera2D: tile_map not assigned.")
		return

	var used: Rect2i = tile_map.get_used_rect()
	if used.size == Vector2i.ZERO:
		used = Rect2i(Vector2i.ZERO, board_size)

	# avoid “integer division” warnings by using >> 1
	var cx: int = used.position.x + (used.size.x >> 1)
	var cy: int = used.position.y + (used.size.y >> 1)
	var center_cell := Vector2i(cx, cy)

	var local := tile_map.map_to_local(center_cell)
	local += tile_map.tile_set.tile_size * 0.5
	global_position = tile_map.to_global(local)
