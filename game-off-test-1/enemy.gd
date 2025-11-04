extends Node2D

var mDirection = 1;

@onready var right_ray_cast_2d = $RightRayCast2D
@onready var left_ray_cast_2d_2 = $LeftRayCast2D2
@onready var animated_sprite_2d = $AnimatedSprite2D

func _process(delta):
	if right_ray_cast_2d.is_colliding() or left_ray_cast_2d_2.is_colliding() :
		mDirection*=-1
		animated_sprite_2d.flip_h = !animated_sprite_2d.flip_h
			
	position.x += mDirection * delta * 100.0
