extends AnimatableBody2D

#hkxdghkodghoxghxghohizgdthiizthzfhkkzthzthkdthokxthxhktghkxhkxgghkxxcjfjnfjfkfjfjfjghkhldyyhkdyhldyhkdhkdtxhgkxghkkdghkdghkxghhkxghkxgxghkkghxkxghkhhcyjcjyhcihiyycgxhkgd
var _animationLocked = false
var _currentTarget : StaticBody2D = null
var _targetPlace = null
@onready
var _animationPlayer = $AnimationPlayer
@onready
var _visual = $Visual
@onready
var _camera = $"../Camera2D"
@onready
var _shapeCast = $ShapeCast2D
var _collisionPoint : Vector2
var _collisionNormal : Vector2
var _movementTween = create_tween()
var _willHurtItself = false
func Attack(enemy: Node2D):
	if (_animationLocked): return
	
	_animationLocked = true;
	_currentTarget = enemy;
	_visual.look_at(_currentTarget.global_position)
	_animationPlayer.stop()
	_animationPlayer.play("attack");
	_movementTween.stop()
	_movementTween = create_tween()
	_movementTween.tween_property(_camera, "global_position", global_position - (_currentTarget.global_position - global_position).normalized() * 100.0, 5.0/60)
	
func DashToTarget():
	if (_currentTarget == null):
		_animationLocked = false
		return
	var spaceState = get_world_2d().direct_space_state
	var start = global_position
	_targetPlace = _currentTarget.global_position
	var query = PhysicsRayQueryParameters2D.create(global_position, _targetPlace)
	_shapeCast.target_position = to_local(_targetPlace)
	_shapeCast.force_shapecast_update()
	
	if _shapeCast.is_colliding():
		var collision = _shapeCast.collision_result[0]
		_targetPlace = FindCircleLineIntersection(collision.point, _shapeCast.shape.radius, global_position, _targetPlace)
		_collisionPoint = collision.point
		_collisionNormal = collision.normal
		_currentTarget = collision.collider
		print("Место столкновения: ", collision.point - collision.collider.global_position)
		var vertices = _currentTarget.get_node("Vertices")
		for vertex in vertices.get_children():
			if collision.point.distance_squared_to(vertex.global_position) < 4.0:
				_willHurtItself = true
				break
		_movementTween.stop()
		_movementTween = create_tween()
		_movementTween.tween_property(self, "global_position", _targetPlace, 3.0/60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		await _movementTween.finished
		_visual.look_at(collision.point)
	else:
		_currentTarget = null
		DashToPlace()
	
func OnAttackHit():
	_animationLocked = false
	var velocityVector
	if _currentTarget != null:
		velocityVector = (_currentTarget.global_position - global_position).normalized()
		if not _willHurtItself:
			_currentTarget.OnHit(10.0, _collisionPoint, - _collisionNormal)
	_willHurtItself = false
	if _currentTarget == null:
		return
	_currentTarget = null
	Engine.time_scale = 0.025
	get_tree().create_timer(0.01).timeout.connect(func():
		Engine.time_scale = 1)
	if _shapeCast.is_colliding():
		var collision = _shapeCast.collision_result[0]
		var normal = collision.normal
		var targetPos = global_position + reflectVector(velocityVector, normal) * 100.0
		_movementTween.stop()
		_movementTween = create_tween()
		_movementTween.tween_property(self, "global_position", targetPos, 120.0/60).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(2.0/60)
		
func JumpTo(newPosition: Vector2):
	if (_animationLocked): return
	_shapeCast.target_position = to_local(newPosition)
	_shapeCast.force_shapecast_update()
	if _shapeCast.is_colliding():
		Attack(_shapeCast.collision_result[0].collider)
		return
	_targetPlace = newPosition
	_animationLocked = true
	_visual.look_at(newPosition)
	_animationPlayer.stop()
	_animationPlayer.play("jump")
	
func DashToPlace():
	_movementTween.stop()
	_movementTween = create_tween()
	_movementTween.tween_property(self, "global_position", _targetPlace, 3.0/60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _movementTween.finished
	_animationLocked = false
	
func FindCircleLineIntersection(circleCenter: Vector2, radius: float, pointA: Vector2, pointB: Vector2) -> Vector2:
	var p1 = pointA - circleCenter
	var p2 = pointB - circleCenter
	var d = p2 - p1
	var a = d.dot(d)
	var b = 2 * p1.dot(d)
	var c = p1.dot(p1) - radius * radius
	var discr = b * b - 4 * a * c
	if discr < 0:
		return Vector2.ZERO
	if is_zero_approx(discr):
		var t = -b/(2*a)
		return p1 + t*d + circleCenter
	var sqrtDiscr = sqrt(discr)
	var t1 = (-b - sqrtDiscr)/(2*a)
	var t2 = (-b + sqrtDiscr)/(2*a)
	if p1.distance_squared_to(p1 + t1 * d) < p1.distance_squared_to(p1 + t2*d):
		return p1 + t1 * d + circleCenter
	return p1 + t2 * d + circleCenter
	
func reflectVector(v: Vector2, normal: Vector2) -> Vector2:
	# Ensure the normal is normalized
	var n = normal.normalized()
	# Calculate dot product
	var dot_product = v.dot(n)
	# Apply reflection formula
	return v - 2 * dot_product * n
	
	
func OvershootCameraEnemy() -> void:
	var tween = create_tween()
	tween.tween_property(_camera, "global_position", _targetPlace, 5.0/60) \
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(6.0/60)
	
func OvershootCameraJump() -> void:
	var tween = create_tween()
	tween.tween_property(_camera, "global_position", _targetPlace, 15.0/60) \
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).set_delay(6.0/60)
				
func ReturnCamera() -> void:
	var tween = create_tween()
	tween.tween_property(_camera, "global_position", global_position, 4.0/60)
				
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
