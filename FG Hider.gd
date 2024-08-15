extends TileMapLayer

func _init():
	# set visible in case it was hidden in editing
	visible = true

func _on_revealer_body_entered(body):
	if body is Player:
		visible = false

func _on_revealer_body_exited(body):
	if body is Player:
		visible = true
