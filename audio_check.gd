extends Node

var _fft := AudioFFTInterface.new()

func _ready():
	_fft.start()   # returns false if permission not yet granted

func _process(_delta):
	var spectrum := _fft.get_spectrum()  # PackedFloat32Array()
	for i in spectrum.size():
		var magnitude := spectrum[i]
		
