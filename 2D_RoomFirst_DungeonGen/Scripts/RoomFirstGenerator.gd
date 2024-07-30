extends Node

var boundry: Rect2i = Rect2i(-1,-1,70,39)
var dummy_tile: Vector2 = Vector2(0, 3)
var grid_tile: Vector2i = Vector2(9, 6)
var room_list: Array[Rect2i]

var room_attempts: int = 10 #maximum amount of times to try and create a room when the previous did not fit

@export var room_count: int = 10
@export var min_room_size: int = 5
@export var max_room_size: int = 10
@export var min_room_seperation: int = 1
@onready var tilemap :TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	visualize_boundry()
	#make_room(Rect2i(3,3,5,5))
	#make_room(Rect2i(7,3,5,5))
	#var test_intersect:Rect2i = Rect2i(7,3,5,5)
	#print(test_intersect.intersects(Rect2i(3,3,5,5)))
	#make_room(Rect2i(boundry.position.x + boundry.size.x - 1,1,2,1))
	generate_rooms(room_count)

func _input(event):
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()

func visualize_boundry():
	var top_left:Vector2i = boundry.position
	tilemap.set_cell(0, top_left, 0, dummy_tile)
	var boundry_cells: PackedVector2Array
	for x in range(top_left.x, (top_left.x + boundry.size.x + 2), boundry.size.x + 1):
		for y in range(top_left.y, (top_left.y + boundry.size.y + 2)):
			tilemap.set_cell(0, Vector2(x,y), 0, dummy_tile)
	for x in range(top_left.x, (top_left.x + boundry.size.x + 2)):
		for y in range(top_left.y, (top_left.y + boundry.size.y + 2), boundry.size.y + 1):
			tilemap.set_cell(0, Vector2(x,y), 0, dummy_tile)

func make_room(parameter: Rect2i):
	var pos: Vector2i = parameter.position
	var size: Vector2i = parameter.size
	var room_cells: Array[Vector2i]
	var wall_cells: Array[Vector2i]
	
	#set walls
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			#print(Vector2(x,y))
			wall_cells.append(Vector2i(x,y))
	tilemap.set_cells_terrain_connect(0, wall_cells, 1, 0)
	#set ground tiles 
	for x in range(pos.x + 1, pos.x + size.x - 1):
		for y in range(pos.y + 1, pos.y + size.y - 1):
			#print(Vector2(x,y))
			room_cells.append(Vector2i(x,y))
	tilemap.set_cells_terrain_connect(0, room_cells, 0, 0)
	
	room_list.append(parameter)
	

func generate_rooms(count: int):
	room_list.clear()
	var room_size: Vector2i
	var room_pos:  Vector2i
	
	for i in count:
		var valid_space: bool = false
		var attempt_count: int = room_attempts
		while !valid_space && (attempt_count > 0):
			room_size = Vector2i(randi_range(min_room_size, max_room_size), randi_range(min_room_size, max_room_size))
			#Randomize the position(top right) of the room according to roomsize, make sure full room can be contained within boundry
			room_pos.x = randi_range(boundry.position.x + 1, boundry.position.x + boundry.size.x + 1 - room_size.x)
			room_pos.y = randi_range(boundry.position.y + 1, boundry.position.y + boundry.size.y + 1 - room_size.y)
			
			if room_list.is_empty():
				valid_space = true
			else:
				var overlap: = false
				for room: Rect2i in room_list:
					var check_area: Rect2i = Rect2i(room_pos,room_size).grow(min_room_seperation)
					if check_area.intersects(room):
						overlap = true
				if !overlap:
					valid_space = true
					
			attempt_count -= 1
		
		if valid_space:
			make_room(Rect2i(room_pos,room_size))
	print("room count: ", room_count)
