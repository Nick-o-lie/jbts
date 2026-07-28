extends AnimatableBody2D

#gxhgxkhgxkbgkbgxhkthktxjhtdhktjghxxghjxyhkxykxkykxyhykxxthkxtyhkxhkxyxyhxykkdyhdyhyhkkyhddyhiyhdkdyykdykddyhkytkthddthk
var speed = 100.0
@onready
var _player = $"../../Player"
@onready
var _animationPlayer = $AnimationPlayer
@export
var _hitParticles : PackedScene
@export
var _dieParticles : PackedScene
@onready
var _sprite = $Sprite2D
@export
var attackDistance = 500.0
@export
var moveDistance = 300.0
@export
var oppositeMoveDistance = 50.0
@export
var chanceOfMovingOpposite = 0.25
var _defaultBPM = 60.0
var BPM = 100.0
var _targetPos = null
var HP = 10.0
var _currentAction : Dictionary
var _scheduledAnimaton : String = ""
var _lastBeatTime : float
var _directionalTween : Tween
var _angularTween : Tween
var _lastPosition : Vector2
var Octave : int

func OnHit(damage: float, hit_point: Vector2, velocity_vector: Vector2) -> void:
	HP -= damage
	var particles = _hitParticles.instantiate()
	particles.global_position = hit_point
	particles.global_rotation = velocity_vector.angle()
	particles.modulate = _sprite.modulate
	add_sibling(particles)
	if HP <= 0:
		Die()

func Die() -> void:
	var particles = _dieParticles.instantiate()
	particles.global_position = global_position
	particles.global_rotation = global_rotation
	particles.modulate = _sprite.modulate
	add_sibling(particles)
	queue_free()

