extends RigidBody3D

@export_category("Load Resources")
@export_group("External")
@export_subgroup("Location Markers")
@export var SPAWN_MARKER: Marker3D
@export_category("Behavior and Information")
@export var OBJECT_NAME: String = "Placeholder"


enum state {init, canBeInteracted, isLifted, restart, waiting}
var currentState: int = state.init

var character: Controllable_Entity
var enabled: bool = false
var nodeMarker: Node3D
var initialYPosition: float = 0.0

func _process(_delta: float):
	match currentState:
		state.init:
			pass
		state.canBeInteracted:
			pass
		state.isLifted:
			pass
		state.restart:
			pass
		state.waiting:
			pass

func _start_of_scene():
	enabled = false
	currentState = state.init

func _rewind_object():
	position = SPAWN_MARKER.global_position

func _enable_entity(_enable: bool = false):
	enabled = _enable
