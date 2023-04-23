class_name TilemapArea
extends TileMap

var mobs = []
var bg_textures = []
var onscreen = false

# Called when the node enters the scene tree for the first time.
func _ready():
	for child in self.get_children():
		if child is Mob:
			mobs.append(child)
		elif child is BG_Texture:
			bg_textures.append(child)
	# initially mark all mobs offscreen.  After the first process, the area on
	# screen should get a signal that it has gone on screen and then that area's
	# mobs should be activated appropriately.
	off_screen([])

func on_screen():
	onscreen = true
	for mob in mobs:
		mob.activate()
		# suppress an error, if the mob is already parented, there's nothing to
		# do as the only parent it could ever have is this node.
		if mob.get_parent() == null:
			self.add_child(mob)
	for bg_tex in bg_textures:
		if bg_tex.get_parent() == null:
			self.add_child(bg_tex)

func off_screen(onscreenMobs):
	onscreen = false
	for mob in mobs:
		if mob in onscreenMobs:
			continue
		self.remove_child(mob)
		mob.deactivate()
	for bg_tex in bg_textures:
		self.remove_child(bg_tex)
