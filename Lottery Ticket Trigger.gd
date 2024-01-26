extends Sprite2D

@onready var game_scene = preload("res://scratch_off.tscn")
@onready var scrap_scene = preload("res://scratch_off_scrap.tscn")
var game_sceneinstance : Node
var player : Player
var should_spawn : bool = false
var should_despawn : bool = false

func _on_scratch_off_want_exit():
	should_despawn = true

func _on_scratch_off_new_ticket():
	var scrap = scrap_scene.instantiate()
	scrap.position = player.position - get_global_transform().origin
	add_child(scrap)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if should_spawn:
		should_spawn = false
		player.process_mode = Node.PROCESS_MODE_DISABLED
		player.velocity.y = 0.0
		game_sceneinstance = game_scene.instantiate()
		# place above everything
		game_sceneinstance.z_index = 1000
		# place at player (center screen)
		game_sceneinstance.position = player.position - get_global_transform().origin
		game_sceneinstance.connect("want_exit", _on_scratch_off_want_exit)
		game_sceneinstance.connect("new_ticket", _on_scratch_off_new_ticket)
		add_child(game_sceneinstance)
	elif should_despawn:
		should_despawn = false
		remove_child(game_sceneinstance)
		game_sceneinstance = null
		player.process_mode = Node.PROCESS_MODE_INHERIT

func _on_lottery_ticket_trigger_body_entered(body):
	if body is Player:
		player = body
		should_spawn = true
