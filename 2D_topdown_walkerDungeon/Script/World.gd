extends Node

var borders = Rect2(1, 1, 35, 19)
@onready var tileMap = $TileMap
@export var walker_steps:int = 500


func _ready():
	randomize()
	generate_world()

func generate_world():
	var walker = Walker.new(Vector2(19, 11), borders)
	var map = walker.walk(300)
	walker.queue_free()
	for cell in map:
		tileMap.erase_cell(0, cell)
		await get_tree().create_timer(0.001)
	
	var changed_cells = tileMap.get_used_cells(0)
	for tile in changed_cells:
		tileMap.erase_cell(0, tile)
	tileMap.set_cells_terrain_connect(0, changed_cells, 0, 0)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
