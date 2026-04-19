class_name TileInfo
extends Control

@onready var label: Label = $Label

func display_tile(tile: Tile, is_objective: bool = false):
	if tile.current_flow == 0:
		label.text = str(tile.current_filling) + "/" + str(tile.max_filling) + "\n(Fill)"
	else:
		label.text = str(tile.current_flow) + "/" + str(tile.max_flow) + "\n(Flow)"
	
	if is_objective:
		label.text += "\n[SORTIE]"

func display_flood():
	label.text = "FLOOD"
