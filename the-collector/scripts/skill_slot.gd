extends TextureRect

@export var skill: GlobalSignals.SkillType
var skill_icon: Texture2D = null

func _ready():
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_refresh_visual()
	# Toggle ring on focus
	focus_entered.connect(func(): $FocusFrame.visible = true)
	focus_exited.connect(func(): $FocusFrame.visible = false)

func _refresh_visual():
	if skill_icon:
		texture = skill_icon
		
func apply_card(data: Dictionary) -> void:
	# Same logic you do in _drop_data, but callable from code
	GlobalSignals.emit_signal("unequip_skill", skill)
	skill = data.get("skill")
	skill_icon = data.get("skill_icon")
	$Name.text = data.get("name")
	GlobalSignals.emit_signal("equip_skill", skill)
	_refresh_visual()

func _drop_data(at_position, data):
	if data.get("source_type","") == "card":
		apply_card(data)

func _can_drop_data(at_position, data):
	return typeof(data) == TYPE_DICTIONARY and data.get("source_type","") == "card"
