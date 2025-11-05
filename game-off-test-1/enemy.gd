extends Node2D

var mDirection = 1;

@onready var right_ray_cast_2d = $RightRayCast2D
@onready var left_ray_cast_2d_2 = $LeftRayCast2D2
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var mPlayer = $"../Player"

func _physics_process(delta):
	var dir  = (mPlayer.global_position - global_position)
	if dir.length() < 1.0:
		return  # already at/near target
	elif dir.x > 0:
		animated_sprite_2d.flip_h = false
	else:
		animated_sprite_2d.flip_h = true
		
	dir = dir.normalized()
	global_position += dir * 80 * delta
	
	

#func _process(delta):
	#if right_ray_cast_2d.is_colliding() or left_ray_cast_2d_2.is_colliding() :
		#mDirection*=-1
		#animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
			
	#position.x += mDirection * delta * 100.0
	
	#look_at(mPlayer.global_position);
