extends TextureRect

@export var skill: GlobalSignals.SkillType

func _ready():
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_PASS
	connect("visibility_changed", _on_visibility_changed)

func _on_visibility_changed():
	if visible:
		$Locked.visible = not GlobalSignals.is_skill_learned(skill)

func _get_drag_data(at_position):
	if not GlobalSignals.is_skill_learned(skill):
		return null
	var preview := TextureRect.new()
	preview.texture = texture
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {
		"source_type": "card",
		"from_path": get_path(),
		"skill": skill,
		"skill_icon": texture
	}

func _can_drop_data(at_position, data):
	return false
