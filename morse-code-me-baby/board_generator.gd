# board_generator.gd
extends TileMap
class_name BoardGenerator

@export var board_size: Vector2i = Vector2i(5, 5)
@export var layer: int = 0
@export var source_id: int = 0

# Put the atlas coords you want to use here (pick a few “ground” tiles)
# Example: [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)]
@export var allowed_atlas_tiles: Array[Vector2i] = []

@export var do_drop_in: bool = true

func _ready() -> void:
	randomize()
	generate_board()
	if do_drop_in:
		play_drop_in()

func generate_board() -> void:
	clear()

	if allowed_atlas_tiles.is_empty():
		push_error("BoardGenerator: allowed_atlas_tiles is empty. Add a few atlas coords in the inspector.")
		return

	for y in range(board_size.y):
		for x in range(board_size.x):
			var atlas := allowed_atlas_tiles[randi() % allowed_atlas_tiles.size()]
			# set_cell(layer, coords, source_id, atlas_coords, alternative)
			set_cell(layer, Vector2i(x, y), source_id, atlas, 0)

func play_drop_in() -> void:
	# Simple “drop + fade” animation
	var final_pos := position
	position = final_pos + Vector2(0, -200)
	modulate.a = 0.0

	var tw := create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position", final_pos, 0.35)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.25)
