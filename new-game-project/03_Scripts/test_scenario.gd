class_name Case_Scenario
extends Node3D


func _ready() -> void:
	if get_parent() is SubViewport: #is not main scene
		return
	get_tree().call_group("ControllableEntity", "_enable", true)
