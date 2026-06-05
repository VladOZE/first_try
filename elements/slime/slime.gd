extends CharacterBody2D

const SPEED = 120.0
@export var max_health := 3

var gnom
var health := max_health
var is_attack := false
@onready var health_bar = $HealthBar
@onready var attack_timer = $AttackTimer


func _ready():
	health_bar.max_value = max_health
	health_bar.value = health
	
func _physics_process(delta: float) -> void:
	if gnom == null or is_attack == true:
		return
	
	var direction = (
		gnom.global_position - global_position
	).normalized()
		
	velocity = direction * SPEED * delta
	
	move_and_collide(velocity)

func attack():
	is_attack = true
	attack_timer.start()

func take_damage(damage):
	health -= damage
	health_bar.value = health
	
	if health <= 0:
		get_parent().enemy_killed()
		queue_free()


func _on_timer_timeout() -> void:
	is_attack = false
