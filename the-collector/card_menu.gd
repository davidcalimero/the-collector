extends PanelContainer

func _ready():
	GlobalSignals.emit_signal("learn_skill", GlobalSignals.SkillType.DASH)
	GlobalSignals.emit_signal("learn_skill", GlobalSignals.SkillType.DOUBLE_JUMP)
	GlobalSignals.emit_signal("learn_skill", GlobalSignals.SkillType.GLIDE)
	GlobalSignals.emit_signal("learn_skill", GlobalSignals.SkillType.CHARGE_ATTACK)
	GlobalSignals.emit_signal("learn_skill", GlobalSignals.SkillType.BLOCK)

func _unhandled_input(event):
	if event.is_action_pressed("toggle_card_menu"):
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu():
	if visible:
		_close_menu()
	else:
		_open_menu()
		
func _open_menu():
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(self, "scale", Vector2.ONE, 0.12)
	
func _close_menu():
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.parallel().tween_property(self, "scale", Vector2(0.95, 0.95), 0.12)
	t.connect("finished", func():
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
