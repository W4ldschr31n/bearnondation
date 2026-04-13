class_name Simulation
extends Node


class Tile:
	# Coordinates
	var x : int
	var y : int
	# Type of tile
	var height : int
	var is_source : bool
	# Water filling
	var max_filling : int
	var current_filling : int
	# Water flowing
	var max_flow : int
	var current_flow : int
	
	func _init(height, is_source, filling, flow):
		self.height = height
		self.is_source = is_source
		self.max_filling = filling
		self.max_flow = flow
		if(is_source):
			self.current_filling = filling
			self.current_flow = flow
	
	static func NewLand():
		return Tile.new(0, false, 10, 10)
	
	static func NewHill():
		return Tile.new(1, false, 15, 15)
		
	static func NewForest():
		return Tile.new(2, false, 20, 20)
		
	static func NewMountain():
		return Tile.new(3, false, 25, 25)
		
	static func NewSource(flow=100):
		return Tile.new(4, true, 50, flow)

var tiles : Array[Array]
var sources : Array
var width: int
var height: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_init_with_board(
		# Tiles
		[
			Tile.NewForest(), Tile.NewForest(), Tile.NewMountain(), Tile.NewForest(),
				Tile.NewHill(), Tile.NewMountain(), Tile.NewMountain(), Tile.NewMountain(),
			Tile.NewForest(), Tile.NewForest(), Tile.NewSource(100), Tile.NewForest(),
				Tile.NewHill(), Tile.NewMountain(), Tile.NewMountain(), Tile.NewMountain(),
		],
		# Width
		8,
		# Height
		4
	)
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

func trickle_down(source: Tile):
	var flow_to_unload = source.current_flow
	var tiles_to_check = get_tile_neighbours(source)
	var checked_tiles = [[source.x, source.y]]
	while(flow_to_unload>0 and tiles_to_check.size()>0):
		print(flow_to_unload)
		var t_coordinates = tiles_to_check.pop_front()
		var tile : Tile = tiles[t_coordinates[0]][t_coordinates[1]]
		checked_tiles.push_back([tile.x, tile.y])
		var unloadable_flow: int = min(flow_to_unload, tile.max_flow - tile.current_flow)
		tile.current_flow += unloadable_flow
		flow_to_unload -= unloadable_flow
		var new_neighbours = get_tile_neighbours(tile)
		# Neighbours must be added in reverse order
		new_neighbours.reverse()
		for n in new_neighbours:
			if(!checked_tiles.has(n) && !tiles_to_check.has(n)):
				tiles_to_check.push_front(n)
	
	if(flow_to_unload>0):
		print("WATER OVERFLOW : ", flow_to_unload)

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
		var source : Tile = tiles[coordinates[0]][coordinates[1]]
		trickle_down(source)

func _on_step_timer_timeout() -> void:
	# Process the board
	pass
