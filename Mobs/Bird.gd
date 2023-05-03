extends Mob

enum BirdMode {
	WANDERING,
	FLYING,
	LANDING
}

@export var texture : Texture2D
@export var start_facing : MovementDirection = MovementDirection.RIGHT
@export var WANDER_SPEED : float = 50.0
@export var WANDER_JUMP : float = -50.0
@export var MIN_NEXT_FLY_TIME : float = 5.0
@export var MAX_NEXT_FLY_TIME : float = 15.0
@export var MIN_FLY_TIME : float = 2.0
@export var MAX_FLY_TIME : float = 7.0
@export var MIN_TAKEOFF_FLAP_POWER : float = 200.0
@export var MAX_TAKEOFF_FLAP_POWER : float = 300.0
@export var MIN_FLAP_POWER : float = 50.0
@export var MAX_FLAP_POWER : float = 100.0
@export var MIN_DIR_CHANGE_TIME : float = 0.5
@export var MAX_DIR_CHANGE_TIME : float = 5.0
@export var FLAP_DAMPING : float = 0.99
@export var GLIDE_ACCEL : float = 1.02
@export var FALL_RECOVER_SPEED : float = 200.0
@export var FLAP_GRAVITY : float = 0.8
@export var GLIDE_GRAVITY : float = 0.6
@export var MAX_LAND_SPEED : float = 200.0
@export var LANDING_FLAP : float = 0.4

var ANIM_STAND = 0
var ANIM_GLIDE = 16
var ANIM_FLAP = 32

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

func flap(multiplier : float = 1.0):
	sprite.texture.region.position.x = ANIM_FLAP
	velocity.y = -randf_range(MIN_FLAP_POWER, MAX_FLAP_POWER) * multiplier
	lastFlapVelocity = velocity.y

func land():
	sprite.texture.region.position.x = ANIM_GLIDE
	mode = BirdMode.LANDING

func wander():
	set_next_fly_time()
	mode = BirdMode.WANDERING

func turn_around():
	facing = opp_dir(facing)
	if facing == MovementDirection.RIGHT:
		sprite.flip_h = false
		velocity.x = WANDER_SPEED
	else:
		sprite.flip_h = true
		velocity.x = -WANDER_SPEED

func deactivate():
	super()
	mode = BirdMode.LANDING
	facing = start_facing
	set_next_fly_time()
	set_next_dir_change_time()

func _ready():
	if texture == null:
		texture = sprite.texture.atlas
	var texHeight = texture.get_height()
	# make sure there's a new atlas texture per each bird.
	sprite.texture = AtlasTexture.new()
	sprite.texture.atlas = texture
	sprite.texture.region = Rect2(0, 0, texHeight, texHeight)
	ANIM_GLIDE = texHeight
	ANIM_FLAP = texHeight * 2
	deactivate()

func _physics_process(delta):
	match mode:
		BirdMode.WANDERING:
			velocity.y += gravity * delta
			sprite.texture.region.position.x = ANIM_STAND
			if is_on_wall():
				turn_around()
			if velocity.y > FALL_RECOVER_SPEED:
				take_off()
			else:
				if is_on_floor():
					if facing == MovementDirection.LEFT:
						velocity = Vector2(-WANDER_SPEED, WANDER_JUMP)
					else:
						velocity = Vector2(WANDER_SPEED, WANDER_JUMP)
				nextFlyTime -= delta
				if nextFlyTime <= 0.0:
					take_off()
				nextDirChangeTime -= delta
				if nextDirChangeTime <= 0:
					set_next_dir_change_time()
					turn_around()
		BirdMode.FLYING:
			if is_on_wall():
				turn_around()
				land()
			elif is_on_floor():
				wander()
			else:
				if velocity.y > 0.0:
					sprite.texture.region.position.x = 16
					velocity.x *= GLIDE_ACCEL
					velocity.y += gravity * GLIDE_GRAVITY * delta
					if velocity.y > -lastFlapVelocity:
						flap()
				else:
					velocity.x *= FLAP_DAMPING
					velocity.y += gravity * FLAP_GRAVITY * delta
				nextFlyTime -= delta
				if nextFlyTime <= 0.0:
					land()
		BirdMode.LANDING:
			if is_on_wall():
				turn_around()
			if is_on_floor():
				wander()
			else:
				velocity.x *= FLAP_DAMPING
				velocity.y += gravity * FLAP_GRAVITY * delta
				if velocity.y > MAX_LAND_SPEED * 0.75:
					sprite.texture.region.position.x = ANIM_GLIDE
					if velocity.y > MAX_LAND_SPEED:
						flap(LANDING_FLAP)

	move_and_slide()
