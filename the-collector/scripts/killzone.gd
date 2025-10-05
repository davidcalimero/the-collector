extends Area2D

@export var player: Node2D
@onready var die_timer : Timer

const TIMER = 0.2

func _on_body_entered(body: Node2D) -> void:
	if (body != player):
		return
		
	if die_timer == null:
		die_timer = Timer.new()
		add_child(die_timer)
		die_timer.wait_time = TIMER
		die_timer.timeout.connect(_on_game_over)
	die_timer.start()
	Engine.time_scale = 0.25
		
func _on_game_over() -> void:
	Engine.time_scale = 1.0
	if die_timer:
		die_timer.stop()
		die_timer = null
	player.global_position = GlobalSignals.last_checkpoint
	#GlobalSignals.refresh_skills()
