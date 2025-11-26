extends CharacterBody2D

@export var wave: Node2D
var waiting_for_double_jump: bool = false

enum States { idle, walking, running, jumping, falling, landing }

const SPEED: float = 200.0
const ACCEL: float = 400.0
const JUMP_VELOCITY: float = -300.0
const MAX_JUMPS: int = 2        # 1 normal jump + 1 double jump

# Dash settings
const DASH_SPEED: float = 400.0 # how fast you dash
const DASH_TIME: float = 0.15   # how long the dash lasts (seconds)

@onready var mAnimatedSprite2D: AnimatedSprite2D = $AnimatedSprite2D

var mState: States = States.idle
var mIdleTime: float = 0.0
var mJumpsLeft: int = MAX_JUMPS

# Dash state
var mCanDash: bool = true        # reset when touching ground
var mIsDashing: bool = false
var dash_timer: float = 0.0
var dash_dir: int = 0           # -1 left, 1 right


func _ready() -> void:
	# start with full jumps & dash
	mJumpsLeft = MAX_JUMPS

	# when we start the level, if we're not on the floor we need to start falling.
	if not is_on_floor():
		startFall()

	if wave:
		wave.connect("smack_peak", Callable(self, "_on_wave_smack_peak"))


func _physics_process(delta: float) -> void:
	#print(str(velocity) + " " + str(position))

	var direction: float = Input.get_axis("ui_left", "ui_right")

	# ---------- DASH INPUT ----------
	if mIsDashing:
		dash_timer -= delta
		if dash_timer <= 0.0:
			endDash()
			
		move_and_slide()
		return
	elif Input.is_action_just_pressed("dash") and mCanDash:
		var dash_input_dir = -1.0 if mAnimatedSprite2D.flip_h else 1.0
		startDash(int(sign(dash_input_dir)))
		
		move_and_slide()
		return

	# ---------- HORIZONTAL MOVEMENT (disabled during dash) ----------
	if direction != 0.0:
		if direction > 0.0:
			mAnimatedSprite2D.flip_h = false
		elif direction < 0.0:
			mAnimatedSprite2D.flip_h = true

		velocity.x += direction * ACCEL * delta
		velocity.x = clamp(velocity.x, -SPEED, SPEED)
	else:
		# this reduces the velocity towards 0 by SPEED
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	# ---------- STATE MACHINE (disabled during dash) ----------
	if mState == States.idle:
		processIdle(delta)
	elif mState == States.falling:
		processFalling()
	elif mState == States.jumping:
		processJump()
	elif mState == States.walking:
		processWalking()
	elif mState == States.running:
		processRunning()

	# ---------- GRAVITY (disabled during dash) ----------
	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

# ================== STATES ==================

func processFalling() -> void:
	if is_on_floor():
		# we landed, so reset available jumps and dash
		mJumpsLeft = MAX_JUMPS
		mCanDash = true

		# we have an animation for "landing" we may want to add in.
		if velocity.x == 0.0:
			startIdle()
		else:
			startWalk()
	else:
		# allow jump while falling (double jump)
		if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
			startJump()


func processIdle(delta: float) -> void:
	mIdleTime += delta
	if mIdleTime > 5.0 and mAnimatedSprite2D.animation == "idle":
		mAnimatedSprite2D.play("longIdle")

	# jump if we have any jumps left
	if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
		startJump()
	elif velocity.x != 0.0:
		startWalk()


func processJump() -> void:
	# allow another jump while already jumping (double jump)
	if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
		startJump()
		return

	# velocity.y < 0 means that we're still "jumping"
	# velocity.y >= 0 means we've started falling
	if velocity.y >= 0.0:
		startFall()


func processWalking() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		startJump()
	elif not is_on_floor():
		startFall()
	elif velocity.x > 160.0 or velocity.x < -160.0:
		startRun()
	elif velocity.x == 0.0:
		startIdle()


func processRunning() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		startJump()
	elif not is_on_floor():
		startFall()
	elif velocity.x < 160.0 and velocity.x > -160.0:
		startWalk()


# ================== STATE START HELPERS ==================
func startWalk() -> void:
	mState = States.walking
	mAnimatedSprite2D.play("walking")

func startRun() -> void:
	mState = States.running
	mAnimatedSprite2D.play("running")

func startJump() -> void:
	if mJumpsLeft <= 0:
		return

	var is_double_jump: bool = not is_on_floor() and mJumpsLeft == 1

	if is_double_jump and wave:
		# Let the wave do its smack first, then we'll jump on signal
		waiting_for_double_jump = true
		wave.call("on_double_jump", global_position)
	else:
		# Normal / first jump: launch immediately
		mJumpsLeft -= 1
		velocity.y = JUMP_VELOCITY
		mState = States.jumping
		mAnimatedSprite2D.play("jump")


func startFall() -> void:
	mState = States.falling
	mAnimatedSprite2D.play("falling")


func startIdle() -> void:
	mIdleTime = 0.0
	mState = States.idle
	mAnimatedSprite2D.play("idle")


# ================== DASH ==================

func startDash(dir: int) -> void:
	if dir == 0:
		return

	mIsDashing = true
	mCanDash = false
	dash_dir = dir
	dash_timer = DASH_TIME

	# flatten vertical motion during dash for a clean side dash
	velocity.y = 0.0
	velocity.x = float(dash_dir) * DASH_SPEED

	# face in dash direction
	if dash_dir > 0:
		mAnimatedSprite2D.flip_h = false
	elif dash_dir < 0:
		mAnimatedSprite2D.flip_h = true

	# optional: play dash animation if you add one
	if mAnimatedSprite2D.sprite_frames and mAnimatedSprite2D.sprite_frames.has_animation("dash"):
		mAnimatedSprite2D.play("dash")

	# NEW: tell the wave we started dashing so it can hug the player
	if wave and wave.has_method("on_dash_start"):
		wave.call("on_dash_start", dash_dir, global_position)



func endDash() -> void:
	mIsDashing = false

	# If we finished the dash while on the ground, allow another dash immediately
	if is_on_floor():
		mCanDash = true

	# NEW: tell the wave dash is over
	if wave and wave.has_method("on_dash_end"):
		wave.call("on_dash_end")




# =========== WAVE DOUBLE-JUMP CALLBACK ===========

func _on_wave_smack_peak(_pos: Vector2) -> void:
	if not waiting_for_double_jump:
		return

	waiting_for_double_jump = false

	if mJumpsLeft <= 0:
		return

	mJumpsLeft -= 1
	velocity.y = JUMP_VELOCITY
	mState = States.jumping
	mAnimatedSprite2D.play("jump")
