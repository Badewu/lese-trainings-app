extends Control

@onready var title_label = $VBoxContainer/TitleLabel
@onready var blitzlesen_button = $VBoxContainer/ModesContainer/BlitzlesenButton
@onready var landkarte_button = $VBoxContainer/ModesContainer/LandkarteButton

func _ready():
	blitzlesen_button.pressed.connect(_on_blitzlesen_pressed)
	landkarte_button.pressed.connect(_on_landkarte_pressed)

func _on_blitzlesen_pressed():
	GameManager.current_session["mode"] = "blitzlesen"
	SignalBus.scene_change_requested.emit("session_setup")

func _on_landkarte_pressed():
	GameManager.current_session["mode"] = "lese_landkarte"
	SignalBus.scene_change_requested.emit("session_setup")
