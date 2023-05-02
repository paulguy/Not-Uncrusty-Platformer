extends Mob

enum BirdMode {
	WANDERING,
	FLYING,
	LANDING
}

@export var start_facing = MovementDirection.RIGHT

const SPEED = 50
const JUMP_VELOCITY = -50.0
const MIN_NEXT_FLY_TIME = 5.0
const MAX_NEXT_FLY_TIME = 15.0
const MIN_FLY_TIME = 2.0
const MAX_FLY_TIME = 7.0
const MIN_TAKEOFF_FLAP_POWER = 200.0
const MAX_TAKEOFF_FLAP_POWER = 300.0
const MIN_FLAP_POWER = 50.0
const MAX_FLAP_POWER = 100.0
const MIN_DIR_CHANGE_TIME = 0.5
const MAX_DIR_CHANGE_TIME = 5.0
const FLAP_DAMPING = 0.99
const GLIDE_ACCEL = 1.02
const FALL_RECOVER_SPEED = 200.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite = get_node("Sprite2D")
var mode
var nextFlyTime
var facing
var lastFlapVelocity
var nextDirChangeTime

func set_next_fly_time():
	nextFlyTime = randf_range(MIN_NEXT_FLY_TIME, MAX_NEXT_FLY_TIME)

func set_next_dir_change_time():
	nextDirChangeTime = randf_range(MIN_DIR_CHANGE_TIME, MAX_DIR_CHANGE_TIME)

func take_off():
	mode = BirdMode.FLYING
	velocity.y = -randf_range(MIN_TAKEOFF_FLAP_POWER, MAX_TAKEOFF_FLAP_POWER)
	if facing == MovementDirection.LEFT:
		velocity.x = velocity.y * 0.2
	else:
		velocity.x = velocity.y * -0.2
	lastFlapVelocity = MAX_FLAP_POWER
	nextFlyTime = randf_range(MIN_FLY_TIME, MAX_FLY_TIME)

func flap():
	velocity.y = -randf_range(MIN_FLAP_POWER, MAX_FLAP_POWER)
	lastFlapVelocity = velocity.y

func turn_around():
	facing = opp_dir(facing)
	if facing == MovementDirection.RIGHT:
		sprite.flip_h = false
		velocity.x = SPEED
	else:
		sprite.flip_h = true
		velocity.x = -SPEED

func deactivate():
	super()
	mode = BirdMode.LANDING
	facing = start_facing
	set_next_fly_time()
	set_next_dir_change_time()

func _ready():
	deactivate()

func _physics_process(delta):
	velocity.y += gravity * delta

	move_and_slide()

	match mode:
		BirdMode.WANDERING:
			sprite.texture.region.position.x = 0
			if is_on_wall():
				turn_around()
			if velocity.y > FALL_RECOVER_SPEED:
				take_off()
			else:
				if is_on_floor():
					if facing == MovementDirection.LEFT:
						velocity = Vector2(-SPEED, JUMP_VELOCITY)
					else:
						velocity = Vector2(SPEED, JUMP_VELOCITY)
				nextFlyTime -= delta
				if nextFlyTime <= 0.0:
					take_off()
				nextDirChangeTime -= delta
				if nextDirChangeTime <= 0:
					set_next_dir_change_time()
					turn_around()
		BirdMode.FLYING:
			if is_on_wall():
				mode = BirdMode.LANDING
			elif is_on_floor():
				mode = BirdMode.WANDERING
				set_next_fly_time()
			else:
				if velocity.y > 0.0:
					sprite.texture.region.position.x = 16
					velocity.x *= GLIDE_ACCEL
					if velocity.y > -lastFlapVelocity:
						flap()
				else:
					sprite.texture.region.position.x = 32
					velocity.x *= FLAP_DAMPING
				nextFlyTime -= delta
				if nextFlyTime <= 0.0:
					mode = BirdMode.LANDING
		BirdMode.LANDING:
			sprite.texture.region.position.x = 32
			if is_on_wall():
				turn_around()
			if is_on_floor():
				mode = BirdMode.WANDERING
				set_next_fly_time()
			else:
				velocity.y *= FLAP_DAMPING
