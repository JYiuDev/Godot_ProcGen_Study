extends Node2D

var boundry: Rect2i = Rect2i(-1,-1,70,39)
var dummy_tile: Vector2 = Vector2(0, 3)
var grid_tile: Vector2i = Vector2(9, 6)
var room_list: Array[Rect2]
var based: Basis

var room_attempts: int = 10 #maximum amount of times to try and create a room when the previous did not fit

@export var room_count: int = 15
@export var min_room_size: int = 5
@export var max_room_size: int = 10
@export var min_room_seperation: int = 1
@onready var tilemap :TileMap = $TileMap
@export var loop_amount: int = 2

var path:AStar2D = AStar2D.new()
var drawMSP: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	visualize_boundry()
	#make_room(Rect2i(3,3,5,5))
	#make_room(Rect2i(7,3,5,5))
	#var test_intersect:Rect2i = Rect2i(7,3,5,5)
	#print(test_intersect.intersects(Rect2i(3,3,5,5)))
	#make_room(Rect2i(boundry.position.x + boundry.size.x - 1,1,2,1))
	generate_rooms(room_count)
	print_nearby_cells_test(Vector2(1,1))
	
func _input(event):
	#if enter is pressed, reload scene
	if event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
	
func _process(delta):
	if(drawMSP):
		queue_redraw()
	else:
		draw

func visualize_boundry(): #Represent the boundry of the usable area with solid color tiles
	var top_left:Vector2i = boundry.position
	tilemap.set_cell(0, top_left, 0, dummy_tile)
	var boundry_cells: PackedVector2Array
	for x in range(top_left.x, (top_left.x + boundry.size.x + 2), boundry.size.x + 1):
		for y in range(top_left.y, (top_left.y + boundry.size.y + 2)):
			tilemap.set_cell(0, Vector2(x,y), 0, dummy_tile)
	for x in range(top_left.x, (top_left.x + boundry.size.x + 2)):
		for y in range(top_left.y, (top_left.y + boundry.size.y + 2), boundry.size.y + 1):
			tilemap.set_cell(0, Vector2(x,y), 0, dummy_tile)

func make_room(parameter: Rect2):
	var pos: Vector2i = parameter.position
	var size: Vector2i = parameter.size
	var room_cells: Array[Vector2i]
	var wall_cells: Array[Vector2i]
	
	#set walls
	for x in range(pos.x, pos.x + size.x):
		for y in range(pos.y, pos.y + size.y):
			#print(Vector2(x,y))
			wall_cells.append(Vector2i(x,y))
	
	#set ground tiles 
	for x in range(pos.x + 1, pos.x + size.x - 1 ):
		for y in range(pos.y + 1, pos.y + size.y - 1 ):
			#print(Vector2(x,y))
			room_cells.append(Vector2i(x,y))
	
	tilemap.set_cells_terrain_connect(0, wall_cells, 1, 0)
	tilemap.set_cells_terrain_connect(0, room_cells, 0, 0)
	room_list.append(parameter)

func generate_rooms(count: int):
	room_list.clear()
	var room_size: Vector2
	var room_pos:  Vector2
	
	for i in count:
		var valid_space: bool = false
		var attempt_count: int = room_attempts
		while !valid_space && (attempt_count > 0):
			room_size = Vector2(randi_range(min_room_size, max_room_size), randi_range(min_room_size, max_room_size))
			#Randomize the position(top left) of the room according to roomsize, make sure full room can be contained within boundry
			room_pos.x = randi_range(boundry.position.x + 1, boundry.position.x + boundry.size.x + 1 - room_size.x)
			room_pos.y = randi_range(boundry.position.y + 1, boundry.position.y + boundry.size.y + 1 - room_size.y)
			
			if room_list.is_empty():
				valid_space = true
			else:
				var overlap: = false
				for room: Rect2 in room_list:
					var check_area: Rect2 = Rect2(room_pos,room_size).grow(min_room_seperation)
					if check_area.intersects(room):
						overlap = true
				if !overlap:
					valid_space = true
			attempt_count -= 1
			
		if valid_space:
			make_room(Rect2(room_pos,room_size))
			await get_tree().create_timer(0.1).timeout
	create_MSP()
	
	#Loop through generated path nodes and generate corridors according to connections
	var path_ids_dupe:Array = path.get_point_ids().duplicate()
	for room_id: int in path.get_point_ids():
		#print(room_id, "connections: ", path.get_point_connections(room_id))
		for neighbour_id: int in path.get_point_connections(room_id):
			if path_ids_dupe.has(neighbour_id):
				room_pos = path.get_point_position(room_id)
				var neighbour_pos = path.get_point_position(neighbour_id)
				#print("room pos: ", room_pos, "neighbour pos: ", neighbour_pos)
				make_corridors(room_pos, neighbour_pos)
				await get_tree().create_timer(0.1).timeout
		path_ids_dupe.erase(room_id)
	drawMSP = false

