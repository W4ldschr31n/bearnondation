extends Node

var MyScriptTile = load("res://Tile.gd")
var MyTile = MyScriptTile.new()
var SimulationRef = load("res://scripts/simulation.gd")
var MainSimulation = SimulationRef.new()
var Bait = Object
var TimeBeforMoving = 0.0
const TimeToMove = 10.0

# move if possible, if a bait exists then toward it, else call the end of the game
func Move() -> void:
	var targetCase = randi_range(0, 5)
	if(LookForABait() == false):
		for i in range (10000):
			if(true):
				targetCase = randi_range(0, 5)
			else :
				Die()
	else :
		if(Bait.transform.y < self.transform) : # Bait is higher than the animals
			if(Bait.transform.x < self.transform) :
				targetCase = 5 #North West
			elif (Bait.transform.x > self.transform) :
				targetCase = 4 #North East
			else :
				targetCase = 3 #North
		else : # Bait is lower than the animals
			if(Bait.transform.x < self.transform) :
				targetCase = 2 #South West
			elif (Bait.transform.x > self.transform) :
				targetCase = 1 #South East
			else :
				targetCase = 0 #South
	self.transform = SimulationRef.get_tiles_neighbours(MyTile)[targetCase].transform
	MyTile.AnimalsOn = false
	SimulationRef.get_tiles_neighbours(MyTile)[targetCase].AnimalsOn = true
	MyTile = SimulationRef.get_tiles_neighbours(MyTile)[targetCase]

	pass

# should return -1 if no bait, or the id of the neigbor case baited
func LookForABait() -> bool:
	# should get a bait from simulation list referencing baits put on board
	if(Bait != null):
		return true
	return false

func WaitTillMove() -> void:
	if(TimeBeforMoving <= 0):
		Move()
		TimeBeforMoving = TimeToMove
	else :
		await get_tree().create_timer(1.0).timeout
		TimeBeforMoving -= 1
		if(LookForABait()):
			TimeBeforMoving -= 1
		WaitTillMove()
	pass

func Die() -> void:
	# do nothing yet, but should end the game
	pass
