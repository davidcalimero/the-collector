extends CharacterBody2D

const DOUBLE_JUMP_CARD_SKILL = "double_jump"
const DASH_CARD_SKILL = "dash"

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_VELOCITY = 900.0
const DASH_REVERT_SPEED = 50.0
const DASH_COOLDOWN = 0.5
const GLIDE_MAX_FALL_SPEED = 50

var double_jumped = false
var can_use_dash = true
var dash_timer : Timer

var current_animation

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		var is_glide_button_pressed = Input.is_action_pressed("glide")
		velocity += get_gravity() * delta
		if is_glide_button_pressed and velocity.y > 0:
			velocity.y = move_toward(velocity.y, GLIDE_MAX_FALL_SPEED, 30)
			animated_sprite.animation = "glide"
		else:
			animated_sprite.animation = "jump" if velocity.y <= 0.0 else "fall"
	elif is_on_floor() and double_jumped:
		double_jumped = false

	verify_jump()	
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

	if not can_use_dash and abs(velocity.x) > SPEED:
		animated_sprite.animation = "dash"
	elif is_on_floor():
		if direction:
			animated_sprite.animation = "move"
		else:
			animated_sprite.animation = "idle"

	if velocity.x < 0.0:
		animated_sprite.flip_h = true
	elif velocity.x > 0.0:
		animated_sprite.flip_h = false

	move_and_slide()

func verify_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
func verify_double_jump() -> void:
	if Input.is_action_just_pressed("jump") and not is_on_floor() and has_card_skill_equipped(DOUBLE_JUMP_CARD_SKILL) and not double_jumped:
		velocity.y = JUMP_VELOCITY
		double_jumped = true;
	
func verify_dash() -> void:
	if Input.is_action_just_pressed("dash") and has_card_skill_equipped(DASH_CARD_SKILL) and can_use_dash:
		var direction = -1 if $"AnimatedSprite2D".flip_h else 1
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
