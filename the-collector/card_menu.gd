extends PanelContainer

@onready var _close_btn: Control = $MarginContainer/VBoxContainer/CloseButton

func _unhandled_input(event):
	if event.is_action_pressed("toggle_card_menu"):
		_toggle_menu()
		get_viewport().set_input_as_handled()

func _toggle_menu():
	if visible:
		_close_menu()
	else:
		_open_menu()

# --------------- OPEN/CLOSE ---------------
		
func _open_menu():
	_close_btn.grab_focus()
	
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
		mouse_filter = Control.MOUSE_FILTER_IGNORE)

# --------------- HELPERS ----------------

func _is_pickable(n: Control) -> bool:
	return n.is_unlocked()
