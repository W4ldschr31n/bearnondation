extends Node

@onready var simulation: Simulation = $Simulation
@onready var board_viewer: Node = $BoardViewer


func _ready() -> void:
	simulation._init_board_15x13()
	board_viewer.init_grid()
