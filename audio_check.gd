extends Node

var _fft := AudioFFTInterface.new()

func _ready():
	_fft.start()   # returns false if permission not yet granted

func _process(_delta):
	var spectrum := _fft.get_spectrum()  # PackedFloat32Array(512)
	for i in spectrum.size():
		var freq_hz  := _fft.bin_to_hz(i)
		var magnitude := spectrum[i]
		var db        := AudioFFTInterface.to_db(magnitude)
