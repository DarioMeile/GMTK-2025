class_name Case_Scenario
extends Node3D


func _ready() -> void:
	if get_parent() is SubViewport: #is not main scene
		return
	get_tree().call_group("ControllableEntity", "_enable", true)

func _process(delta: float) -> void:
	if get_parent() is SubViewport: #is not main scene
		return
	if Input.is_action_just_pressed("debug_key"):
		get_tree().call_group("NPC", "_start_npc")

func _startScene():
	get_tree().call_group("NPC", "_start_npc")

func _rewinding():
	get_tree().call_group("NPC", "_rewind_npc")
