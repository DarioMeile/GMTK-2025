class_name Basic_NPC
extends CharacterBody3D

@export_category("Load Resources")
@export_group("External")
@export_subgroup("Perspective Textures")
@export var PERSPECTIVE_TEXTURE_A: Resource
@export var PERSPECTIVE_TEXTURE_B: Resource
@export var PERSPECTIVE_TEXTURE_C: Resource
@export var PERSPECTIVE_TEXTURE_D: Resource
@export_subgroup("Location Markers")
@export var SPAWN_MARKER: Marker3D
@export var LOCATION_MARKERS: Array[Marker3D] #Will follow the array in order, will remain idle at the last location marker
@export var LOCATION_MARKERS_SOLUTION: Array[Marker3D]
@export_category("Behavior and General Information")
@export_group("Spawn Behavior")
@export var APPEAR_AT_START: bool = true
@export_group("Timers")
@export var APPEAR_AT_START_TIMER: float = 0.0 #ONLY USED IF `APPEAR_AT_START == false`
@export var TIMER_BETWEEN_LOCATIONS: Array[float] #Will follow these timers in order. n = 0 Spawn point timer, if less than the total of markers, will follow the last one.
@export var TIMER_BETWEEN_LOCATIONS_SOLUTION: Array[float]
@export_group("Speed")
@export var MOVEMENT_SPEEDS: Array[float] = [4] #Will follow movement speed determined by the spawn marker, if less than the total, will remain at the last one.
@export var MOVEMENT_SPEEDS_SOLUTION: Array[float]

@onready var navigationAgent := %NavigationAgent3D

var locationIndex: int = 0
var useSolution: bool = false

enum npcState {init, startScene, idle, moving, reached, end, inactive, waiting}
var currentNpcState: int = npcState.init

#Navigation control
var navigationStarted: bool = false
var distanceToTarget: float = 0.0
var currentTarget

func _ready() -> void:
	navigationAgent.velocity_computed.connect(Callable(_on_velocity_computed))

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if NavigationServer3D.map_get_iteration_id(navigationAgent.get_navigation_map()) == 0:
		return
	if not is_on_floor():
		velocity += get_gravity() * delta
	match currentNpcState:
		npcState.init: #Initiate
			position.x = SPAWN_MARKER.global_position.x
			position.z = SPAWN_MARKER.global_position.z
			npcState.waiting
			show()
		npcState.startScene:
			if APPEAR_AT_START:
				currentNpcState = npcState.idle
				show()
			else:
				currentNpcState = npcState.waiting
				await get_tree().create_timer(APPEAR_AT_START_TIMER).timeout
				currentNpcState = npcState.idle
				show()
		npcState.idle:
			velocity.x = 0
			velocity.z = 0
			currentNpcState = npcState.waiting #GET OUT OF IDLE, SO CODE ONLY RUNS ONCE
			var _index: int
			if useSolution:
				_index = TIMER_BETWEEN_LOCATIONS_SOLUTION.size() - 1 #GET LAST IF NEEDED
				if locationIndex < TIMER_BETWEEN_LOCATIONS_SOLUTION.size(): #CAN ENTER
					_index = locationIndex
				await get_tree().create_timer(TIMER_BETWEEN_LOCATIONS_SOLUTION[_index]).timeout
			else:
				_index = TIMER_BETWEEN_LOCATIONS.size() - 1 #GET LAST IF NEEDED
				if locationIndex < TIMER_BETWEEN_LOCATIONS.size(): #CAN ENTER
					_index = locationIndex
				await get_tree().create_timer(TIMER_BETWEEN_LOCATIONS[_index]).timeout
			currentNpcState = npcState.moving
		npcState.moving:
			if useSolution:
				set_movement_target(LOCATION_MARKERS_SOLUTION[locationIndex].global_position)
				var _index = MOVEMENT_SPEEDS_SOLUTION.size() - 1 #GET LAST IF NEEDED
				if locationIndex < MOVEMENT_SPEEDS_SOLUTION.size(): #CAN ENTER
					_index = locationIndex
				var nextPathPosition: Vector3 = navigationAgent.get_next_path_position()
				var newVelocity: Vector3 = global_position.direction_to(nextPathPosition).normalized() * MOVEMENT_SPEEDS_SOLUTION[_index]
				if navigationAgent.avoidance_enabled:
					navigationAgent.set_velocity(newVelocity)
				else:
					_on_velocity_computed(newVelocity)
				if navigationAgent.is_navigation_finished(): #Reached destination
					currentNpcState = npcState.reached
					print(name + ", position: "+ str(global_position) + ", marker position: " + str(LOCATION_MARKERS_SOLUTION[locationIndex].global_position))
			#no solution targets
			else:
				set_movement_target(LOCATION_MARKERS[locationIndex].global_position)
				var _index = MOVEMENT_SPEEDS.size() - 1 #GET LAST IF NEEDED
				if locationIndex < MOVEMENT_SPEEDS.size(): #CAN ENTER
					_index = locationIndex
				var nextPathPosition: Vector3 = navigationAgent.get_next_path_position()
				var newVelocity: Vector3 = global_position.direction_to(nextPathPosition).normalized() * MOVEMENT_SPEEDS[_index]
				if navigationAgent.avoidance_enabled:
					navigationAgent.set_velocity(newVelocity)
				else:
					_on_velocity_computed(newVelocity)
				if navigationAgent.is_navigation_finished(): #Reached destination
					currentNpcState = npcState.reached
					print(name + ", position: "+ str(global_position) + ", marker position: " + str(LOCATION_MARKERS[locationIndex].global_position))
		npcState.reached:
			velocity.x = 0
			velocity.z = 0
			locationIndex += 1
			if useSolution:
				if locationIndex < LOCATION_MARKERS_SOLUTION.size(): #IS NOT THE LAST MARKER
					currentNpcState = npcState.idle
					return
			else:
				if locationIndex < LOCATION_MARKERS.size(): #IS NOT THE LAST MARKER
					currentNpcState = npcState.idle
					return
			#Is the last marker
			currentNpcState = npcState.end
		npcState.end:
			velocity.x = 0
			velocity.z = 0
			get_tree().call_group("Main", "_npc_reached_final_destination", self)
			currentNpcState = npcState.waiting
		npcState.inactive:
			velocity.x = 0
			velocity.z = 0
		npcState.waiting:
			pass
	move_and_slide()

func set_movement_target(movement_target: Vector3):
	navigationAgent.set_target_position(movement_target)

func _on_velocity_computed(safe_velocity: Vector3):
	velocity.x = safe_velocity.x
	velocity.z = safe_velocity.z


#Signals called externally

func _found_solution():
	useSolution = true

func _start_npc():
	currentNpcState = npcState.startScene

func _rewind_npc():
	useSolution = false
	currentNpcState = npcState.init
	locationIndex = 0
