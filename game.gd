extends Node2D

func _input(event):
	if event is InputEventScreenTouch and event.is_pressed():
		print("Touch position (Viewport): ", event.position)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
