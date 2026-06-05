extends CharacterBody2D


@onready var sprite = $AnimatedSprite2D

var enemies = []
const SPEED = 200.0
const RUN_SPEED = 300.0


var is_attacking = false
var last_direction = Vector2.DOWN

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	var direction = Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
        "ui_down"
	)
	
	var is_run = Input.is_key_pressed(KEY_SHIFT)
	
	velocity = direction * (RUN_SPEED if is_run else SPEED) * delta

	var isAttack = Input.is_key_pressed(KEY_SPACE)
	if isAttack:
		attack()
		
	move_and_collide(velocity)

	update_animation(direction, is_run)

func attack():
	if is_attacking:
		return
	is_attacking = true
	
	sprite.stop()
	sprite.play("attack")
	

	
func update_animation(direction: Vector2, is_run: bool):
	if sprite.animation.begins_with("attack") and sprite.is_playing():
		return
		
	if direction == Vector2.ZERO:
		sprite.play("stay")
		return

	var normalized_dir = direction.normalized()
	
	# Определяем основные октанты (8 направлений)
	var angle = rad_to_deg(atan2(normalized_dir.y, normalized_dir.x))
	if angle < 0:
		angle += 360
	
	# Маппинг углов на направления
	var dir_map = {
		0: "right", 45: "down_right", 90: "down", 135: "down_left",
		180: "left", 225: "up_left", 270: "up", 315: "up_right"
	}
	
	# Находим ближайшее направление (шаг 45 градусов)
	var rounded_angle = int(round(angle / 45.0) * 45)
	if rounded_angle >= 360:
		rounded_angle = 0
	
	var direction_name = dir_map[rounded_angle]
	
	# Обработка переворота для левых направлений
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
	
	# Проигрываем анимацию
	var anim_name = ("run" if is_run else "walk") + "_" + anim_direction
	sprite.flip_h = flip_h
	sprite.play(anim_name)


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation.begins_with("attack"):
		is_attacking = false
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.take_damage(1)
		update_animation(Vector2.ZERO, false)

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		enemies.append(body)

func _on_area_2d_body_exited(body: Node2D) -> void:
	enemies.erase(body)
