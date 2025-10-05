extends Area2D

@export var show_prompt_above := true
var player : Node = null

const BUTTON_PROMPTS := {
	"keyboard": "Press E",
	"xbox":  "Press Y",
	"playstation": "Press △",
	"switch": "Press X",
}

func _ready() -> void:
	$Prompt.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GlobalSignals.device_changed.connect(_on_device_changed)

func _unhandled_input(event: InputEvent) -> void:
	if player and Input.is_action_just_pressed("interact"):
		_activate_checkpoint()
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		player = body
		$Prompt.visible = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player"):
		player = null
		$Prompt.visible = false

func _activate_checkpoint() -> void:
	GlobalSignals.set_checkpoint(global_position)
	var t := create_tween()
	t.tween_property($Sprite2D, "modulate", Color(1,1,1,0.4), 0.1)
	t.tween_property($Sprite2D, "modulate", Color(1,1,1,1.0), 0.1)


func _on_device_changed(device: String):
	var label = BUTTON_PROMPTS[device]
	$Prompt.text = label
