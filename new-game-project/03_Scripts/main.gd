class_name Main_Scene
extends Node3D

@export_category("Load Resources")
@export_group("Internal")
@export_subgroup("Pikachus")
@export var PIKACHU_REAL: CharacterBody3D
@export var PIKACHU_CRT: CharacterBody3D
@export_category("Room Behavior")
@export_group("Light Control")
@export var FLICKERING_LIGHTS: bool = true
@export_range(0.01,0.1,0.01, "suffix:s") var FLICKERING_LIGHT_OFF_TIMER_MIN: float = 0.01
@export_range(0.01,0.5,0.01, "suffix:s") var FLICKERING_LIGHT_OFF_TIMER_MAX: float = 0.01
@export_range(0.1,3,0.1, "suffix:s") var FLICKERING_LIGHT_ON_TIMER_MIN: float = 2
@export_range(0.1,6,0.1, "suffix:s") var FLICKERING_LIGHT_ON_TIMER_MAX: float = 4
@export_group("UI")
@export_subgroup("UI Button Indicators")
@export var UI_INDICATOR_UP: PanelContainer
@export var UI_INDICATOR_DOWN: PanelContainer
@export var UI_INDICATOR_LEFT: PanelContainer
@export var UI_INDICATOR_RIGHT: PanelContainer

@onready var roomLight:= %RoomLight
@onready var enabled: bool = true
var lightTimer: float = 0.0
var transitioningLight: bool = false
var lightOn: bool = false

#Room control
enum roomPerspectives {room, tapes, tv, rightWall}
var currentRoomPerspective: int = 0
var hoverIndex: int = 0

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	_flicker_light(delta)
	_room_perspective_control(delta)
	
	if Input.is_action_just_pressed("ui_accept"):
		pass
		#get_tree().call_group("TV", "_outline_meshes", true, 0)

func _room_perspective_control(delta: float):
	match currentRoomPerspective:
		roomPerspectives.room:
			pass
		roomPerspectives.tapes:
			pass
		roomPerspectives.tv:
			pass
		roomPerspectives.rightWall:
			pass

func _flicker_light(delta: float):
	if transitioningLight:
		return
	lightTimer -= delta
	if lightTimer < 0:
		transitioningLight = true
		match lightOn:
			true:
				var _tween = create_tween()
				_tween.set_ease(Tween.EASE_IN)
				_tween.set_trans(Tween.TRANS_EXPO)
				_tween.tween_property(roomLight, "light_energy", 0, 0.05).from_current()
				await _tween.finished
				var _rng = RandomNumberGenerator.new()
				lightTimer = _rng.randf_range(FLICKERING_LIGHT_OFF_TIMER_MIN, FLICKERING_LIGHT_OFF_TIMER_MAX)
				lightOn = false
				transitioningLight = false
			false:
				var _tween = create_tween()
				_tween.set_ease(Tween.EASE_IN)
				_tween.set_trans(Tween.TRANS_EXPO)
				_tween.tween_property(roomLight, "light_energy", 1, 0.05).from_current()
				await _tween.finished
				var _rng = RandomNumberGenerator.new()
				lightTimer = _rng.randf_range(FLICKERING_LIGHT_ON_TIMER_MIN, FLICKERING_LIGHT_ON_TIMER_MAX)
				lightOn = true
				transitioningLight = false
