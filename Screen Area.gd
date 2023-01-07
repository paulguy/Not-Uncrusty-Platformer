extends Area2D

var onscreenMobs = {}

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_area_entered(area : Area2D):
	area.get_parent().on_screen()

func _on_area_exited(area : Area2D):
	area.get_parent().off_screen(onscreenMobs)

func _on_body_entered(body):
	if body is Mob:
		onscreenMobs[body] = null
		body.on_screen()

func _on_body_exited(body):
	if body is Mob:
		body.off_screen()
		onscreenMobs.erase(body)
