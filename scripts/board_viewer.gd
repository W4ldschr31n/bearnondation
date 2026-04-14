extends Node

@export var simulation: Simulation
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var labels: Control = $Labels
var tile_info_scene = preload("res://scenes/TileInfo.tscn")
var tile_infos : Array[Array]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func init_grid():
	tile_map_layer.clear()
	for child in labels.get_children():
		child.queue_free()
	tile_infos = []
	tile_infos.resize(simulation.width)
	for i in simulation.width:
		tile_infos[i].resize(simulation.height)
	
	var source_id = 0
	var is_odd_row = false
	
	for y in simulation.height:
		for x in range(1 if is_odd_row else 0, simulation.width, 2):
			var tile = simulation.get_tile(x, y)
			var cell_coordinates = Vector2i(tile.x, tile.y/2)
			tile_map_layer.set_cell(cell_coordinates, source_id, Vector2i(4-tile.height, 0))
			var new_widget : TileInfo = tile_info_scene.instantiate()
			labels.add_child(new_widget)
			var coords2D = tile_map_layer.to_global(tile_map_layer.map_to_local(cell_coordinates))
			new_widget.set_global_position(coords2D)
			tile_infos[tile.x][tile.y] = new_widget
		is_odd_row = not is_odd_row


func _on_init_button_pressed() -> void:
	simulation._init_board_8x4()
	init_grid()


func _on_print_button_pressed() -> void:
	simulation.print_board()


func _on_process_button_pressed() -> void:
	simulation.process_board()


func _on_display_grid_button_pressed() -> void:
	var is_odd_row = false
	for y in simulation.height:
		for x in range(1 if is_odd_row else 0, simulation.width, 2):
			tile_infos[x][y].display_tile(simulation.get_tile(x, y))
		is_odd_row = not is_odd_row
	
