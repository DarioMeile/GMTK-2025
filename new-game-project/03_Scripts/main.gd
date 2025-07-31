extends Node3D

@export_category("Load Resources")
@export_group("Internal")
@export_subgroup("Pikachus")
@export var PIKACHU_REAL: CharacterBody3D
@export var PIKACHU_CRT: CharacterBody3D

@onready var enabled: bool = true

func _ready() -> void:
	PIKACHU_REAL.enabled = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		if enabled:
			enabled = false
			PIKACHU_REAL.enabled = false
			PIKACHU_CRT.enabled = true
		else:
			enabled = true
			PIKACHU_REAL.enabled = true
			PIKACHU_CRT.enabled = false
