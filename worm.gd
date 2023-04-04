extends Mob

const SPEED = 30.0
const JUMP_VELOCITY = -400.0

@export var startDirection : MovementDirection = MovementDirection.RIGHT

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim = get_node("AnimatedSprite2D")
var animForward = true

var direction = startDirection

func deactivate():
	super()
	direction = startDirection

func _physics_process(delta):
	if is_on_wall():
		direction = opp_dir(direction)
		if direction == MovementDirection.LEFT:
			anim.play("left")
		else:
			anim.play("right")
		animForward = true
		velocity.x = 0.0

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		anim.pause()
	else:
		anim.play()

	move_and_slide()

func _on_animated_sprite_2d_animation_finished():
	var animName = "right"
	if direction == MovementDirection.LEFT:
		animName = "left"

	animForward = not animForward

	if animForward:
		anim.play(animName)
		velocity.x = 0.0
	else:
		anim.play_backwards(animName)
		velocity.x = dir_to_vec(direction).x * SPEED
