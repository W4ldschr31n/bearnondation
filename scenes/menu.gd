extends Control
@onready var main_level = preload("res://scenes/MainScene.tscn")

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_packed(main_level)
