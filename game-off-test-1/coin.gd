extends Area2D

@onready var game_manager = %GameManager
@onready var mCoinNoise = $AudioStreamPlayer2D
@onready var mAnimationPlayer = $AnimationPlayer

func _on_body_entered(body):
	game_manager.addCoin()
	mAnimationPlayer.play("pickup")
