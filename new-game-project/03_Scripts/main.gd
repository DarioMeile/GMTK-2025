class_name Main_Scene
extends Node3D

@export_category("Load Resources")
@export_group("Internal")
@export_subgroup("Pikachus")
@export var PIKACHU_REAL: CharacterBody3D
@export var PIKACHU_CRT: CharacterBody3D
@export_subgroup("Cameras")
@export var ROOM_CAMERA: PhantomCamera3D
@export var DOOR_CAMERA: PhantomCamera3D
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
@export_group("Tweens")
@export var FADE_TO_BLACK_TIMER: float = 0.25

#Get nodes
@onready var roomLight := %RoomLight
@onready var tapeNodes := %"VHS-Tapes"
@onready var board := %Board
@onready var blackScreen := %BlackScreen

#Dialogue nodes
@onready var dialogueNode:= %Dialogue
@onready var dialogueLabel:= %DialogueTextLabel
#Notification nodes
@onready var itemNotificationNode:= %ItemLabels
@onready var itemNotificationLabel:= %ItemNotificationLabel
@onready var buttonNotificationNode:= %ButtonNotification
@onready var buttonNotificationLabel:= %ButtonLabel

var enabled: bool = true
var lightTimer: float = 0.0
var transitioningLight: bool = false
var lightOn: bool = false

##Overall control
enum state {init, introduction, initialDialogue, waitingForInput, startSelecting, selectingPerspective, waiting}
var currentState: int = state.init

##Introduction control
var showingButtonTimer: float = 4.0
var turnOnTVShowed: bool = false
var doorDialoguePassed: bool = false
var vhsFirstWatch: bool = false
var totemWatched: bool = false

##Room control
enum roomPerspectives {room, tapes, tv, rightWall, door}
enum interactuableObject {nothing, tv, vhsTapes, board}
var currentRoomPerspective: int = roomPerspectives.room
var currentInteractuableObject: int = interactuableObject.nothing

##Tape control
enum tapeState {init, selecting, viewing, selected, waiting}
var currentTapeState: int = tapeState.init
var tapesInserted: bool = false

##TV control
enum tvState {init, firstWatch, selecting, controlling, waitingForInput, watching, waiting}
var firstWatched: bool = false
var currentTvState = tvState.init
var tvOn: bool = false

##Board control
enum boardState {init, selecting, controling}
var currentBoardState = boardState.init


func _ready() -> void:
	blackScreen.show()
	dialogueNode.hide()
	tapeNodes.hide()
	itemNotificationNode.hide()
	buttonNotificationNode.hide()
	dialogueLabel.text = ""
	var _pauses = get_tree().get_nodes_in_group("Pause_Overlay")
	for _pause in _pauses:
		_pause.hide()
	var _plays = get_tree().get_nodes_in_group("Play_Overlay")
	for _play in _plays:
		_play.hide()
	get_tree().call_group("TV", "_turn_screen", false)
	board.material_overlay.set("shader_parameter/scale", 0)
	board.material_overlay.set("shader_parameter/outline_spread", 0)
	get_tree().call_group("TV", "_outline_meshes", false, 0)
	get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
	await get_tree().create_timer(0.5).timeout
	_fade_to_black(false)

func _process(delta: float) -> void:
	_flicker_light(delta)
	match currentState:
		state.init:
			currentState = state.waiting
			await get_tree().create_timer(1).timeout
			currentState = state.introduction
		state.selectingPerspective:
			_room_perspective_control(delta)
		state.introduction:
			showingButtonTimer -= delta
			if showingButtonTimer < 0 and showingButtonTimer > -100:
				buttonNotificationLabel.text = "PRESS [ACCEPT] TO START"
				buttonNotificationNode.show()
				showingButtonTimer = -100
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
				currentState = state.initialDialogue
				buttonNotificationNode.hide()
				DOOR_CAMERA.priority = 2
		state.initialDialogue:
			currentState = state.waiting
			await get_tree().create_timer(0.1).timeout
			dialogueNode.show()
			await get_tree().create_timer(0.1).timeout
			dialogueLabel.clear()
			dialogueLabel.visible_characters = 0
			dialogueLabel.show()
			dialogueLabel.append_text("[wave amp=50.0 freq=5.0 connected=1]KNOCK KNOCK[/wave]\n")
			dialogueLabel.append_text("We received the VHS tapes from the packing security cameras, see if you can find anything.")
			var _tween = create_tween()
			_tween.set_ease(Tween.EASE_IN)
			_tween.set_parallel(false)
			_tween.tween_property(dialogueLabel, "visible_characters", 12, 0.4).from(0)
			_tween.tween_interval(1)
			_tween.tween_property(dialogueLabel, "visible_characters", 102, 2).from(12)
			await _tween.finished
			tapeNodes.show()
			_showItemNotification("RECEIVED VHS TAPES")
			currentState = state.waitingForInput
		state.waitingForInput:
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
				currentState = state.selectingPerspective
				dialogueLabel.clear()
				dialogueLabel.visible_characters = 0
				dialogueLabel.text = ""
				dialogueNode.hide()
				DOOR_CAMERA.priority = 0
		state.waiting:
			pass



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
						currentTvState = tvState.init
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
			showingButtonTimer = 4.0
		tapeState.selecting:
			showingButtonTimer -= delta
			if showingButtonTimer < 0 and showingButtonTimer > -100:
				buttonNotificationLabel.text = "PRESS [ACCEPT] TO INSERT TAPES"
				buttonNotificationNode.show()
				showingButtonTimer = -100
			if Input.is_action_just_pressed("ui_cancel"):
				TAPES_CAMERA.priority = 0
				board.material_overlay.set("shader_parameter/scale", 0)
				board.material_overlay.set("shader_parameter/outline_spread", 0)
				get_tree().call_group("TV", "_outline_meshes", false, 0)
				get_tree().call_group("VHS_Tapes", "_outline_meshes", true)
				currentRoomPerspective = roomPerspectives.room
				buttonNotificationNode.hide()
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
				buttonNotificationNode.hide()
				get_tree().call_group("TV", "_turn_screen", tvOn, tapesInserted)
				var _pauses = get_tree().get_nodes_in_group("Pause_Overlay")
				for _pause in _pauses:
					_pause.show()
				_showItemNotification("INSERTED SECURITY TAPES")
		tapeState.viewing:
			pass
		tapeState.selected:
			pass

