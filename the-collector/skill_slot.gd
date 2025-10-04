extends TextureRect

@export var skill_icon: Texture2D
@export var skill_name: String = ""
@export var skill_id: String = ""
@export var skill_data: Dictionary

var has_skill := false

func _ready():
	texture = skill_icon if skill_icon else preload("res://assets/Sprites/skill_slot.png")
	mouse_filter = Control.MOUSE_FILTER_PASS

func _get_drag_data(at_position):
	if has_skill:
		var preview = TextureRect.new()
		preview.texture = texture
		preview.scale = Vector2(0.5, 0.5)
		set_drag_preview(preview)
		return {"skill_id": skill_id, "icon": texture, "skill_data": skill_data}
	return null

func _drop_data(at_position, data):
	set_skill(data)

func set_skill(data: Dictionary):
	skill_icon = data["icon"]
	skill_id = data["skill_id"]
	skill_data = data["skill_data"]
	texture = skill_icon
	has_skill = true
