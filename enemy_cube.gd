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
var _defaultBPM = 60.0
var BPM = 100.0
var _targetPos = null
var HP = 10.0

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
	particles.emitting = true
	add_sibling(particles)
	queue_free()

func AttackWindUp() -> void:
	_targetPos = _player.global_position
	var directionalTween = create_tween()
	var windUpVector = global_position - (_targetPos - global_position).normalized() * 100.0
	var timeForTween = 1.0 * _defaultBPM / BPM
	directionalTween.tween_property(self, "global_position", windUpVector, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var angularTween = create_tween()
	var targetRotation = global_position.angle_to_point(_targetPos) + randi_range(1, 4) * PI / 2 + PI / 4
	while abs(targetRotation - rotation) < 3 * PI / 4:
		if targetRotation > rotation:
			targetRotation += PI / 2
		else:
			targetRotation -= PI / 2
	angularTween.tween_property(self, "rotation", targetRotation, timeForTween) \
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
func Attack() -> void:
	var directionalTween = create_tween()
	var attackVector = _targetPos + (_targetPos - global_position).normalized() * 500.0
	var timeForTween = 1.0 * _defaultBPM / BPM
	directionalTween.tween_property(self, "global_position", attackVector, timeForTween).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_targetPos = _player.global_position
	_animationPlayer.speed_scale = BPM / 60.0
	pass # Replace with function body.
	
func _noAction() -> void:
	pass
	
func _attackStart() -> void:
	_animationPlayer.play("attack")

	

var possibleActions = {
	'moveX' : {
		'frequency' : 1.0,
		'action' : _noAction
	},
	'moveY' : {
		'frequency' : 1.0,
		'action' : _noAction
	},
	'attack' : {
		'frequency' : 5.0,
		'action' : _attackStart
	},
	'turn' : {
		'frequency' : 0.5,
		'action' : _noAction
	},
	'rotate' : {
		'frequency': 0.5,
		'action' : _noAction
	}
}

func OnBeat() -> void:
	if not _animationPlayer.is_playing():
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

var _doNothing = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