func _tv_perspective_control(delta: float):
	match currentTvState:
		tvState.init:
			if !turnOnTVShowed:
				buttonNotificationLabel.text = "PRESS [ACCEPT] TO TURN ON THE TVs"
				buttonNotificationNode.show()
			get_tree().call_group("ControllableEntity", "_enable", tvOn)
			if tvOn and tapesInserted and !firstWatched:
				currentTvState = tvState.firstWatch
				return
			currentTvState = tvState.selecting
		tvState.firstWatch:
			firstWatched = true
			currentTvState = tvState.waiting
			dialogueNode.show()
			dialogueLabel.clear()
			dialogueLabel.visible_characters = 0
			dialogueLabel.show()
			dialogueLabel.append_text("[i][color=olive]...Hmmm,\n")
			dialogueLabel.append_text("let me check the tapes first...[/color][/i]")
			var _tween = create_tween()
			_tween.set_ease(Tween.EASE_IN)
			_tween.set_parallel(false)
			_tween.tween_property(dialogueLabel, "visible_characters", 9, 0.4).from(0)
			_tween.tween_interval(1)
			_tween.tween_property(dialogueLabel, "visible_characters", 40, 0.8).from(9)
			await _tween.finished
			currentTvState = tvState.waitingForInput
		tvState.selecting:
			if Input.is_action_just_pressed("ui_cancel"):
				if !turnOnTVShowed:
					buttonNotificationNode.hide()
				TV_CAMERA.priority = 0
				board.material_overlay.set("shader_parameter/scale", 0)
				board.material_overlay.set("shader_parameter/outline_spread", 0)
				get_tree().call_group("TV", "_outline_meshes", true, 0)
				get_tree().call_group("VHS_Tapes", "_outline_meshes", false)
				get_tree().call_group("ControllableEntity", "_enable", false)
				currentRoomPerspective = roomPerspectives.room
			if Input.is_action_just_pressed("ui_accept"):
				if !turnOnTVShowed:
					turnOnTVShowed = true
					buttonNotificationNode.hide()
				if tvOn:
					tvOn = false
				else:
					tvOn = true
				get_tree().call_group("TV", "_turn_screen", tvOn, tapesInserted)
				if tapesInserted:
					if !firstWatched:
						currentTvState = tvState.firstWatch
						return
					get_tree().call_group("ControllableEntity", "_enable", tvOn)
		tvState.controlling:
			pass
		tvState.waiting:
			pass
		tvState.waitingForInput:
			if Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("ui_left") or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_down"):
				currentTvState = tvState.waiting
				dialogueLabel.clear()
				dialogueLabel.visible_characters = 0
				dialogueLabel.text = ""
				dialogueNode.hide()
				var _pauses = get_tree().get_nodes_in_group("Pause_Overlay")
				for _pause in _pauses:
					_pause.hide()
				var _plays = get_tree().get_nodes_in_group("Play_Overlay")
				for _play in _plays:
					_play.show()
				await get_tree().create_timer(0.4).timeout
				for _play in _plays:
					_play.hide()
				currentTvState = tvState.watching


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


##Tweens and Animations

func _fade_to_black(_black: bool = true):
	var _alpha: int = 0
	if _black:
		_alpha = 1
	var _tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_CUBIC)
	blackScreen.show()
	_tween.tween_property(blackScreen, "modulate", Color(1,1,1,_alpha), FADE_TO_BLACK_TIMER).from_current()
	await _tween.finished
	if !_black:
		blackScreen.hide()

func _showItemNotification(_text: String):
	itemNotificationLabel.text = _text
	itemNotificationNode.modulate.a = 0
	itemNotificationNode.show()
	var _tween = create_tween()
	_tween.set_ease(Tween.EASE_IN)
	_tween.set_trans(Tween.TRANS_CUBIC)
	_tween.set_parallel(false)
	_tween.tween_property(itemNotificationNode, "modulate:a", 1, 0.1).from_current()
	_tween.tween_interval(2)
	_tween.tween_property(itemNotificationNode, "modulate:a", 0, 0.1).from(1)
	await _tween.finished
	itemNotificationNode.hide()

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
