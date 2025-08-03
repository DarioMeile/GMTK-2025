@tool
class_name CRT_TV
extends RigidBody3D

@export_category("Debug")
@export var FUNCTION_AS_TOOL: bool = false
@export_category("Load Resources")
@export_group("External")
@export_subgroup("Viewports")
@export var VIEWPORT: NodePath
@export_group("Internal")
@export var OFF_SCREEN: CSGBox3D
@export var VIEWPORT_SCREEN: CSGBox3D
@export_subgroup("Meshes")
@export var TV_MESH: MeshInstance3D
@export var VHS_MESH: MeshInstance3D
@export_category("Behavior & Information")
@export var DISABLED: bool = false
@export_group("VHS Tape Information")
@export var SIDE_STRING: String = "Placeholder"

@onready var tvIsOn: bool = false

##Get nodes
@onready var sideLabel:= %SideLabel

func _ready() -> void:
	if DISABLED:
		OFF_SCREEN.show()
		VIEWPORT_SCREEN.hide()
		TV_MESH.material_overlay.set("shader_parameter/scale", 0)
		TV_MESH.material_overlay.set("shader_parameter/outline_spread", 0)
		VHS_MESH.material_overlay.set("shader_parameter/scale", 0)
		VHS_MESH.material_overlay.set("shader_parameter/outline_spread", 0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		if FUNCTION_AS_TOOL:
			if Input.is_action_just_pressed("ui_accept") and Input.is_action_pressed("ui_filedialog_show_hidden"):
				match tvIsOn:
					true:
						tvIsOn = false
					false:
						tvIsOn = true
				_turn_screen(tvIsOn)
		return

func _set_viewport():
	if DISABLED:
		return
	VIEWPORT_SCREEN.material_override.albedo_texture.set("viewport_path", VIEWPORT)

func _show_string(_show: bool = true, _string: String = SIDE_STRING):
	if DISABLED:
		return
	match _show:
		true:
			sideLabel.show()
			sideLabel.text = _string
		false:
			sideLabel.hide()



func _outline_meshes(_true: bool, _mesh: int = 0):
	if DISABLED:
		return
	var _outlineSize: int = 2
	if !_true:
		_outlineSize = 0
	match _mesh:
		0:
			TV_MESH.material_overlay.set("shader_parameter/scale", _outlineSize)
			TV_MESH.material_overlay.set("shader_parameter/outline_spread", _outlineSize)
			VHS_MESH.material_overlay.set("shader_parameter/scale", _outlineSize)
			VHS_MESH.material_overlay.set("shader_parameter/outline_spread", _outlineSize)
		1:
			TV_MESH.material_overlay.set("shader_parameter/scale", _outlineSize)
			TV_MESH.material_overlay.set("shader_parameter/outline_spread", _outlineSize)
		2:
			VHS_MESH.material_overlay.set("shader_parameter/scale", _outlineSize)
			VHS_MESH.material_overlay.set("shader_parameter/outline_spread", _outlineSize)


func _turn_screen(_on: bool = true, _tapeInside: bool = false):
	if DISABLED:
		return
	match _on:
		true:
			OFF_SCREEN.hide()
			if _tapeInside:
				_set_viewport()
				VIEWPORT_SCREEN.show()
				return
			VIEWPORT_SCREEN.hide()
		false:
			OFF_SCREEN.show()
			VIEWPORT_SCREEN.hide()
