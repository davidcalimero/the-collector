extends CharacterBody2D

const SPEED = 25.0
const ATTACK_COOLDOWN = 0.75
const ATTACK_SPEED = 35.0
const ATTACK_SPEED_SLOW = 3
const TIME_UNTIL_DETECTION_AGAIN = 5.0
const HITS_UNTIL_DEATH = 3
const IDLE_DAMAGE = 2
const DAMAGE = 5
const ATTACK_INTERVAL = 0.75

@export var rallyPointA : Node2D
@export var rallyPointB : Node2D
@export var playerNode : Node2D

@onready var animatedSprite = $"AnimatedSprite2D"
@onready var detection = $"Detection"
@onready var detectionCollision = $"Detection/Detection Collision"

@onready var attackDetectionNode = $"Attack Detection"
@onready var attackDetection = $"Attack Detection/Attack Detection"
@onready var attackNode = $"Attack"
@onready var attackCollision = $"Attack/Attack Collision"

var numberOfHits = HITS_UNTIL_DEATH

var goingFromAToB = true
var inPursuit = false
var attackCooldownTimer : Timer
var inAttackCooldown = false
var detectionTimer : Timer
var attackDirectedToLeft = false
var playerInterval : Timer

var staticRallyPointAXPosition : float
var staticRallyPointBXPosition : float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	staticRallyPointAXPosition = rallyPointA.global_position.x
	staticRallyPointBXPosition = rallyPointB.global_position.x
	
	if not playerNode:
		var ps := get_tree().get_nodes_in_group("Player")
		if ps.size() > 0:
			playerNode = ps[0] as Node2D
	
	position = rallyPointA.position
	
	attackCooldownTimer = Timer.new()
	add_child(attackCooldownTimer)
	attackCooldownTimer.wait_time = ATTACK_COOLDOWN
	attackCooldownTimer.timeout.connect(_on_attack_cooldown_ended)
	
	detectionTimer = Timer.new()
	add_child(detectionTimer)
	detectionTimer.wait_time = TIME_UNTIL_DETECTION_AGAIN
	detectionTimer.timeout.connect(_on_give_up_pursuit)
	
	playerInterval = Timer.new()
	add_child(playerInterval)
	playerInterval.wait_time = ATTACK_INTERVAL
	playerInterval.timeout.connect(_on_player_hit)
	
	detection.body_entered.connect(_on_body_detected)
	attackDetectionNode.body_entered.connect(_on_ready_to_attack)
	
	attackNode.body_entered.connect(_on_player_enter)
	attackNode.body_exited.connect(_on_player_exit)
	
func _physics_process(delta: float) -> void:
	velocity.y += get_gravity().y * delta
	
	var xDirection : int
	var xDestination : float
	if animatedSprite.animation == "damaged":
		velocity.x = move_toward(velocity.x, 0, SPEED)
	elif animatedSprite.animation == "attack" and not inAttackCooldown:
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
	
	animatedSprite.flip_h = xDirection > 0 if (animatedSprite.animation == "attack" or inAttackCooldown) else xDirection < 0
		
	move_and_slide()
		
func _on_attack_finished() -> void:
	inAttackCooldown = true
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
	if body == playerNode and not inAttackCooldown:
		attackDirectedToLeft = playerNode.position.x < position.x
		attackDetection.disabled = true
		set_animation("attack")
		animatedSprite.animation_finished.connect(_on_attack_finished)
		detectionTimer.stop()
	
func _on_body_detected(body: Node2D) -> void:
	if body == playerNode:
		inPursuit = true
		detectionCollision.disabled = true
		detectionTimer.start()

func _on_player_enter(target: Node2D) -> void:
	if target.is_in_group("Player"):
		_on_player_hit()
		playerInterval.start()
		
func _on_player_hit() -> void:
	if animatedSprite.animation == "attack" and not inAttackCooldown:
		GlobalSignals.emit_signal("update_health", -DAMAGE)
	else:
		GlobalSignals.emit_signal("update_health", -IDLE_DAMAGE) 

func _on_player_exit(target: Node2D) -> void:
	if target.is_in_group("Player"):
		playerInterval.stop()

func take_damage(damage : float) -> void:
	if animatedSprite.animation == "die":
		return
		
	if animatedSprite.animation != "attack":
		set_animation("damaged")
	
	numberOfHits -= damage
	
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
