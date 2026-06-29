extends CharacterBody2D

const SPEED = 120.0
const STOP_DISTANCE := 32.0

@export var max_health := 3
@export var attack_cooldown := 1.0

var health := max_health
var is_attack := false
var knockback_velocity := Vector2.ZERO

@onready var health_bar = $HealthBar
@onready var attack_timer = $AttackTimer
@onready var attack_area = $Area2D
@onready var sprite = $AnimatedSprite2D

func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	attack_timer.wait_time = attack_cooldown

func _get_player() -> Node2D:
	var game = get_parent()
	if game != null:
		return game.get_node_or_null("Gnom")
	return null

func _physics_process(delta):
	var player = _get_player()
	if player == null:
		return

	if knockback_velocity.length() > 1.0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, 8.0 * delta)
		move_and_slide()
		return

	if is_attack:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var offset = player.global_position - global_position
	var distance = offset.length()

	if distance <= STOP_DISTANCE:
		velocity = Vector2.ZERO
	else:
		velocity = offset / distance * SPEED

	move_and_slide()
	update_animation(offset if distance > STOP_DISTANCE else Vector2.ZERO)

func update_animation(direction: Vector2):
	if (sprite.animation.begins_with("hurt_down") or sprite.animation.begins_with("attack_down")) and sprite.is_playing():
		return

	if direction == Vector2.ZERO:
		sprite.play("stay_down")
		return
	sprite.play("walk_down")

func try_attack() -> void:
	if is_attack:
		return
	is_attack = true
	sprite.play("attack_down")
	attack_timer.start()

func _get_player_in_range() -> Node2D:
	for body in attack_area.get_overlapping_bodies():
		if body != self and body.has_method("take_damage"):
			return body
	return null

func take_damage(damage, attacker: Node2D = null):
	health -= damage
	health_bar.value = health
	sprite.play("hurt_down")

	var source = attacker if is_instance_valid(attacker) else _get_player()
	if source != null:
		var knockback_offset = global_position - source.global_position
		if knockback_offset.length_squared() > 0.001:
			knockback_velocity = knockback_offset.normalized() * 120.0

	if health <= 0:
		queue_free()
		get_parent().enemy_killed()

func _on_timer_timeout() -> void:
	is_attack = false
	var target = _get_player_in_range()
	if target == null:
		return
	target.take_damage(1, self)
	try_attack()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body != self and body.has_method("take_damage"):
		try_attack()

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation.begins_with("hurt_down") and not is_attack:
		var player = _get_player()
		if player == null:
			sprite.play("stay_down")
			return
		var offset = player.global_position - global_position
		if offset.length() > STOP_DISTANCE:
			sprite.play("walk_down")
		else:
			sprite.play("stay_down")
