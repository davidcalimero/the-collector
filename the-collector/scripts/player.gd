class_name Player extends CharacterBody2D

const SPEED = 150.0
const JUMP_VELOCITY = -400.0
const DASH_VELOCITY = 900.0
const DASH_REVERT_SPEED = 50.0
const DASH_COOLDOWN = 0.5
const GLIDE_MAX_FALL_SPEED = 50
const WALL_JUMP_MAX_FALL_SPEED = 100
const WALL_JUMP_X_VELOCITY = 300.0
const WALL_JUMP_Y_MULTIPLIER = 0.75
const WALL_JUMP_COOLDOWN = 0.25
const ATTACK_COOLDOWN = 0.15

var double_jumped = false
var can_use_dash = true
var dash_timer : Timer

var can_move = true
var wall_jump_timer : Timer

var in_attack_cooldown = false
var attack_timer : Timer

var is_dead = false
var is_reviving = false

var current_animation

@onready var animated_sprite = $AnimatedSprite2D
@onready var attack_collision = $"AttackArea/Attack Collision"
@onready var attack_area = $"AttackArea"
@onready var block_collision = $"Block Collision"
@export var equipment : Node2D

func _ready():
	GlobalSignals.set_checkpoint(global_position)
	
	dash_timer = Timer.new()
	add_child(dash_timer)
	dash_timer.wait_time = DASH_COOLDOWN
	dash_timer.timeout.connect(_on_dash_timer_timeout)
	
	wall_jump_timer = Timer.new()
	add_child(wall_jump_timer)
	wall_jump_timer.wait_time = WALL_JUMP_COOLDOWN
	wall_jump_timer.timeout.connect(_on_wall_jump_timer_timeout)
	
	attack_timer = Timer.new()
	add_child(attack_timer)
	attack_timer.wait_time = ATTACK_COOLDOWN
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	attack_area.body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_dead:
		if animated_sprite.animation == "death":
			return
		animated_sprite.animation = "death"
		animated_sprite.play()
		velocity = Vector2(0,0)
		return
	if is_reviving:
		if animated_sprite.animation == "revive":
			return
		animated_sprite.animation = "revive"
		animated_sprite.play()
		animated_sprite.animation_finished.connect(_on_revive_timer_timeout)
		velocity = Vector2(0,0)
		return
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if Input.is_action_pressed("glide") and velocity.y > 0 and equipment.has_card_skill_equipped(GlobalSignals.SkillType.GLIDE) and animated_sprite.animation != "wall_grab":
			velocity.y = move_toward(velocity.y, GLIDE_MAX_FALL_SPEED, 30)
			animated_sprite.animation = "glide"
		elif is_on_wall() and velocity.y > 0  and equipment.has_card_skill_equipped(GlobalSignals.SkillType.WALL_GRAB) and block_collision.disabled:
			velocity.y = move_toward(velocity.y, WALL_JUMP_MAX_FALL_SPEED, 30)
		elif attack_collision.disabled:
			animated_sprite.animation = "jump" if velocity.y <= 0.0 else "fall"
	elif is_on_floor() and double_jumped:
		double_jumped = false

	verify_jump()
	verify_wall_jump()
	verify_double_jump()
	verify_dash()
	verify_block()
	verify_attack()

	var direction := Input.get_axis("move_left", "move_right")
	if can_move:		# Get the input direction and handle the movement/deceleration.
		if direction and abs(velocity.x) <= SPEED:
			velocity.x = direction * SPEED
		elif abs(velocity.x) > SPEED:
			velocity.x = move_toward(velocity.x, 0, DASH_REVERT_SPEED)
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if not block_collision.disabled or not attack_collision.disabled:
		if velocity.x < 0.0:
			animated_sprite.flip_h = true
		elif velocity.x > 0.0:
			animated_sprite.flip_h = false
	elif is_on_wall_only() and equipment.has_card_skill_equipped(GlobalSignals.SkillType.WALL_GRAB):
		# Verify if asset needs to be flipped
		animated_sprite.animation = "wall_grab"
		animated_sprite.flip_h = get_last_slide_collision().get_normal().x < 0.0
	else:
		if not can_use_dash and abs(velocity.x) > SPEED:
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
	if Input.is_action_just_pressed("jump") and is_on_floor() and block_collision.disabled:
		velocity.y = JUMP_VELOCITY
	
func verify_double_jump() -> void:
	if Input.is_action_just_pressed("jump") and animated_sprite.animation != "wall_grab" and not is_on_floor() and equipment.has_card_skill_equipped(GlobalSignals.SkillType.DOUBLE_JUMP) and not double_jumped and block_collision.disabled:
		velocity.y = JUMP_VELOCITY
		double_jumped = true;
	
func verify_dash() -> void:
	if Input.is_action_just_pressed("dash") and equipment.has_card_skill_equipped(GlobalSignals.SkillType.DASH) and can_use_dash:
		var direction = -1 if $"AnimatedSprite2D".flip_h else 1
		velocity.x = direction * DASH_VELOCITY
		can_use_dash = false
		dash_timer.start()
	
func verify_wall_jump() -> void:
	if Input.is_action_just_pressed("jump") and animated_sprite.animation == "wall_grab" and equipment.has_card_skill_equipped(GlobalSignals.SkillType.WALL_GRAB):
		var direction = -1 if $"AnimatedSprite2D".flip_h else 1
		velocity.y = JUMP_VELOCITY * WALL_JUMP_Y_MULTIPLIER
		velocity.x = direction * WALL_JUMP_X_VELOCITY
		can_move = false
		double_jumped = false
		wall_jump_timer.start()
	
func verify_attack() -> void:
	if Input.is_action_just_pressed("attack") and not in_attack_cooldown:
		in_attack_cooldown = true
		attack_collision.disabled = false
		animated_sprite.animation = "attack"
		attack_timer.start()

func verify_block() -> void:
	if Input.is_action_pressed("block") and equipment.has_card_skill_equipped(GlobalSignals.SkillType.BLOCK):
		block_collision.disabled = false
		animated_sprite.animation = "block"
		can_move = false
	else:
		block_collision.disabled = true
		can_move = true
	
func _on_wall_jump_timer_timeout() -> void:
	can_move = true
	
func _on_dash_timer_timeout() -> void:
	can_use_dash = true

func _on_attack_timer_timeout() -> void:
	attack_timer.stop()
	in_attack_cooldown = false
	attack_collision.disabled = true

func _on_revive_timer_timeout() -> void:
	is_reviving = false

func die() -> void:
	is_dead = true
	
func revive() -> void:
	is_dead = false 
	is_reviving = true
	
func _on_body_entered(target: Node):
	if target.is_in_group("Enemy"):
		target.take_damage(1)
	
