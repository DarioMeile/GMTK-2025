class_name Case_Scenario_2
extends Node3D

@export_category("Load Resources")
@export var CONTROLLABLE_ENTITY: Controllable_Entity


#Trigger areas
@onready var wetSignNotArea:= %WetSignNotHereArea
@onready var fanArea:= %FanHereArea

#NPCs
@onready var fishermanNPC:= $NPC_1/Fisherman
@onready var storeLadyNPC:= $NPC_2/StoreLady
@onready var criminalNPC:= $NPC_3/StoreCriminal


var wetSignInPlace: bool = false #FALSE IS OK
var fanInPlace: bool = false #TRUE IS OK

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
			print("fanInplace: " + str(fanInPlace))
			print("wetSignInPlace: " + str(wetSignInPlace))
			if fanInPlace:
				fishermanNPC._found_solution()
			if !wetSignInPlace:
				storeLadyNPC._found_solution()
				criminalNPC._found_solution()
			if fanInPlace and !wetSignInPlace:
				criminalNPC.hatFlyOff = true
				_both_solutions()
		scenarioState.rewinding:
			fanInPlace = false
			wetSignInPlace = true
		scenarioState.playerControlling:
			#GET AREAS3D
			var _wetInPlace: bool = false
			for _area in wetSignNotArea.get_overlapping_areas():
				if _area.get_parent() is Interactuable_Object:
					if _area.get_parent().OBJECT_NAME == "Wet Floor Sign":
						_wetInPlace = true
						break
			wetSignInPlace = _wetInPlace
			var _fanInPlace: bool = false
			for _area in fanArea.get_overlapping_areas():
				if _area.get_parent() is Interactuable_Object:
					if _area.get_parent().OBJECT_NAME == "Store Fan":
						_fanInPlace = true
						break
			fanInPlace = _fanInPlace
		scenarioState.waiting:
			pass

	if get_parent() is SubViewport: #is not main scene
		return
	if Input.is_action_just_pressed("debug_key"):
		get_tree().call_group("NPC", "_start_npc")

func _startScene():
	currentScenarioState = scenarioState.startingScene
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

func _both_solutions():
	get_tree().call_group("Main", "_both_solutions")
