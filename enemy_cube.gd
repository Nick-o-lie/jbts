extends AnimatableBody2D

#gxhgxkhgxkbgkbgxhkthktxjhtdhktjghxxghjxyhkxykxkykxyhykxxthkxtyhkxhkxyxyhxykkdyhdyhyhkkyhddyhiyhdkdyykdykddyhkytkthddthk
var speed = 100.0
@onready
var _player = $"../Player"
@onready
var _animationPlayer = $AnimationPlayer
@export
var _hitParticles : PackedScene
@export
var _dieParticles : PackedScene
@onready
var _sprite = $Sprite2D
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
	directionalTween.tween_property(self, "global_position", windUpVector, 30.0/60).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	var angularTween = create_tween()
	var targetRotation = global_position.angle_to_point(_targetPos) + randi_range(1, 4) * PI / 2 + PI / 4
	while abs(targetRotation - rotation) < 3 * PI / 4:
		if targetRotation > rotation:
			targetRotation += PI / 2
		else:
			targetRotation -= PI / 2
	angularTween.tween_property(self, "rotation", targetRotation, 30.0/60) \
	.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	
func Attack() -> void:
	var directionalTween = create_tween()
	var attackVector = _targetPos + (_targetPos - global_position).normalized() * 500.0
	directionalTween.tween_property(self, "global_position", attackVector, 30.0/60).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_targetPos = _player.global_position
	pass # Replace with function body.


var _doNothing = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var distanceToPlayer = _player.global_position.distance_to(global_position)
	if distanceToPlayer > 500.0 and not _animationPlayer.is_playing():
		_targetPos = _player.global_position
		var moveVector = (_targetPos - global_position).normalized()
		global_position += moveVector * speed * delta
	elif not _animationPlayer.is_playing():
		_animationPlayer.play("attack")
