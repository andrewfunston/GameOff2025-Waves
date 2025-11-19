extends CharacterBody2D

@export var wave: Node2D   # set this to the Wave in the Inspector


enum States {idle, walking, running, jumping, falling, landing}

const SPEED = 200.0
const ACCEL = 400.0
const JUMP_VELOCITY = -300.0
const MAX_JUMPS:int = 2 # NEW: 1 normal jump + 1 double jump

@onready var mAnimatedSprite2D = $AnimatedSprite2D

var mState:States = States.idle
var mLastVelocity:Vector2
var mIdleTime:float = 0
var mJumpsLeft:int = MAX_JUMPS # NEW: how many jumps we have left before landing

func _ready(): # Called when the node enters the scene tree for the first time.
	# NEW: start with full jumps
	mJumpsLeft = MAX_JUMPS
	
	# when the start the level if we're not on the floor we need to start falling.
	if not is_on_floor():
		startFall()

func _physics_process(delta):
	#print(str(velocity) + " " + str(position))
	
	var direction = Input.get_axis("ui_left", "ui_right")
	
	if direction:
		if direction > 0:
			mAnimatedSprite2D.flip_h = false
		elif direction < 0 :
			mAnimatedSprite2D.flip_h = true	
			
		velocity.x += direction * ACCEL * delta
		velocity.x = clamp(velocity.x, -SPEED, SPEED)
	else: # this reduces the velocity towards 0 by SPEED
		velocity.x = move_toward(velocity.x, 0, SPEED)
	
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

	if not is_on_floor():
		velocity += get_gravity() * delta

	# NEW: removed the old ground-only jump here.
	# Jump input is now handled in the state functions so we can also jump in mid-air.
	# if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	# 	velocity.y = JUMP_VELOCITY

	mLastVelocity = velocity
	move_and_slide()

func processFalling():
	if is_on_floor():
		# NEW: we landed, so reset available jumps
		mJumpsLeft = MAX_JUMPS
		
		# we have an animation for "landing" we may want to add in.
		if velocity.x == 0:
			startIdle()
		else:
			startWalk()
	else:
		# NEW: allow jump while falling (double jump)
		if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
			startJump()

func processIdle(delta):
	mIdleTime+=delta
	if(mIdleTime>5 && mAnimatedSprite2D.animation == "idle"):
		mAnimatedSprite2D.play("longIdle")
		
	# NEW: jump if we have any jumps left
	if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
		startJump()
	elif velocity.x != 0:
		startWalk()

func processJump():
	# NEW: allow another jump while already jumping (double jump)
	if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
		startJump()
		return
	
	# velocity.y < 0 means that we're still "jumping"
	# velocity.y >= 0 means we've started falling
	if velocity.y >= 0:
		startFall()

func processWalking():
	# NEW: use jump counter instead of "only if on floor"
	if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
		startJump()
	elif !is_on_floor():
		startFall()
	elif(velocity.x > 160 || velocity.x < -160):
		startRun()
		return	
	elif velocity.x == 0:
		startIdle()

func processRunning():
	# NEW: use jump counter instead of "only if on floor"
	if Input.is_action_just_pressed("ui_accept") and mJumpsLeft > 0:
		startJump()
	elif !is_on_floor():
		startFall()
	elif velocity.x < 160 && velocity.x > -160:
		startWalk()
		
func startWalk():
	mState = States.walking
	mAnimatedSprite2D.play("walking")
	
func startRun():
	mState = States.running
	mAnimatedSprite2D.play("running")	
	
func startJump():
	if mJumpsLeft <= 0:
		return

	# Second jump in the air = double jump
	var is_double_jump := not is_on_floor() and mJumpsLeft == 1

	mJumpsLeft -= 1
	velocity.y = JUMP_VELOCITY
	mState = States.jumping
	mAnimatedSprite2D.play("jump")

	if is_double_jump and wave:
		wave.call("on_double_jump", global_position)

	
func startFall():
	mState = States.falling
	mAnimatedSprite2D.play("falling")
	
func startIdle():
	mIdleTime=0
	mState = States.idle
	mAnimatedSprite2D.play("idle")
