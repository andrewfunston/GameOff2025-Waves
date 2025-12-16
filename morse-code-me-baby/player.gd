# Player.gd
extends Node2D

@export var tile_map: TileMap
@export var cell := Vector2i(4, 4)

func _ready() -> void:
	if tile_map == null:
		push_error("Player: tile_map not assigned.")
		return

	var local_pos := tile_map.map_to_local(cell)

	# For isometric maps, this is usually correct:
	local_pos += tile_map.tile_set.tile_size * 0.5

	global_position = tile_map.to_global(local_pos)
