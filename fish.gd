extends Mob

const MIN_SPEED = 500.0
const MAX_SPEED = 3000.0
const DIFF_SPEED = MAX_SPEED - MIN_SPEED
const THRUST_TIME = 0.5
const DRIFT_TIME = 1.0
const MAX_VERT_WANDER = PI / 4.0
@export var startDirection : MovementDirection = MovementDirection.RIGHT

@onready var sprite = get_node("Animation")
@onready var particles = get_node("Bubbles")

var direction = startDirection
var dirVector = Vector2.ZERO
var dirSpeed = MIN_SPEED
var drifting = false

func set_dir(dir, top_open, bottom_open):
	direction = dir
	var min_ang = 0.0
	var max_ang = 0.0
	if dir == MovementDirection.LEFT:
		if top_open:
			max_ang = MAX_VERT_WANDER
		if bottom_open:
			min_ang = -MAX_VERT_WANDER
	else:
		if top_open:
			min_ang = -MAX_VERT_WANDER
		if bottom_open:
			max_ang = MAX_VERT_WANDER
	dirVector = dir_to_vec(direction).rotated(randf_range(min_ang, max_ang))
	if direction == MovementDirection.LEFT:
		sprite.scale.x = 1.0
		sprite.position.x = 4
		particles.position.x = -4
	else:
		sprite.scale.x = -1.0
		sprite.position.x = -4
		particles.position.x = 4

func update_dir(colls):
	var openSides = {
		MovementDirection.UP: true,
		MovementDirection.DOWN: true,
		MovementDirection.LEFT: true,
		MovementDirection.RIGHT: true
	}

	for collId in colls:
		var coll = get_slide_collision(collId)
		var norm = coll.get_normal()
		if norm.x < 0.0:
			openSides[MovementDirection.RIGHT] = false
		elif norm.x > 0.0:
			openSides[MovementDirection.LEFT] = false
		if norm.y < 0.0:
			openSides[MovementDirection.DOWN] = false
		elif norm.y > 0.0:
			openSides[MovementDirection.UP] = false

	if openSides[MovementDirection.LEFT] != openSides[MovementDirection.RIGHT]:
		if openSides[MovementDirection.LEFT]:
			set_dir(MovementDirection.LEFT,
					openSides[MovementDirection.UP],
					openSides[MovementDirection.DOWN])
		else:
			set_dir(MovementDirection.RIGHT,
					openSides[MovementDirection.UP],
					openSides[MovementDirection.DOWN])
	else:
		if randi_range(0, 1) == 0:
			set_dir(MovementDirection.LEFT,
					openSides[MovementDirection.UP],
					openSides[MovementDirection.DOWN])
		else:
			set_dir(MovementDirection.RIGHT,
					openSides[MovementDirection.UP],
					openSides[MovementDirection.DOWN])

func deactivate():
	super()
	set_dir(startDirection, true, true)

# Called when the node enters the scene tree for the first time.
func _ready():
	deactivate()

func _physics_process(delta):
	if drifting:
		dirSpeed = move_toward(dirSpeed, MIN_SPEED, DIFF_SPEED / DRIFT_TIME * delta)
		if dirSpeed == MIN_SPEED:
			drifting = false
			sprite.speed_scale = 2.0
	else:
		dirSpeed = move_toward(dirSpeed, MAX_SPEED, DIFF_SPEED / THRUST_TIME * delta)
		if dirSpeed == MAX_SPEED:
			drifting = true
			sprite.speed_scale = 1.0
	velocity = dirVector * dirSpeed * delta

	move_and_slide()

	var colls = get_slide_collision_count()
	if colls > 0:
		update_dir(colls)
