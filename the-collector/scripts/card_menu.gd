extends PanelContainer

# --- CONFIG ---
@export var skill_bar_path: NodePath
@export var preview_size: Vector2i = Vector2i(64, 64)

# --- STATE ---
var _choosing_slot: bool = false
var _origin_card: Control = null
var _slots: Array[Control] = []
var _preview: TextureRect = null
var _selected_card_data: Dictionary = {}

func _ready() -> void:
	if skill_bar_path != NodePath():
		var bar := get_node_or_null(skill_bar_path)
		if bar:
			for n in bar.get_children():
				if n is Control:
					_slots.append(n as Control)

	# cria o node de preview (invisível) uma vez
	_preview = TextureRect.new()
	_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_preview.custom_minimum_size = preview_size
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.visible = false
	_preview.top_level = true
	_preview.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_preview.z_index = 100
	add_child(_preview)

	get_viewport().gui_focus_changed.connect(func(focused: Control):
		if _choosing_slot:
			_update_preview_position())

func _unhandled_input(event):
	if event.is_action_pressed("toggle_card_menu"):
		_toggle_menu()
		get_viewport().set_input_as_handled()
		return
	if not visible:
		return
	if _choosing_slot:
		if event.is_action_pressed("ui_accept"):
			_confirm_apply_to_focused_slot()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_cancel"):
			_end_choose_slot()
			get_viewport().set_input_as_handled()
			return
		return
	if event.is_action_pressed("ui_accept"):
		var f := get_viewport().gui_get_focus_owner()
		if f == $MarginContainer/VBoxContainer/CloseButton : 
			_toggle_menu()
			return
		if f and f.is_unlocked():
			_start_choose_slot(f)
			get_viewport().set_input_as_handled()
			return

func _toggle_menu():
	if visible:
		_close_menu()
	else:
		_open_menu()

# --------------- OPEN/CLOSE ---------------
		
func _open_menu():
	$MarginContainer/VBoxContainer/CloseButton.grab_focus()
	
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	scale = Vector2(0.95, 0.95)
	var t = create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.12)
	t.parallel().tween_property(self, "scale", Vector2.ONE, 0.12)
	
func _close_menu():
	_end_choose_slot()
	var t = create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.12)
	t.parallel().tween_property(self, "scale", Vector2(0.95, 0.95), 0.12)
	t.connect("finished", func():
		visible = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE)

# --------------- HELPERS ----------------

func _is_pickable(n: Control) -> bool:
	return n.is_unlocked()
	
# --------------- CHOOSE-SLOT FLOW ---------------

func _start_choose_slot(card: Control) -> void:
	if _slots.is_empty():
		return
	_origin_card = card
	
	_selected_card_data = {
		"source_type": "card",
		"from_path": card.get_path(),
		"skill": card.skill,
		"skill_icon": card.texture,
		"name": card.Name
	}
	_preview.texture = _selected_card_data.get("skill_icon")
	_preview.visible = true
	_choosing_slot = true
	_slots[0].grab_focus()
	_update_preview_position()
	
func _update_preview_position() -> void:
	if not _preview.visible: 
		return
	var f := get_viewport().gui_get_focus_owner()
	for s in _slots:
		if f and (f == s or s.is_ancestor_of(f)):
			var gr := s.get_global_rect()
			# centro do slot
			var center := gr.position + gr.size * 0.5
			_preview.global_position = center - _preview.size * 0.5
			return
		
func _confirm_apply_to_focused_slot() -> void:
	if _slots.is_empty() or _selected_card_data.is_empty():
		_end_choose_slot()
		return
	var f := get_viewport().gui_get_focus_owner()
	if f and _slots.has(f):
		f.apply_card(_selected_card_data)
	_end_choose_slot()
	
func _end_choose_slot() -> void:
	_choosing_slot = false
	_selected_card_data.clear()
	_preview.visible = false
	if is_instance_valid(_origin_card):
		_origin_card.grab_focus()
	_origin_card = null
