class_name TileInfo
extends Control

@onready var label: Label = $Label


func display_tile(tile: Tile):
	label.text = str(tile.current_flow) + "/" + str(tile.max_flow)
