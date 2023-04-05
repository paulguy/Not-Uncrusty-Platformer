extends Mob

const SPEED = 30.0
const JUMP_VELOCITY = -400.0

@export var startDirection : MovementDirection = MovementDirection.RIGHT

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var anim = get_node("AnimatedSprite2D")
var animForward = true
var animPlaying = false

var direction = startDirection

func deactivate():
	super()
	animForward = true
	direction = startDirection
	play()

const _dirToName = {
	MovementDirection.LEFT: "left",
	MovementDirection.RIGHT: "right"
}

func pause():
	anim.pause()
	animPlaying = false

func play():
	var animName = _dirToName[direction]
	if animForward:
		anim.speed_scale = 1.0
	else:
		anim.speed_scale = -1.0
		anim.frame = anim.sprite_frames.get_frame_count(animName) - 1
		anim.frame_progress = 1.0
	anim.play(animName)
	animPlaying = true

func unpause():
	if not animPlaying:
		var current_frame = anim.get_frame()
		var current_progress = anim.get_frame_progress()
		if animForward:
			anim.speed_scale = 1.0
		else:
			anim.speed_scale = -1.0
		anim.play(_dirToName[direction])
		anim.set_frame_and_progress(current_frame, current_progress)
		animPlaying = true

func _physics_process(delta):
	if is_on_wall():
		direction = opp_dir(direction)
		play()
		animForward = true
		velocity.x = 0.0

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		pause()
	else:
		unpause()

	move_and_slide()

func _on_animated_sprite_2d_animation_finished():
	animForward = not animForward
	play()

	if animForward:
		velocity.x = 0.0
	else:
		velocity.x = dir_to_vec(direction).x * SPEED
