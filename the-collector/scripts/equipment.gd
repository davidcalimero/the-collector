extends Node2D

func _ready() -> void:
	pass
	
func acquired_skills() -> void:
	pass
	
func has_card_skill_equipped(skill_type: GlobalSignals.SkillType) -> bool:
	return GlobalSignals.equipped_skills.has(skill_type)
