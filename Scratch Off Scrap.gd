extends CharacterBody2D

const INITIAL_HORIZONTAL_SPEED = 100
const TIME_TO_LIVE = 30

var lifetime : float = 0.0
var tween : Tween = null

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready():
	velocity.x = randf_range(-INITIAL_HORIZONTAL_SPEED, INITIAL_HORIZONTAL_SPEED)
	lifetime = TIME_TO_LIVE

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = 0.0

	move_and_slide()

	lifetime -= delta
	if tween == null and lifetime <= 0.0:
		tween = get_tree().create_tween()
		tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 0.0), 1.0)
		tween.tween_callback(queue_free)
