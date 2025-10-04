extends Area2D

@export var player: Node2D
@export var next_scene: String

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == player:
		get_tree().change_scene_to_file(next_scene)
