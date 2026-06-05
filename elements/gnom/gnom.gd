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

	if abs(direction.x) > abs(direction.y):
		if direction.x > 0:
			sprite.flip_h = false
			if is_run:
				sprite.play("run_right")
			else:
				sprite.play("walk_right")
		elif direction.x < 0:
			sprite.flip_h = true
			if is_run:
				sprite.play("run_right")
			else:
				sprite.play("walk_right")
	else:
		if direction.y > 0:
			if is_run:
				sprite.play("run_down")
			else:
				sprite.play("walk_right")
		else:
			if is_run:
				sprite.play("run_up")
			else:
				sprite.play("walk_up")
	move_and_collide(velocity)


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
