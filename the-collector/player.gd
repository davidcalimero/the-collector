extends CharacterBody2D

const DOUBLE_JUMP_CARD_SKILL = "double_jump"

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var double_jumped = false

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	elif is_on_floor() and double_jumped:
		double_jumped = false

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	verify_double_jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func verify_double_jump() -> void:
	if Input.is_action_just_pressed("jump") and not is_on_floor() and has_card_skill_equipped(DOUBLE_JUMP_CARD_SKILL) and not double_jumped:
		velocity.y = JUMP_VELOCITY
		double_jumped = true;
	
func dash() -> void:
	print("dash")
	
func has_card_skill_equipped(skill_card_name: String) -> bool:
	return true
