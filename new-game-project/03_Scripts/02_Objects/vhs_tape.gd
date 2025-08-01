extends RigidBody3D

@export_category("Debug")
@export var FUNCTION_AS_TOOL: bool = false
@export_category("Load Resources")
@export_group("External")
@export_group("Internal")
@export_subgroup("Meshes")
@export var VHS_MESH: MeshInstance3D


func _outline_meshes(_true: bool):
	var _outlineSize: int = 2
	if !_true:
		_outlineSize = 0
	VHS_MESH.material_overlay.set("shader_parameter/scale", _outlineSize)
	VHS_MESH.material_overlay.set("shader_parameter/outline_spread", _outlineSize)
