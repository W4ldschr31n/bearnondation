extends Node

@export var simulation: Simulation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_init_button_pressed() -> void:
	simulation._init_board_8x4()


func _on_print_button_pressed() -> void:
	simulation.print_board()


func _on_process_button_pressed() -> void:
	simulation.process_board()
