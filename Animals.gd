extends Node

var MyScriptCase = load("res://Case.gd")
var MyCase = MyScriptCase.new()
var TimeBeforMoving = 0.0
const TimeToMove = 10.0

# move if possible, priorising baited cases, else call the end of the game
func Move() -> void:
	var targetCase = randi_range(0, 5)
	if(LookForABait() == -1):
		for i in range (10000):
			if(true):
				targetCase = randi_range(0, 5)
			else :
				Die()
	else :
		targetCase = LookForABait()
	self.transform = MyCase.NeighborCases[targetCase].transform
	MyCase.AnimalsOn = false
	MyCase.NeighborCases[targetCase].AnimalsOn = true
	MyCase = MyCase.NeighborCases[targetCase]

	pass

# should return -1 if no bait, or the id of the neigbor case baited
func LookForABait() -> int:
	for i in range (6):
		if (MyCase.NeigborCases[i].IsBaited):
			return i
	return -1

func WaitTillMove() -> void:
	if(TimeBeforMoving <= 0):
		Move()
		TimeBeforMoving = TimeToMove
	else :
		await get_tree().create_timer(1.0).timeout
		TimeBeforMoving -= 1
		if(LookForABait() >= 0):
			TimeBeforMoving -= 1
		WaitTillMove()
	pass

func Die() -> void:
	print("do nothing yet, but should end the game")
	pass
