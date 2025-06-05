extends Control

@onready var stats_label = $VBoxContainer/StatsLabel
@onready var details_container = $VBoxContainer/ScrollContainer/DetailsContainer
@onready var back_button = $VBoxContainer/BackButton

func _ready():
	var stats = GameManager.get_aggregated_statistics()
	
	stats_label.text = "Statistik:\n"
	stats_label.text += "Versuche: %d\n" % stats.total_attempts
	stats_label.text += "Korrekt: %d\n" % stats.correct
	stats_label.text += "Genauigkeit: %.1f%%\n" % stats.accuracy
	stats_label.text += "Durchschn. Zeit: %.1fs" % stats.avg_time
	
	# Show detailed results
	for i in GameManager.session_results.size():
		var result = GameManager.session_results[i]
		var detail_label = Label.new()
		detail_label.text = "Versuch %d: %s (%.1fs)" % [
			i + 1,
			"✓" if result.correct else "✗",
			result.time_taken
		]
		details_container.add_child(detail_label)
	
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	SignalBus.scene_change_requested.emit("main_menu")
