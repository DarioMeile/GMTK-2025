class_name VHS_Tape_Object
extends RigidBody3D

@export_category("Debug")
@export var FUNCTION_AS_TOOL: bool = false
@export_category("Load Resources")
@export_group("External")
@export_group("Internal")
@export_subgroup("Meshes")
@export var VHS_MESH: MeshInstance3D
@export_category("Information & Behavior")
@export_group("VHS Tape Information")
@export var TOP_STRING: String = "Placeholder"
@export var SIDE_STRING: String = "Placeholder"

##Get nodes
@onready var topLabel:= %TopLabel
@onready var sideLabel:= %SideLabel

func _ready() -> void:
	_updateLabels()

func _outline_meshes(_true: bool):
	var _outlineSize: int = 2
	if !_true:
		_outlineSize = 0
	VHS_MESH.material_overlay.set("shader_parameter/scale", _outlineSize)
	VHS_MESH.material_overlay.set("shader_parameter/outline_spread", _outlineSize)

func _updateLabels(_topString: String = TOP_STRING, _sideString: String = SIDE_STRING):
	topLabel.text = _topString
	sideLabel.text = _sideString
