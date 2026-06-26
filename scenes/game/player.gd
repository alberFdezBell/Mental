extends CharacterBody3D

# --- Variables de Movimiento ---
const SPEED_NORMAL = 5.0
const SPEED_CROUCH = 2.5
const SPEED_SPRINT = 8.0 # NUEVO: Velocidad al correr con Shift
var current_speed = SPEED_NORMAL

const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.003

# --- Variables para Agacharse ---
const HEIGHT_NORMAL = 2.0
const HEIGHT_CROUCH = 1.0
const CROUCH_SPEED = 10.0

# --- Referencias de Nodos ---
@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Manejar el Salto (Solo si está en el suelo y NO está agachado)
	if Input.is_action_just_pressed("jump") and is_on_floor() and not Input.is_action_pressed("crouch"):
		velocity.y = JUMP_VELOCITY

	# NUEVO / MODIFICADO: Manejar los estados de velocidad (Agachado, Correr o Normal)
	_actualizar_velocidad_y_estado(delta)

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()

# NUEVO: Esta función centraliza todos los estados del jugador (Caminar, Agacharse, Correr)
func _actualizar_velocidad_y_estado(delta: float):
	# ESTADO 1: Agachado (Tiene prioridad sobre correr)
	if Input.is_action_pressed("crouch"):
		current_speed = SPEED_CROUCH
		collision_shape.shape.height = move_toward(collision_shape.shape.height, HEIGHT_CROUCH, CROUCH_SPEED * delta)
		head.position.y = move_toward(head.position.y, 0.8, CROUCH_SPEED * delta)
		
	# ESTADO 2: Esprintando (Si pulsa Shift y se está moviendo hacia adelante)
	elif Input.is_action_pressed("sprint") and Input.is_action_pressed("move_forward"):
		current_speed = SPEED_SPRINT
		# Nos aseguramos de volver a la altura normal de la cámara si veníamos de estar agachados
		collision_shape.shape.height = move_toward(collision_shape.shape.height, HEIGHT_NORMAL, CROUCH_SPEED * delta)
		head.position.y = move_toward(head.position.y, 1.5, CROUCH_SPEED * delta)
		
	# ESTADO 3: Caminar normal
	else:
		current_speed = SPEED_NORMAL
		collision_shape.shape.height = move_toward(collision_shape.shape.height, HEIGHT_NORMAL, CROUCH_SPEED * delta)
		head.position.y = move_toward(head.position.y, 1.5, CROUCH_SPEED * delta)