func AttackWindUp() -> void:
	_scheduledAnimaton = ""
	_directionalTween = create_tween()
	var windUpVector = global_position - (_targetPos - global_position).normalized() * 100.0
	var timeForTween = 1.0 * _defaultBPM / BPM
	_directionalTween.tween_property(self, "global_position", windUpVector, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_angularTween = create_tween()
	var targetRotation = global_position.angle_to_point(_targetPos) + randi_range(1, 4) * PI / 2 + PI / 4
	while abs(targetRotation - rotation) < 3 * PI / 4:
		if targetRotation > rotation:
			targetRotation += PI / 2
		else:
			targetRotation -= PI / 2
	_angularTween.tween_property(self, "rotation", targetRotation, timeForTween) \
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
func Attack() -> void:
	if _directionalTween:
		_directionalTween.kill()
	if _angularTween:
		_angularTween.kill()
	_directionalTween = create_tween()
	var attackVector : Vector2 = _targetPos + (_targetPos - global_position).normalized() * 500.0
	if (attackVector.distance_to(global_position) > 1100.0):
		print(attackVector.distance_to(global_position))
	var timeForTween = 1.0 * _defaultBPM / BPM
	_directionalTween.tween_property(self, "global_position", attackVector, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func MoveX() -> void:
	_scheduledAnimaton = ""
	_directionalTween = create_tween()
	var direction = 1 if (_player.global_position - position).x > 0 else -1
	if randf() > chanceOfMovingOpposite:
		_targetPos = Vector2(position.x + direction * moveDistance, position.y)
	else:
		_targetPos = Vector2(position.x - direction * oppositeMoveDistance, position.y)
	var timeForTween = 1.0 * _defaultBPM / BPM
	_directionalTween.tween_property(self, "global_position", _targetPos, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func MoveY() -> void:
	_scheduledAnimaton = ""
	_directionalTween = create_tween()
	var direction = 1 if (_player.global_position - position).y > 0 else -1
	if randf() > chanceOfMovingOpposite:
		_targetPos = Vector2(position.x, position.y + direction * moveDistance)
	else:
		_targetPos = Vector2(position.x, position.y - direction * oppositeMoveDistance)
	var timeForTween = 1.0 * _defaultBPM / BPM
	_directionalTween.tween_property(self, "global_position", _targetPos, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func Turn() -> void:
	_scheduledAnimaton = ""
	_angularTween = create_tween()
	var current_deg = rotation_degrees
	var remainder = fmod(current_deg, 45.0)
	var target_rotation = 0.0
	if abs(remainder) > 10 and abs(remainder - 45) > 10 and abs(remainder + 45) > 10:
		# Snap to nearest multiple of 45
		target_rotation = deg_to_rad(round(current_deg / 45.0) * 45.0)
	else:
		# Random ±45
		var change = 45.0 if randf() > 0.5 else -45.0
		target_rotation = deg_to_rad(round((rotation_degrees + change) / 45.0) * 45.0)
	var timeForTween = 1.0 * _defaultBPM / BPM
	_angularTween.tween_property(self, "rotation", target_rotation, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)

func Rotate() -> void:
	_scheduledAnimaton = ""
	_angularTween = create_tween()
	var change = 360.0 if randf() > 0.5 else -360.0
	var targetRotationDegrees = rotation_degrees + change
	var timeForTween = 1.0 * _defaultBPM / BPM
	_angularTween.tween_property(self, "rotation_degrees", targetRotationDegrees, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_targetPos = _player.global_position
	_animationPlayer.speed_scale = BPM / 60.0
	_lastPosition = position
	pass # Replace with function body.
	
func _noAction() -> void:
	_scheduledAnimaton = ""
	pass
	
func _attackStart() -> void:
	_targetPos = _player.global_position
	_currentAction = possibleActions['attack']
	_scheduledAnimaton = "attack"
	
func _moveX() -> void:
	_currentAction = possibleActions['moveX']
	_scheduledAnimaton = "moveX"
	
func _moveY() -> void:
	_currentAction = possibleActions['moveY']
	_scheduledAnimaton = "moveY"
	
func _turn() -> void:
	_currentAction = possibleActions['turn']
	_scheduledAnimaton = "turn"
	
func _rotate() -> void:
	_currentAction = possibleActions['rotate']
	_scheduledAnimaton = "rotate"
	
	
var possibleActions = {
	'moveX' : {
		'frequency' : 1.0,
		'action' : _moveX,
		'delay' : 0.5,
		'length' : 1.0
	},
	'moveY' : {
		'frequency' : 1.0,
		'action' : _moveY,
		'delay' : 0.5,
		'length' : 1.0
	},
	'attack' : {
		'frequency' : 5.0,
		'action' : _attackStart,
		'delay' : 0.5,
		'length' : 2.0
	},
	'turn' : {
		'frequency' : 1.0,
		'action' : _turn,
		'delay' : 0.5,
		'length' : 1.0
	},
	'rotate' : {
		'frequency': 1.0,
		'action' : _rotate,
		'delay' : 0.5,
		'length' : 1.0
	}
}
var maxMagnitude = 0.0

func SetMagnitude(magnitude : float):
	if magnitude > maxMagnitude:
		maxMagnitude = magnitude
	scale = Vector2.ONE.lerp(Vector2(2, 2), magnitude / 128.0)

func OnBeat() -> void:
	if _scheduledAnimaton == "":
		#print(_animationPlayer.current_animation_position)
		if not _animationPlayer.is_playing():
			_lastBeatTime = Time.get_ticks_msec() / 1000.0
			var currentActions = possibleActions.duplicate()
			var distanceToPlayer = _player.global_position.distance_to(global_position)
			if distanceToPlayer > attackDistance:
				currentActions.erase('attack')
			ChooseAction(currentActions)
		elif _animationPlayer.current_animation_position > _currentAction['length'] - _currentAction['delay'] - 0.1:
			_lastBeatTime = Time.get_ticks_msec() / 1000.0
			var currentActions = possibleActions.duplicate()
			var distanceToPlayer = _player.global_position.distance_to(global_position)
			if distanceToPlayer > attackDistance:
				currentActions.erase('attack')
			ChooseAction(currentActions)
		
func ChooseAction(actions : Dictionary) -> void:
	var total_frequency = 0.0
	for action in actions.values():
		total_frequency += float(action["frequency"])
	
	# Handle edge case: empty array or zero total frequency
	if total_frequency <= 0.0 or actions.is_empty():
		push_error("Cannot pick from empty list or zero frequencies")
	
	# Step 2: Generate random value in [0, total_frequency)
	var random_value = randf() * total_frequency
	
	# Step 3: Iterate and accumulate until we exceed random_value
	var accumulated = 0.0
	for action in actions.values():
		accumulated += float(action["frequency"])
		if accumulated >= random_value:
			action['action'].call()
			return
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _scheduledAnimaton != "":
		if Time.get_ticks_msec() / 1000.0 - _lastBeatTime > _currentAction['delay'] * _defaultBPM / BPM:
			_animationPlayer.stop(false)
			if _directionalTween:
				_directionalTween.kill()
			if _angularTween:
				_angularTween.kill()
			_animationPlayer.play(_scheduledAnimaton)
			_scheduledAnimaton = ""
	pass
