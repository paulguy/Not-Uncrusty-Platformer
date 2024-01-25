extends Node2D

const PARTICLE_SPAWN_TIME = 0.2
const ANIM_SPEED_VARIANCE = 0.4
const DISTANCE_VARIANCE = 10
const DISTANCE_POWER = 0.5

var last_time = 0
var cur_particle = 0

var particles : Array[AnimatedSprite2D] = []

# Called when the node enters the scene tree for the first time.
func _ready():
	for particle in get_children():
		if particle is AnimatedSprite2D:
			particles.append(particle)
			remove_child(particle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	last_time += delta
	if last_time > PARTICLE_SPAWN_TIME:
		last_time -= PARTICLE_SPAWN_TIME
		for particle in particles:
			if particle not in get_children():
				add_child(particle)
				var color = Color(1.0, 1.0, 1.0)
				color.s = randf_range(0.5, 1.0)
				color.h = randf_range(0.0, 1.0)
				particle.animate(1.0 + randf_range(-ANIM_SPEED_VARIANCE, ANIM_SPEED_VARIANCE),
								 Vector2.UP.rotated(randf_range(0.0, PI*2.0)) * 
									(1.0 - pow(randf_range(0.0, 1.0), DISTANCE_POWER)) * DISTANCE_VARIANCE,
								 color)

func done_animating(sprite : AnimatedSprite2D):
	remove_child(sprite)
