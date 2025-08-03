class_name Car_Marker_Slot
extends Marker3D

@export var SOLUTION_ID: int = 0
@export var HAS_CAR: bool = true

@onready var area3D:= $Area3D

func _on_area_3d_area_entered(area: Area3D) -> void:
	if area.get_parent() is Interactuable_Car:
		get_tree().call_group("Scenario", "_space_occupied", SOLUTION_ID)


func _on_area_3d_area_exited(area: Area3D) -> void:
	if area.get_parent() is Interactuable_Car:
		get_tree().call_group("Scenario", "_space_open", SOLUTION_ID)
