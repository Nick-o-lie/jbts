extends Node

@onready
var _camera = $"../Camera2D"
@onready
var _scene = $".."

var _enemy = preload("res://EnemyCube.tscn")

var _difficulty = 1.0
var _bank = 0.0
var _actions = []
var _chosenAction = null

var _spawnRadius = 3000.0

func ChooseAction() -> void:
	# Step 1: Calculate total frequency (weight)
	var total_frequency = 0.0
	for action in _actions:
		total_frequency += float(action["frequency"])
	
	# Handle edge case: empty array or zero total frequency
	if total_frequency <= 0.0 or _actions.is_empty():
		push_error("Cannot pick from empty list or zero frequencies")
	
	# Step 2: Generate random value in [0, total_frequency)
	var random_value = randf() * total_frequency
	
	# Step 3: Iterate and accumulate until we exceed random_value
	var accumulated = 0.0
	for action in _actions:
		accumulated += float(action["frequency"])
		if accumulated >= random_value:
			_chosenAction = action
			return
			
	# Fallback: return last item (should rarely happen due to floating‑point precision)
	_chosenAction = [_actions.size() - 1]

func ExecuteAction() -> void:
	_bank -= _chosenAction["cost"]
	var enemyToSpawn = _enemy
	if _chosenAction["enemy"] == "cube":
		enemyToSpawn = _enemy
	var angle = randf_range(0, 2 * PI)
	var offset = Vector2(cos(angle) * _spawnRadius, sin(angle) * _spawnRadius)
	var enemy = enemyToSpawn.instantiate()
	enemy.global_position = _camera.global_position + offset
	_scene.add_child(enemy)
	if _chosenAction["count"] > 1:
		var angleOffset = 2 * PI / _chosenAction["count"]
		for i in range(1, _chosenAction["count"]):
			angle += angleOffset
			offset = Vector2(cos(angle) * _spawnRadius, sin(angle) * _spawnRadius)
			enemy = enemyToSpawn.instantiate()
			enemy.global_position = _camera.global_position + offset
			_scene.add_child(enemy)
		
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_actions.append({"cost": 1, "enemy": "cube", "count": 1, "frequency": 1})
	_actions.append({"cost": 2, "enemy": "cube", "count": 2, "frequency": 1})
	_actions.append({"cost": 4, "enemy": "cube", "count": 4, "frequency": 1})
	ChooseAction()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	_bank += delta * _difficulty
	if _bank > _chosenAction["cost"]:
		ExecuteAction()
		ChooseAction()
	pass
