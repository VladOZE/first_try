extends Node2D

@export var enemy_scene: PackedScene

@onready var label = $Label
@onready var gnom = $Gnom

var kills := 0

func enemy_killed():
	kills += 1
	label.set_text(str(kills))
	
func _on_timer_timeout():

	var enemy = enemy_scene.instantiate()
	
	enemy.global_position = Vector2(
		randf_range(0, 1536),
		randf_range(0, 1024)
	)

	enemy.gnom = gnom

	add_child(enemy)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.set_text(str(kills))