func make_corridors(start: Vector2, end: Vector2):
	var x_diff: int = sign(end.x - start.x)
	var y_diff: int = sign(end.y - start.y)
	
	if x_diff == 0: x_diff = pow(-1, randi()% 2)
	if y_diff == 0: y_diff = pow(-1, randi()% 2)
	
	#shuffle start/end position
	var pos1:Vector2
	var pos2:Vector2
	if pow(-1, randi()% 2) > 0:
		pos1 = start
		pos2 = end
	else:
		pos1 = end
		pos2 = start
	
	var corridor_cells:Array
	for x in range(start.x, end.x, x_diff):
		#tilemap.set_cell(0, Vector2(x,pos1.y), 0, dummy_tile)
		corridor_cells.append(Vector2(x,pos1.y))
		print_nearby_cells(Vector2(x, pos1.y))
	for y in range(start.y, end.y, y_diff):
		#tilemap.set_cell(0, Vector2(pos2.x,y), 0, dummy_tile)
		corridor_cells.append(Vector2(pos2.x,y))
	tilemap.set_cells_terrain_connect(0, corridor_cells,0,0)
	
func create_MSP(): #Create a min spanning tree with the position of rooms(Rect2) using primms algo
	drawMSP = true
	var room_positions: Array[Vector2]
	for room in room_list:
		room_positions.append(room.get_center())
		#tilemap.set_cell(0, room.get_center(), 0, dummy_tile)
	path.add_point(path.get_available_point_id(), room_positions.pop_front())
	
	var room_positions_dupe = room_positions.duplicate()
	while !room_positions_dupe.is_empty():
		var min_distance: float = INF
		var current_poiont: Vector2
		var min_dist_point: Vector2
		for id in path.get_point_count():
			var point1:Vector2 = path.get_point_position(id)
			for point2:Vector2 in room_positions_dupe:
				var dist: float = point1.distance_to(point2)
				if dist < min_distance:
					min_distance = dist
					current_poiont = point1
					min_dist_point = point2
		var new_id = path.get_available_point_id()
		path.add_point(new_id, min_dist_point)
		path.connect_points(path.get_closest_point(current_poiont), new_id)
		room_positions_dupe.erase(min_dist_point)
		
		
	# randomly add loops into the MSP to make the dungeon path more interesting
	# room will look for the second closest candidates to form loop
	for n in loop_amount:
		var node_list:Array = path.get_point_ids()
		var node1 = node_list.pick_random()
		var node1_pos: Vector2 = path.get_point_position(node1)
		var min_dist: float = INF
		var min_dist_room: int
		for node2_pos in room_positions:
			#Get the point with minimum distance BUT not already connected
			if node1_pos.distance_to(node2_pos) < min_dist && (node1_pos != node2_pos):
				var node2 = path.get_closest_point(node2_pos)
				if path.get_point_connections(node1).has(node2):
					pass
				else:
					min_dist = node1_pos.distance_to(node2_pos)
					min_dist_room = node2
					
		if min_dist_room: #Connecting the astar nodes
			path.connect_points(node1, min_dist_room)
		node_list.erase(node1)

func _draw():
	if path && drawMSP:
		for id in path.get_point_count():
			for c in path.get_point_connections(id):
				var pp = path.get_point_position(id)
				pp = tilemap.map_to_local(pp)
				var cp = path.get_point_position(c)
				cp = tilemap.map_to_local(cp)
				draw_line(Vector2(pp.x, pp.y),Vector2(cp.x, cp.y),Color(1, 1, 0, 1), 15, true)

func print_nearby_cells(query_cell: Vector2):
	var neighbour_array: Array[Vector2] = [Vector2(-1, -1), Vector2(1, 0)]
	#Order of neighbour tiles
	#	0 1 2
	#	7 # 3
	#	6 5 4
	for n in neighbour_array:
		var cell_data = tilemap.get_cell_atlas_coords(0, query_cell + n)
		print(cell_data)

func print_nearby_cells_test(query_cell: Vector2):
	var i: Array[int] = [-1, 0, 1, 1, 1, 0, -1. -1]
	var j: Array[int] = [-1, -1, -1, 0, 1, 1, 1, 0]
	#Order of neighbour tiles
	#	0 1 2
	#	7 # 3
	#	6 5 4
	for n in i.size():
		print(Vector2(i[n], j[n]))
