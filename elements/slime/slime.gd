extends CharacterBody2D

const SPEED = 120.0
@export var max_health := 3

var gnom
var health := max_health
var is_attack := false
var knockback_velocity := Vector2.ZERO

@onready var health_bar = $HealthBar
@onready var attack_timer = $AttackTimer
@onready var sprite = $AnimatedSprite2D


func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	
func _physics_process(delta):

	if knockback_velocity.length() > 1:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8 * delta)
		move_and_collide(knockback_velocity)
		return

	if gnom == null:
		return

	var direction = (
		gnom.global_position - global_position
	).normalized()

	velocity = direction * SPEED * delta

	move_and_collide(velocity)
	update_animation(direction)

func update_animation(direction: Vector2):
	if (sprite.animation.begins_with("hurt_down") or sprite.animation.begins_with("attack_down")) and sprite.is_playing():
		return
	
	if direction == Vector2.ZERO:
		sprite.play("stay_down")
		return
	sprite.play("walk_down")

func attack():
	if is_attack:
		return
	is_attack = true
	sprite.play("attack_down")
	attack_timer.start()

func take_damage(damage):
	health -= damage
	health_bar.value = health
	sprite.play("hurt_down")
	
	var knockback_direction = (
		global_position - gnom.global_position
	).normalized()

	knockback_velocity = knockback_direction * 10
	
	if health <= 0:
		queue_free()
		get_parent().enemy_killed()

func _on_timer_timeout() -> void:
	is_attack = false
	if gnom == null:
		return
	if !gnom.has_method("take_damage"):
		return
	if global_position.distance_to(gnom.global_position) < 65:
		gnom.take_damage(1)

func _on_area_2d_body_entered(body: Node2D) -> void:
	attack()
