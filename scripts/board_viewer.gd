extends Node

@export var simulation: Simulation
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var highlight_layer: TileMapLayer = $HighlightLayer
@onready var labels: Control = $Labels
@onready var ghost: Sprite2D = $SatelliteGhost
@onready var timer_label: Label = $Buttons/TimerLabel

var tile_info_scene = preload("res://scenes/TileInfo.tscn")
var tile_infos : Array[Array]
var is_placing_satellite : bool = false
var current_pattern : Satellite.Pattern = Satellite.Pattern.CIRCLE

enum PlacementMode { SATELLITE, ACTION }
var current_mode = PlacementMode.SATELLITE
var current_action_type : Simulation.ActionType = Simulation.ActionType.BAIT

func _ready() -> void:
	add_to_group("viewer")
	if simulation == null:
		simulation = get_parent().get_node("Simulation")
	ghost.visible = false
	if highlight_layer:
		highlight_layer.clear()

func _process(_delta: float) -> void:
	if is_placing_satellite:
		update_satellite_ghost_position()
		update_preview_zone()
	else:
		if highlight_layer:
			highlight_layer.clear()
	
	update_timer_display()

func update_timer_display():
	if simulation and simulation.turn_timer:
		var time_left = simulation.turn_timer.time_left
		timer_label.text = "Prochain scan : %.1f s" % time_left
		timer_label.modulate = Color.RED if time_left < 5.0 else Color.WHITE

# LOGIQUE DE PRÉVISUALISATION

func update_preview_zone():
	if !highlight_layer: return
	highlight_layer.clear()
	
	var mouse_pos = tile_map_layer.get_local_mouse_position()
	var grid_pos = tile_map_layer.local_to_map(mouse_pos)
	
	var sim_x = grid_pos.x
	var sim_y = grid_pos.y * 2
	
	var center_tile = simulation.get_tile(sim_x, sim_y)
	if center_tile == null:
		center_tile = simulation.get_tile(sim_x, sim_y + 1)
	
	if center_tile != null:
		var pattern_to_use = current_pattern
		if current_mode == PlacementMode.ACTION:
			pattern_to_use = Satellite.Pattern.CIRCLE
			
		var zone_coords = simulation.get_pattern_coordinates(center_tile.x, center_tile.y, pattern_to_use)
		
		for coords in zone_coords:
			var cell_pos = Vector2i(coords[0], coords[1] / 2)
			highlight_layer.set_cell(cell_pos, 0, Vector2i(0, 0)) 
		
		var pulse = (sin(Time.get_ticks_msec() * 0.003) + 1.0) / 2.0
		var alpha = 0.3 + (pulse * 0.4)
		
		if current_mode == PlacementMode.ACTION:
			if current_action_type == Simulation.ActionType.BAIT:
				highlight_layer.modulate = Color(0.0, 15.0, 0.0, alpha)
			else:
				highlight_layer.modulate = Color(15.0, 0.0, 0.0, alpha)
		else:
			highlight_layer.modulate = Color(15.0, 5.0, 0.0, alpha)

# PLACEMENT ET MAGNÉTISME

func update_satellite_ghost_position():
	var mouse_pos = tile_map_layer.get_local_mouse_position()
	var grid_pos = tile_map_layer.local_to_map(mouse_pos)
	var local_snapped_pos = tile_map_layer.map_to_local(grid_pos)
	ghost.global_position = tile_map_layer.to_global(local_snapped_pos)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if is_placing_satellite:
			place_satellite_at_mouse()

func place_satellite_at_mouse():
	var mouse_pos = tile_map_layer.get_local_mouse_position()
	var grid_pos = tile_map_layer.local_to_map(mouse_pos)
	var sim_x = grid_pos.x
	var sim_y = grid_pos.y * 2
	
	var tile = simulation.get_tile(sim_x, sim_y)
	if tile == null: tile = simulation.get_tile(sim_x, sim_y + 1)
	
	if tile != null:
		if current_mode == PlacementMode.SATELLITE:
			simulation.place_satellite(tile.x, tile.y, current_pattern, 3)
		else:
			simulation.place_action(tile.x, tile.y, current_action_type)
		
		is_placing_satellite = false
		ghost.visible = false
		ghost.modulate = Color.WHITE
		if highlight_layer: highlight_layer.clear()

