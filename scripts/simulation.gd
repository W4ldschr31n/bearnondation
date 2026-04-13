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
			self.current_filling = max_filling
			self.max_flow = max_flow
	
	static func NewLand():
		return Tile.new(0, false, 10, 10)
	
	static func NewHill():
		return Tile.new(1, false, 15, 15)
		
	static func NewForest():
		return Tile.new(2, false, 20, 20)
		
	static func NewMountain():
		return Tile.new(3, false, 25, 25)
		
	static func NewSource():
		return Tile.new(4, true, 50, 50)

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
			Tile.NewForest(), Tile.NewForest(), Tile.NewSource(), Tile.NewForest(),
				Tile.NewHill(), Tile.NewMountain(), Tile.NewMountain(), Tile.NewMountain(),
		],
		# Width
		8,
		# Height
		4
	)
	
	print_tiles()


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

func print_tiles():
	var is_odd_row = false
	for y in height:
		var final_str = "  " if is_odd_row else ""
		for x in range(1 if is_odd_row else 0, width, 2):
			final_str += str(tiles[x][y].height) + "   "
		is_odd_row = not is_odd_row
		print(final_str)

func _on_step_timer_timeout() -> void:
	# Process the board
	pass # Replace with function body.
