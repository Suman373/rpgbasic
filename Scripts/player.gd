extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 3
const WALK_SPEED = 5.0
const RUN_SPEED = 9.0

var sensitivity = 0.001
@onready var camera = $Camera3D

var stamina: = 100.0
var max_stamina: = 100.0
var stamina_drain:= 30.0 # per second drain
var stamina_recover:= 20.0 # per second recover


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * sensitivity)
		camera.rotate_x(-event.relative.y * sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-60), deg_to_rad(70))
	
func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_moving_forward := input_dir.y < 0
	var is_running := Input.is_action_pressed("run") and stamina > 0 and is_moving_forward
	
	var current_speed:= RUN_SPEED if is_running else WALK_SPEED
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, WALK_SPEED)

	move_and_slide()
