extends Node

#direction in binary value
const N = 1
const E = 2
const S = 4
const W = 8

var map_seed:int = 0

var wall_directions: Dictionary
var wall_directions_uniform: Dictionary = {Vector2.UP: N, Vector2.RIGHT: E, Vector2.DOWN: S, Vector2.LEFT: W}
var tile_size: int = 16
var width: int = 17
var height: int = 9
var unvisited: Array
var used_cells: Array

#Tileset properties
var tileset_collumns: int = 4
var tileset_rows:     int = 4

#Random elements
var random_remove_factor:float = 0.2

#Step property?
var step_size: int = 1

@onready var tilemap:TileMap = $TileMap

func _ready():
	if step_size == 1:
		wall_directions = wall_directions_uniform
		new_map_seed()
		create_maze()
	else:
		for key: Vector2 in wall_directions_uniform:
			wall_directions[key * step_size] = wall_directions_uniform[key]
		new_map_seed()
		create_maze()
		

func _input(event):
	if event.is_action_pressed("ui_accept"):
		new_map_seed()
		create_maze()

func get_univisted_neighbours(cell: Vector2, univisited: Array) -> Array:
	#Returns an array of the cells univisited neighbours
	var list = []
	for dir in wall_directions.keys():
		var neighbour_cell: Vector2 = cell + dir
		if neighbour_cell in univisited:
			list.append(neighbour_cell)
	return list

func create_maze():
	var stack = [] #stack of cells travelled
	unvisited.clear()
	tilemap.clear()
	for x in range(width):
		for y in range(height):
			#register tiles
			var cell: Vector2 = Vector2(x,y)
			tilemap.set_cell(0, cell, 0, int_to_atlas(N|E|S|W))
			
	for x in range(0, width, step_size):
		for y in range(0, height, step_size):
			unvisited.append(Vector2(x, y))
			used_cells.append(Vector2(x, y))
			#print(atlas_to_int(tilemap.get_cell_atlas_coords(0, cell)) - wall_directions[Vector2.UP])
	
	var current_cell : Vector2 = Vector2.ZERO
	unvisited.erase(current_cell)
	
	while !unvisited.is_empty():
		#iterate backtrack algo
		var neighbours: Array = get_univisted_neighbours(current_cell, unvisited)
		if neighbours:
			var next_cell: Vector2 = neighbours.pick_random()
			#knock down walls between two cells
			remove_walls(current_cell, next_cell)
			stack.append(current_cell)
			current_cell = next_cell
			unvisited.erase(current_cell)
			await get_tree().create_timer(0.01).timeout
		else:
			current_cell = stack.pop_back()
	
	random_remove_walls()


func remove_walls(a_cell: Vector2, b_cell: Vector2):
	var a_to_b: Vector2i = int_to_atlas(wall_directions[b_cell - a_cell])
	var b_to_a: Vector2i = int_to_atlas(wall_directions[a_cell - b_cell])
	tilemap.set_cell(0, a_cell, 0, tilemap.get_cell_atlas_coords(0, a_cell) - a_to_b)
	tilemap.set_cell(0, b_cell, 0, tilemap.get_cell_atlas_coords(0, b_cell) - b_to_a)

	if step_size > 1:
		#fill in horizontal or vertical cell when step size is bigger than 1
		var dir:Vector2 = (b_cell - a_cell).normalized()
		var cur_cell: Vector2 = a_cell
		
		for i in step_size - 1:
			cur_cell = cur_cell + dir
			if dir.x != 0:
				tilemap.set_cell(0, cur_cell, 0, int_to_atlas(S|N))
			else:
				tilemap.set_cell(0, cur_cell, 0, int_to_atlas(E|W))
			if !used_cells.has(cur_cell):
				used_cells.append(cur_cell)
			
func random_remove_walls():
	#GOAL: to add loops the the maze
	#go through the tiles and remove tiles at random
	for i in range(int(width * height * random_remove_factor)):
		#pick random tile not on the edge
		#var cell: Vector2 = Vector2(randi_range(step_size , width - step_size), randi_range(step_size, height - step_size))
		var cell: Vector2 = used_cells.pick_random()
		var next_dir :Vector2 = wall_directions.keys().pick_random()
		#check if there's a wall between them
		if atlas_to_int(tilemap.get_cell_atlas_coords(0, cell)) & wall_directions[next_dir] && used_cells.has(cell + next_dir):
			remove_walls(cell, (cell + next_dir))
		await get_tree().create_timer(0.01).timeout

func int_to_atlas(num: int) -> Vector2:
	var atlas_coord: Vector2 = Vector2(num % tileset_collumns, num / tileset_rows)
	return atlas_coord

func atlas_to_int(coord: Vector2) -> int:
	var num = coord.x + (coord.y * tileset_rows)
	return num
	
func new_map_seed():
	randomize()
	map_seed = randi()
	seed(map_seed)
	print("Seed: ", map_seed)
