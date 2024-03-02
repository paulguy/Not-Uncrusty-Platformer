class_name Mob
extends CharacterBody2D

enum MovementDirection {
	UP,
	DOWN,
	LEFT,
	RIGHT
}

@onready var startPos = position

func deactivate():
	position = startPos

func activate():
	pass

const _dirVectDict = {
	MovementDirection.UP: Vector2.UP,
	MovementDirection.DOWN: Vector2.DOWN,
	MovementDirection.LEFT: Vector2.LEFT,
	MovementDirection.RIGHT: Vector2.RIGHT
}

func dir_to_vec(dir : MovementDirection) -> Vector2:
	return _dirVectDict[dir]

const _dirOppDict = {
	MovementDirection.UP: MovementDirection.DOWN,
	MovementDirection.DOWN: MovementDirection.UP,
	MovementDirection.LEFT: MovementDirection.RIGHT,
	MovementDirection.RIGHT: MovementDirection.LEFT
}

func opp_dir(dir : MovementDirection) -> MovementDirection:
	return _dirOppDict[dir]
