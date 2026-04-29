extends Node2D

const Enemy = preload("res://EnemyCube.tscn")
@export
var _controlRect : TextureRect
var EnemyMaxDistanceFromTouch = 400.0
#aaaaaacjgcjyhkcchjchjhjchcjhjchjcchjhcjhjcchjchjcghdxgkhkxhtkxghkhxtkhxtxkhttkhxkxutxtku
func _input(event):
	if (event is InputEventScreenTouch or event is InputEventMouseButton) and event.is_pressed():
		var player = $Player
		var camera = $Camera2D
		var controlSize = _controlRect.size.x
		var controlCenter = _controlRect.global_position + Vector2(controlSize / 2, controlSize / 2)
		var relativePosition = event.position - controlCenter
		if relativePosition.length() > controlSize / 2:
			return
		var viewportSize = get_viewport_rect().size / camera.zoom
		var viewportMinSize = min(viewportSize.x, viewportSize.y)
		var multiplier = viewportMinSize / controlSize
		var multipliedPos = relativePosition * multiplier
		
		var worldPosition = player.global_position + multipliedPos
		var targetEnemy = get_closest_node_in_group("Enemies", worldPosition)
		if targetEnemy:
			if (worldPosition.distance_to(targetEnemy.global_position) <= EnemyMaxDistanceFromTouch):
				player.Attack(targetEnemy)
			else:
				player.JumpTo(worldPosition)
		else:
			player.JumpTo(worldPosition)
		
func get_closest_node_in_group(group_name: String, target_position: Vector2) -> Node:
	var nodes = get_tree().get_nodes_in_group(group_name)
	var closest_node = null
	var shortest_distance = INF # Устанавливаем бесконечность как начальное значение
	for node in nodes:
		if node is Node2D:
			# Используем distance_squared_to, так как это быстрее (не вычисляет квадратный корень)
			var distance = node.global_position.distance_squared_to(target_position)
			if distance < shortest_distance:
				shortest_distance = distance
				closest_node = node
	return closest_node



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
