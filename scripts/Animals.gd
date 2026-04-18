class_name Animals
extends Node

signal moved

@export var SimulationRef : Simulation
@export var x : int
@export var y : int

var MyTile : Tile
var TimeBeforMoving = 0.0
const TimeToMove = 10.0

# move if possible, if a bait exists then toward it, else call the end of the game
func Move() -> void:
	MyTile = SimulationRef.get_tile(x, y)
	var target_coordinates = [x,y]
	if(LookForABait() == false):
		for coordinates : Array in SimulationRef.get_tile_neighbours(MyTile):
			var tile_to_check : Tile = SimulationRef.get_tile(coordinates[0], coordinates[1])
			if(tile_to_check.is_filled() == false):
				target_coordinates = coordinates
				break
	else :
		#should get the best bait
		var baited_case : Tile
		for line_to_check in SimulationRef.tiles :
			if (line_to_check != []):
				for tile_to_check : Tile in line_to_check :
					if(tile_to_check != null):
						print(tile_to_check.name, " is tile to check")
						if(SimulationRef.get_action_at(tile_to_check.x, tile_to_check.y) == SimulationRef.ActionType.BAIT):
							baited_case = SimulationRef.get_tile(tile_to_check.x, tile_to_check.y)
		var bait_direction : int
		if(baited_case.y < y) : # Bait is higher than the animals
			if(baited_case.x < x) :
				bait_direction = 5 #North West
			elif (baited_case.x > x) :
				bait_direction = 4 #North East
			else :
				bait_direction = 3 #North
		else : # Bait is lower than the animals
			if(baited_case.x < x) :
				bait_direction = 2 #South West
			elif (baited_case.x > x) :
				bait_direction = 1 #South East
			else :
				bait_direction = 0 #South
		var neighbour_direction : int
		for coordinates : Array in (SimulationRef.get_tile_neighbours(MyTile)):
			if(coordinates[1] < y) : # Bait is higher than the animals
				if(coordinates[0] < x) :
					neighbour_direction = 5 #North West
				elif (coordinates[0] > x) :
					neighbour_direction = 4 #North East
				else :
					neighbour_direction = 3 #North
			else : # Bait is lower than the animals
				if(coordinates[0] < x) :
					neighbour_direction = 2 #South West
				elif (coordinates[0] > x) :
					neighbour_direction = 1 #South East
				else :
					neighbour_direction = 0 #South
			if (bait_direction == neighbour_direction) :
				target_coordinates = coordinates
				break
			else:
				print("Error : can't move")
	x = target_coordinates[0]
	y = target_coordinates[1]
	if (SimulationRef.get_action_at(x, y) == SimulationRef.ActionType.BAIT):
		#enlever l'appat
		pass
	moved.emit()

# should return -1 if no bait, or the id of the neigbor case baited
func LookForABait() -> bool:
	# should get a bait from simulation list referencing baits put on board
	#if (SimulationRef.baits == []):
		#return false
	for line_to_check in SimulationRef.tiles :
		if (line_to_check != []):
			for tile_to_check : Tile in line_to_check :
				if(tile_to_check != null):
					print(tile_to_check.name, " is tile to check")
					if(SimulationRef.get_action_at(tile_to_check.x, tile_to_check.y) == SimulationRef.ActionType.BAIT):
						return true
	return false

func _on_timer_timeout() -> void:
	Move()
	print(x, y)
