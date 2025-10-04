extends TextureRect

@export var empty_icon: Texture2D
@export var skill_icon: Texture2D
@export var skill: GlobalSignals.SkillType
@export var has_skill = false

func _ready():
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_refresh_visual()

func _refresh_visual():
	texture = skill_icon if has_skill else empty_icon

func _drop_data(at_position, data):
	if data.get("source_type","") == "card":
		GlobalSignals.emit_signal("unequip_skill", skill)
		skill = data.get("skill")
		skill_icon = data.get("skill_icon")
		has_skill = true
		GlobalSignals.emit_signal("equip_skill", skill)
		_refresh_visual()

func _can_drop_data(at_position, data):
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if data.get("source_type","") == "card":
		return true
	return false
