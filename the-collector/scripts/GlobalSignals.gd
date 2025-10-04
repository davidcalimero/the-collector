extends Node

enum SkillType { DASH, DOUBLE_JUMP, BLOCK, GLIDE, CHARGE_ATTACK, WALL_GRAB }

# Health
signal update_health(increment : float)
signal reset_health

# Skills
signal equip_skill(skill : SkillType)
signal unequip_skill(skill : SkillType)
signal learn_skill(skill : SkillType)



#Skills Mananger
var learned_skills: Array = []
var equipped_skills: Array = []

func _ready():
	GlobalSignals.learn_skill.connect(_on_learn_skill)
	GlobalSignals.equip_skill.connect(_on_equip_skill)
	GlobalSignals.unequip_skill.connect(_on_unequip_skill)

# === Signal handlers ===
func _on_learn_skill(skill):
	if skill not in learned_skills:
		learned_skills.append(skill)

func _on_equip_skill(skill):
	if skill not in equipped_skills:
		equipped_skills.append(skill)

func _on_unequip_skill(skill):
	if skill in equipped_skills:
		equipped_skills.erase(skill)

# === Utility functions ===
func is_skill_learned(skill) -> bool:
	return skill in learned_skills

func is_skill_equipped(skill) -> bool:
	return skill in equipped_skills

func get_equipped_skills() -> Array:
	return equipped_skills.duplicate()

func get_learned_skills() -> Array:
	return learned_skills.duplicate()
