class_name Simulation
extends Node

var tiles : Array[Array]
var sources : Array
var width: int
var height: int

# Gestion des tours et satellites
var current_turn : int = 0
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

func _self_init():
	_init_board_16x9()
	print("--- Plateau 16x9 Initialisé ---")
	process_board()
	print_board()

func _init_board_16x9():
	var board: Array[Tile] = []
	for i in range(72):
		var rand = randf()
		if i % 18 == 4:
			board.append(Tile.NewSource(randi_range(150, 300)))
		elif rand < 0.2:
			board.append(Tile.NewMountain())
		elif rand < 0.6:
			board.append(Tile.NewForest())
		else:
			board.append(Tile.NewHill())
			
	_init_with_board(board, 16, 9)

func _init_with_board(board: Array[Tile], p_width: int, p_height: int) -> void:
	self.width = p_width
	self.height = p_height
	
	var expected_size = (width * height) / 2
	if board.size() != expected_size:
		printerr("Erreur : Taille du tableau incorrecte.")
		return

	tiles = []
	tiles.resize(width)
	for i in width:
		tiles[i].resize(height)
	sources = []
	
	var current_x = 0
	var current_y = 0
	var is_odd_row = false
	
	for t in board:
		t.x = current_x
		t.y = current_y
		if t.is_source:
			sources.append([current_x, current_y])
		tiles[current_x][current_y] = t
			
		current_x += 2
		if current_x >= width:
			is_odd_row = !is_odd_row
			current_x = 1 if is_odd_row else 0
			current_y += 1

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

# Patterns de scan satellites
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

func process_board():
	process_sources()

func process_sources():
	for coordinates in sources:
		var source : Tile = tiles[coordinates[0]][coordinates[1]]
		trickle_down(source)

func trickle_down(source: Tile):
	var flow_to_unload = source.current_flow
	var source_neighbours = get_tile_neighbours(source)
	source_neighbours.reverse()
	var tiles_to_check = []
	for n in source_neighbours:
		var neighbour = get_tile(n[0], n[1])
		if neighbour and neighbour.height == source.height-1:
			tiles_to_check.push_front(n)
			
	var checked_tiles = [[source.x, source.y]]
	while flow_to_unload > 0 and tiles_to_check.size() > 0:
		var t_coordinates = tiles_to_check.pop_front()
		var tile : Tile = tiles[t_coordinates[0]][t_coordinates[1]]
		checked_tiles.push_back([tile.x, tile.y])
		
		var unloadable_flow: int = min(flow_to_unload, tile.max_flow - tile.current_flow)
		tile.current_flow += unloadable_flow
		flow_to_unload -= unloadable_flow
		
		var new_neighbours = get_tile_neighbours(tile)
		new_neighbours.reverse()
		for n in new_neighbours:
			var neighbour = get_tile(n[0], n[1])
			if neighbour and !checked_tiles.has(n) and !tiles_to_check.has(n) and neighbour.height == tile.height-1:
				tiles_to_check.push_front(n)

# DEBUG

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

func _on_step_timer_timeout() -> void:
	advance_turn()

func place_action(x: int, y: int, type: ActionType):
	if action_charges[type] > 0:
		active_actions[str(x) + "," + str(y)] = type
		action_charges[type] -= 1
		print("Action placée: ", type, " Charges restantes: ", action_charges[type])
		
		var viewer = get_tree().get_first_node_in_group("viewer")
		if viewer: viewer.update_visuals()
	else:
		print("Plus de charges pour cette action !")

func get_action_at(x: int, y: int):
	var key = str(x) + "," + str(y)
	return active_actions.get(key, null)
