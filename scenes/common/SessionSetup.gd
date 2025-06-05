extends Control

@onready var mode_label = $VBoxContainer/ModeLabel
@onready var symbol_type = $VBoxContainer/SymbolTypeOption
@onready var line_count = $VBoxContainer/LineCountSlider
@onready var symbol_count = $VBoxContainer/SymbolCountSlider
@onready var display_time = $VBoxContainer/DisplayTimeSlider
@onready var line_mode = $VBoxContainer/LineModeOption
@onready var repetitions = $VBoxContainer/RepetitionsSlider
@onready var start_button = $VBoxContainer/StartButton

var config = {}

func _ready():
	mode_label.text = "Modus: " + GameManager.current_session.get("mode", "").capitalize()
	
	# Setup UI elements
	symbol_type.add_item("Buchstaben")
	symbol_type.add_item("Zahlen")
	symbol_type.add_item("Silben")
	
	line_mode.add_item("Statische Linien")
	line_mode.add_item("Wandernde Linien")
	line_mode.add_item("Keine Linien")
	
	line_count.value = 1
	symbol_count.value = 4
	display_time.value = 1.0
	repetitions.value = 3
	
	start_button.pressed.connect(_on_start_pressed)

func _on_start_pressed():
	config = {
		"mode": GameManager.current_session.get("mode"),
		"symbol_type": symbol_type.selected,
		"line_count": int(line_count.value),
		"symbol_count": int(symbol_count.value),
		"display_time": display_time.value,
		"line_mode": line_mode.selected,
		"repetitions": int(repetitions.value),
		"current_rep": 0
	}
	
	SignalBus.session_started.emit(config)
	
	if config.mode == "blitzlesen":
		SignalBus.scene_change_requested.emit("blitzlesen")
	else:
		SignalBus.scene_change_requested.emit("lese_landkarte")


func _on_line_count_slider_value_changed(value: float) -> void:
	%LineCount.text = "Anzahl an Zeilen: " + str(int(value))


func _on_symbol_count_slider_value_changed(value: float) -> void:
	%SymbolCount.text = "Anzahl der Symbole: " + str(int(value))


func _on_display_time_slider_value_changed(value: float) -> void:
	%DisplayTime.text = "Anzeigedauer der Symbole: " + str(value)


func _on_repetitions_slider_value_changed(value: float) -> void:
	%Repetitions.text = "Wiederholungen: " + str(int(value))
