class_name Animals
extends Node

signal moved

@export var SimulationRef : Simulation
@export var x : int = 0
@export var y : int = 0

var MyTile : Tile

func _ready() -> void:
	if (x % 2 != y % 2):
		y += 1
	moved.emit()

func Move() -> void:
	MyTile = SimulationRef.get_tile(x, y)
	if MyTile == null: return

	var valid_neighbours = get_safe_neighbours()
	
	if valid_neighbours.is_empty():
		print("Famille bloquée à ", x, ";", y)
		return

	var target_coordinates = [x, y]
	var closest_bait_tile = get_closest_action(SimulationRef.ActionType.BAIT)
	
	if closest_bait_tile != null:
		target_coordinates = get_best_neighbour_towards(valid_neighbours, closest_bait_tile)
	else:
		target_coordinates = choose_autonomous_move(valid_neighbours)

	x = target_coordinates[0]
	y = target_coordinates[1]
	
	if (SimulationRef.get_action_at(x, y) == SimulationRef.ActionType.BAIT):
		SimulationRef.remove_action_at(x, y)
		
	moved.emit()

func get_hex_dist(x1: int, y1: int, x2: int, y2: int) -> float:
	return Vector2(x1, y1 * 0.5).distance_to(Vector2(x2, y2 * 0.5))

func get_closest_action(type: Simulation.ActionType) -> Tile:
	var closest_tile : Tile = null
	var min_dist = 999999.0
	
	for key in SimulationRef.active_actions:
		if SimulationRef.active_actions[key] == type:
			var coords = key.split(",")
			var tx = int(coords[0])
			var ty = int(coords[1])
			var dist = get_hex_dist(x, y, tx, ty)
			if dist < min_dist:
				min_dist = dist
				closest_tile = SimulationRef.get_tile(tx, ty)
	return closest_tile

func get_safe_neighbours() -> Array:
	var safe = []
	var neighbours = SimulationRef.get_tile_neighbours(MyTile)
	
	for coords in neighbours:
		var t = SimulationRef.get_tile(coords[0], coords[1])
		if t != null:
			var is_ocean = t.x <= SimulationRef.current_flood_x
			var is_flooded = t.is_fully_flooded()
			var is_repelled = SimulationRef.get_action_at(t.x, t.y) == SimulationRef.ActionType.REPELLENT
			
			if not is_ocean and not is_flooded and not is_repelled:
				safe.append(coords)
			else:
				print("Case ", coords, " rejetée : Ocean=", is_ocean, " Eau=", is_flooded, " Bombe=", is_repelled)
	return safe

func get_best_neighbour_towards(neighbours: Array, target: Tile) -> Array:
	var best_coords = neighbours[0]
	var min_dist = 999999.0
	
	for coords in neighbours:
		var dist = get_hex_dist(coords[0], coords[1], target.x, target.y)
		dist -= (coords[0] - x) * 0.01 
		
		if dist < min_dist:
			min_dist = dist
			best_coords = coords
	return best_coords

func choose_autonomous_move(neighbours: Array) -> Array:
	var best = neighbours[0]
	var max_score = -999999.0
	
	for coords in neighbours:
		var t = SimulationRef.get_tile(coords[0], coords[1])
		var score = 0.0
		score += (coords[0] - x) * 100 
		score += t.height * 10
		
		if score > max_score:
			max_score = score
			best = coords
	return best

func _on_timer_timeout() -> void:
	Move()
