class_name Main_Scene
extends Node3D

@export_category("Load Resources")
@export_group("Internal")
@export_subgroup("Pikachus")
@export var PIKACHU_REAL: CharacterBody3D
@export var PIKACHU_CRT: CharacterBody3D
@export_subgroup("Cameras")
@export var ROOM_CAMERA: PhantomCamera3D
@export var TV_CAMERA: PhantomCamera3D
@export var TAPES_CAMERA: PhantomCamera3D
@export var BOARD_CAMERA: PhantomCamera3D
@export_subgroup("TVs")
@export var TV_NODES: Array[CRT_TV]
@export_subgroup("Tapes")
@export var TAPE_NODES: Array[VHS_Tape_Object]
@export_category("Room Behavior")
@export_group("Light Control")
@export var FLICKERING_LIGHTS: bool = true
@export_range(0.01,0.1,0.01, "suffix:s") var FLICKERING_LIGHT_OFF_TIMER_MIN: float = 0.01
@export_range(0.01,0.5,0.01, "suffix:s") var FLICKERING_LIGHT_OFF_TIMER_MAX: float = 0.01
@export_range(0.1,3,0.1, "suffix:s") var FLICKERING_LIGHT_ON_TIMER_MIN: float = 2
@export_range(0.1,6,0.1, "suffix:s") var FLICKERING_LIGHT_ON_TIMER_MAX: float = 4


#Get nodes
@onready var roomLight := %RoomLight
@onready var tapeNodes := %"VHS-Tapes"
@onready var board := %Board

var enabled: bool = true
var lightTimer: float = 0.0
var transitioningLight: bool = false
var lightOn: bool = false

##Overall control
enum state {init, selectingPerspective}
var currentState: int = state.init

##Room control
enum roomPerspectives {room, tapes, tv, rightWall}
enum interactuableObject {nothing, tv, vhsTapes, board}
var currentRoomPerspective: int = roomPerspectives.room
var currentInteractuableObject: int = interactuableObject.nothing

##Tape control
enum tapeState {init, selecting, viewing, selected}
var currentTapeState: int = tapeState.init
var tapesInserted: bool = false

##TV control
enum tvState {init, selecting, controling}
var currentTvState = tvState.init
var tvOn: bool = false

##Board control
enum boardState {init, selecting, controling}
var currentBoardState = boardState.init


func _ready() -> void:
	get_tree().call_group("TV", "_turn_screen", false)

func _process(delta: float) -> void:
	_flicker_light(delta)
	match currentState:
		state.init:
			currentState = state.selectingPerspective
		state.selectingPerspective:
			_room_perspective_control(delta)



func _room_perspective_control(delta: float):
	match currentRoomPerspective:
		roomPerspectives.room:
			if Input.is_action_just_pressed("ui_left"):
				match currentInteractuableObject:
					interactuableObject.nothing:
						if tapesInserted:
							return
						currentInteractuableObject  = interactuableObject.vhsTapes
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", false, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", true)
					interactuableObject.tv:
						if tapesInserted:
							return
						currentInteractuableObject  = interactuableObject.vhsTapes
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", false, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", true)
					interactuableObject.vhsTapes:
						pass
					interactuableObject.board:
						currentInteractuableObject  = interactuableObject.tv
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", true, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
			if Input.is_action_just_pressed("ui_right"):
				match currentInteractuableObject:
					interactuableObject.nothing:
						currentInteractuableObject  = interactuableObject.tv
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", true, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
					interactuableObject.tv:
						currentInteractuableObject  = interactuableObject.board
						board.material_overlay.set("shader_parameter/scale", 2)
						board.material_overlay.set("shader_parameter/outline_spread", 2)
						get_tree().call_group("TV", "_outline_meshes", false, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
					interactuableObject.vhsTapes:
						currentInteractuableObject  = interactuableObject.tv
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", true, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
					interactuableObject.board:
						pass
			if Input.is_action_just_pressed("ui_accept"):
				match currentInteractuableObject:
					interactuableObject.nothing:
						pass
					interactuableObject.tv:
						currentRoomPerspective  = roomPerspectives.tv
						TV_CAMERA.priority = 2
						get_tree().call_group("TV", "_outline_meshes", false, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
					interactuableObject.vhsTapes:
						currentRoomPerspective  = roomPerspectives.tapes
						TAPES_CAMERA.priority = 2
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", false, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
					interactuableObject.board:
						currentRoomPerspective  = roomPerspectives.rightWall
						BOARD_CAMERA.priority = 2
						board.material_overlay.set("shader_parameter/scale", 0)
						board.material_overlay.set("shader_parameter/outline_spread", 0)
						get_tree().call_group("TV", "_outline_meshes", false, 0)
						get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
		roomPerspectives.tapes:
			_tapes_perspective_control(delta)
		roomPerspectives.tv:
			_tv_perspective_control(delta)
		roomPerspectives.rightWall:
			_board_perspective_control(delta)


func _tapes_perspective_control(delta: float):
	match currentTapeState:
		tapeState.init:
			currentTapeState = tapeState.selecting
		tapeState.selecting:
			if Input.is_action_just_pressed("ui_cancel"):
				TAPES_CAMERA.priority = 0
				board.material_overlay.set("shader_parameter/scale", 0)
				board.material_overlay.set("shader_parameter/outline_spread", 0)
				get_tree().call_group("TV", "_outline_meshes", false, 0)
				get_tree().call_group("VHS_Tapes", "_outline_meshes", true)
				currentRoomPerspective = roomPerspectives.room
			if Input.is_action_just_pressed("ui_accept"): #Put tapes inside TV
				for n in TAPE_NODES.size():
					var _tape: VHS_Tape_Object = TAPE_NODES[n]
					var _sideString: String = _tape.SIDE_STRING
					TV_NODES[n]._show_string(true, _sideString)
					_tape.hide()
				TAPES_CAMERA.priority = 0
				board.material_overlay.set("shader_parameter/scale", 0)
				board.material_overlay.set("shader_parameter/outline_spread", 0)
				get_tree().call_group("TV", "_outline_meshes", false, 0)
				get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
				currentRoomPerspective = roomPerspectives.room
				tapesInserted = true
		tapeState.viewing:
			pass
		tapeState.selected:
			pass

func _tv_perspective_control(delta: float):
	match currentTvState:
		tvState.init:
			currentTvState = tvState.selecting
		tvState.selecting:
			if Input.is_action_just_pressed("ui_cancel"):
				TV_CAMERA.priority = 0
				board.material_overlay.set("shader_parameter/scale", 0)
				board.material_overlay.set("shader_parameter/outline_spread", 0)
				get_tree().call_group("TV", "_outline_meshes", true, 0)
				get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
				currentRoomPerspective = roomPerspectives.room
			if Input.is_action_just_pressed("ui_accept"):
				if tvOn:
					tvOn = false
				else:
					tvOn = true
				get_tree().call_group("TV", "_turn_screen", tvOn, tapesInserted)
		tvState.controling:
			pass

func _board_perspective_control(delta: float):
	match currentBoardState:
		boardState.init:
			currentBoardState = boardState.selecting
		boardState.selecting:
			if Input.is_action_just_pressed("ui_cancel"):
				BOARD_CAMERA.priority = 0
				board.material_overlay.set("shader_parameter/scale", 2)
				board.material_overlay.set("shader_parameter/outline_spread", 2)
				get_tree().call_group("TV", "_outline_meshes", false, 0)
				get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
				currentRoomPerspective = roomPerspectives.room
		boardState.controling:
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
