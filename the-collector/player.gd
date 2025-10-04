extends CharacterBody2D

const DOUBLE_JUMP_CARD_SKILL = "double_jump"
const DASH_CARD_SKILL = "dash"
const WALL_GRAB_CARD_SKILL = "wall_grab"
const GLIDE_CARD_SKILL = "glide"

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const DASH_VELOCITY = 900.0
const DASH_REVERT_SPEED = 50.0
const DASH_COOLDOWN = 0.5
const GLIDE_MAX_FALL_SPEED = 50
const WALL_JUMP_X_VELOCITY = 300.0
const WALL_JUMP_Y_MULTIPLIER = 0.75
const WALL_JUMP_COOLDOWN = 0.25

var double_jumped = false
var can_use_dash = true
var dash_timer : Timer

var can_move = true
var wall_jump_timer : Timer

var current_animation

@onready var animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor() and not is_on_wall():
		var is_glide_button_pressed = Input.is_action_pressed("glide")
		velocity += get_gravity() * delta
		if is_glide_button_pressed and velocity.y > 0 and has_card_skill_equipped(GLIDE_CARD_SKILL):
			velocity.y = move_toward(velocity.y, GLIDE_MAX_FALL_SPEED, 30)
			animated_sprite.animation = "glide"
		else:
			animated_sprite.animation = "jump" if velocity.y <= 0.0 else "fall"
	elif is_on_floor() and double_jumped:
		double_jumped = false

	verify_jump()
	verify_wall_jump()
	verify_double_jump()
	verify_dash()

	var direction := Input.get_axis("move_left", "move_right")
	if can_move:
		# Get the input direction and handle the movement/deceleration.
		if direction and abs(velocity.x) < SPEED:
			velocity.x = direction * SPEED
		elif abs(velocity.x) > SPEED:
			velocity.x = move_toward(velocity.x, 0, DASH_REVERT_SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_on_wall_only():
		# Verify if asset needs to be flipped
		animated_sprite.animation = "wall_grab"
		animated_sprite.flip_h = get_last_slide_collision().get_normal().x < 0.0
	else:
		if  not can_use_dash and abs(velocity.x) > SPEED:
			animated_sprite.animation = "dash"
		elif is_on_floor():
			if direction:
				animated_sprite.animation = "move"
			else:
				animated_sprite.animation = "idle"
			
		# Verify if asset needs to be flipped
		if velocity.x < 0.0:
			animated_sprite.flip_h = true
		elif velocity.x > 0.0:
			animated_sprite.flip_h = false

	

	move_and_slide()

func verify_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
func verify_double_jump() -> void:
	if Input.is_action_just_pressed("jump") and animated_sprite.animation != "wall_grab" and not is_on_floor() and has_card_skill_equipped(DOUBLE_JUMP_CARD_SKILL) and not double_jumped:
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
	
func verify_wall_jump() -> void:
	if Input.is_action_just_pressed("jump") and animated_sprite.animation == "wall_grab" and has_card_skill_equipped(WALL_GRAB_CARD_SKILL):
		var direction = -1 if $"AnimatedSprite2D".flip_h else 1
		velocity.y = JUMP_VELOCITY * WALL_JUMP_Y_MULTIPLIER
		velocity.x = direction * WALL_JUMP_X_VELOCITY
		can_move = false
		
		if wall_jump_timer == null:
			wall_jump_timer = Timer.new()
			add_child(wall_jump_timer)
			wall_jump_timer.wait_time = WALL_JUMP_COOLDOWN
			wall_jump_timer.timeout.connect(_on_wall_jump_timer_timeout)
		wall_jump_timer.start()
	
func _on_wall_jump_timer_timeout() -> void:
	can_move = true
	
func _on_dash_timer_timeout() -> void:
	can_use_dash = true
	
func has_card_skill_equipped(skill_card_name: String) -> bool:
	return true
