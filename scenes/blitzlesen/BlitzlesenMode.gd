# === BLITZLESEN MODE: BlitzlesenMode.gd ===
extends Control

@onready var display_area = $VBoxContainer/DisplayArea
@onready var input_area = $VBoxContainer/InputArea
@onready var line_container = $VBoxContainer/DisplayArea/LineContainer
@onready var symbol_container = $VBoxContainer/DisplayArea/SymbolContainer

var symbols_to_show: Array = []
var shown_positions: Array = []
var current_index: int = 0
var start_time: float = 0.0

const SYMBOL_SETS = {
	0: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
		"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"],  # Buchstaben
	1: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],  # Zahlen
	2: ["BA", "BE", "BI", "BO", "BU", "DA", "DE", "DI", "DO", "DU",
		"FA", "FE", "FI", "FO", "FU", "GA", "GE", "GI", "GO", "GU"]  # Silben
}

func _ready():
	input_area.visible = false
	_setup_session()

func _setup_session():
	var config = GameManager.current_session
	
	# Generate symbols
	symbols_to_show.clear()
	shown_positions.clear()
	
	var symbol_set = SYMBOL_SETS[config.symbol_type]
	for i in config.symbol_count:
		symbols_to_show.append(symbol_set.pick_random())
	
	# Setup lines
	_setup_lines(config.line_count, config.line_mode)
	
	# Start sequence
	current_index = 0
	start_time = Time.get_ticks_msec() / 1000.0
	_show_next_symbol()

func _setup_lines(count: int, mode: int):
	# Clear existing lines
	for child in line_container.get_children():
		child.queue_free()
	
	if mode == 2:  # Keine Linien
		return
	
	var viewport_size = get_viewport_rect().size
	var line_spacing = 100
	var start_y = (viewport_size.y - (count - 1) * line_spacing) / 2
	
	for i in count:
		var line = Line2D.new()
		line.add_point(Vector2(50, start_y + i * line_spacing))
		line.add_point(Vector2(viewport_size.x - 50, start_y + i * line_spacing))
		line.width = 2.0
		line.default_color = Color(0.5, 0.5, 0.5, 0.5)
		line.z_index = -1  # Linien hinter den Symbolen
		line_container.add_child(line)

func _show_next_symbol():
	if current_index >= symbols_to_show.size():
		_sequence_completed()
		return
	
	var config = GameManager.current_session
	var symbol = symbols_to_show[current_index]
	
	# Calculate position - zeilenweise von links nach rechts
	var viewport_size = get_viewport_rect().size
	var symbols_per_line = ceil(float(symbols_to_show.size()) / float(config.line_count))
	var line_index = current_index / symbols_per_line
	var position_in_line = current_index % int(symbols_per_line)
	
	# Sicherstellen, dass wir nicht mehr Zeilen nutzen als verfügbar
	if line_index >= config.line_count:
		line_index = config.line_count - 1
		# Verteile übrige Symbole auf die letzte Zeile
		var symbols_in_last_line = symbols_to_show.size() - (config.line_count - 1) * symbols_per_line
		position_in_line = (current_index - (config.line_count - 1) * symbols_per_line)
	
	var x = 100 + position_in_line * 150 + randf() * 50
	var y = (viewport_size.y - (config.line_count - 1) * 100) / 2 + line_index * 100
	
	# Create symbol display
	var label = Label.new()
	label.text = str(symbol)
	label.add_theme_font_size_override("font_size", 48)
	label.position = Vector2(x, y)
	label.z_index = 1  # Symbole über den Linien
	symbol_container.add_child(label)
	
	shown_positions.append(Vector2(x, y))
	
	# Hide after display time
	await get_tree().create_timer(config.display_time).timeout
	label.modulate.a = 0.3  # Keep faint trace
	
	current_index += 1
	await get_tree().create_timer(0.2).timeout  # Small pause between symbols
	_show_next_symbol()

func _sequence_completed():
	display_area.visible = false
	input_area.visible = true
	
	# Setup input UI
	var input_field = LineEdit.new()
	input_field.placeholder_text = "Geben Sie die Sequenz ein..."
	input_field.grab_focus()
	
	var submit_button = Button.new()
	submit_button.text = "Überprüfen"
	submit_button.pressed.connect(_validate_input.bind(input_field))
	
	input_area.add_child(input_field)
	input_area.add_child(submit_button)

func _validate_input(input_field: LineEdit):
	var user_input = input_field.text.to_upper()
	var correct_sequence = ""
	for symbol in symbols_to_show:
		correct_sequence += str(symbol)
	
	var result = {
		"correct": user_input == correct_sequence,
		"time_taken": Time.get_ticks_msec() / 1000.0 - start_time,
		"expected": correct_sequence,
		"user_input": user_input
	}
	
	SignalBus.session_completed.emit(result)
	
	# Check if more repetitions needed
	var config = GameManager.current_session
	config.current_rep += 1
	
	if config.current_rep < config.repetitions:
		# Reset for next repetition
		for child in symbol_container.get_children():
			child.queue_free()
		for child in input_area.get_children():
			child.queue_free()
		
		display_area.visible = true
		input_area.visible = false
		
		await get_tree().create_timer(1.0).timeout
		_setup_session()
	else:
		SignalBus.scene_change_requested.emit("results")
