class_name Interactuable_Car
extends Interactuable_Object

var downPosition: Vector3
var canBePutDown: bool = false
var currentMarker: Marker3D

func _process(_delta: float):
	match currentState:
		state.init:
			currentMarker = SPAWN_MARKER
			pass
		state.canBeInteracted:
			if Input.is_action_just_pressed("ui_accept") and character.liftingPossibilities.size() > 0:
				currentMarker.HAS_CAR = false
				if character.liftingPossibilities[0] != self:
					return
				currentState = state.isLifted
				character.liftingSomething = true
				character._lifting()
				_show_outline(false)
		state.isLifted:
			#global_position = Vector3(character.position.x, character.position.y+3, character.position.z)
			global_position = nodeMarker.global_position
			if Input.is_action_just_pressed("ui_accept") and canBePutDown:
				currentState = state.waiting
				global_position.y = initialYPosition
				global_position.x = downPosition.x
				global_position.z = downPosition.z
				character.liftingSomething = false
				character._putDown()
				currentMarker.HAS_CAR = true
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

func _start_of_scene():
	enabled = false
	currentState = state.init

func _rewind_object():
	position = SPAWN_MARKER.global_position
	currentMarker = SPAWN_MARKER

func _enable_entity(_enable: bool = false):
	enabled = _enable


func _on_area_3d_body_entered(body: Node3D) -> void:
	if !enabled:
		return
	if body is Controllable_Entity and currentState != state.isLifted:
		if body.liftingSomething: #Already lifting something
			return
		if !body.liftingPossibilities.has(self):
			body.liftingPossibilities.append(self)
		character = body
		nodeMarker = character.objectTransform
		initialYPosition = global_position.y
		currentState = state.canBeInteracted
		_show_outline(true)
		print("Player is IN range to interact with " + OBJECT_NAME)



func _on_area_3d_body_exited(body: Node3D) -> void:
	if !enabled:
		return
	if body is Controllable_Entity and currentState != state.isLifted:
		if body.liftingPossibilities.has(self):
			body.liftingPossibilities.erase(self)
		currentState = state.waiting
		_show_outline(false)
		print("Player is OUT of range to interact with " + OBJECT_NAME)
	#elif body is Controllable_Entity: #CHANGE FOR THE CLASS RELATED TO DOWN POSITIONS
	#	if currentState != state.isLifted: #Is not being lifted
	#		return
	#	canBePutDown = false
	#	_show_outline(false)


func _on_area_3d_area_entered(area: Area3D) -> void:
	if !enabled:
		return
	if area.get_parent() is Car_Marker_Slot or area.get_parent() is Car_Marker_General: #CHANGE FOR THE CLASS RELATED TO DOWN POSITIONS
		if currentState != state.isLifted: #Is not being lifted
			return
		if area.get_parent().HAS_CAR:
			return
		currentMarker = area.get_parent()
		downPosition = area.get_parent().position
		canBePutDown = true
		_show_outline(true)

func _on_area_3d_area_exited(area: Area3D) -> void:
	if !enabled:
		return
	if area.get_parent() is Car_Marker_Slot or area.get_parent() is Car_Marker_General: #CHANGE FOR THE CLASS RELATED TO DOWN POSITIONS
		if currentState != state.isLifted: #Is not being lifted
			return
		downPosition = area.get_parent().position
		canBePutDown = false
		_show_outline(false)
