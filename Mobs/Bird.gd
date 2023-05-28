extends Mob

enum BirdMode {
	IDLE,
	WANDERING,
	FLYING,
	LANDING
}

@export var texture : Texture2D
@export var start_facing : MovementDirection = MovementDirection.RIGHT
@export var WANDER_SPEED : float = 50.0
@export var WANDER_JUMP : float = -50.0
@export var MIN_NEXT_FLY_TIME : float = 1.0
@export var MAX_NEXT_FLY_TIME : float = 4.0
@export var MIN_FLY_TIME : float = 2.0
@export var MAX_FLY_TIME : float = 7.0
@export var MIN_TAKEOFF_HEIGHT_GAIN : float = 40.0
@export var MAX_TAKEOFF_HEIGHT_GAIN : float = 100.0
@export var MIN_FLAP_POWER : float = 50.0
@export var MAX_FLAP_POWER : float = 100.0
@export var MIN_DIR_CHANGE_TIME : float = 0.5
@export var MAX_DIR_CHANGE_TIME : float = 5.0
@export var FLAP_DAMPING : float = 0.99
@export var GLIDE_ACCEL : float = 1.035
@export var FALL_RECOVER_SPEED : float = 200.0
@export var FLAP_GRAVITY : float = 0.5
@export var GLIDE_GRAVITY : float = 0.3
@export var MAX_LAND_SPEED : float = 200.0
@export var LANDING_FLAP : float = 0.4
@export var TAKEOFF_FLAP : float = 1.5
@export var MAX_TAKEOFF_FALL_SPEED : float = 60.0
@export var MIN_KICKOFF_SPEED : float = 25.0
@export var MAX_KICKOFF_SPEED : float = 40.0
@export var TAKEOFF_ACCEL : float = 1.02
@export var TRY_MAX_DISTANCE : float = 500.0
@export var DISTANCE_POWER_FACTOR : float = 0.5

var ANIM_STAND = 0
var ANIM_GLIDE = 16
var ANIM_FLAP = 32

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite = get_node("Sprite2D")
var facing
var mode
var nextFlyTime
var lastFlapVelocity
var nextDirChangeTime
var takeoffHeight
var heightGain

func set_next_fly_time():
	nextFlyTime = randf_range(MIN_NEXT_FLY_TIME, MAX_NEXT_FLY_TIME)

func set_next_dir_change_time():
	# try to get the bird to turn around more often towards the start position
	# 1.0 is at the start, 0.0 is at or beyond TRY_MAX_DISTANCE
	var distFromStart = clamp(TRY_MAX_DISTANCE - abs(position.x - startPos.x), 0.0, TRY_MAX_DISTANCE) / TRY_MAX_DISTANCE
	var diff_dir_change_time = MAX_DIR_CHANGE_TIME - MIN_DIR_CHANGE_TIME
	if (facing == MovementDirection.LEFT and position.x < startPos.x) or \
	   (facing == MovementDirection.RIGHT and position.x > startPos.x):
		# facing away
		# make time shorter as distance increases
		diff_dir_change_time *= pow(distFromStart, DISTANCE_POWER_FACTOR)
	else:
		# facing towards
		# make time longer as distance increases
		diff_dir_change_time *= pow(1.0 - distFromStart, DISTANCE_POWER_FACTOR)
	nextDirChangeTime = randf_range(MIN_DIR_CHANGE_TIME, MIN_DIR_CHANGE_TIME + diff_dir_change_time)

func take_off():
	mode = BirdMode.FLYING
	takeoffHeight = position.y
	heightGain = randf_range(MIN_TAKEOFF_HEIGHT_GAIN, MAX_TAKEOFF_HEIGHT_GAIN)
	if facing == MovementDirection.LEFT:
		velocity.x = -randf_range(MIN_KICKOFF_SPEED, MAX_KICKOFF_SPEED)
	else:
		velocity.x = randf_range(MIN_KICKOFF_SPEED, MAX_KICKOFF_SPEED)
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
	mode = BirdMode.WANDERING

func idle():
	velocity.x = 0.0
	mode = BirdMode.IDLE

func wander_or_idle():
	sprite.texture.region.position.x = ANIM_STAND
	set_next_fly_time()
	if randi_range(0, 1) > 0:
		wander()
	else:
		idle()

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
	facing = start_facing
	set_next_fly_time()
	set_next_dir_change_time()
	land()

func _ready():
	if texture == null:
		texture = sprite.texture.atlas
	var texHeight = texture.get_height()
	# make sure there's a new atlas texture per each bird.
	sprite.texture = AtlasTexture.new()
	sprite.texture.atlas = texture
	sprite.texture.region = Rect2(0, 0, texHeight, texHeight)
	get_node("CollisionShape2D").shape.radius = int(texHeight) / 2.0
	ANIM_GLIDE = texHeight
	ANIM_FLAP = texHeight * 2
	deactivate()

func _physics_process(delta):
	match mode:
		BirdMode.IDLE:
			velocity.y += gravity * delta
			nextDirChangeTime -= delta
			if nextDirChangeTime <= 0:
				set_next_dir_change_time()
				wander()
			nextFlyTime -= delta
			if nextFlyTime <= 0.0:
				take_off()
			if velocity.y > FALL_RECOVER_SPEED:
				take_off()
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
				nextDirChangeTime -= delta
				if nextDirChangeTime <= 0:
					set_next_dir_change_time()
					if randi_range(0, 1) > 0:
						idle()
					else:
						turn_around()
				nextFlyTime -= delta
				if nextFlyTime <= 0.0:
					take_off()
		BirdMode.FLYING:
			if is_on_wall():
				turn_around()
				land()
			elif is_on_floor():
				wander_or_idle()
			else:
				if heightGain > 0.0:
					velocity.x *= TAKEOFF_ACCEL
					velocity.y += gravity * FLAP_GRAVITY * delta
					if is_on_ceiling() or position.y < takeoffHeight - heightGain:
						heightGain = 0.0
					elif velocity.y > 0.0:
						sprite.texture.region.position.x = ANIM_GLIDE
						velocity.y += gravity * GLIDE_GRAVITY * delta
						if velocity.y > -MAX_TAKEOFF_FALL_SPEED:
							flap(TAKEOFF_FLAP)
				else:
					velocity.x *= FLAP_DAMPING
					velocity.y += gravity * FLAP_GRAVITY * delta
					if velocity.y > 0.0:
						sprite.texture.region.position.x = ANIM_GLIDE
						velocity.x *= GLIDE_ACCEL
						velocity.y += gravity * GLIDE_GRAVITY * delta
						if velocity.y > -lastFlapVelocity:
							flap()
				nextFlyTime -= delta
				if nextFlyTime <= 0.0:
					land()
		BirdMode.LANDING:
			if is_on_wall():
				turn_around()
			if is_on_floor():
				wander_or_idle()
			else:
				#velocity.x *= GLIDE_ACCEL
				velocity.y += gravity * FLAP_GRAVITY * delta
				if velocity.y > MAX_LAND_SPEED * 0.75:
					sprite.texture.region.position.x = ANIM_GLIDE
					if velocity.y > MAX_LAND_SPEED:
						flap(LANDING_FLAP)

	move_and_slide()
