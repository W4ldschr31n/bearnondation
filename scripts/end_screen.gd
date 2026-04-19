extends Control

@onready var end_text: Label = $EndText

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if(Globals.has_won):
		end_text.text = "Victoire !\nLes ours sont sauvés!"
	else:
		end_text.text = "Défaite...\nLes ours vont se noyer."


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_again_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainScene.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
