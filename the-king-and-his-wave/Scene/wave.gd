extends Node2D

signal smack_peak(player_pos: Vector2)     # tells player "I hit you now!"

@export var follow_target: Node2D          # drag your Player here
@export var follow_speed: float = 300.0    # how fast the wave follows
@export var base_y: float = 0.0            # ocean line; 0 = use current Y
@export var x_offset_behind: float = 32.0  # distance BEHIND the player
@export var smack_time: float = 0.25       # how long the smack lasts (seconds)

# NEW: dash hug settings
@export var dash_hug_distance_x: float = 8.0   # how close to the side of the player during dash
@export var dash_hug_offset_y: float = 0.0     # vertical offset during dash (0 = same height as player)

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var smack_timer: float = 0.0
var original_y: float = 0.0

var last_wave_x: float = 0.0
var last_target_x: float = 0.0
var player_dir: int = 1   # 1 = moving right, -1 = moving left

var smack_start_pos: Vector2      # where the wave starts the smack (waterline)
var smack_target_pos: Vector2     # where the wave wants to hit (player position)
var has_emitted_smack: bool = false   # so we only fire the signal once per smack

# NEW: dash hug state
var is_dashing: bool = false
var dash_dir: int = 1


func _ready() -> void:
	if base_y == 0.0:
		base_y = global_position.y
	original_y = base_y
	global_position.y = base_y

	last_wave_x = global_position.x
	if follow_target:
		last_target_x = follow_target.global_position.x

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _physics_process(delta: float) -> void:
	# If we're in dash hug mode, do that and skip follow/smack
	if is_dashing:
		_process_dash_hug()
		return

	if smack_timer <= 0.0:
		# --- Normal follow mode (trail behind player) ---
		if follow_target:
			var target_x := _get_trailing_target_x()
			global_position.x = move_toward(global_position.x, target_x, follow_speed * delta)

			var dx_wave := global_position.x - last_wave_x
			if abs(dx_wave) > 0.1 and sprite:
				sprite.flip_h = dx_wave < 0
			last_wave_x = global_position.x

		global_position.y = original_y
	else:
		# --- Smack mode: move from start → player → back ---
		smack_timer -= delta
		var t := 1.0 - (smack_timer / smack_time)  # 0 → 1 over smack_time
		var curve := sin(t * PI)                   # 0 → 1 → 0

		var pos := smack_start_pos.lerp(smack_target_pos, curve)
		global_position = pos

		# When we reach the top of the smack (curve ~ 1), tell the player
		if not has_emitted_smack and curve >= 0.99:
			has_emitted_smack = true
			emit_signal("smack_peak", global_position)

		if smack_timer <= 0.0:
			smack_timer = 0.0
			global_position.y = original_y
			if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
				sprite.play("idle")


func _get_trailing_target_x() -> float:
	if not follow_target:
		return global_position.x

	var target_pos := follow_target.global_position

	var player_dx := target_pos.x - last_target_x
	if player_dx > 0.5:
		player_dir = 1
	elif player_dx < -0.5:
		player_dir = -1

	last_target_x = target_pos.x

	return target_pos.x - float(player_dir) * x_offset_behind


func on_double_jump(player_pos: Vector2) -> void:
	# Don't start smack animation while in dash hug
	if is_dashing:
		return

	# Start the smack animation
	smack_timer = smack_time
	has_emitted_smack = false

	# Wave starts behind the player on the waterline
	var start_x: float = _get_trailing_target_x()
	smack_start_pos = Vector2(start_x, original_y)

	# Target position is the player's current position (X and Y)
	smack_target_pos = player_pos

	# Put the wave visually at the start before the motion begins
	global_position = smack_start_pos

	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("smack"):
		sprite.play("smack")


# ========= DASH HUG API (called from Player) =========

func on_dash_start(dir: int, player_pos: Vector2) -> void:
	is_dashing = true
	dash_dir = dir

	# cancel any smack animation
	smack_timer = 0.0
	has_emitted_smack = false

	_update_dash_hug_position()

	if sprite and sprite.sprite_frames:
		if sprite.sprite_frames.has_animation("dash"):
			sprite.play("dash")
		elif sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle") # fallback


func on_dash_end() -> void:
	is_dashing = false
	# snap back to waterline; normal follow resumes next frame
	global_position.y = original_y
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _update_dash_hug_position() -> void:
	if not follow_target:
		return

	var p: Vector2 = follow_target.global_position

	# place the wave pig slightly to the side of the player
	if dash_dir > 0:
		# dashing right → wave sits just to the left
		global_position.x = p.x - dash_hug_distance_x
		if sprite:
			sprite.flip_h = false
	else:
		# dashing left → wave sits just to the right
		global_position.x = p.x + dash_hug_distance_x
		if sprite:
			sprite.flip_h = true

	# hug vertically around the player's body
	global_position.y = p.y + dash_hug_offset_y


func _process_dash_hug() -> void:
	# follow the player closely while dashing
	_update_dash_hug_position()
