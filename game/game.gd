extends Node2D

@export var enemy_scene: PackedScene

const SPEED_UPGRADE_COSTS := [3, 5, 7, 10]
const HEALTH_UPGRADE_COSTS := [4, 6, 8, 11]
const RANGE_UPGRADE_COSTS := [4, 6, 9, 12]
const SPEED_UPGRADE_BONUS := 20.0
const HEALTH_UPGRADE_BONUS := 2
const RANGE_UPGRADE_BONUS := 2.0
const SAVE_PATH := "user://progress.cfg"

@onready var label = $Label
@onready var gnom = $Gnom

var kills := 0
static var skip_start_screen := false
static var best_score := 0
static var saved_points := 0
static var speed_level := 0
static var health_level := 0
static var range_level := 0
static var progress_loaded := false

@onready var death_screen = $DeathScreen
@onready var final_score_label = $DeathScreen/CenterContainer/Panel/VBoxContainer/score
@onready var best_score_label = $DeathScreen/CenterContainer/Panel/VBoxContainer/BestScore
@onready var currency_label = $DeathScreen/CenterContainer/Panel/VBoxContainer/Currency
@onready var speed_button = $DeathScreen/CenterContainer/Panel/VBoxContainer/SpeedUpgradeButton
@onready var health_button = $DeathScreen/CenterContainer/Panel/VBoxContainer/HealthUpgradeButton
@onready var range_button = $DeathScreen/CenterContainer/Panel/VBoxContainer/RangeUpgradeButton
@onready var restart_button = $DeathScreen/CenterContainer/Panel/VBoxContainer/RestartButton
@onready var start_screen = $StartScreen
@onready var start_button = $StartScreen/CenterContainer/Panel/VBoxContainer/StartButton
@onready var spawn_timer = $Timer

func get_upgrade_cost(costs: Array, level: int) -> int:
	if level >= costs.size():
		return -1
	return costs[level]

func load_progress():
	if progress_loaded:
		return

	var config = ConfigFile.new()
	var error = config.load(SAVE_PATH)
	if error != OK:
		progress_loaded = true
		return

	best_score = int(config.get_value("progress", "best_score", 0))
	saved_points = int(config.get_value("progress", "saved_points", 0))
	speed_level = int(config.get_value("progress", "speed_level", 0))
	health_level = int(config.get_value("progress", "health_level", 0))
	range_level = int(config.get_value("progress", "range_level", 0))
	progress_loaded = true

func save_progress():
	var config = ConfigFile.new()
	config.set_value("progress", "best_score", best_score)
	config.set_value("progress", "saved_points", saved_points)
	config.set_value("progress", "speed_level", speed_level)
	config.set_value("progress", "health_level", health_level)
	config.set_value("progress", "range_level", range_level)
	config.save(SAVE_PATH)

func update_upgrade_buttons():
	var speed_cost = get_upgrade_cost(SPEED_UPGRADE_COSTS, speed_level)
	var health_cost = get_upgrade_cost(HEALTH_UPGRADE_COSTS, health_level)
	var range_cost = get_upgrade_cost(RANGE_UPGRADE_COSTS, range_level)

	currency_label.text = "Валюта: " + str(saved_points)
	best_score_label.text = "Рекорд: " + str(best_score)
	speed_button.text = _build_upgrade_text("Скорость", speed_level, speed_cost)
	health_button.text = _build_upgrade_text("Жизнь", health_level, health_cost)
	range_button.text = _build_upgrade_text("Дальность атаки", range_level, range_cost)

	speed_button.disabled = speed_cost == -1 or saved_points < speed_cost
	health_button.disabled = health_cost == -1 or saved_points < health_cost
	range_button.disabled = range_cost == -1 or saved_points < range_cost

func _build_upgrade_text(title: String, level: int, cost: int) -> String:
	if cost == -1:
		return title + " ур. " + str(level) + " (макс.)"
	return title + " ур. " + str(level) + " - цена " + str(cost)

func apply_saved_upgrades():
	gnom.apply_upgrade_stats(
		speed_level * SPEED_UPGRADE_BONUS,
		health_level * HEALTH_UPGRADE_BONUS,
		range_level * RANGE_UPGRADE_BONUS
	)

func start_game():
	start_screen.visible = false
	spawn_timer.start()
	get_tree().paused = false

func game_over():
	spawn_timer.stop()
	saved_points += kills
	best_score = maxi(best_score, kills)
	save_progress()
	final_score_label.text = "Очки: " + str(kills)
	death_screen.visible = true
	update_upgrade_buttons()
	get_tree().paused = true

func _on_restart_pressed():
	skip_start_screen = true
	get_tree().paused = false
	get_tree().reload_current_scene()

func _buy_speed_upgrade():
	var cost = get_upgrade_cost(SPEED_UPGRADE_COSTS, speed_level)
	if cost == -1 or saved_points < cost:
		return
	saved_points -= cost
	speed_level += 1
	save_progress()
	update_upgrade_buttons()

func _buy_health_upgrade():
	var cost = get_upgrade_cost(HEALTH_UPGRADE_COSTS, health_level)
	if cost == -1 or saved_points < cost:
		return
	saved_points -= cost
	health_level += 1
	save_progress()
	update_upgrade_buttons()

func _buy_range_upgrade():
	var cost = get_upgrade_cost(RANGE_UPGRADE_COSTS, range_level)
	if cost == -1 or saved_points < cost:
		return
	saved_points -= cost
	range_level += 1
	save_progress()
	update_upgrade_buttons()

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
	load_progress()
	death_screen.visible = false
	apply_saved_upgrades()
	label.set_text(str(kills))
	restart_button.pressed.connect(_on_restart_pressed)
	speed_button.pressed.connect(_buy_speed_upgrade)
	health_button.pressed.connect(_buy_health_upgrade)
	range_button.pressed.connect(_buy_range_upgrade)
	start_button.pressed.connect(start_game)
	if skip_start_screen:
		skip_start_screen = false
		start_game()
	else:
		get_tree().paused = true
