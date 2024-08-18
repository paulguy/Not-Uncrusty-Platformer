class_name Player
extends CharacterBody2D

const FLOOR_SPEED = 1200.0
const AIR_SPEED = 400.0
const JUMP_VELOCITY = 300.0
const THRUST = Vector2(500.0, 1700.0)
const AIR_DECELERATION = Vector2(1.0, 1.0)
const FLOOR_DECELERATION = Vector2(3.0, 1.0)
const FLOOR_FRICTION_MAX_SPEED = 20.0
const FLOOR_FRICTION_FACTOR = 1.7
const FLOOR_FRICTION_FACTOR2 = 0.08
const FLOOR_FRICTION_STRENGTH = 80.0
const MAX_ANIM_TIME = 0.15
const ACTOR_COLLISION_LAYER = 2
const KNOCK_BACK = Vector2(200.0, -120.0)
const THRUST_PER_SECOND = 1.0
const THRUST_RECHARGE_FACTOR = 0.8
const THRUST_DEPLETED_RECHARGE_FACTOR = 0.6
const THRUST_MAX_DISTANCE = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity : Vector2 = Vector2(0.0, ProjectSettings.get_setting("physics/2d/default_gravity"))

@onready var camera = self.get_node("Player Camera")
@onready var sprite = self.get_node("Player Sprite")
@onready var particles = self.get_node("Player Particles")
@onready var invinco = self.get_node("Invincibility Time")
@onready var invinco_anim_timer = self.get_node("Invincibility Animation")
@onready var orig_material = sprite.material
@onready var invinco_material = preload("res://Mobs/white_material.tres")
@onready var meter = self.get_node("Thrust Meter")
@onready var thrust_sprite = self.get_node("Thrust Sprite")

var mousepos : Vector2 = Vector2.ZERO
var tween = null
var anim_dir : Vector2 = Vector2.ZERO
var invincible : bool = false
var invinco_anim : bool = false
var thrust_remaining : float = 1.0
var thrust_depleted : bool = false
var thrust_cheat : bool = false

var text_cache = {}

func _ready():
	camera.make_current()
	Cheater.register('THRUSSY', self)
	Cheater.register('TEXTJSON', self)

func _input(event):
	if event is InputEventMouse:
		mousepos = event.position

func _process(_delta):
	var ang = anim_dir.angle()
	# make the cardinal directions be halfway through a segment
	var seg = 4
	if ang < 0:
		if ang < -PI / 8:
			seg = 3
		if ang < -PI / 8 * 3:
			seg = 2
		if ang < -PI / 8 * 5:
			seg = 1
		if ang < -PI / 8 * 7:
			seg = 0
	else:
		if ang > PI / 8:
			seg = 5
		if ang > PI / 8 * 3:
			seg = 6
		if ang > PI / 8 * 5:
			seg = 7
		if ang > PI / 8 * 7:
			seg = 0
	sprite.texture.region.position.x = seg * sprite.texture.region.size.x
	if anim_dir.length() > 0.5:
		sprite.texture.region.position.y = 0
	else:
		sprite.texture.region.position.y = sprite.texture.region.size.y

