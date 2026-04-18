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
		var Bait = SimulationRef.baits[0]
		var bait_direction : int
		if(Bait.y < y) : # Bait is higher than the animals
			if(Bait.x < x) :
				bait_direction = 5 #North West
			elif (Bait.x > x) :
				bait_direction = 4 #North East
			else :
				bait_direction = 3 #North
		else : # Bait is lower than the animals
			if(Bait.x < x) :
				bait_direction = 2 #South West
			elif (Bait.x > x) :
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
	moved.emit()

# should return -1 if no bait, or the id of the neigbor case baited
func LookForABait() -> bool:
	# should get a bait from simulation list referencing baits put on board
	if (SimulationRef.baits == []):
		return false
	return true

func _on_timer_timeout() -> void:
	Move()
	print(x, y)
