extends Area2D

@export var skill : GlobalSignals.SkillType 
@export var pickup_sound: AudioStream

var _consumed := false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _consumed:
		return
	if not _is_player(body):
		return
	_consumed = true
	GlobalSignals.emit_signal("learn_skill", skill)

	if pickup_sound:
		_play_and_free()
	else:
		queue_free()

func _is_player(body: Node) -> bool:
	return body.is_in_group("Player")

func _play_and_free():
	var asp := AudioStreamPlayer.new()
	asp.stream = pickup_sound
	add_child(asp)
	asp.bus = "SFX"
	asp.play()
	hide()
	monitoring = false
	asp.finished.connect(func(): queue_free())
