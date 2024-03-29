class_name Player
extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = 300.0
const THRUST = Vector2(500, 1700)
const AIR_DAMP = Vector2(1, 1)
const FLOOR_DAMP = Vector2(3, 0)
const MAX_SPEED = 800.0
const MAX_ANIM_TIME = 0.15
const ACTOR_COLLISION_LAYER = 2
const KNOCK_BACK = Vector2(200, -120)
const THRUST_PER_SECOND = 1.0
const THRUST_RECHARGE_FACTOR = 0.8
const THRUST_DEPLETED_RECHARGE_FACTOR = 0.6
const THRUST_MAX_DISTANCE = 100.0

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var camera = self.get_node("Player Camera")
@onready var sprite = self.get_node("Player Sprite")
@onready var particles = self.get_node("Player Particles")
@onready var invinco = self.get_node("Invincibility Time")
@onready var invinco_anim_timer = self.get_node("Invincibility Animation")
@onready var orig_material = sprite.material
@onready var invinco_material = preload("res://Mobs/white_material.tres")
@onready var meter = self.get_node("Thrust Meter")
@onready var thrust_sprite = self.get_node("Thrust Sprite")

var mousepos = Vector2.ZERO
var tween = null
var anim_dir = Vector2.ZERO
var invincible = false
var invinco_anim = false
var thrust_remaining = 1.0
var thrust_depleted = false
var thrust_cheat = false

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
	var speed = velocity.length()
	var addVel = Vector2.ZERO
	var damp = AIR_DAMP
	var thrust = Vector2.ZERO
	var diff = Vector2.ZERO
	var thrust_dec = 0.0
	var jump = false
	var direction = 0

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		diff = mousepos - (get_viewport_rect().size / 2.0)
	else:
		diff = Vector2(Input.get_axis("right_analog_left", "right_analog_right"),
					   Input.get_axis("right_analog_up", "right_analog_down")) * THRUST_MAX_DISTANCE

	var thrust_angle = diff.angle()
	var thrust_power = clamp(diff.length() / THRUST_MAX_DISTANCE, -1.0, 1.0)

	if diff != Vector2.ZERO:
		if not thrust_depleted:
			if thrust_remaining > 0:

				thrust_dec = thrust_power * (THRUST_PER_SECOND * delta)
				thrust_remaining -= thrust_dec
				if thrust_remaining < 0:
					thrust_dec = -thrust_remaining
					thrust_depleted = true

				thrust = Vector2.RIGHT.rotated(thrust_angle) * (THRUST * thrust_dec)
				addVel += thrust
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

	meter.set_thrust(thrust_remaining)
	if thrust_dec > 0.0:
		thrust_sprite.set_thrust(thrust_angle, thrust_dec / (THRUST_PER_SECOND * delta), THRUST_MAX_DISTANCE)
	if thrust_cheat:
		thrust_remaining = 1.0

	var stick = Vector2(Input.get_axis("left_analog_left", "left_analog_right"),
						Input.get_axis("left_analog_up", "left_analog_down"))
	if stick != Vector2.ZERO:
		stick = stick.angle()

		if stick > -PI * (7.0/8.0) and stick < -PI * (1.0/8.0):
			jump = true

		if stick < -PI * (5.0/8.0) or stick > PI * (5.0/8.0):
			direction = -1
		elif stick > -PI * (3.0/8.0) and stick < PI * (3.0/8.0):
			direction = 1
	else:
		if Input.is_action_just_pressed("jump"):
			jump = true
		direction = Input.get_axis("move_left", "move_right")

	# Add the gravity.
	if not is_on_floor():
		addVel += Vector2(0, gravity * delta)
	else:
		damp += FLOOR_DAMP

		# Handle Jump.
		if jump:
			addVel += Vector2.UP * JUMP_VELOCITY
			thrust += Vector2.UP

		if direction:
			addVel += Vector2(direction * delta * SPEED, 0)
			thrust += Vector2(direction, 0)

	if addVel != Vector2.ZERO:
		speed += addVel.length()
		velocity += addVel * sqrt(max(0.0, (MAX_SPEED - speed) / MAX_SPEED))
	else:
		velocity -= velocity * damp * delta

	if thrust == Vector2.ZERO:
		particles.emitting = false
		# make idle player face right
		# it's left because facing (blowing) right indicates leftwards movement
		thrust = Vector2.LEFT
	else:
		particles.emitting = true
		var particleVec = Vector2(-thrust.x, -thrust.y).normalized()
		particles.process_material.direction = Vector3(particleVec.x, particleVec.y, 0)
		particles.position = particleVec.rotated(PI / 3.5) * sprite.texture.region.size.x / 3

	var dir = thrust.normalized()
	var dist = abs((dir - anim_dir).length()) * MAX_ANIM_TIME
	if tween != null:
		tween.kill()
	
	tween = create_tween()
	tween.tween_property(self, "anim_dir", dir, dist)
	
	move_and_slide()

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
