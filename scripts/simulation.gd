class_name Simulation
extends Node

# board
var tiles : Array[Array]
var sources : Array
var width: int
var height: int
var current_turn: int = 0
@export var objective_pos : Vector2i = Vector2i(15, 5)

# flood
@export var turns_before_flood_starts: int = 5
@export var turns_between_flood_advances: int = 5
var current_flood_x: int = -1

# animals
var baits = []

# per run variables
var lowest_height: int
var flow_to_unload: int

# Gestion des tours et satellites
var turn_timer : Timer
@export var turn_duration : float = 15.0
var satellites : Array[Satellite] = []

# INITIALISATION

func _ready() -> void:
	turn_timer = Timer.new()
	turn_timer.wait_time = turn_duration
	turn_timer.autostart = true
	turn_timer.one_shot = false
	turn_timer.timeout.connect(advance_turn)
	add_child(turn_timer)
	
	if get_tree().current_scene == self:
		_self_init()

enum ActionType { BAIT, REPELLENT }

var active_actions : Dictionary = {}

var action_charges : Dictionary = {
	ActionType.BAIT: 3,
	ActionType.REPELLENT: 2
}

signal action_used

func _self_init():
	_init_board_16x9()
	print("--- Plateau 16x9 Initialisé ---")
	process_board()
	print_board()

func _init_with_board(board: Array[Tile], p_width: int, p_height: int) -> void:
	var current_x = 0
	var current_y = 0
	var is_odd_row = false
	self.width = p_width
	self.height = p_height
	self.current_flood_x = -1
	self.current_turn = 0
	
	# Init empty tiles
	tiles = []
	tiles.resize(p_width)
	for i in p_width:
		tiles[i].resize(p_height)
	sources = []
	
	# Check size matches
	var expected_size = (p_width * p_height + p_width%2)/2.0
	if(board.size() < expected_size):
		printerr("Not enough tiles to init :%d/%d"%[board.size(), expected_size])
		return
	elif(board.size() > expected_size):
		printerr("Too much tiles :%d/%d"%[board.size(), expected_size])
		return
	
	for t in board:
		t.x = current_x
		t.y = current_y
		if(t.is_source):
			sources.append([current_x, current_y])
		tiles[current_x][current_y] = t
			
		current_x += 2
		if(current_x >= p_width):
			is_odd_row = not is_odd_row
			current_x = 1 if is_odd_row else 0
			current_y += 1

func _init_board_16x9():
	var board: Array[Tile] = []
	for i in range(72):
		var rand = randf()
		if i % 18 == 4:
			board.append(Tile.NewSource(randi_range(30, 60)))
		elif rand < 0.2:
			board.append(Tile.NewMountain())
		elif rand < 0.6:
			board.append(Tile.NewForest())
		else:
			board.append(Tile.NewHill())
			
	_init_with_board(board, 16, 9)

