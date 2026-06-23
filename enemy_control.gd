extends Node

@onready
var _timer = $"Timer"

var BPM = 100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer.wait_time = 60.0 / BPM
	_timer.timeout.connect(_onBeat)
	_timer.start()
	
func _onBeat() -> void:
	for child in get_children():
		if (child.has_method("OnBeat")):
			child.OnBeat()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
