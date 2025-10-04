extends HBoxContainer

@onready var slots = [
	$SkillSlot1,
	$SkillSlot2,
	$SkillSlot3
]

func _ready():
	for slot in slots:
		slot.has_skill = false
