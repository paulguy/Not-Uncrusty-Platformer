extends Mob

enum MovementDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var direction : MovementDirection = MovementDirection.RIGHT
@export var clockwise : bool = true
@export_range(0.0, 9999.0) var speed = 1500.0
var motion = Vector2.ZERO
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var falling = true

@onready var sprite = self.get_node("Mob Sprite")

var startDirection = direction

func deactivate():
	super()
	motion = Vector2.ZERO
	falling = true
	direction = startDirection
	self.set_sprite()

func set_sprite():
	if clockwise:
		match direction:
			MovementDirection.UP:
				sprite.texture.region.position.x = sprite.texture.region.size.x
				sprite.position = Vector2.ZERO
				sprite.flip_h = false
				motion = Vector2.UP * speed
				self.up_direction = Vector2.LEFT
			MovementDirection.DOWN:
				sprite.texture.region.position.x = sprite.texture.region.size.x
				sprite.position = Vector2.ZERO
				sprite.flip_h = true
				motion = Vector2.DOWN * speed
				self.up_direction = Vector2.RIGHT
			MovementDirection.RIGHT:
				sprite.texture.region.position.x = 0
				sprite.position = Vector2(0, -1)
				sprite.flip_v = false
				motion = Vector2.RIGHT * speed
				self.up_direction = Vector2.UP
			MovementDirection.LEFT:
				sprite.texture.region.position.x = 0
				sprite.position = Vector2(0, 1)
				sprite.flip_v = true
				motion = Vector2.LEFT * speed
				self.up_direction = Vector2.DOWN
	else:
		match direction:
			MovementDirection.UP:
				sprite.texture.region.position.x = sprite.texture.region.size.x
				sprite.position = Vector2.ZERO
				sprite.flip_h = true
				motion = Vector2.UP * speed
				self.up_direction = Vector2.RIGHT
			MovementDirection.DOWN:
				sprite.texture.region.position.x = sprite.texture.region.size.x
				sprite.position = Vector2.ZERO
				sprite.flip_h = false
				motion = Vector2.DOWN * speed
				self.up_direction = Vector2.LEFT
			MovementDirection.RIGHT:
				sprite.texture.region.position.x = 0
				sprite.position = Vector2(0, 1)
				sprite.flip_v = true
				motion = Vector2.RIGHT * speed
				self.up_direction = Vector2.DOWN
			MovementDirection.LEFT:
				sprite.texture.region.position.x = 0
				sprite.position = Vector2(0, -1)
				sprite.flip_v = false
				motion = Vector2.LEFT * speed
				self.up_direction = Vector2.UP

# Called when the node enters the scene tree for the first time.
func _ready():
	set_sprite()

func calc_velocity(delta) -> Vector2:
	if falling:
		return velocity + (Vector2(0, gravity) * delta)
	else:
		return (motion + (-self.up_direction * gravity)) * delta

func set_falling():
	falling = true
	if clockwise:
		direction = MovementDirection.RIGHT
	else:
		direction = MovementDirection.LEFT
	self.set_sprite()

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
	velocity = calc_velocity(delta)
	move_and_slide()

	for j in get_slide_collision_count():
		var collision = get_slide_collision(j)
		var collider = collision.get_collider()
		if collider is Player:
			collider.hit(position)
			move_and_slide()
			break

	if not falling:
		if is_on_wall():
			self.update_direction(false)
		elif not is_on_floor():
			if direction == MovementDirection.LEFT or direction == MovementDirection.RIGHT:
				velocity = Vector2(-velocity.x * 2, 0)
			else:
				velocity = Vector2(0, -velocity.y * 2)

			self.update_direction(true)

			move_and_slide()
			if not is_on_floor():
				self.set_falling()
	else:
		if is_on_floor():
			falling = false

func _on_anim_timer_timeout():
	if direction == MovementDirection.LEFT or direction == MovementDirection.RIGHT:
		sprite.flip_h = not sprite.flip_h
	else:
		sprite.flip_v = not sprite.flip_v
