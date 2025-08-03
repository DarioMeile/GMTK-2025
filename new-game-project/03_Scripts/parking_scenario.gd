class_name Case_Scenario_1
extends Node3D

@export_category("Load Resources")
@export var CONTROLLABLE_ENTITY: Controllable_Entity
@export var CAR_MARKER_SOLUTION: Array[Marker3D]
@export var CAR_INTERACTUABLES: Array[Interactuable_Object]

#Trigger areas
@onready var lightArea:= %LightArea
var LInPlace: bool = false
var solutionOne: bool = false
#NPCs
@onready var criminalCar:= $NPC_1/CriminalCar
@onready var criminalNPC:= $NPC_2/ParkingCriminal

var parkingSlotOpen: bool = false #true IS OK
var parkingMarkerOpen: Marker3D

enum scenarioState {init, startingScene, rewinding, playerControlling, waiting}
var currentScenarioState = scenarioState.init

func _ready() -> void:
	if get_parent() is SubViewport: #is not main scene
		return

func _process(delta: float) -> void:
	match currentScenarioState:
		scenarioState.init:
			pass
		scenarioState.startingScene:
			currentScenarioState = scenarioState.waiting
			if LInPlace:
				pass
		scenarioState.rewinding:
			parkingSlotOpen = false
			LInPlace = false
			solutionOne = false
		scenarioState.playerControlling:
			var _LInPlace: bool = false
			for _area in lightArea.get_overlapping_areas():
				if _area.get_parent() is Interactuable_Object:
					if _area.get_parent().OBJECT_NAME == "Lantern":
						_LInPlace = true
						break
			LInPlace = _LInPlace
		scenarioState.waiting:
			pass

	if get_parent() is SubViewport: #is not main scene
		return

func _space_open(_marker: int):
	parkingSlotOpen = true

func _space_occupied(_marker: int):
	if parkingMarkerOpen == null:
		return

func _startScene():
	currentScenarioState = scenarioState.startingScene
	for n in CAR_MARKER_SOLUTION.size():
		if !CAR_MARKER_SOLUTION[n].HAS_CAR:
			criminalCar._found_solution_id(n)
			criminalNPC._found_solution_id(n)
			solutionOne = true
			get_tree().call_group("Main", "_both_solutions")
			break
	get_tree().call_group("NPC", "_start_npc")
	CONTROLLABLE_ENTITY._start_of_scene()
	get_tree().call_group("Interactuable_Object", "_start_of_scene")

func _rewinding():
	get_tree().call_group("NPC", "_rewind_npc")
	get_tree().call_group("Interactuable_Object", "_rewind_object")

func _player_controlling_scene():
	currentScenarioState = scenarioState.playerControlling
	CONTROLLABLE_ENTITY._start_controlling()
	get_tree().call_group("Interactuable_Object", "_enable_entity", true)
