extends Node

# Navigation signals
signal scene_change_requested(scene_path)
signal mode_selected(mode_name)

# Session signals
signal session_started(config)
signal session_completed(results)

# Blitzlesen signals
signal symbol_sequence_completed
signal input_validated(correct)

# Lese-Landkarte signals
signal token_dropped(token, position)
signal placement_validated(results)
