extends TileMap

func _on_revealer_body_entered(body):
	if body is Player:
		visible = false

func _on_revealer_body_exited(body):
	if body is Player:
		visible = true
