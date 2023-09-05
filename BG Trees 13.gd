extends Sprite2D

@onready var dialog_box = $"Dialog Box"

func _on_area_2d_body_entered(body):
	if body is Player:
		var size = dialog_box.set_text(body, "{\"ratio\":1.5,\"text\":\"Hello, I am a happy tree.\nI can't show much useful text yet though so yeah.\nI don't know which tree in this patch I am though.\",\"width\":169.482421875}")
		dialog_box.position = Vector2(-size.x / 2.0, -size.y - (texture.get_height() * scale.y) - 2.0)

func _on_area_2d_body_exited(body):
	if body is Player:
		dialog_box.disappear()
