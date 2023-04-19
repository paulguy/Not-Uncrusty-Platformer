extends Node2D

const FADE_IN_TIME = 0.05
const FADE_OUT_TIME = 0.2
const FRAMES = 9
const MIN_ALPHA = 0.05
const MAX_ALPHA = 0.5

@onready var ring = get_node("Ring")
@onready var pie = get_node("Pie")
var tween

var val = 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func fade_to(alpha):
	if tween:
		tween.kill()
	tween = self.create_tween()
	tween.tween_property(self, "modulate:a", alpha, FADE_IN_TIME).from_current()

func _process(_delta):
	if val < 1.0:
		# become visible
		fade_to(MAX_ALPHA)
	else:
		# become invisible
		fade_to(MIN_ALPHA)

	var frame = int(val * (FRAMES - (1.0/FRAMES)))

	pie.region_rect.position.y = (frame + 1) * 24

func set_thrust(newval):
	val = clampf(newval, 0.0, 1.0)
