extends Button

@export var target_scene_path: String = "res://main_scene.tscn"

func _ready():
	Music.play_music(load("res://assets/audio/music.mp3"))
	grab_focus()

func _on_button_pressed():
	get_tree().change_scene_to_file(target_scene_path)
	
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept") and has_focus():
		_on_button_pressed()