func _init_board_15x13():
	var board: Array[Tile] = [
		Tile.NewForest(), Tile.NewForest(), Tile.NewForest(), Tile.NewMountain(), Tile.NewForest(), Tile.NewHill(), Tile.NewHill(), Tile.NewHill(),
			Tile.NewForest(), Tile.NewMountain(), Tile.NewSource(), Tile.NewForest(), Tile.NewForest(), Tile.NewHill(), Tile.NewHill(),
		Tile.NewForest(), Tile.NewForest(), Tile.NewForest(), Tile.NewMountain(), Tile.NewForest(), Tile.NewForest(), Tile.NewForest(), Tile.NewForest(),
			Tile.NewHill(), Tile.NewForest(), Tile.NewForest(), Tile.NewForest(), Tile.NewForest(), Tile.NewForest(), Tile.NewMountain(),
		Tile.NewForest(), Tile.NewHill(), Tile.NewForest(), Tile.NewHill(), Tile.NewHill(), Tile.NewForest(), Tile.NewMountain(), Tile.NewMountain(),
			Tile.NewForest(), Tile.NewHill(), Tile.NewMountain(), Tile.NewHill(), Tile.NewForest(), Tile.NewSource(), Tile.NewMountain(),
		Tile.NewForest(), Tile.NewForest(), Tile.NewHill(), Tile.NewHill(), Tile.NewHill(), Tile.NewMountain(), Tile.NewMountain(), Tile.NewForest(),
			Tile.NewMountain(), Tile.NewHill(), Tile.NewLand(), Tile.NewLand(), Tile.NewForest(), Tile.NewMountain(), Tile.NewForest(),
		Tile.NewMountain(), Tile.NewMountain(), Tile.NewHill(), Tile.NewLand(), Tile.NewLand(), Tile.NewForest(), Tile.NewForest(), Tile.NewHill(),
			Tile.NewSource(), Tile.NewForest(), Tile.NewHill(), Tile.NewLand(), Tile.NewForest(), Tile.NewForest(), Tile.NewHill(),
		Tile.NewForest(), Tile.NewMountain(), Tile.NewForest(), Tile.NewHill(), Tile.NewForest(), Tile.NewForest(), Tile.NewHill(), Tile.NewLand(),
			Tile.NewForest(), Tile.NewForest(), Tile.NewHill(), Tile.NewForest(), Tile.NewHill(), Tile.NewLand(), Tile.NewLand(),
		Tile.NewForest(), Tile.NewForest(), Tile.NewHill(), Tile.NewHill(), Tile.NewHill(), Tile.NewLand(), Tile.NewLand(), Tile.NewLand(),
	]
	
	_init_with_board(board, 15, 13)
	print("init 15x13 done")

# LOGIQUE DES SATELLITES

func place_satellite(x: int, y: int, pattern: Satellite.Pattern, interval: int):
	for i in range(satellites.size() - 1, -1, -1):
		if satellites[i].pattern_type == pattern:
			satellites.remove_at(i)
	
	var sat = Satellite.new(x, y, pattern, interval)
	satellites.append(sat)
	trigger_satellite(sat)

func advance_turn():
	current_turn += 1
	process_board()
	
	for sat in satellites:
		trigger_satellite(sat)
	
	var viewer = get_tree().get_first_node_in_group("viewer")
	if viewer: 
		viewer.update_visuals()

func trigger_satellite(sat: Satellite):
	var tile_coords_to_reveal = get_pattern_coordinates(sat.center_x, sat.center_y, sat.pattern_type)
	for coords in tile_coords_to_reveal:
		var t_x = coords[0]
		var t_y = coords[1]
		if t_x >= 0 and t_x < width and t_y >= 0 and t_y < height:
			var tile = get_tile(t_x, t_y)
			if tile != null:
				tile.last_revealed_turn = current_turn

func get_pattern_coordinates(c_x: int, c_y: int, pattern: Satellite.Pattern) -> Array:
	var coords = [[c_x, c_y]]
	var center_tile = get_tile(c_x, c_y)
	if center_tile == null: 
		return coords
	
	var n1 = get_tile_neighbours(center_tile)
	
	match pattern:
		Satellite.Pattern.CIRCLE:
			coords.append_array(n1)
		Satellite.Pattern.COLUMN:
			for target_x in [c_x - 1, c_x, c_x + 1]:
				if target_x >= 0 and target_x < width:
					for target_y in range(height):
						if target_x % 2 == target_y % 2:
							coords.append([target_x, target_y])
		Satellite.Pattern.OVAL:
			coords.append_array(n1)
			if c_x + 2 < width: coords.append([c_x + 2, c_y])
			if c_x - 2 >= 0: coords.append([c_x - 2, c_y])
		Satellite.Pattern.BUTTERFLY:
			coords.append_array(n1)
			var offsets = [[-2,-2], [2,-2], [-2,2], [2,2]]
			for o in offsets:
				coords.append([c_x + o[0], c_y + o[1]])
	
	return coords

# LOGIQUE DE SIMULATION (EAU)

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
	flow_to_unload = source.send_flow(flow_to_unload)
	
	var source_neighbours = get_tile_neighbours(source)
	for n in source_neighbours:
		var neighbour = get_tile(n[0], n[1])
		var is_just_beneath = (neighbour.height == source.height-1) || (source.is_source && (neighbour.height == source.height-2))
		if(is_just_beneath || neighbour.height == lowest_height && !neighbour.is_flowing()):
			trickle_down(neighbour)

