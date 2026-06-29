extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D
@onready var health_bar = $HealthBar
@onready var attack_area = $Area2D
@onready var attack_area_shape = $Area2D/CollisionShape2D

@export var base_speed := 200.0
@export var base_run_speed := 300.0
@export var max_health := 10
@export var attack_radius := 55.0

var health
var is_attacking = false
var last_direction = Vector2.DOWN

func _ready():
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	_update_attack_shape()

func _physics_process(_delta: float) -> void:
	var direction = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	if direction != Vector2.ZERO:
		last_direction = direction.normalized()

	var is_run = Input.is_key_pressed(KEY_SHIFT)

	if not is_attacking:
		var speed = base_run_speed if is_run else base_speed
		velocity = direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

	if Input.is_action_just_pressed("attack"):
		attack()

	update_animation(direction if not is_attacking else Vector2.ZERO, is_run)

func die():
	get_parent().game_over()
	queue_free()

func attack():
	if is_attacking:
		return
	is_attacking = true
	sprite.stop()
	sprite.play("attack")

func take_damage(damage, _attacker: Node2D = null):
	health -= damage
	health_bar.value = health
	if health <= 0:
		die()

func apply_upgrade_stats(speed_bonus: float, health_bonus: int, range_bonus: float):
	base_speed += speed_bonus
	base_run_speed += speed_bonus * 1.5
	max_health += health_bonus
	health = max_health
	health_bar.max_value = max_health
	health_bar.value = health
	attack_radius += range_bonus
	_update_attack_shape()

func _update_attack_shape() -> void:
	var shape = attack_area_shape.shape as CircleShape2D
	if shape == null:
		return
	var world_scale = maxf(absf(scale.x), absf(scale.y))
	shape.radius = attack_radius / world_scale if world_scale > 0.0 else attack_radius

func _deal_attack_damage() -> void:
	for body in attack_area.get_overlapping_bodies():
		if body != self and is_instance_valid(body) and body.has_method("take_damage"):
			body.take_damage(1, self)

func update_animation(direction: Vector2, is_run: bool):
	if sprite.animation.begins_with("attack") and sprite.is_playing():
		return

	if direction == Vector2.ZERO:
		sprite.play("stay")
		return

	var normalized_dir = direction.normalized()

	var angle = rad_to_deg(atan2(normalized_dir.y, normalized_dir.x))
	if angle < 0:
		angle += 360

	var dir_map = {
		0: "right", 45: "down_right", 90: "down", 135: "down_left",
		180: "left", 225: "up_left", 270: "up", 315: "up_right"
	}

	var rounded_angle = int(round(angle / 45.0) * 45)
	if rounded_angle >= 360:
		rounded_angle = 0

	var direction_name = dir_map[rounded_angle]

	var flip_h = direction_name in ["left", "up_left", "down_left"]
	var anim_direction = direction_name
	if flip_h:
		match direction_name:
			"left":
				anim_direction = "right"
			"up_left":
				anim_direction = "up_right"
			"down_left":
				anim_direction = "down_right"

	var anim_name = ("run" if is_run else "walk") + "_" + anim_direction
	sprite.flip_h = flip_h
	sprite.play(anim_name)

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation.begins_with("attack"):
		is_attacking = false
		_deal_attack_damage()
		update_animation(Vector2.ZERO, false)
