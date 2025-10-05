extends CharacterBody2D

@export var life: float = 200

# -------- CONFIG GERAL --------
@export var gravity: float = 2400.0
@export var move_speed: float = 80.0   # só usado p/ desacelerar rápido ao parar

# Timings
@export var windup_time: float = 0.6
@export var recovery_time: float = 0.6
@export var cycle_pause: float = 0.5

# -------- JUMP SLAM --------
@export var jump_height: float = 200.0
@export var slam_damage_time: float = 0.25
@export var slam_damage: float = 15
@export var jump_min_dx: float = 0.0
@export var jump_max_dx: float = 400.0
@export var jump_prefer_toward_player := true
@export var arena_left: float = -400
@export var arena_right: float = 400

# -------- SPIT --------
@export var projectile_scene: PackedScene
@export var spit_count: int = 5
@export var spit_spread_deg: float = 40.0
@export var spit_speed: float = 420.0

# -------- SUMMON --------
@export var minion_scene: PackedScene
@export var minion_count: int = 3
@export var summon_radius: float = 64.0

# -------- CICLO DE ATAQUES --------
enum Attack { JUMP_SLAM, SPIT, SUMMON }
@export var cycle_order: Array[Attack] = [Attack.JUMP_SLAM, Attack.SPIT, Attack.SUMMON]

# -------- ESTADO --------
var _cycle_index: int = 0
var _active: bool = false
var _activated_once: bool = false
var _can_move: bool = false
var _dead : bool = false

# (opcional) referência ao player para saltar “na direção”
@export var player_path: NodePath
var _player: Node2D = null

# -------- NÓS --------
@onready var _anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var _shoot: Marker2D = $ShootOrigin
@onready var _hitbox: Area2D = $HitBox
@onready var _ground_ray: RayCast2D = $GroundRay
@onready var _zone: Area2D = $ActivationZone

signal attack_started(kind: Attack)
signal attack_finished(kind: Attack)

func _ready() -> void:
	if player_path != NodePath():
		_player = get_node_or_null(player_path)
	else:
		var ps := get_tree().get_nodes_in_group("Player")
		if ps.size() > 0:
			_player = ps[0] as Node2D

	_zone.body_entered.connect(_on_zone_body_entered)
	_hitbox.body_entered.connect(_on_slam_body_entered)
	_hitbox.monitoring = false
	_anim.play("idle")

func _on_zone_body_entered(body: Node) -> void:
	if _activated_once: return
	if body.is_in_group("Player"):
		_activate_boss()

func _activate_boss() -> void:
	_active = true
	_activated_once = true
	_start_loop()

# -------- FÍSICA --------
func _physics_process(delta: float) -> void:
	# gravidade
	velocity.y += gravity * delta

	# mobilidade controlada por _can_move
	if not _can_move:
		# “trava” rápido quando não queremos movimento horizontal
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 8.0 * delta)
	# (se _can_move for true, deixamos velocity.x como está — p.ex. no salto)

	move_and_slide()

# -------- LOOP PRINCIPAL --------
func _start_loop() -> void:
	_run_cycle()

func _run_cycle() -> void:
	if _dead or not _active: return
	var kind: Attack = cycle_order[_cycle_index % cycle_order.size()]
	_cycle_index += 1
	match kind:
		Attack.JUMP_SLAM:
			await _do_jump_slam()
		Attack.SPIT:
			await _do_spit_shotgun()
		Attack.SUMMON:
			await _do_summon_minions()
	await get_tree().create_timer(cycle_pause).timeout
	_run_cycle()

# -------- ATAQUES --------
func _do_jump_slam() -> void:
	emit_signal("attack_started", Attack.JUMP_SLAM)
	_set_mobility(false)

	_anim.play("windup_jump")
	await get_tree().create_timer(windup_time).timeout

	# alvo horizontal p/ não aterrar no mesmo sítio
	var target_x: float = _pick_jump_target_x()

	# vertical inicial
	var v0y: float = -sqrt(2.0 * gravity * jump_height)
	# tempo de voo aproximado (mesma altura): T = 2|v0| / g
	var T: float = 2.0 * abs(v0y) / gravity
	var vx: float = (target_x - global_position.x) / max(T, 0.001)

	# inicia salto
	velocity.y = v0y
	velocity.x = vx
	_set_mobility(true)
	_anim.play("jump")

	# espera descer e tocar no chão
	await _wait_until_descending()
	_hitbox.monitoring = true
	_anim.play("falling")
	await _wait_until_grounded()

	# impacto
	_set_mobility(false)
	velocity.x = 0.0
	_anim.play("slam")
	await get_tree().create_timer(slam_damage_time).timeout
	_hitbox.monitoring = false

	# recuperação
	_anim.play("recover")
	await get_tree().create_timer(recovery_time).timeout
	_anim.play("idle")
	emit_signal("attack_finished", Attack.JUMP_SLAM)

