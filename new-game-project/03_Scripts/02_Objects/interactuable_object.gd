class_name Interactuable_Object
extends RigidBody3D

@export_category("Load Resources")
@export_group("External")
@export_subgroup("Perspective Textures")
@export var PERSPECTIVE_TEXTURE_A: Resource
@export var PERSPECTIVE_TEXTURE_B: Resource
@export var PERSPECTIVE_TEXTURE_C: Resource
@export var PERSPECTIVE_TEXTURE_D: Resource
@export_subgroup("Location Markers")
@export var SPAWN_MARKER: Marker3D
@export_category("Behavior and Information")
@export var OBJECT_NAME: String = "Placeholder"
@export_group("Outline Shader")
@export var OUTLINE_SCALE: float = 2.135
@export_group("Perspective Control")
@export var TEXTURE_A_PIXEL_SIZE: float = 0.0
@export var TEXTURE_B_PIXEL_SIZE: float = 0.01
@export var TEXTURE_C_PIXEL_SIZE: float = 0.01
@export var TEXTURE_D_PIXEL_SIZE: float = 0.01


#Load nodes
@onready var textureA: = %PerspectiveA
@onready var textureB: = %PerspectiveB
@onready var textureC: = %PerspectiveC
@onready var textureD: = %PerspectiveD

enum state {init, canBeInteracted, isLifted, restart, waiting}
var currentState: int = state.init

var character: Controllable_Entity
var enabled: bool = false
var downPosition
var initialYPosition: float = 0.0

func _process(_delta: float):
	match currentState:
		state.init:
			if textureA.texture == null:
				textureA.texture = PERSPECTIVE_TEXTURE_A
				textureB.texture = PERSPECTIVE_TEXTURE_B
				textureC.texture = PERSPECTIVE_TEXTURE_C
				textureD.texture = PERSPECTIVE_TEXTURE_D
			if TEXTURE_A_PIXEL_SIZE > 0.0:
				textureA.pixel_size = TEXTURE_A_PIXEL_SIZE
				textureB.pixel_size = TEXTURE_B_PIXEL_SIZE
				textureC.pixel_size = TEXTURE_C_PIXEL_SIZE
				textureD.pixel_size = TEXTURE_D_PIXEL_SIZE
		state.canBeInteracted:
			if Input.is_action_just_pressed("ui_accept"):
				currentState = state.isLifted
				character.liftingSomething = true
				_show_outline(false)
		state.isLifted:
			global_position = Vector3(character.position.x, character.position.y+3, character.position.z)
			if Input.is_action_just_pressed("ui_accept"):
				currentState = state.waiting
				global_position.y = initialYPosition
				character.liftingSomething = false
				currentState = state.canBeInteracted
				_show_outline(true)
		state.restart:
			pass
		state.waiting:
			pass

func _show_outline(_show: bool = false):
	var _scale: float = 0.0
	if _show:
		_scale = OUTLINE_SCALE
	$CSGBox3D.material_overlay.set("shader_parameter/scale", _scale)
	$CSGBox3D.material_overlay.set("shader_parameter/outline_spread", _scale)

func _start_of_scene():
	enabled = false
	currentState = state.init
	position = SPAWN_MARKER.global_position

func _enable_entity(_enable: bool = false):
	enabled = _enable


func _on_area_3d_body_entered(body: Node3D) -> void:
	if !enabled:
		return
	if body is Controllable_Entity and currentState != state.isLifted:
		if body.liftingSomething: #Already lifting something
			return
		character = body
		initialYPosition = global_position.y
		currentState = state.canBeInteracted
		_show_outline(true)
		print("Player is IN range to interact with " + OBJECT_NAME)
	#elif body is Controllable_Entity: #CHANGE FOR THE CLASS RELATED TO DOWN POSITIONS
	#	if currentState != state.isLifted: #Is not being lifted
	#		return
	#	downPosition = body.position
	#	canBePutDown = true
	#	_show_outline(true)


func _on_area_3d_body_exited(body: Node3D) -> void:
	if !enabled:
		return
	if body is Controllable_Entity and currentState != state.isLifted:
		currentState = state.waiting
		_show_outline(false)
		print("Player is OUT of range to interact with " + OBJECT_NAME)
	#elif body is Controllable_Entity: #CHANGE FOR THE CLASS RELATED TO DOWN POSITIONS
	#	if currentState != state.isLifted: #Is not being lifted
	#		return
	#	canBePutDown = false
	#	_show_outline(false)
