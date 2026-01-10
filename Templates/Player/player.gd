extends CharacterBody3D

const mouse_sensitivity := 0.0015

var sprint_acceleration:float # running acceleration in m/s
var ground_sprint_speed := 6.5
var air_sprint_speed := 4.5 # speed in m/s

const jump_velocity:float = 8 #no clue what this is measured in or why this seems good
const terminal_fall_velocity:float = 25 #in m/s 

const jump_speed_mult := 1.1

var target_velocity := Vector3.ZERO

var velocity_increase := Vector3.ZERO
var single_velocity_multiplier:float = 1 #multiplier to increase velocity

var game_running:bool = false
var should_jump:bool = false #variable that is true when the player should jump on the next physics tick

func start_game() -> void:
	game_running = true

func hit_scan_shot() -> void:
	var end_point:Vector3 = $CameraAnchor/HitScanRay.get_collision_point()
	

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

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event): #called on inputs(mouse movements and keypressed)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		$CameraAnchor.rotate_x(-event.relative.y * mouse_sensitivity)
		$CameraAnchor.rotation.x = clampf($CameraAnchor.rotation.x, -deg_to_rad(90), deg_to_rad(90))
	elif event is InputEventKey:
		if event.keycode == KEY_SPACE and is_on_floor(): #queues a jump for the next physics tick
			should_jump = true
		
		if event.keycode == KEY_ESCAPE and not event.is_echo():
			set_physics_process(false)
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			$CameraAnchor/Camera3D/EscapeMenu.pause()
		
		if event.keycode == KEY_UP and not event.is_echo() and not event.is_released():
			ground_sprint_speed += 1
			print("[Player/Input] Movement speed is now "+str(sprint_acceleration))
		if event.keycode == KEY_DOWN and not event.is_echo() and not event.is_released():
			ground_sprint_speed -= 1
			print("[Player/Input] Movement speed is now "+str(sprint_acceleration))

func multiply_all_velocity(multiplier:float) -> void: #function to be called by other things and here, to mutliply velocity
	print("[Player/Physics] Velocity multiplier called, multiplying by "+str(multiplier)+" at the end of the current physics frame")
	single_velocity_multiplier = multiplier

func _physics_process(delta: float) -> void:
	if Utils.debug_mode == true:
		update_debug_readouts()
	if game_running:
		var target_acceleration := Vector3.ZERO
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
