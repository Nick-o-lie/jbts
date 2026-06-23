# export_plugin.gd
# This is a @tool script that integrates the AudioFFTPlugin AAR into the
# Godot Android export pipeline.
#
# Place this file at:  addons/AudioFFTPlugin/export_plugin.gd
#
# The Godot Editor loads it automatically when the plugin is enabled via
# Project → Project Settings → Plugins.

@tool
extends EditorPlugin

# Hold a reference to the export plugin so it is not garbage-collected.
var _export_plugin: _AndroidExportPlugin


func _enter_tree() -> void:
	_export_plugin = _AndroidExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


# ---------------------------------------------------------------------------
# Inner class — the actual export plugin
# ---------------------------------------------------------------------------
class _AndroidExportPlugin extends EditorExportPlugin:

	const _PLUGIN_NAME := "AudioFFTPlugin"

	# Tell the editor this plugin only targets Android.
	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	# Return the plugin's unique name (must match AndroidManifest meta-data).
	func _get_name() -> String:
		return _PLUGIN_NAME

	# Paths to the AAR binaries, relative to the addons/ directory.
	# After building in Android Studio, copy the AARs here.
	func _get_android_libraries(
			_platform: EditorExportPlatform,
			debug: bool
	) -> PackedStringArray:
		if debug:
			return PackedStringArray([
				"AudioFFTPlugin/bin/debug/AudioFFTPlugin-debug.aar"
			])
		else:
			return PackedStringArray([
				"AudioFFTPlugin/bin/release/AudioFFTPlugin-release.aar"
			])

	# Inject the RECORD_AUDIO permission into the generated AndroidManifest.
	# This is equivalent to adding the tag in the manifest directly, but
	# survives Godot Editor updates automatically.
	func _get_android_manifest_element_contents(
			_platform: EditorExportPlatform,
			_debug: bool
	) -> String:
		return '<uses-permission android:name="android.permission.RECORD_AUDIO" />'
