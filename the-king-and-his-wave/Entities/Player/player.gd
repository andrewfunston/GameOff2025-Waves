extends CharacterBody2D

enum States {idle, walking, running, jumping, falling, landing}

const SPEED = 300.0
const ACCEL = 600.0
const JUMP_VELOCITY = -400.0

@onready var mAnimatedSprite2D = $AnimatedSprite2D

var mState:States = States.idle
var mLastVelocity:Vector2
var mIdleTime:float = 0

func _ready():# Called when the node enters the scene tree for the first time.
	# when the start the level if we're not on the floor we need to start falling.
	if not is_on_floor():
		startFall()

func _physics_process(delta):
	print(str(velocity) + " " + str(position))
	
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

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	mLastVelocity = velocity
	move_and_slide()

func processFalling():
	if is_on_floor():
		# we have an animation for "landing" we may want to add in.
		if velocity.x == 0:
			startIdle()
		else:
			startWalk()
	
func processIdle(delta):
	mIdleTime+=delta
	if(mIdleTime>5 && mAnimatedSprite2D.animation == "idle"):
		mAnimatedSprite2D.play("longIdle")
		
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		startJump()
	elif velocity.x != 0:
		startWalk()

func processJump():
	# velocity.y < 0 means that we're still "jumping"
	# velocity.x > 0 means we've started falling
	if velocity.y >= 0:
		startFall()

func processWalking():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		startJump()
	elif !is_on_floor():
		startFall()
	elif(velocity.x > 160 || velocity.x < -160):
		startRun()
		return	
	elif velocity.x == 0:
		startIdle()

func processRunning():
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
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
	velocity.y = JUMP_VELOCITY
	mState = States.jumping
	mAnimatedSprite2D.play("jump")
	
func startFall():
	mState = States.falling
	mAnimatedSprite2D.play("falling")
	
func startIdle():
	mIdleTime=0
	mState = States.idle
	mAnimatedSprite2D.play("idle")
