extends CharacterBody2D

const SPEED = 25.0
const ATTACK_COOLDOWN = 0.75
const ATTACK_SPEED = 35.0
const ATTACK_SPEED_SLOW = 3
const TIME_UNTIL_DETECTION_AGAIN = 5.0

const HITS_UNTIL_DEATH = 3

@export var rallyPointA : Node2D
@export var rallyPointB : Node2D
@export var playerNode : Node2D

@onready var animatedSprite = $"AnimatedSprite2D"
@onready var detection = $"Detection"
@onready var detectionCollision = $"Detection/Detection Collision"

@onready var attack = $"Attack Node"
@onready var attackDetection = $"Attack Node/Attack Detection"
@onready var attackCollision = $"Attack Collision"

var numberOfHits = HITS_UNTIL_DEATH

var goingFromAToB = true
var inPursuit = false
var attackCooldownTimer : Timer
var inAttackCooldown = false
var detectionTimer : Timer
var attackDirectedToLeft = false

var staticRallyPointAXPosition : float
var staticRallyPointBXPosition : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	staticRallyPointAXPosition = rallyPointA.global_position.x
	staticRallyPointBXPosition = rallyPointB.global_position.x
	
	position = rallyPointA.position
	
	attackCooldownTimer = Timer.new()
	add_child(attackCooldownTimer)
	attackCooldownTimer.wait_time = ATTACK_COOLDOWN
	attackCooldownTimer.timeout.connect(_on_attack_cooldown_ended)
	
	detectionTimer = Timer.new()
	add_child(detectionTimer)
	detectionTimer.wait_time = TIME_UNTIL_DETECTION_AGAIN
	detectionTimer.timeout.connect(_on_give_up_pursuit)
	
	detection.body_entered.connect(_on_body_detected)
	attack.body_entered.connect(_on_ready_to_attack)

func _physics_process(delta: float) -> void:
	velocity.y += get_gravity().y * delta
	
	var xDirection : int
	var xDestination : float
	if animatedSprite.animation == "damaged":
		pass
	elif not attackCollision.disabled:
		xDirection = -1 if attackDirectedToLeft else 1
		velocity.x = xDirection * ATTACK_SPEED
	elif inAttackCooldown:
		xDirection = -1 if attackDirectedToLeft else 1
		velocity.x = move_toward(velocity.x, 0, ATTACK_SPEED_SLOW)
	elif inPursuit:
		xDestination = playerNode.position.x
		xDirection = 1 if xDestination > position.x else -1
		velocity.x = xDirection * SPEED
	else:
		if detectionCollision.disabled:
			detectionCollision.disabled = false
		xDestination = staticRallyPointBXPosition if goingFromAToB else staticRallyPointAXPosition
		xDirection = 1 if xDestination > position.x else -1
		velocity.x = xDirection * SPEED
		if abs(xDestination - position.x) <= 1.0:
			goingFromAToB = not goingFromAToB
	
	animatedSprite.flip_h = xDirection > 0 if (not attackCollision.disabled or inAttackCooldown) else xDirection < 0
		
	move_and_slide()
		
func _on_attack_finished() -> void:
	inAttackCooldown = true
	attackCollision.disabled = true
	attackCooldownTimer.start()
	
func _on_attack_cooldown_ended() -> void:
	inAttackCooldown = false
	inPursuit = false
	attackCooldownTimer.stop()
	set_animation("movement")
	
func _on_give_up_pursuit() -> void:
	inPursuit = false
	detectionTimer.stop()
	
func _on_ready_to_attack(body: Node2D) -> void:
	if body == playerNode and not inAttackCooldown and attackCollision.disabled:
		attackDirectedToLeft = playerNode.position.x < position.x
		attackDetection.disabled = true
		attackCollision.disabled = false
		set_animation("attack")
		animatedSprite.animation_finished.connect(_on_attack_finished)
		detectionTimer.stop()
	
func _on_body_detected(body: Node2D) -> void:
	if body == playerNode:
		inPursuit = true
		detectionCollision.disabled = true
		detectionTimer.start()

func take_damage() -> void:
	set_animation("damaged")
	numberOfHits -= 1
	if numberOfHits <= 0:
		die()
	else:
		animatedSprite.animation_finished.connect(_on_damaged_finished)

func _on_damaged_finished() -> void:
	set_animation("movement")

func die() -> void:
	attackCollision.disabled = true
	detectionCollision.disabled = true
	attackDetection.disabled = true
	set_animation("die")
	animatedSprite.animation_finished.connect(_on_die_animation_finished)

func _on_die_animation_finished() -> void:
	queue_free()
	
func set_animation(animationName: String) -> void:
	animatedSprite.animation = animationName
	animatedSprite.play()
