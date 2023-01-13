class_name Mob
extends CharacterBody2D

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
