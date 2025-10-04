extends TextureRect

@export var skill_id: String = ""
@export var unlocked: bool = false

func _ready():
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_PASS
	$Locked.visible = not unlocked
	
func _unlock():
	$Locked.visible = true

func _get_drag_data(at_position):
	if not unlocked:
		return null
	var preview := TextureRect.new()
	preview.texture = texture
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)
	return {
		"source_type": "card",
		"from_path": get_path(),
		"skill_id": skill_id,
		"skill_icon": texture
	}

func _can_drop_data(at_position, data):
	return false
