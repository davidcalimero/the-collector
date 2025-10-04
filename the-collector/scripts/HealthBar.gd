extends CenterContainer

@export var value: float = 100.0

func _ready():
	GlobalSignals.update_health.connect(_on_update_health)
	GlobalSignals.reset_health.connect(_on_reset)

func _on_update_health(_increment: float) -> void:
	value = max(min(value + _increment, 100), 0)
	var tween = create_tween()
	tween.tween_property($OverBar, "value", value, 0.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($UnderBar, "value", value, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_reset() -> void:
	value = 100
	$OverBar.value = value
	$UnderBar.value = value
