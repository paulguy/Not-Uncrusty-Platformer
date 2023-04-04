class_name Mob
extends CharacterBody2D

enum MovementDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@export var health : int = 0

@onready var area = get_parent()

@onready var startPos = position
@onready var startHealth = health
var onscreen = false

func deactivate():
	position = startPos
	health = startHealth

func activate():
	pass

func on_screen():
	onscreen = true

func off_screen():
	onscreen = false
	if not area.onscreen:
		area.remove_child(self)
		deactivate()

func _ready():
	pass

var _dirVectDict = {
	MovementDirection.UP: Vector2.UP,
	MovementDirection.DOWN: Vector2.DOWN,
	MovementDirection.LEFT: Vector2.LEFT,
	MovementDirection.RIGHT: Vector2.RIGHT
}

func dir_to_vec(dir : MovementDirection) -> Vector2:
	return _dirVectDict[dir]

var _dirOppDict = {
	MovementDirection.UP: MovementDirection.DOWN,
	MovementDirection.DOWN: MovementDirection.UP,
	MovementDirection.LEFT: MovementDirection.RIGHT,
	MovementDirection.RIGHT: MovementDirection.LEFT
}

func opp_dir(dir : MovementDirection) -> MovementDirection:
	return _dirOppDict[dir]
