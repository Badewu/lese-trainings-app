# === LESE-LANDKARTE MODE: LeseLandkarteMode.gd ===
extends Control

@onready var display_area = $VBoxContainer/DisplayArea
@onready var input_area = $VBoxContainer/InputArea
@onready var line_container = $VBoxContainer/DisplayArea/LineContainer
@onready var symbol_container = $VBoxContainer/DisplayArea/SymbolContainer
@onready var token_container = $VBoxContainer/InputArea/TokenContainer
@onready var drop_zone_container = $VBoxContainer/InputArea/DropZoneContainer

var symbols_to_show: Array = []
var symbol_positions: Array = []
var current_index: int = 0
var start_time: float = 0.0
var placed_tokens: Dictionary = {}

const SYMBOL_SETS = {
	0: ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", 
		"N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"],
	1: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
	2: ["BA", "BE", "BI", "BO", "BU", "DA", "DE", "DI", "DO", "DU",
		"FA", "FE", "FI", "FO", "FU", "GA", "GE", "GI", "GO", "GU"]
}

func _ready():
	input_area.visible = false
	_setup_session()

func _setup_session():
	var config = GameManager.current_session
	
	symbols_to_show.clear()
	symbol_positions.clear()
	placed_tokens.clear()
	
	var symbol_set = SYMBOL_SETS[config.symbol_type]
	for i in config.symbol_count:
		symbols_to_show.append(symbol_set.pick_random())
	
	_setup_lines(config.line_count, config.line_mode)
	
	current_index = 0
	start_time = Time.get_ticks_msec() / 1000.0
	_show_all_symbols()

func _setup_lines(count: int, mode: int):
	for child in line_container.get_children():
		child.queue_free()
	
	if mode == 2:
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

func _show_all_symbols():
	var config = GameManager.current_session
	_show_next_symbol_sequential()

func _show_next_symbol_sequential():
	if current_index >= symbols_to_show.size():
		# Alle Symbole gezeigt - warte kurz, dann zeige Eingabebereich
		await get_tree().create_timer(1.0).timeout
		_sequence_completed()
		return
	
	var config = GameManager.current_session
	var symbol = symbols_to_show[current_index]
	var viewport_size = get_viewport_rect().size
	
	# Calculate position - zeilenweise von links nach rechts
	var symbols_per_line = ceil(float(symbols_to_show.size()) / float(config.line_count))
	var line_index = current_index / symbols_per_line
	var position_in_line = current_index % int(symbols_per_line)
	
	# Sicherstellen, dass wir nicht mehr Zeilen nutzen als verfügbar
	if line_index >= config.line_count:
		line_index = config.line_count - 1
		var symbols_in_last_line = symbols_to_show.size() - (config.line_count - 1) * symbols_per_line
		position_in_line = (current_index - (config.line_count - 1) * symbols_per_line)
	
	var x = 100 + position_in_line * 150 + randf() * 30  # Nur leichte horizontale Variation
	var y = (viewport_size.y - (config.line_count - 1) * 100) / 2 + line_index * 100  # Feste Zeilenhöhe
	
	var label = Label.new()
	label.text = str(symbol)
	label.add_theme_font_size_override("font_size", 48)
	label.position = Vector2(x, y)
	label.z_index = 1  # Symbole über den Linien
	symbol_container.add_child(label)
	
	symbol_positions.append({"symbol": symbol, "pos": Vector2(x, y)})
	
	# Zeige für längere Zeit (3x display time)
	await get_tree().create_timer(config.display_time * 3.0).timeout
	
	# Blende aus
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	
	current_index += 1
	await get_tree().create_timer(0.2).timeout  # Kleine Pause zwischen Symbolen
	_show_next_symbol_sequential()

func _sequence_completed():
	display_area.visible = false
	input_area.visible = true
	
	_create_drop_zones()
	_create_draggable_tokens()

func _create_drop_zones():
	var config = GameManager.current_session
	
	for i in symbol_positions.size():
		var drop_zone = Panel.new()
		drop_zone.custom_minimum_size = Vector2(80, 80)
		drop_zone.position = symbol_positions[i].pos
		drop_zone.set_meta("index", i)
		drop_zone.set_meta("expected_symbol", symbol_positions[i].symbol)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3, 0.3)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.5, 0.5, 0.5, 0.5)
		drop_zone.add_theme_stylebox_override("panel", style)
		
		drop_zone_container.add_child(drop_zone)

