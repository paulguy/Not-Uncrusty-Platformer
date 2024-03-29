extends Sprite2D

const FADE_IN_TIME = 0.05
const FADE_OUT_TIME = 0.2
const MIN_ALPHA = 0.0
const MAX_ALPHA = 0.5
const MIN_VIS_TIME = 0.2
const MIN_DIST = 0.1
const MIN_SCALE = 0.5

var tween
var vis : bool = false
var vistime : float

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func fade_to(alpha):
	if tween:
		tween.kill()
	tween = self.create_tween()
	tween.tween_property(self, "modulate:a", alpha, FADE_IN_TIME).from_current()

func _process(delta):
	vistime -= delta
	if vis and vistime <= 0.0:
		vis = false
		fade_to(MIN_ALPHA)

func set_thrust(ang, length, len_factor):
	if not vis:
		vis = true
		vistime = MIN_VIS_TIME
		fade_to(MAX_ALPHA)
	self.rotation = ang
	self.position = Vector2.RIGHT.rotated(ang) * (length * (1.0 - MIN_DIST) + MIN_DIST) * len_factor
	length = length * (1.0 - MIN_SCALE) + MIN_SCALE
	self.scale = Vector2(length, length)
