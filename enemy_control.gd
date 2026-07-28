extends Node

@onready
var _timer = $"Timer"

var BPM = 100.0

var _fft := AudioFFTInterface.new()
var _octaves : Array[float] = []
var _octavesForPumps : Array[float] = []
const _octave_ranges = [
	{"min_hz" : 0.0, "max_hz" : 33.0},
	{"min_hz" : 33.0, "max_hz" : 65.0},
	{"min_hz" : 65.0, "max_hz" : 131.0},
	{"min_hz" : 131.0, "max_hz" : 262.0},
	{"min_hz" : 262.0, "max_hz" : 523.0},
	{"min_hz" : 523.0, "max_hz" : 1047.0},
	{"min_hz" : 1047.0, "max_hz" : 2093.0},
	{"min_hz" : 2093.0, "max_hz" : 4186.0},
	{"min_hz" : 4186.0, "max_hz" : 8372.0},
	{"min_hz" : 8372.0, "max_hz" : 22000.0}
]
var _bin_count : int
var _sample_rate : int
var _hz_per_bin : float
const _target_fps = 60
const _beatHold = 0.95
#var bar_count = 512
#var bar_width = 3.0
#var spacing = 1.0
#var bars : Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_timer.wait_time = 60.0 / BPM
	_timer.timeout.connect(_onBeat)
	_timer.start()
	$AudioRestart.timeout.connect(_restartAudio)
	_fft.start()
	if _fft.capturing():
		_bin_count = _fft.bin_count()
		@warning_ignore("integer_division")
		_sample_rate = _fft.sample_rate() / 2
		_hz_per_bin = float(_sample_rate) / (_bin_count - 1)
	$AudioRestart.start()
	_octaves.resize(10)
	_octaves.fill(0.0)
	_octavesForPumps = _octaves.duplicate()
	
	
	#for i in range(bar_count):
		#var bar = MeshInstance2D.new()
		#bar.mesh = QuadMesh.new()
		#bar.mesh.size = Vector2(100, bar_width)
		#bar.position = Vector2(0, i * (bar_width + spacing))
		#
		#bar.position.y -= (bar_count * (bar_width + spacing)) / 2
		#
		#$"../Camera2D".add_child(bar)
		#bars.append(bar)
	
func _onBeat() -> void:
	for child in get_children():
		if (child.has_method("OnBeat")):
			child.OnBeat()

func _restartAudio() -> void:
	if not _fft.capturing():
		_fft.start()
		if _fft.capturing():
			_bin_count = _fft.bin_count()
			@warning_ignore("integer_division")
			_sample_rate = _fft.sample_rate() / 1000 / 2
			_hz_per_bin = float(_sample_rate) / (_bin_count - 1)

func calculate_octave_rms(spectrum : Array, delta: float) -> void:
	"""
	Calculates RMS for each octave/frequency bin defined by min/max Hz ranges.
	"""
	
	for octave in range(len(_octave_ranges)):
		var min_hz = _octave_ranges[octave].min_hz
		var max_hz = _octave_ranges[octave].max_hz
		var start_bin = max(0, int(floor(min_hz / _hz_per_bin)))
		var end_bin = min(_bin_count - 1, int(ceil(max_hz / _hz_per_bin)))
		var sum_squares = 0.0
		var bin_count_used = 0
		
		for i in range(start_bin, end_bin + 1):
			var magnitude = spectrum[i]
			sum_squares += pow(magnitude, 2)
			bin_count_used += 1
			
		if bin_count_used > 0:
			_octaves[octave] = sqrt(sum_squares / bin_count_used)
		var loggedMagnitude = log(_octaves[octave] + 1)
		if loggedMagnitude > _octavesForPumps[octave]:
			_octavesForPumps[octave] = loggedMagnitude
		else:
			_octavesForPumps[octave] *= pow(_beatHold, delta * _target_fps)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var spectrum = _fft.get_spectrum()
	if spectrum:
		calculate_octave_rms(spectrum, delta)
		for child in get_children():
			if (child.has_method("SetMagnitude")):
				child.SetMagnitude(_octavesForPumps[child.Octave])
	pass
