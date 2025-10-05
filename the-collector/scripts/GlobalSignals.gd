extends Node

enum SkillType { INVALID, DASH, DOUBLE_JUMP, BLOCK, GLIDE, CHARGE_ATTACK, WALL_GRAB }

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

#Checkpoint
var last_checkpoint: Vector2

#Device
const DEADZONE := 0.3
var current_device := "keyboard"
signal device_changed(device: String)

func _ready():
	GlobalSignals.learn_skill.connect(_on_learn_skill)
	GlobalSignals.equip_skill.connect(_on_equip_skill)
	GlobalSignals.unequip_skill.connect(_on_unequip_skill)
	
	emit_signal("learn_skill", SkillType.DASH)
	emit_signal("learn_skill", SkillType.DOUBLE_JUMP)
	emit_signal("learn_skill", SkillType.BLOCK)
	emit_signal("learn_skill", SkillType.GLIDE)
	emit_signal("learn_skill", SkillType.CHARGE_ATTACK)
	emit_signal("learn_skill", SkillType.WALL_GRAB)

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

func refresh_skills() -> void:
	learned_skills.clear()
	equipped_skills.clear()
	
func set_checkpoint(pos: Vector2) -> void:
	last_checkpoint = pos

func _input(event):
	var new_device = current_device
	
	# --- keyboard / mouse ---
	if (event is InputEventKey and event.pressed) \
	or (event is InputEventMouseButton and event.pressed) \
	or (event is InputEventMouseMotion):
		new_device = "keyboard"
	# --- gamepad button ---
	elif event is InputEventJoypadButton and event.pressed:
		new_device = _device_from_name(Input.get_joy_name(event.device))
# --- analog stick / some D-pads (axes) ---
	elif event is InputEventJoypadMotion and abs(event.axis_value) > DEADZONE:
		new_device = _device_from_name(Input.get_joy_name(event.device))
	
	# emit only on change
	if new_device != current_device:
		current_device = new_device
		emit_signal("device_changed", current_device)
		
func _device_from_name(raw: String) -> String:
	var n := raw.to_lower().strip_edges().replace(" ", "")
	if n.find("xbox") != -1:
		return "xbox"
	if n.find("playstation") != -1 or n.find("dualshock") != -1 or n.find("dualsense") != -1:
		return "playstation"
	if n.find("nintendo") != -1 or n.find("switch") != -1 or n.find("procontroller") != -1:
		return "switch"
	return "xbox"
