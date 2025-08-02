class_name Case_Scenario
extends Node3D

@export_category("Load Resources")
@export var CONTROLLABLE_ENTITY: Controllable_Entity


enum scenarioState {init, startingScene, rewinding, playerControlling}
var currentScenarioState = scenarioState.init

func _ready() -> void:
	if get_parent() is SubViewport: #is not main scene
		return

func _process(delta: float) -> void:
	match currentScenarioState:
		scenarioState.init:
			pass
		scenarioState.startingScene:
			pass
		scenarioState.rewinding:
			pass
		scenarioState.playerControlling:
			pass
	if get_parent() is SubViewport: #is not main scene
		return
	if Input.is_action_just_pressed("debug_key"):
		get_tree().call_group("NPC", "_start_npc")

func _startScene():
	get_tree().call_group("NPC", "_start_npc")
	CONTROLLABLE_ENTITY._start_of_scene()
	get_tree().call_group("Interactuable_Object", "_start_of_scene")

func _rewinding():
	get_tree().call_group("NPC", "_rewind_npc")

func _player_controlling_scene():
	CONTROLLABLE_ENTITY._start_controlling()
	get_tree().call_group("Interactuable_Object", "_enable_entity", true)