func _do_spit_shotgun() -> void:
	emit_signal("attack_started", Attack.SPIT)
	_set_mobility(false)

	_anim.play("windup_spit")
	await get_tree().create_timer(windup_time).timeout
	
	# Base direction toward the player right now
	var base_dir := Vector2.RIGHT
	if is_instance_valid(_player):
		var to_player := _player.global_position - _shoot.global_position
		if to_player.length() > 0.001:
			base_dir = to_player.normalized()
			
	var total: int = max(1, spit_count)
	var step: float = 0.0
	if total > 1:
		step = deg_to_rad(spit_spread_deg) / float(total - 1)

	for i: int in range(total):
		var t: float = -0.5 * float(total - 1) + float(i)
		var dir := base_dir.rotated(t * step)
		var ang := dir.angle()  
		_spawn_projectile(ang)
		_anim.play("spit")
		await get_tree().create_timer(0.05).timeout

	_anim.play("recover")
	await get_tree().create_timer(recovery_time).timeout
	_anim.play("idle")
	emit_signal("attack_finished", Attack.SPIT)

func _do_summon_minions() -> void:
	emit_signal("attack_started", Attack.SUMMON)
	_set_mobility(false)

	_anim.play("summon")
	await get_tree().create_timer(windup_time).timeout
	
	# Find the ground Y under the boss right now
	var ground_y := global_position.y
	if _ground_ray and _ground_ray.is_colliding():
		ground_y = _ground_ray.get_collision_point().y

	for i: int in range(minion_count):
		var x := global_position.x + randf_range(-summon_radius, summon_radius)
		if minion_scene:
			var m := minion_scene.instantiate()
			m.add_collision_exception_with(self)
			get_parent().add_child(m)
			m.global_position = Vector2(x, ground_y - 8)
		await get_tree().create_timer(0.08).timeout

	_anim.play("recover")
	await get_tree().create_timer(recovery_time).timeout
	_anim.play("idle")
	emit_signal("attack_finished", Attack.SUMMON)
	
	
func _on_slam_body_entered(body: Node) -> void:
	if body.is_in_group("Player"):
		GlobalSignals.emit_signal("update_health", -slam_damage)

# -------- HELPERS --------
func _spawn_projectile(angle: float) -> void:
	if projectile_scene == null: return
	var node := projectile_scene.instantiate()
	get_parent().add_child(node)
	node.global_position = _shoot.global_position
	node.add_collision_exception_with(self)
	var dir := Vector2.RIGHT.rotated(angle)
	# Se o teu projectile tem class_name Projectile e launch(dir, speed):
	if node.has_method("launch"):
		node.call("launch", dir, spit_speed)

func _wait_until_descending() -> void:
	while velocity.y < 0.0:
		await get_tree().physics_frame

func _wait_until_grounded() -> void:
	while not (is_on_floor() or (_ground_ray and _ground_ray.is_colliding())):
		await get_tree().physics_frame

func _set_mobility(on: bool) -> void:
	_can_move = on

func _pick_jump_target_x() -> float:
	var dir := 1.0
	if jump_prefer_toward_player and is_instance_valid(_player):
		dir = sign(_player.global_position.x - global_position.x)
		if dir == 0.0:
			dir = 1.0

	var dx := randf_range(jump_min_dx, jump_max_dx) * dir
	var raw_target := global_position.x + dx
	var clamped : float = clamp(raw_target, arena_left, arena_right)

	# se ficou muito perto, tenta ao lado oposto
	if abs(clamped - global_position.x) < jump_min_dx * 0.6:
		dir *= -1.0
		dx = randf_range(jump_min_dx, jump_max_dx) * dir
		clamped = clamp(global_position.x + dx, arena_left, arena_right)

	return clamped

# -------- CONTROLO EXTERNO --------
func set_active(on: bool) -> void:
	_active = on
	
func take_damage(amount : float):
	if _dead:
		return
	life -= amount
	if life <= 0:
		_dead = true
		_anim.play("die")
		await get_tree().create_timer(0.2).timeout
		queue_free()
	else:
		_anim.play("damage")
		
