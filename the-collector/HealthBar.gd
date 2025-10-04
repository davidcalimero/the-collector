extends CenterContainer

signal update_health(increment : float)
signal reset

@export var value: float = 100.0

func _ready():
	connect("update_health", _on_update_health)
	connect("reset", _on_reset)

func _on_update_health(_increment: float) -> void:
	value = max(min(value + _increment, 100), 0)
	var tween = create_tween()
	tween.tween_property($OverBar, "value", value, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($UnderBar, "value", value, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_reset() -> void:
	value = 100
	$OverBar.value = value
	$UnderBar.value = value
