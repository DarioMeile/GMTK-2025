class_name Controllable_Entity
extends CharacterBody3D


@export_category("Load Resources")
@export_group("External")
@export_subgroup("Perspective Textures")
@export var PERSPECTIVE_TEXTURE_A: Sprite3D
@export var PERSPECTIVE_TEXTURE_B: Sprite3D
@export var PERSPECTIVE_TEXTURE_C: Sprite3D
@export var PERSPECTIVE_TEXTURE_D: Sprite3D
@export_subgroup("Location Markers")
@export var SPAWN_MARKER: Marker3D
@export_category("Behavior and General Information")
@export var MOVEMENT_SPEED: float = 4 #Will follow movement MOVEMENT_SPEED determined by the spawn marker, if less than the total, will remain at the last one.


@onready var animPlayer:= $AnimationPlayer
@onready var objectTransform:= %Object

var liftingSomething: bool = false
var droppingSomething: bool = false
var liftingPossibilities: Array[Interactuable_Object]

var enabled: bool = false

func _ready():
	pass

func _process(delta: float) -> void:
	pass

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if !enabled:
		return

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("ui_right", "ui_left", "ui_down", "ui_up")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * MOVEMENT_SPEED
		velocity.z = direction.z * MOVEMENT_SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, MOVEMENT_SPEED)
		velocity.z = move_toward(velocity.z, 0, MOVEMENT_SPEED)

	move_and_slide()


func _start_of_scene():
	#animTreeStateMachine.start("Disappear")
	enabled = false
	liftingSomething = false
	liftingPossibilities.clear()
	await get_tree().create_timer(1).timeout
	position.x = SPAWN_MARKER.global_position.x
	position.z = SPAWN_MARKER.global_position.z
	hide()

func _start_controlling():
	enabled = true
	#animTreeStateMachine.start("Appear")
	show()

func _enable(_enable: bool = false):
	if !_enable:
		enabled = false
	else:
		enabled = true


func _lifting():
	for _sprite in $Sprites.get_children():
		_sprite.hide()
	$Sprites/FrontPerspectiveLifting.show()

func _putDown():
	for _sprite in $Sprites.get_children():
		_sprite.show()
	$Sprites/FrontPerspectiveLifting.hide()
