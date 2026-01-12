extends CharacterBody3D

const mouse_sensitivity := 0.0015

var beam_scene:Resource

var sprint_acceleration:float # running acceleration in m/s
var ground_sprint_speed := 6.5
var air_sprint_speed := 4.5 # speed in m/s

const jump_velocity:float = 8 #no clue what this is measured in or why this seems good
const terminal_fall_velocity:float = 25 #in m/s 

const jump_speed_mult := 1.1

var target_velocity := Vector3.ZERO
var target_acceleration := Vector3.ZERO

var velocity_increase := Vector3.ZERO
var single_velocity_multiplier:float = 1 #multiplier to increase velocity

var game_running:bool = false
var is_paused:bool = false
var should_jump:bool = false #variable that is true when the player should jump on the next physics tick

var equipped_weapon:String
const hitscan_weapons:Array = ["railgun"]

const weapons:Dictionary = {
	"railgun":{"damage":50,"range":256}
	}

func resume_game() -> void:
	is_paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	set_physics_process(true)

func start_game() -> void:
	game_running = true

func hit_scan_shot() -> Array:
	if $CameraAnchor/HitscanRay.is_colliding():
		var end_point:Vector3 = $CameraAnchor/HitscanRay.get_collision_point()
		var distance:float = position.distance_to(end_point)
		
		var hit_object = $CameraAnchor/HitscanRay.get_collider()
		
		return [true,distance,end_point,hit_object]
	else:
		var distance:float = -$CameraAnchor/HitscanRay.target_position.z
		var ray_end_point:Vector3 = $CameraAnchor.global_position + Vector3(0,0,-distance)
		
		var rotated_end_point:Vector3 = transform.basis * ray_end_point
		return [false,distance,rotated_end_point,null]
	

func equip_weapon(weapon:StringName) -> void:
	if weapon in weapons:
		equipped_weapon = weapon
	else:
		push_error("Attempted to equip invalid weapon: " + weapon)

func shoot() -> void:
	var root = get_node("/root")
	print("firing")
	if equipped_weapon in hitscan_weapons:
		var shot_result := hit_scan_shot()
		var hit_point:Vector3 = shot_result[2]
		match equipped_weapon:
			"railgun":
				print("shooting railgun")
				var debug_pos1 = position
				var debug_pos2 = global_position
				var debug_pos3 = $CameraAnchor.global_position
				var beam_spawnpoint:Vector3 = (hit_point + $CameraAnchor.global_position)/2
				var beam = beam_scene.instantiate()
				
				var distance = shot_result[1]
				
				beam.position = beam_spawnpoint
				beam.beam_length = distance
				root.add_child(beam)
				beam.rotation = Vector3($CameraAnchor.rotation.x,rotation.y,0)

func _ready() -> void:
	beam_scene = load("res://Templates/Shots/InstaRay/insta_ray.tscn")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func _input(event): #called on inputs(mouse movements and keypressed)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		$CameraAnchor.rotate_x(-event.relative.y * mouse_sensitivity)
		$CameraAnchor.rotation.x = clampf($CameraAnchor.rotation.x, -deg_to_rad(90), deg_to_rad(90))
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE and is_on_floor(): #queues a jump for the next physics tick
			should_jump = true
		
		if event.keycode == KEY_ESCAPE and not event.is_echo() and not event.is_released():
			if not is_paused:
				is_paused = true
				set_physics_process(false)
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
				$CameraAnchor/Camera3D/EscapeMenu.pause()
			else:
				$CameraAnchor/Camera3D/EscapeMenu.resume()
				
		
		if event.keycode == KEY_UP and not event.is_echo() and not event.is_released():
			ground_sprint_speed += 1
			print("[Player/Input] Movement speed is now "+str(sprint_acceleration))
		if event.keycode == KEY_DOWN and not event.is_echo() and not event.is_released():
			
			ground_sprint_speed -= 1
			print("[Player/Input] Movement speed is now "+str(sprint_acceleration))
		
	elif event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.is_released():
			shoot()

func multiply_all_velocity(multiplier:float) -> void: #function to be called by other things and here, to mutliply velocity
	print("[Player/Physics] Velocity multiplier called, multiplying by "+str(multiplier)+" at the end of the current physics frame")
	single_velocity_multiplier = multiplier

func _process(_delta: float) -> void:
	if Utils.debug_mode == true:
		$CameraAnchor/Camera3D/DebugUI.visible = true
		update_debug_readouts()
	else:
		$CameraAnchor/Camera3D/DebugUI.visible = false

