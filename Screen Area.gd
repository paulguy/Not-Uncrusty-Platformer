extends Area2D

var onscreenMobs = []
var toBeOnScreen = []
var mobs_paused = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# eventually on_screen will call add_child which seems to do something with
	# the 2D physics engine that it doesn't like being done while evaluating
	# whether collisions happened, so change to collecting all objects which
	# will become on screen, then do it all at once during processing the frame.
	# This seems to make it happy.
	for item in toBeOnScreen:
		item.on_screen()
	toBeOnScreen.clear()

func _on_area_entered(area : Area2D):
	toBeOnScreen.append(area.get_parent())

func _on_area_exited(area : Area2D):
	area.get_parent().off_screen(onscreenMobs)

func _on_body_entered(body):
	if not mobs_paused:
		if body is Mob:
			onscreenMobs.append(body)
			body.on_screen()

func _on_body_exited(body):
	if not mobs_paused:
		if body is Mob:
			body.off_screen()
			onscreenMobs.erase(body)

func pause_mobs(paused : bool):
	mobs_paused = paused

	for item in onscreenMobs:
		if paused:
			item.process_mode = PROCESS_MODE_DISABLED
		else:
			item.process_mode = PROCESS_MODE_INHERIT
