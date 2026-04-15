class_name Simulation
extends Node

var tiles : Array[Array]
var sources : Array
var width: int
var height: int

# per run variables
var tiles_to_check: Array
var tiles_visited: Array
var lowest_height: int
var flow_to_unload: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Only if launched from editor directly
	if get_tree().current_scene == self:
		_self_init()
	
func _init_board_8x4():
	_init_with_board(
		# Tiles
		[
			Tile.NewForest(), Tile.NewForest(), Tile.NewMountain(), Tile.NewForest(),
				Tile.NewHill(), Tile.NewMountain(), Tile.NewMountain(), Tile.NewMountain(),
			Tile.NewForest(), Tile.NewForest(), Tile.NewSource(50), Tile.NewForest(),
				Tile.NewHill(), Tile.NewForest(), Tile.NewForest(), Tile.NewForest(),
		],
		# Width
		8,
		# Height
		4
	)

func _self_init():
	_init_board_8x4()
	print_board()
	print("Processing sources")
	process_sources()
	print_board()

func _init_with_board(board: Array[Tile], width, height) -> void:
	var current_x = 0
	var current_y = 0
	var is_odd_row = false
	self.width = width
	self.height = height
	
	# Init empty tiles
	tiles = []
	tiles.resize(width)
	for i in width:
		tiles[i].resize(height)
	sources = []
	
	# Check size matches
	var expected_size = width * height/2
	if(board.size() < expected_size):
		printerr("Not enough tiles to init")
		return
	elif(board.size() > expected_size):
		printerr("Too much tiles")
		return
	
	# Read board
	for t in board:
		# Record tile
		t.x = current_x
		t.y = current_y
		if(t.is_source):
			sources.append([current_x, current_y])
		tiles[current_x][current_y] = t
			
		# Update index
		current_x += 2
		if(current_x >= width):
			is_odd_row = not is_odd_row
			current_x = 1 if is_odd_row else 0
			current_y += 1
	

	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func print_tiles(callback: Callable, offset: String = "  ", separator: String = "   "):
	var is_odd_row = false
	for y in height:
		var final_str = offset if is_odd_row else ""
		for x in range(1 if is_odd_row else 0, width, 2):
			final_str += callback.call(tiles[x][y]) + separator
		is_odd_row = not is_odd_row
		print(final_str)

func print_tiles_heights():
	print_tiles(func(t: Tile): return str(t.height))
	
func print_tiles_filling():
	print_tiles(func(t: Tile): return str(t.current_filling) + "/" + str(t.max_filling), "    ", "     ")

func print_tiles_flow():
	print_tiles(func(t: Tile): return str(t.current_flow) + "/" + str(t.max_flow), "    ", "     ")
	
func print_tiles_index():
	print_tiles(func(t: Tile): return str(t.x) + ";" + str(t.y), "   ", "    ")

func print_board():
	print("Heights")
	print_tiles_heights()
	print("\nFilling")
	print_tiles_filling()
	print("\nFlow")
	print_tiles_flow()
	print("\nIndex")
	print_tiles_index()

func foreach_tile(callback: Callable, filter: Callable):
	var is_odd_row = false
	for y in height:
		for x in range(1 if is_odd_row else 0, width, 2):
			var tile = get_tile(x, y)
			if(filter.call(tile)):
				callback.call(tile)
		is_odd_row = not is_odd_row

func trickle_down(source: Tile):
	if (flow_to_unload==0):
		return
	print("Tile ", source.x, ";", source.y, " has ", flow_to_unload, " to unload")
	flow_to_unload = source.send_flow(flow_to_unload)
	
	var source_neighbours = get_tile_neighbours(source)
	for n in source_neighbours:
		var neighbour = get_tile(n[0], n[1])
		if(neighbour.height == source.height-1 || neighbour.height == lowest_height && !neighbour.is_flowing()):
			trickle_down(neighbour)


func get_tile(x, y) -> Tile:
	return tiles[x][y]

func get_tile_neighbours(tile : Tile):
	var neighbours = []
	# South
	if(tile.y+2 < height):
		neighbours.push_back([tile.x, tile.y+2])
	if(tile.y+1 < height):
		# South West
		if(tile.x-1 >= 0):
			neighbours.push_back([tile.x-1, tile.y+1])
		# South East
		if(tile.x+1 < width):
			neighbours.push_back([tile.x+1, tile.y+1])
	# North
	if(tile.y-2 >= 0):
		neighbours.push_back([tile.x, tile.y-2])
	if(tile.y-1 >= 0):
		# North West
		if(tile.x-1 >= 0):
			neighbours.push_back([tile.x-1, tile.y-1])
		# North East
		if(tile.x+1 < width):
			neighbours.push_back([tile.x+1, tile.y-1])
			
	return neighbours

func process_sources():
	for coordinates in sources:
		lowest_height = 0
		var source : Tile = tiles[coordinates[0]][coordinates[1]]
		flow_to_unload = source.current_flow
		while flow_to_unload > 0 and lowest_height < source.height:
			tiles_visited = []
			tiles_to_check = []
			trickle_down(source)
			lowest_height += 1
			print("Remaining flow : ", flow_to_unload)
		print("Overflow : ", flow_to_unload)

func reset_flow():
	foreach_tile(func (tile: Tile): tile.current_flow = 0, func (tile: Tile): return not tile.is_source)

func process_board():
	reset_flow()
	process_sources()

func _on_step_timer_timeout() -> void:
	# Process the board
	pass
