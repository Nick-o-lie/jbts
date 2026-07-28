# AudioFFTInterface.gd
# Place anywhere in your Godot project (e.g. res://addons/AudioFFTPlugin/).
#
# Usage example in any Node script:
#
#   var _fft := AudioFFTInterface.new()
#
#   func _ready():
#       if not _fft.start():
#           print("RECORD_AUDIO permission not yet granted — try again after grant.")
#
#   func _process(_delta):
#       var spectrum: PackedFloat32Array = _fft.get_spectrum()
#       # spectrum[i]  →  magnitude of frequency bin i
#       # frequency of bin i  =  i * _fft.hz_per_bin()   (≈ 43.07 Hz steps)
#       # convert to dB:  20 * log10(max(spectrum[i], 1e-9))

class_name AudioFFTInterface
extends RefCounted

const PLUGIN_NAME := "AudioFFTPlugin"

var _singleton           # the Java/Kotlin singleton object
var _available: bool = false


func _init() -> void:
	print("AudioFFTInterface started")
	if Engine.has_singleton("AudioFFTPlugin"):
		_singleton  = Engine.get_singleton("AudioFFTPlugin")
		_available  = true
	else:
		push_warning(
			"AudioFFTPlugin singleton not found. "
			+ "Are you running on Android with the plugin installed and Gradle Build enabled?"
		)


# ── Control ────────────────────────────────────────────────────────────────

## Start microphone capture. Returns false on non-Android or missing permission.
func start() -> bool:
	if not _available:
		return false
	return _singleton.startCapture()


## Stop microphone capture and release the AudioRecord.
func stop() -> void:
	if _available:
		_singleton.stopCapture()


## True while the capture thread is running.
func capturing() -> bool:
	if not _available:
		return false
	return _singleton.isCapturing()


# ── Data ───────────────────────────────────────────────────────────────────

## Returns a PackedFloat32Array of 513 magnitude values (DC … Nyquist).
## Call this every frame or as needed.  Thread-safe.
func get_spectrum() -> PackedFloat32Array:
	if not _available:
		return PackedFloat32Array()
	return _singleton.getFrequencyData()


## Number of frequency bins (512 max).
func bin_count() -> int:
	if not _available:
		return 0
	return _singleton.getFrequencyBinCount()


## Sample rate in Hz (44100).
func sample_rate() -> int:
	if not _available:
		return 0
	return _singleton.getSampleRate()


## Frequency step per bin in Hz (≈ 43.07 Hz).
func hz_per_bin() -> float:
	if not _available:
		return 0.0
	return _singleton.getFrequencyResolution()


## Convert a bin index to its centre frequency in Hz.
func bin_to_hz(bin: int) -> float:
	return bin * hz_per_bin()


## Convert a linear magnitude to decibels (returns -180 dB for 0).
static func to_db(magnitude: float) -> float:
	return 20.0 * log(maxf(magnitude, 1e-9)) / log(10.0)
