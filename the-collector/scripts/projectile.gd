extends CharacterBody2D
class_name Projectile

@export var speed: float = 400.0
@export var accel: float = 0.0
@export var lifetime: float = 3.0
@export var damage: float = 5.0

func _ready() -> void:
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if accel != 0.0:
		velocity += velocity.normalized() * accel * delta

	var collision := move_and_collide(velocity * delta)  # ← single move
	if collision:
		_on_hit(collision)

func _on_hit(collision: KinematicCollision2D) -> void:
	var target := collision.get_collider()
	if not target:
		queue_free()
		return
	if target.is_in_group("Player"):
		GlobalSignals.emit_signal("update_health", -damage)
	queue_free()

func launch(dir: Vector2, spd: float = -1.0) -> void:
	var used_speed := spd if spd > 0.0 else speed
	velocity = dir.normalized() * used_speed
