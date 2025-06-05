extends Node

const SCENES = {
	"main_menu": "res://scenes/main_menu/MainMenu.tscn",
	"blitzlesen": "res://scenes/blitzlesen/BlitzlesenMode.tscn",
	"lese_landkarte": "res://scenes/lese_landkarte/LeseLandkarteMode.tscn",
	"session_setup": "res://scenes/common/SessionSetup.tscn",
	"results": "res://scenes/common/ResultsScreen.tscn"
}

var current_session: Dictionary = {}
var session_results: Array = []

func _ready():
	SignalBus.scene_change_requested.connect(_on_scene_change_requested)
	SignalBus.session_started.connect(_on_session_started)
	SignalBus.session_completed.connect(_on_session_completed)

func _on_scene_change_requested(scene_key: String):
	if scene_key in SCENES:
		get_tree().change_scene_to_file(SCENES[scene_key])

func _on_session_started(config: Dictionary):
	current_session = config
	session_results.clear()

func _on_session_completed(results: Dictionary):
	session_results.append(results)

func get_aggregated_statistics() -> Dictionary:
	var stats = {
		"total_attempts": session_results.size(),
		"correct": 0,
		"avg_time": 0.0,
		"accuracy": 0.0
	}
	
	var total_time = 0.0
	for result in session_results:
		if result.get("correct", false):
			stats.correct += 1
		total_time += result.get("time_taken", 0.0)
	
	if stats.total_attempts > 0:
		stats.accuracy = float(stats.correct) / float(stats.total_attempts) * 100.0
		stats.avg_time = total_time / float(stats.total_attempts)
	
	return stats