func _physics_process(delta):
	var deceleration : Vector2 = AIR_DECELERATION
	var diff : Vector2 = Vector2.ZERO
	var thrust : Vector2 = Vector2.ZERO
	var thrust_dec : float = 0.0
	var thrusting : bool = false
	var movement : Vector2 = Vector2.ZERO
	var jump : Vector2 = Vector2.ZERO
	var acceleration : Vector2 = Vector2.ZERO
	var friction : Vector2 = Vector2.ZERO

	# read thrust input (not yet normalized)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		diff = mousepos - (get_viewport_rect().size / 2.0)
	else:
		diff = Vector2(Input.get_axis("right_analog_left", "right_analog_right"),
					   Input.get_axis("right_analog_up", "right_analog_down")) * THRUST_MAX_DISTANCE

	# convert thrust to vector to angle and intended power
	var thrust_angle = diff.angle()
	var thrust_power = clamp(diff.length() / THRUST_MAX_DISTANCE, -1.0, 1.0)

	# if thrusting, check if there's thrust remaining and apply intended thrust
	# if there's inadequate thrust, apply thrust proportionate to what's remaining
	# decrease consumed thrust
	# if depleted, enable slow recharge/no thrust until full
	# if not thrusting, recharge
	if thrust_power != 0:
		if not thrust_depleted:
			if thrust_remaining > 0:
				thrust_dec = thrust_power * (THRUST_PER_SECOND * delta)
				thrust_remaining -= thrust_dec
				if thrust_remaining < 0:
					thrust_dec = -thrust_remaining
					thrust_depleted = true

				thrust = Vector2.RIGHT.rotated(thrust_angle) * (THRUST * thrust_dec)

				thrusting = true
		else:
			thrust_remaining += THRUST_DEPLETED_RECHARGE_FACTOR * delta
			if thrust_remaining >= 1.0:
				thrust_remaining = 1.0
				thrust_depleted = false
	else:
		if thrust_depleted:
			thrust_remaining += THRUST_DEPLETED_RECHARGE_FACTOR * delta
			if thrust_remaining >= 1.0:
				thrust_remaining = 1.0
				thrust_depleted = false
		else:
			thrust_remaining += THRUST_RECHARGE_FACTOR * delta
			if thrust_remaining >= 1.0:
				thrust_remaining = 1.0

	# at this point thrust is a Vector2 for the acceleration added to the player
	# velocity due to thrust

	# update thrust meter
	meter.set_thrust(thrust_remaining)
	# update thrust visualization sprite
	if thrust_dec > 0.0:
		thrust_sprite.set_thrust(thrust_angle, thrust_dec / (THRUST_PER_SECOND * delta), THRUST_MAX_DISTANCE)
	# if cheating, set thrust to full right away
	if thrust_cheat:
		thrust_remaining = 1.0

	# evaluate input for normal movement and jumping
	var stick = Vector2(Input.get_axis("left_analog_left", "left_analog_right"),
						Input.get_axis("left_analog_up", "left_analog_down"))
	if stick != Vector2.ZERO:
		stick = stick.angle()

		if stick > -PI * (7.0/8.0) and stick < -PI * (1.0/8.0):
			jump.y = -JUMP_VELOCITY

		if stick < -PI * (5.0/8.0) or stick > PI * (5.0/8.0):
			movement.x = -1.0
		elif stick > -PI * (3.0/8.0) and stick < PI * (3.0/8.0):
			movement.x = 1.0
	else:
		if Input.is_action_just_pressed("jump"):
			jump.y = -JUMP_VELOCITY
		movement.x = Input.get_axis("move_left", "move_right")

	# if in the air, don't allow jumping
	# also update damping
	if is_on_floor():
		movement.x *= FLOOR_SPEED
		deceleration = FLOOR_DECELERATION
		friction.x = (pow(maxf(0.0, FLOOR_FRICTION_MAX_SPEED - abs(velocity.x)) / FLOOR_FRICTION_MAX_SPEED, FLOOR_FRICTION_FACTOR) *
					  pow(minf(FLOOR_FRICTION_MAX_SPEED, abs(velocity.x)) / FLOOR_FRICTION_MAX_SPEED, FLOOR_FRICTION_FACTOR2))
		if velocity.x < 0.0:
			friction.x = -friction.x
	else:
		movement.x *= AIR_SPEED
		jump.y = 0.0

	# get gravity, thrust and movement acceleration together in to a final velocity
	# also apply damping
	acceleration = (gravity + thrust + movement)

	# apply deceleration, friction and acceleration factors
	velocity += acceleration * delta
	velocity += jump
	velocity -= velocity * deceleration * delta
	velocity -= FLOOR_FRICTION_STRENGTH * friction * delta

	# update thrust particle state
	if thrusting:
		particles.emitting = true
		var particleVec = Vector2(-thrust.x, -thrust.y).normalized()
		particles.process_material.direction = Vector3(particleVec.x, particleVec.y, 0)
		particles.position = particleVec.rotated(PI / 3.5) * sprite.texture.region.size.x / 4
	else:
		particles.emitting = false
		# make idle player face right
		# it's left because facing (blowing) right indicates leftwards movement
		thrust = Vector2.LEFT
		if movement.x < 0.0:
			thrust = Vector2.RIGHT

	# update player animation
	var dir = thrust.normalized()
	var dist = abs((dir - anim_dir).length()) * MAX_ANIM_TIME
	if tween != null:
		tween.kill()

	tween = create_tween()
	tween.tween_property(self, "anim_dir", dir, dist)

	# move
	move_and_slide()

	# do collisions
	for i in get_slide_collision_count():
		var collision : KinematicCollision2D = get_slide_collision(i)
		# get absolute value of the distance off-center
		var angle : float = 0.0
		# suppress an error
		if velocity != Vector2():
			angle = collision.get_angle(velocity)
		if angle > PI:
			angle = TAU - angle
		# get off-center-ness in terms of 0.0 to 1.0ish
		# but only for a semicircle
		angle = max(angle, PI / 2.0) / (PI / 2.0)
		# TODO: probably some kind of curve for how much player speed is affected
		# multiply velocity by collision to reduce/remove speed
		velocity *= angle

func hit(pos : Vector2):
	if pos.x < position.x:
		velocity = KNOCK_BACK
	else:
		velocity = -KNOCK_BACK
	self.collision_layer &= ~ACTOR_COLLISION_LAYER
	invincible = true
	invinco_anim = false
	set_invinco_color(true)
	invinco.start()
	invinco_anim_timer.start()

func set_invinco_color(set_color : bool):
	if set_color:
		sprite.material = invinco_material
	else:
		sprite.material = orig_material
	
func _on_invincibility_time_timeout():
	self.collision_layer |= ACTOR_COLLISION_LAYER
	invincible = false
	self.set_invinco_color(false)
	invinco_anim_timer.stop()

func _on_invincibility_animation_timeout():
	if invincible:
		self.set_invinco_color(invinco_anim)
		invinco_anim = not invinco_anim

func cheat(code):
	if code == "THRUSSY":
		thrust_cheat = not thrust_cheat
	elif code == "TEXTJSON":
		print("Text Cache JSON:")
		for key in text_cache.keys():
			print(JSON.stringify({'text':key[0], 'ratio':key[1], 'width':text_cache[key]}))

func get_cache():
	return text_cache
