extends Mob

# TODO: why does it randomly float up on respawn?

enum MovementDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var startDirection : MovementDirection = MovementDirection.RIGHT
@export var clockwise : bool = true
@export_range(0.0, 9999.0) var speed = 1500.0
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var motion = Vector2.ZERO
var falling = true
var direction = startDirection

@onready var sprite = get_node("Mob Sprite")

func set_sprite():
	if clockwise:
		match direction:
			MovementDirection.UP:
				motion = Vector2.UP * speed
				up_direction = Vector2.LEFT
			MovementDirection.DOWN:
				motion = Vector2.DOWN * speed
				up_direction = Vector2.RIGHT
			MovementDirection.RIGHT:
				motion = Vector2.RIGHT * speed
				up_direction = Vector2.UP
			MovementDirection.LEFT:
				motion = Vector2.LEFT * speed
				up_direction = Vector2.DOWN
	else:
		match direction:
			MovementDirection.UP:
				motion = Vector2.UP * speed
				up_direction = Vector2.RIGHT
			MovementDirection.DOWN:
				motion = Vector2.DOWN * speed
				up_direction = Vector2.LEFT
			MovementDirection.RIGHT:
				motion = Vector2.RIGHT * speed
				up_direction = Vector2.DOWN
			MovementDirection.LEFT:
				motion = Vector2.LEFT * speed
				up_direction = Vector2.UP

func update_angle(normal):
	sprite.rotation = normal.angle() + (PI / 2)
	# compensate for non-square shape
	sprite.position = Vector2(0, normal.y)

func deactivate():
	super()
	falling = true
	direction = startDirection
	velocity = Vector2.ZERO
	update_angle(Vector2.UP)
	set_sprite()

# Called when the node enters the scene tree for the first time.
func _ready():
	set_sprite()

func calc_velocity(delta) -> Vector2:
	if falling:
		return velocity + (Vector2(0, gravity) * delta)
	else:
		return (motion + (-up_direction * gravity)) * delta

func set_falling():
	falling = true
	if clockwise:
		direction = MovementDirection.RIGHT
	else:
		direction = MovementDirection.LEFT
	set_sprite()

func update_direction(dir_order : bool):
	if dir_order:
		dir_order = clockwise
	else:
		dir_order = not clockwise

	if dir_order:
		match direction:
			MovementDirection.UP:
				direction = MovementDirection.RIGHT
			MovementDirection.DOWN:
				direction = MovementDirection.LEFT
			MovementDirection.LEFT:
				direction = MovementDirection.UP
			MovementDirection.RIGHT:
				direction = MovementDirection.DOWN
	else:
		match direction:
			MovementDirection.UP:
				direction = MovementDirection.LEFT
			MovementDirection.DOWN:
				direction = MovementDirection.RIGHT
			MovementDirection.LEFT:
				direction = MovementDirection.DOWN
			MovementDirection.RIGHT:
				direction = MovementDirection.UP
	self.set_sprite()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var normal = Vector2.UP
	var hit_player = false
	# split velocity so movement is in smaller steps ~1.0 each
	var v = calc_velocity(delta)
	var vi = v.length() * delta
	v = v / vi

	for i in vi:
		velocity = v
		move_and_slide()

		# detect hitting the player and continue motion
		for j in get_slide_collision_count():
			var collision = get_slide_collision(j)
			var collider = collision.get_collider()
			if collider is Player:
				# signal player to not collide with mobs
				collider.hit(position)
				hit_player = true
			elif collider is TileMap:
				normal = collision.get_normal()

		if hit_player:
			# complete the motion
			move_and_slide()

		if not falling:
			if is_on_wall():
				update_direction(false)
			elif not is_on_floor():
				if direction == MovementDirection.LEFT or direction == MovementDirection.RIGHT:
					v = Vector2(-v.x * 2, 0)
				else:
					v = Vector2(0, -v.y * 2)

				update_direction(true)

				velocity = v
				move_and_slide()
				if not is_on_floor():
					set_falling()
					normal = Vector2.UP
				else:
					for j in get_slide_collision_count():
						var collision = get_slide_collision(j)
						var collider = collision.get_collider()
						if collider is TileMap:
							normal = collision.get_normal()
		else:
			if is_on_floor():
				falling = false

	update_angle(normal)

func _on_anim_timer_timeout():
	sprite.flip_h = not sprite.flip_h
