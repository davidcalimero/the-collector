extends Button

@export var target_scene_path: String = "res://scenes//main_scene.tscn"

func _ready():
	Music.play_music(load("res://assets/audio/music.mp3"))
	grab_focus()

func _on_button_pressed():
	GlobalSignals.refresh_skills()
	get_tree().change_scene_to_file(target_scene_path)