func _physics_process(delta: float) -> void:
	if game_running:
		target_acceleration = Vector3.ZERO
		if is_on_floor():
			sprint_acceleration = ground_sprint_speed
			

			# Handle jumping logic
			if should_jump and is_on_floor():
				velocity.y = jump_velocity
				multiply_all_velocity(1.2)
				should_jump = false

			# Input-based movement
			if Input.is_key_pressed(KEY_W):
				target_acceleration.z -= sprint_acceleration 
			if Input.is_key_pressed(KEY_S):
				target_acceleration.z += sprint_acceleration
			if Input.is_key_pressed(KEY_A):
				target_acceleration.x -= sprint_acceleration
			if Input.is_key_pressed(KEY_D):
				target_acceleration.x += sprint_acceleration
			
			target_velocity = target_acceleration
			target_acceleration = transform.basis * target_acceleration#rotate the applied movement
			

			velocity.x = lerp(velocity.x, target_acceleration.x, delta * 10) # Smooth acceleration
			velocity.z = lerp(velocity.z, target_acceleration.z, delta * 10) # Smooth acceleration
		else:
			sprint_acceleration = air_sprint_speed
			velocity += get_gravity() * delta
			
			# Input-based movement
			if Input.is_key_pressed(KEY_W):
				target_acceleration.z -= sprint_acceleration 
			if Input.is_key_pressed(KEY_S):
				target_acceleration.z += sprint_acceleration
			if Input.is_key_pressed(KEY_A):
				target_acceleration.x -= sprint_acceleration
			if Input.is_key_pressed(KEY_D):
				target_acceleration.x += sprint_acceleration
			
			target_velocity = target_acceleration
			target_acceleration = transform.basis * target_acceleration#rotate the applied movement		
			
			velocity.x += target_acceleration.x * delta
			velocity.z += target_acceleration.z * delta
		
		# Apply any global velocity multiplier
		if single_velocity_multiplier != 1:
			velocity *= single_velocity_multiplier
			print("[Player/Physics] New velocity will be " + str(velocity))
			single_velocity_multiplier = 1
		
		velocity.y = clamp(velocity.y,-terminal_fall_velocity,9223372036854775807)
		move_and_slide()

#region Dev Functions

func pos_reset() -> void: #linked to dev escape menu
	position.x = 0
	position.y = 0.5
	position.z = 0
	target_acceleration = Vector3.ZERO
	velocity = Vector3.ZERO

func rot_reset() -> void:
	rotation = Vector3.ZERO
	$CameraAnchor.rotation.x = 0

func update_velocity_feed() -> void: #updates a debug feed for velocities
	#actual velocities
	var velX = snapped(velocity.x,0.1)
	var velY = snapped(velocity.y,0.1)
	var velZ = snapped(velocity.z,0.1)
	$CameraAnchor/Camera3D/DebugUI/MovementReadout/Velocity.text = "VelX:"+str(velX)+" VelY:"+str(velY)+" VelZ:"+str(velZ)
	
	#target velocities
	var target_velX = snapped(target_velocity.x,0.1)
	var target_velY = snapped(target_velocity.y,0.1)
	var target_velZ = snapped(target_velocity.z,0.1)
	$CameraAnchor/Camera3D/DebugUI/MovementReadout/TargetVelocity.text = "TVelX:"+str(target_velX)+" TVelY:"+str(target_velY)+" TVelZ:"+str(target_velZ)
	
	#position debug
	var posX = snapped(position.x,0.1)
	var posY = snapped(position.y,0.1)
	var posZ = snapped(position.z,0.1)
	$CameraAnchor/Camera3D/DebugUI/MovementReadout/Position.text = "PosX:"+str(posX)+" PosY:"+str(posY)+" PosZ:"+str(posZ)
	
	$CameraAnchor/Camera3D/DebugUI/MovementReadout/Gravity.text = "Gravity: " + str(get_gravity())
	
func update_debug_readouts() -> void: #updates all debug readouts on the camera
	update_velocity_feed()
	$CameraAnchor/Camera3D/DebugUI/OtherReadout/GameRunningIndicator.text = "Game Running: " + str(game_running)
	#$CameraAnchor/Camera3D/DebugUI/OtherReadout/MoveAllowedIndicator.text = "Move Allowed: " + str(move_allowed) # this is broken. don't know why
	$CameraAnchor/Camera3D/DebugUI/OtherReadout/OnFloorIndicator.text = "On Floor: " + str(is_on_floor())
	$CameraAnchor/Camera3D/DebugUI/OtherReadout/PhysicsProcessIndicator.text = "Physics Processing: " + str(is_physics_processing())
#endregion
