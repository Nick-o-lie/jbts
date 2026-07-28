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
var _collisionPoint : Vector2
var _collisionNormal : Vector2
var _movementTween = create_tween()
var _willHurtItself = false
@export
var _targetPosition : Vector2

func Attack(enemy: Node2D):
	if (_animationLocked): return
	
	_animationLocked = true;
	_currentTarget = enemy;
	_visual.look_at(_currentTarget.global_position)
	_animationPlayer.stop()
	_animationPlayer.play("attack");
	_movementTween.kill()
	_movementTween = create_tween()
	_movementTween.tween_property(_camera, "global_position", global_position - (_currentTarget.global_position - global_position).normalized() * 100.0, 5.0/60)
	
func DashToTarget():
	if (_currentTarget == null):
		_animationLocked = false
		return
	_targetPlace = _currentTarget.global_position
	_movementTween.kill()
	_movementTween = create_tween()
	_movementTween.tween_property(self, "_targetPosition", _targetPlace, 3.0/60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	
func OnAttackHit(collision : KinematicCollision2D):
	_animationLocked = false
	var velocityVector : Vector2
	_currentTarget = collision.get_collider()
	if _currentTarget != null:
		velocityVector = (_currentTarget.global_position - global_position).normalized()
	var vertices = _currentTarget.get_node("Vertices")
	var collisionPosition : Vector2 = collision.get_position()
	_visual.look_at(collisionPosition)
	_willHurtItself = false
	for vertex in vertices.get_children():
		#print(collisionPosition.distance_squared_to(vertex.global_position))
		if collisionPosition.distance_squared_to(vertex.global_position) < 4.0:
			_willHurtItself = true
			break
	if not _willHurtItself:
		_currentTarget.OnHit(10.0, collisionPosition, - collision.get_normal())
	else:
		global_position -= velocityVector * 10.0
	_targetPosition = global_position
	_animationPlayer.play("attack_hit")
	Engine.time_scale = 0.025
	get_tree().create_timer(0.01).timeout.connect(func():
		Engine.time_scale = 1)
	var normal = collision.get_normal()
	var targetPos = global_position + reflectVector(velocityVector, normal) * 100.0
	_movementTween.kill()
	_movementTween = create_tween()
	_movementTween.tween_property(self, "_targetPosition", targetPos, 120.0/60).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC).set_delay(2.0/60)
		
func JumpTo(newPosition: Vector2):
	if (_animationLocked): return
	_targetPlace = newPosition
	_animationLocked = true
	_visual.look_at(newPosition)
	_animationPlayer.stop()
	_animationPlayer.play("jump")
	
func DashToPlace():
	_movementTween.kill()
	_targetPosition = global_position
	_movementTween = create_tween()
	_movementTween.tween_property(self, "_targetPosition", _targetPlace, 3.0/60).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT) \
	.finished.connect(func() : 
		_animationLocked = false
		_animationPlayer.play("jump_recovery"))
	
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
	tween.tween_property(_camera, "global_position", global_position, 5.0/60) \
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
func OvershootCameraJump() -> void:
	var tween = create_tween()
	tween.tween_property(_camera, "global_position", global_position, 15.0/60) \
	.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				
func ReturnCamera() -> void:
	var tween = create_tween()
	tween.tween_property(_camera, "global_position", global_position, 4.0/60)
				
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	var collision : KinematicCollision2D = move_and_collide(_targetPosition - global_position)
	if collision:
		if _movementTween:
			_movementTween.kill()
		OnAttackHit(collision)
		_animationLocked = false
				
