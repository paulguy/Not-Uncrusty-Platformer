extends AnimatedSprite2D

func animate(speed : float, pos : Vector2, mod : Color):
	position = pos
	modulate = mod
	visible = true
	play("default", speed)

func _on_animation_finished():
	stop()
	visible = false
	get_parent().done_animating(self)
