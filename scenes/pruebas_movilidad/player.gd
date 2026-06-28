extends CharacterBody3D

# Velocidades de movimiento
@export var walk_speed: float = 4.0
@export var sprint_speed: float = 7.0
@export var crouch_speed: float = 2.0
@export var jump_velocity: float = 4.5

# Parámetros de agachado
@export var default_height: float = 1.8
@export var crouch_height: float = 1.0
@export var default_camera_y: float = 1.6
@export var crouch_camera_y: float = 0.8
@export var crouch_transition_speed: float = 10.0

# Sensibilidad del ratón
@export var mouse_sensitivity: float = 0.002

# Referencias a nodos
@onready var head: Node3D = $Head
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var ceiling_check: RayCast3D = $CeilingCheck

# Gravedad
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

# Estados y variables de control
var speed: float = walk_speed
var target_speed: float = walk_speed
var is_crouching: bool = false

func _ready() -> void:
	# Capturar ratón
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Captura/liberación del ratón con ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Movimiento de cámara con el ratón
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

func _physics_process(delta: float) -> void:
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Manejar salto
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

	# Manejar agachado (Crouch)
	var crouch_input = Input.is_action_pressed("crouch")
	
	if crouch_input:
		is_crouching = true
	else:
		# Si ya no se presiona agacharse, verificar si hay espacio arriba para levantarse
		if is_crouching:
			if ceiling_check.is_colliding():
				# Hay un obstáculo arriba, mantener agachado
				is_crouching = true
			else:
				is_crouching = false

	# Ajustar altura de colisión y cámara progresivamente
	var target_height = crouch_height if is_crouching else default_height
	var target_cam_y = crouch_camera_y if is_crouching else default_camera_y
	
	# Cambiar la altura y posición del colisionador de la cápsula
	if collision_shape.shape is CapsuleShape3D:
		var current_h = collision_shape.shape.height
		var new_h = lerp(current_h, target_height, crouch_transition_speed * delta)
		collision_shape.shape.height = new_h
		# Mantener la base del colisionador en y = 0
		collision_shape.position.y = new_h / 2.0
	
	# Ajustar la posición y de la cabeza/cámara
	head.position.y = lerp(head.position.y, target_cam_y, crouch_transition_speed * delta)

	# Manejar Velocidad (Caminar, Correr, Agachado)
	if is_crouching:
		target_speed = crouch_speed
	elif Input.is_action_pressed("sprint") and is_on_floor():
		target_speed = sprint_speed
	else:
		target_speed = walk_speed

	# Suavizar cambios de velocidad
	speed = lerp(speed, target_speed, 10.0 * delta)

	# Obtener dirección de entrada y manejar movimiento/desaceleración
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Desaceleración suave
		var friction = 12.0 if is_on_floor() else 2.0
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)

	move_and_slide()
