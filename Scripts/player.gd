extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 3
const WALK_SPEED = 5.0
const RUN_SPEED = 6.0
const SLIDE_SPEED = 6
const CROUCH_SPEED = 2

var sensitivity = 0.001

var stamina := 100.0
var max_stamina := 100.0
var stamina_drain:= 18.0 # per second drain
var stamina_recover:= 5.0 # per second recover

var flash_battery := 100.0
var max_battery := 100
var battery_drain := 5.0
var battery_recover := 2.0

var footstep_timer := 0.0
var slide_timer := 0.0
var walk_interval := 0.5
var run_interval := 0.3
var slide_duration := 0.4
var is_crouching := false
var is_sliding := false

@onready var camera = $Camera3D
@onready var stamina_bar = $"../CanvasLayer/StaminaBar"
@onready var footstep_audio = $FootstepAudio
@onready var flashlight = $Camera3D/SpotLight3D
@onready var flashlight_sound_on = $Camera3D/SpotLight3D/SoundOn
@onready var flashlight_sound_off = $Camera3D/SpotLight3D/SoundOff
@onready var flash_battery_bar = $"../CanvasLayer/FlashBatteryBar"


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	

func reduce_height(delta):
	camera.position.y = lerp(camera.position.y, 0.5, delta * 10.0)

func reset_height(delta):
	camera.position.y = lerp(camera.position.y, 1.5, delta * 10.0)

# handle UI related operations (runs at every frame)
func _process(delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("flashlight"):
		if flashlight.visible:
			flashlight_sound_on.play()
		else:
			flashlight_sound_off.play()
		flashlight.visible = !flashlight.visible

# camera rotation in y and x axis
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))
	

# physics related logic, runs at fixed frame rate and best for movement, collision
func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	# handle crouching
	var can_run := stamina > 20
	var is_moving := direction.length() > 0.1 and is_on_floor()
	var is_moving_forward := input_dir.y < 0
	var is_running := Input.is_action_pressed("run") and can_run and is_moving_forward and !is_crouching
	
	if Input.is_action_pressed("crouch"):
		is_crouching = true
	else:
		is_crouching = false
	
	# handle slide
	if Input.is_action_just_pressed("slide") and is_moving and stamina >= 20:
		is_sliding = true
		is_crouching = false
		slide_timer = slide_duration
		stamina -= 20.0
	
	# determine character camera height
	if is_crouching or is_sliding:
		reduce_height(delta)
	else:
		reset_height(delta)
	
	
	# footstep audio
	if is_moving:
		footstep_timer -= delta
		var interval = run_interval if is_running else walk_interval
		# play the audio
		if footstep_timer <= 0:
			if is_crouching:
				footstep_audio.volume_db = -30.0
				footstep_audio.pitch_scale = randf_range(0.7,0.9)
			else:
				footstep_audio.volume_db = 0.0
				footstep_audio.pitch_scale = randf_range(0.8, 1.2) 
			footstep_audio.play()
			footstep_timer = interval
	else:
		footstep_timer = 0
#		# kill sound
		if footstep_audio.playing:
			footstep_audio.stop()

	# stamina drain
	if is_running:
		stamina -= stamina_drain * delta
	else:
		stamina += stamina_recover * delta
	# ---- STAMINA BAR -------------
	stamina = clamp(stamina, 0, max_stamina)
	stamina_bar.value = stamina
	
	# run speed and direction 
	var current_speed:= WALK_SPEED
	
	if is_sliding:
		current_speed = SLIDE_SPEED
		slide_timer -= delta
		if slide_timer <= 0:
			is_sliding = false
			if Input.is_action_pressed("crouch"):
				is_crouching = true
	elif is_running:
		current_speed = RUN_SPEED
	elif is_crouching:
		current_speed = CROUCH_SPEED
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)
		
	# flashlight and battery
	if flashlight.visible:
		flash_battery -= battery_drain * delta
		var target_color = Color(0.8, 0.2, 0.2) if flash_battery < 30 else Color(0.9, 0.8, 0.1)
		var current_fill = flash_battery_bar.get_theme_stylebox("fill")
		if current_fill.bg_color != target_color:
			var fill_style = current_fill.duplicate()
			fill_style.bg_color = target_color
			flash_battery_bar.add_theme_stylebox_override("fill", fill_style)
			
		if flash_battery <= 0:
			flash_battery = 0
			flashlight.visible = false
			flashlight_sound_off.play()
	else:
		flash_battery += battery_recover * delta
	flash_battery = clamp(flash_battery, 0, max_battery)
	flash_battery_bar.value = flash_battery
	
	 

	move_and_slide()
