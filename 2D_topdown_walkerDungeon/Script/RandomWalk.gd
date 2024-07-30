extends Node
class_name  Walker

const DIRECTIONS = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]

var position: Vector2 = Vector2.ZERO
var direction: Vector2 = Vector2.RIGHT
var borders:Rect2 = Rect2()
var map_cells: Array = []
var step_since_turn: int = 0
var max_straight: int = 7
var rooms: Array = []

func _init(start_position: Vector2, new_borders: Rect2):
	#check if start position is within borders
	assert(new_borders.has_point(start_position))
	position = start_position
	map_cells.append(start_position)
	borders = new_borders
	

func step() -> bool:	#Try step in the current direction, return true if able and vice versa
	var try_position: Vector2 = position + direction
	if(borders.has_point(try_position)):
		position = try_position
		step_since_turn += 1
		return true
	else:
		return false

func walk(walk_length: int) -> Array:
	generate_room(position)
	for i in walk_length:
		if step_since_turn >= max_straight:
			change_direction()
		if step():
			map_cells.append(position)
		else:
			change_direction()
	return map_cells

func change_direction():
	generate_room(position)
	var directions:Array = DIRECTIONS.duplicate()
	directions.erase(direction)
	directions.shuffle()
	var try_dir = directions.pop_front()
	while !borders.has_point(position + try_dir):
		try_dir = directions.pop_front()
	direction = try_dir
	step_since_turn = 0
	
#generates rooms and puts each room cell into the map array
func generate_room(position: Vector2):
	var room_size: Vector2 = Vector2(randi()%4 +2, randi()%4 +2)
	var top_left_room_cell: Vector2 = (position - room_size/2).ceil()
	for x in room_size.x:
		for y in room_size.y:
			var try_cell:Vector2 = top_left_room_cell + Vector2(x,y)
			if(borders.has_point(try_cell)):
				map_cells.append(try_cell)
				
	
	
	