func _start_action_placement(type: Simulation.ActionType):
	is_placing_satellite = true 
	current_mode = PlacementMode.ACTION
	current_action_type = type
	ghost.visible = true
	
	if type == Simulation.ActionType.BAIT:
		ghost.modulate = Color.GREEN
	else:
		ghost.modulate = Color.RED
	update_satellite_ghost_position()

# INITIALISATION ET MISE À JOUR VISUELLE

func init_grid():
	tile_map_layer.clear()
	for child in labels.get_children():
		child.queue_free()
	
	tile_infos = []
	tile_infos.resize(simulation.width)
	for i in simulation.width:
		tile_infos[i].resize(simulation.height)
	
	var is_odd_row = false
	for y in simulation.height:
		for x in range(1 if is_odd_row else 0, simulation.width, 2):
			var tile = simulation.get_tile(x, y)
			var cell_coordinates = Vector2i(tile.x, tile.y/2)
			tile_map_layer.set_cell(cell_coordinates, 0, Vector2i(4-tile.height, 0))
			
			var new_widget : TileInfo = tile_info_scene.instantiate()
			labels.add_child(new_widget)
			var coords2D = tile_map_layer.to_global(tile_map_layer.map_to_local(cell_coordinates))
			new_widget.set_global_position(coords2D)
			tile_infos[tile.x][tile.y] = new_widget
		is_odd_row = not is_odd_row

func update_visuals():
	var is_odd_row = false
	for y in simulation.height:
		for x in range(1 if is_odd_row else 0, simulation.width, 2):
			var tile = simulation.get_tile(x, y)
			if tile == null: continue
			
			var info = tile_infos[x][y]
			var cell_coords = Vector2i(tile.x, tile.y/2)
			
			var fog = tile.get_fog_level(simulation.current_turn)
			var gray_value = 1.0 - (fog * 0.125) 
			
			info.modulate = Color(gray_value, gray_value, gray_value, 1.0)
			info.display_tile(tile)
			
			var action = simulation.get_action_at(tile.x, tile.y)
			if action != null:
				if action == Simulation.ActionType.BAIT:
					info.label.text += "\n[APPÂT]"
					info.modulate = Color(0.5, 1.0, 0.5, 1.0) 
				elif action == Simulation.ActionType.REPELLENT:
					info.label.text += "\n[REPOUSSE]"
					info.modulate = Color(1.0, 0.5, 0.5, 1.0)

			tile_map_layer.set_cell(cell_coords, 0, Vector2i(4-tile.height, 0), fog)
				
		is_odd_row = not is_odd_row
	
	_update_action_ui_labels()

func _update_action_ui_labels():
	if has_node("Buttons/BaitCount"):
		get_node("Buttons/BaitCount").text = "x" + str(simulation.action_charges[Simulation.ActionType.BAIT])
	if has_node("Buttons/RepellentCount"):
		get_node("Buttons/RepellentCount").text = "x" + str(simulation.action_charges[Simulation.ActionType.REPELLENT])

# SIGNAUX UI

func _on_btn_circle_pressed(): _start_placement(Satellite.Pattern.CIRCLE)
func _on_btn_column_pressed(): _start_placement(Satellite.Pattern.COLUMN)
func _on_btn_oval_pressed(): _start_placement(Satellite.Pattern.OVAL)
func _on_btn_butterfly_pressed(): _start_placement(Satellite.Pattern.BUTTERFLY)
func _on_btn_bait_pressed(): _start_action_placement(Simulation.ActionType.BAIT)
func _on_btn_repellent_pressed(): _start_action_placement(Simulation.ActionType.REPELLENT)

func _start_placement(pattern: Satellite.Pattern):
	is_placing_satellite = true
	current_mode = PlacementMode.SATELLITE
	current_pattern = pattern
	ghost.visible = true
	ghost.modulate = Color.WHITE
	update_satellite_ghost_position()

func _on_init_button_pressed():
	simulation._init_board_16x9()
	init_grid()

func _on_print_button_pressed(): simulation.print_board()
func _on_process_button_pressed(): simulation.process_board()
