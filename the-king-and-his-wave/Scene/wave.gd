extends Node2D

@export var follow_target: Node2D          # drag your Player here
@export var follow_speed: float = 300.0    # how fast the wave follows
@export var base_y: float = 0.0            # ocean line; 0 = use current Y
@export var x_offset_behind: float = 32.0  # distance BEHIND the player
@export var smack_time: float = 0.25       # how long the smack lasts (seconds)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var smack_timer: float = 0.0
var original_y: float = 0.0

var last_wave_x: float = 0.0
var last_target_x: float = 0.0
var player_dir: int = 1   # 1 = moving right, -1 = moving left

var smack_start_pos: Vector2              # where the wave starts the smack (waterline)
var smack_target_pos: Vector2             # where the wave wants to hit (player position)


func _ready() -> void:
	# Set the baseline Y at the ocean line
	if base_y == 0.0:
		base_y = global_position.y
	original_y = base_y
	global_position.y = base_y

	last_wave_x = global_position.x
	if follow_target:
		last_target_x = follow_target.global_position.x

	# Play idle if it exists
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _physics_process(delta: float) -> void:
	if smack_timer <= 0.0:
		# --- Normal follow mode (trail behind player) ---
		if follow_target:
			var target_x := _get_trailing_target_x()
			global_position.x = move_toward(global_position.x, target_x, follow_speed * delta)

			# Flip sprite based on wave movement
			var dx_wave := global_position.x - last_wave_x
			if abs(dx_wave) > 0.1 and sprite:
				sprite.flip_h = dx_wave < 0
			last_wave_x = global_position.x

		# stay on the ocean line when not smacking
		global_position.y = original_y
	else:
		# --- Smack mode: move from start → player → back ---
		smack_timer -= delta
		var t := 1.0 - (smack_timer / smack_time)  # 0 → 1 over smack_time
		var curve := sin(t * PI)                   # 0 → 1 → 0

		# Lerp both X and Y between the start position and the target (player)
		var pos := smack_start_pos.lerp(smack_target_pos, curve)
		global_position = pos

		if smack_timer <= 0.0:
			smack_timer = 0.0
			# when done, snap back to waterline on Y, let follow logic pull X back behind
			global_position.y = original_y
			if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")


func _get_trailing_target_x() -> float:
	if not follow_target:
		return global_position.x

	var target_pos := follow_target.global_position

	# Figure out which way the player is moving
	var player_dx := target_pos.x - last_target_x
	if player_dx > 0.5:
		player_dir = 1      # moving right
	elif player_dx < -0.5:
		player_dir = -1     # moving left

	last_target_x = target_pos.x

	# "Behind" = opposite side of movement direction
	# moving right  (dir=1)  → wave = player.x - offset (left)
	# moving left   (dir=-1) → wave = player.x + offset (right)
	return target_pos.x - float(player_dir) * x_offset_behind


# Called by Player when a double jump happens
func on_double_jump(player_pos: Vector2) -> void:
	# Start the smack animation
	smack_timer = smack_time

	# Wave starts from behind the player on the waterline
	var start_x: float = _get_trailing_target_x()
	smack_start_pos = Vector2(start_x, original_y)

	# Target position is the player's current position (X and Y)
	smack_target_pos = player_pos

	# Put the wave visually at the start before the motion begins
	global_position = smack_start_pos

	# Optional special animation
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("smack"):
		sprite.play("smack")