func _create_draggable_tokens():
	var config = GameManager.current_session
	var shuffled_symbols = symbols_to_show.duplicate()
	shuffled_symbols.shuffle()
	
	# Add some extra wrong tokens for difficulty
	var extra_count = max(2, symbols_to_show.size() / 3)
	var symbol_set = SYMBOL_SETS[config.symbol_type]
	for i in extra_count:
		shuffled_symbols.append(symbol_set.pick_random())
	
	shuffled_symbols.shuffle()
	
	# Create token container at bottom
	var hbox = HBoxContainer.new()
	hbox.position = Vector2(50, get_viewport_rect().size.y - 150)
	token_container.add_child(hbox)
	
	for symbol in shuffled_symbols:
		var token = _create_token(str(symbol))
		hbox.add_child(token)

func _create_token(text: String) -> Control:
	var token = Panel.new()
	token.custom_minimum_size = Vector2(60, 60)
	token.set_meta("symbol", text)
	token.set_meta("is_draggable", true)
	
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 32)
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	token.add_child(label)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.4, 0.6, 0.8)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	token.add_theme_stylebox_override("panel", style)
	
	token.gui_input.connect(_on_token_gui_input.bind(token))
	
	return token

var dragging_token = null
var drag_offset = Vector2.ZERO

func _on_token_gui_input(event: InputEvent, token: Control):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging_token = token
				drag_offset = token.global_position - event.global_position
				token.z_index = 10
			else:
				if dragging_token:
					_handle_drop(event.global_position)
					dragging_token.z_index = 0
					dragging_token = null
	
	elif event is InputEventMouseMotion and dragging_token:
		dragging_token.global_position = event.global_position + drag_offset

func _handle_drop(drop_position: Vector2):
	if not dragging_token:
		return
	
	var symbol = dragging_token.get_meta("symbol")
	
	# Find nearest drop zone
	var nearest_zone = null
	var min_distance = INF
	
	for zone in drop_zone_container.get_children():
		var zone_center = zone.global_position + zone.size / 2
		var distance = drop_position.distance_to(zone_center)
		if distance < min_distance and distance < 100:
			min_distance = distance
			nearest_zone = zone
	
	if nearest_zone:
		var index = nearest_zone.get_meta("index")
		
		# Remove existing token in this zone
		for child in nearest_zone.get_children():
			child.queue_free()
		
		placed_tokens[index] = symbol
		
		# Visual feedback
		var placed_label = Label.new()
		placed_label.text = symbol
		placed_label.add_theme_font_size_override("font_size", 32)
		placed_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
		nearest_zone.add_child(placed_label)
		
		dragging_token.queue_free()
		
		# Check if all placed
		if placed_tokens.size() == symbol_positions.size():
			_validate_placement()
	else:
		# Return token to original position
		dragging_token.position = Vector2(50, get_viewport_rect().size.y - 150)

func _validate_placement():
	var all_correct = true
	var correct_count = 0
	
	for i in symbol_positions.size():
		if i in placed_tokens:
			if placed_tokens[i] == symbol_positions[i].symbol:
				correct_count += 1
			else:
				all_correct = false
		else:
			all_correct = false
	
	var result = {
		"correct": all_correct,
		"time_taken": Time.get_ticks_msec() / 1000.0 - start_time,
		"correct_placements": correct_count,
		"total_placements": symbol_positions.size()
	}
	
	SignalBus.session_completed.emit(result)
	
	# Check repetitions
	var config = GameManager.current_session
	config.current_rep += 1
	
	if config.current_rep < config.repetitions:
		# Reset
		for child in symbol_container.get_children():
			child.queue_free()
		for child in token_container.get_children():
			child.queue_free()
		for child in drop_zone_container.get_children():
			child.queue_free()
		
		display_area.visible = true
		input_area.visible = false
		
		await get_tree().create_timer(1.0).timeout
		_setup_session()
	else:
		SignalBus.scene_change_requested.emit("results")
