class_name Criminal_Car
extends Basic_NPC

@export var SPAWN_SOLUTION: Marker3D
@export var SOLUTION_1_LOCATIONS: Array[Marker3D]
@export var SOLUTION_2_LOCATIONS: Array[Marker3D]

var solutionID: int = 0

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
			if APPEAR_AT_START:
				show()
			else:
				hide()
		npcState.startScene:
			if useSolution:
				position.x = SPAWN_SOLUTION.global_position.x
				position.z = SPAWN_SOLUTION.global_position.z
			if APPEAR_AT_START:
				currentNpcState = npcState.idle
				show()
			else:
				hide()
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
				match solutionID:
					0:
						set_movement_target(SOLUTION_1_LOCATIONS[locationIndex].global_position)
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
					1:
						set_movement_target(SOLUTION_2_LOCATIONS[locationIndex].global_position)
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
			%AudioStreamPlayer3D.play()
			get_tree().call_group("Main", "_npc_reached_final_destination", self)
			currentNpcState = npcState.waiting
		npcState.inactive:
			velocity.x = 0
			velocity.z = 0
		npcState.waiting:
			pass
	move_and_slide()

#Signals called externally

func _found_solution():
	return

func _start_npc():
	currentNpcState = npcState.startScene

func _found_solution_id(_solution: int):
	useSolution = true
	solutionID = _solution

func _rewind_npc():
	useSolution = false
	solutionID = 0
	currentNpcState = npcState.init
	locationIndex = 0
