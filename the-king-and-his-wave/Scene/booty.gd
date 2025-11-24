extends Area2D

@export var value: int = 1   # how much this piece of booty is worth

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Play idle animation if it exists
	if anim and anim.sprite_frames and anim.sprite_frames.has_animation("idle"):
		anim.play("idle")

	# Detect when something touches this Area2D
	connect("body_entered", Callable(self, "_on_body_entered"))


func _on_body_entered(body: Node) -> void:
	# Only react to the player
	if not body.is_in_group("player"):
		return

	# TODO: later we can tell a GameManager to add 'value' to a coin counter
	# e.g. body.add_booty(value) or GameManager.add_booty(value)

	# For now just disappear when collected
	queue_free()
