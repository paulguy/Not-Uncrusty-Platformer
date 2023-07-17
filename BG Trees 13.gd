extends Sprite2D

@onready var dialog_box = $"Dialog Box"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_2d_body_entered(body):
	var size = dialog_box.set_text("Hello, I am a happy tree.\nI can't show much useful text yet though so yeah.\nI don't know which tree in this patch I am though.")
	dialog_box.position = Vector2(-size.x / 2.0, -size.y - (texture.get_height() * scale.y) - 8.0)

func _on_area_2d_body_exited(body):
	dialog_box.disappear()