# DEBUG ET UTILITAIRES

func print_board():
	print("--- ÉTAT DU PLATEAU (Tour: ", current_turn, ") ---")
	print_tiles_heights()

func print_tiles(callback: Callable, offset: String = "  ", separator: String = "    "):
	var is_odd_row = false
	for y in height:
		var final_str = offset if is_odd_row else ""
		for x in range(1 if is_odd_row else 0, width, 2):
			final_str += callback.call(tiles[x][y]) + separator
		is_odd_row = !is_odd_row
		print(final_str)

func print_tiles_heights():
	print_tiles(func(t: Tile): return str(t.height))

func get_tile(x: int, y: int) -> Tile:
	if x < 0 or x >= width or y < 0 or y >= height: return null
	return tiles[x][y]

func get_tile_neighbours(tile : Tile):
	var neighbours = []
	if tile.y+2 < height: neighbours.push_back([tile.x, tile.y+2])
	if tile.y-2 >= 0: neighbours.push_back([tile.x, tile.y-2])
	var lateral_offsets = [-1, 1]
	var vertical_offsets = [-1, 1]
	for ox in lateral_offsets:
		for oy in vertical_offsets:
			if tile.x + ox >= 0 and tile.x + ox < width and tile.y + oy >= 0 and tile.y + oy < height:
				neighbours.push_back([tile.x + ox, tile.y + oy])
	return neighbours
	
func process_sources():
	for coordinates in sources:
		lowest_height = 0
		var source : Tile = tiles[coordinates[0]][coordinates[1]]
		flow_to_unload = source.current_flow
		while flow_to_unload > 0 and lowest_height < source.height:
			trickle_down(source)
			lowest_height += 1
		print("Overflow source en ", source.x, ":", source.y, " = ", flow_to_unload)

func reset_flow():
	foreach_tile(func (tile: Tile): tile.current_flow = 0, func (tile: Tile): return not tile.is_source && tile.x > current_flood_x)

func process_flood():
	if(
		current_turn >= turns_before_flood_starts
		&& ((turns_before_flood_starts-current_turn) % turns_between_flood_advances) == 0
	):
		flood_advance()

func flood_advance():
	current_flood_x += 1
	foreach_tile(func(tile: Tile): tile.flood(), func(tile: Tile): return tile.x==current_flood_x)

func process_board():
	reset_flow()
	process_sources()
	process_flood()
	cleanup_submerged_actions()

func place_action(p_x: int, p_y: int, type: ActionType):
	var tile = get_tile(p_x, p_y)
	if tile == null: return
	
	if tile.is_fully_flooded() or tile.x <= current_flood_x:
		print("Impossible : Zone inondée !")
		return
	
	if action_charges[type] > 0:
		active_actions[str(p_x) + "," + str(p_y)] = type
		action_charges[type] -= 1
		var viewer = get_tree().get_first_node_in_group("viewer")
		if viewer: viewer.update_visuals()
	else:
		print("Plus de charges pour cette action !")
		
	action_used.emit()

func get_action_at(p_x: int, p_y: int):
	var key = str(p_x) + "," + str(p_y)
	return active_actions.get(key, null)

func remove_action_at(p_x: int, p_y: int):
	var key = str(p_x) + "," + str(p_y)
	if active_actions.has(key):
		active_actions.erase(key)
		var viewer = get_tree().get_first_node_in_group("viewer")
		if viewer: viewer.update_visuals()

func cleanup_submerged_actions():
	var keys_to_remove = []
	for key in active_actions.keys():
		var coords = key.split(",")
		var tile = get_tile(int(coords[0]), int(coords[1]))
		if tile != null and (tile.is_fully_flooded() or tile.x <= current_flood_x):
			keys_to_remove.append(key)
	
	for key in keys_to_remove:
		active_actions.erase(key)
