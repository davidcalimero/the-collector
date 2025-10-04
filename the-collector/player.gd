extends CharacterBody2D

const DOUBLE_JUMP_CARD_SKILL = "double_jump"
const DASH_CARD_SKILL = "dash"

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_VELOCITY = 900.0
const DASH_REVERT_SPEED = 50.0
const DASH_COOLDOWN = 0.5

var double_jumped = false
var can_use_dash = true
var dash_timer : Timer

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
	verify_dash()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction and abs(velocity.x) < SPEED:
		velocity.x = direction * SPEED
	elif abs(velocity.x) > SPEED:
		velocity.x = move_toward(velocity.x, 0, DASH_REVERT_SPEED)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

func verify_double_jump() -> void:
	if Input.is_action_just_pressed("jump") and not is_on_floor() and has_card_skill_equipped(DOUBLE_JUMP_CARD_SKILL) and not double_jumped:
		velocity.y = JUMP_VELOCITY
		double_jumped = true;
	
func verify_dash() -> void:
	if Input.is_action_just_pressed("dash") and has_card_skill_equipped(DASH_CARD_SKILL) and can_use_dash:
		var direction := Input.get_axis("move_left", "move_right")
		velocity.x = direction * DASH_VELOCITY
		can_use_dash = false
		
		# Add cooldown
		if dash_timer == null:
			dash_timer = Timer.new()
			add_child(dash_timer)
		dash_timer.wait_time = DASH_COOLDOWN
		dash_timer.timeout.connect(_on_dash_timer_timeout)
		dash_timer.start()
		
func _on_dash_timer_timeout() -> void:
	can_use_dash = true
	
func has_card_skill_equipped(skill_card_name: String) -> bool:
	return true
