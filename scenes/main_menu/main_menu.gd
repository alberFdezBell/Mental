extends Node3D

const MAIN_MENU_PATH = "res://scenes/main_menu/main_menu.tscn"

@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
@onready var main_menu_layer: CanvasLayer = $MainMenuLayer
@onready var menu_container: Control = $MainMenuLayer/LeftMenuContainer
@onready var player: Node3D = $Player
@onready var back_button: Button = $MainMenuLayer/BackButton

@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var area_light_1: AreaLight3D = $AreaLight3D
@onready var area_light_2: AreaLight3D = $AreaLight3D2
@onready var audio_parpadeo: AudioStreamPlayer3D = $tililar

var base_omni_energy: float
var base_area1_energy: float
var base_area2_energy: float

enum EstadoLuz { NORMAL, PARPADEO_ESTANDAR, PRE_APAGON, APAGON_TOTAL, POST_APAGON }
var estado_actual: EstadoLuz = EstadoLuz.NORMAL

var tiempo_proximo_evento: float = 2.0

const TIEMPO_ESPERA_MIN = 4.0
const TIEMPO_ESPERA_MAX = 8.0
const DURACION_FALLO_MIN = 0.3
const DURACION_FALLO_MAX = 1.0

const PROB_APAGON_TOTAL = 0.35
const DURACION_APAGON = 1.5
const DURACION_RAFAGA_MIN = 0.3
const DURACION_RAFAGA_MAX = 0.6

var angulo_origen_y: float = 0.0
var angulo_objetivo_y: float = 0.0
var en_configuracion: bool = false
const VELOCIDAD_GIRO: float = 2.0

var juego_iniciado: bool = false

# Posiciones de reposo de los elementos UI (leídas del editor)
var menu_pos_original: float = 0.0
var back_button_pos_original: float = 0.0

# Progreso de la animación UI: 0.0 = menú principal visible, 1.0 = configuración visible
var ui_progreso: float = 0.0

# Desplazamientos de salida
const MENU_DESP_IZQ: float = 600.0
const BACK_DESP_DER: float = 500.0


func _ready() -> void:
	pause_menu.visible = false
	main_menu_layer.visible = true
	get_tree().paused = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if player:
		player.set_process(false)
		player.set_physics_process(false)
		player.set_process_unhandled_input(false)
		angulo_origen_y = player.rotation.y
		angulo_objetivo_y = player.rotation.y

	randomize()

	base_omni_energy = omni_light.light_energy
	base_area1_energy = area_light_1.light_energy
	base_area2_energy = area_light_2.light_energy

	tiempo_proximo_evento = randf_range(TIEMPO_ESPERA_MIN, TIEMPO_ESPERA_MAX)

	# Guardamos las posiciones que configuraste en el editor
	if menu_container:
		menu_pos_original = menu_container.position.x
	if back_button:
		back_button_pos_original = back_button.position.x

	# Estado inicial: menú visible, botón atrás fuera de pantalla
	ui_progreso = 0.0
	_aplicar_ui_progreso(0.0)


func _process(delta: float) -> void:
	# --- Rotación de cámara ---
	if player:
		player.rotation.y = lerp_angle(player.rotation.y, angulo_objetivo_y, VELOCIDAD_GIRO * delta)
		
		# --- Animación UI Sincronizada (Ida y Vuelta) ---
		# Calculamos el ángulo de destino extremo (cuando está en configuración)
		var angulo_config_y = angulo_origen_y - deg_to_rad(55.0)
		
		# Medimos el progreso comparando la posición actual de la cámara siempre entre 
		# el punto de origen (0.0) y el punto de configuración máxima (1.0)
		if not is_equal_approx(angulo_origen_y, angulo_config_y):
			ui_progreso = remap(player.rotation.y, angulo_origen_y, angulo_config_y, 0.0, 1.0)
			ui_progreso = clampf(ui_progreso, 0.0, 1.0)
		else:
			ui_progreso = 1.0 if en_configuracion else 0.0
			
		_aplicar_ui_progreso(ui_progreso)

	# --- Luces ---
	if get_tree().paused:
		return

	tiempo_proximo_evento -= delta

	if tiempo_proximo_evento <= 0:
		match estado_actual:
			EstadoLuz.NORMAL:
				if randf() < PROB_APAGON_TOTAL:
					estado_actual = EstadoLuz.PRE_APAGON
					tiempo_proximo_evento = randf_range(DURACION_RAFAGA_MIN, DURACION_RAFAGA_MAX)
				else:
					estado_actual = EstadoLuz.PARPADEO_ESTANDAR
					tiempo_proximo_evento = randf_range(DURACION_FALLO_MIN, DURACION_FALLO_MAX)

				if audio_parpadeo and not audio_parpadeo.playing:
					audio_parpadeo.play()

			EstadoLuz.PARPADEO_ESTANDAR:
				_restaurar_luces_normales()

			EstadoLuz.PRE_APAGON:
				estado_actual = EstadoLuz.APAGON_TOTAL
				tiempo_proximo_evento = DURACION_APAGON
				_apagar_luces_por_completo()

				if audio_parpadeo and audio_parpadeo.playing:
					audio_parpadeo.stop()

			EstadoLuz.APAGON_TOTAL:
				estado_actual = EstadoLuz.POST_APAGON
				tiempo_proximo_evento = randf_range(DURACION_RAFAGA_MIN, DURACION_RAFAGA_MAX)

				if audio_parpadeo and not audio_parpadeo.playing:
					audio_parpadeo.play()

			EstadoLuz.POST_APAGON:
				_restaurar_luces_normales()

	match estado_actual:
		EstadoLuz.PARPADEO_ESTANDAR, EstadoLuz.PRE_APAGON, EstadoLuz.POST_APAGON:
			var factor_ruido = _calcular_ruido_parpadeo()
			omni_light.light_energy = base_omni_energy * factor_ruido
			area_light_1.light_energy = base_area1_energy * factor_ruido
			area_light_2.light_energy = base_area2_energy * factor_ruido


# Aplica las posiciones UI según el progreso (0.0 → menú visible / 1.0 → config visible)
func _aplicar_ui_progreso(p: float) -> void:
	if menu_container:
		menu_container.position.x = menu_pos_original - (MENU_DESP_IZQ * p)
	if back_button:
		back_button.position.x = back_button_pos_original + (BACK_DESP_DER * (1.0 - p))


func _apagar_luces_por_completo() -> void:
	omni_light.light_energy = 0.0
	area_light_1.light_energy = 0.0
	area_light_2.light_energy = 0.0


func _restaurar_luces_normales() -> void:
	estado_actual = EstadoLuz.NORMAL
	tiempo_proximo_evento = randf_range(TIEMPO_ESPERA_MIN, TIEMPO_ESPERA_MAX)

	omni_light.light_energy = base_omni_energy
	area_light_1.light_energy = base_area1_energy
	area_light_2.light_energy = base_area2_energy

	if audio_parpadeo and audio_parpadeo.playing:
		audio_parpadeo.stop()


func _calcular_ruido_parpadeo() -> float:
	var t = Time.get_ticks_msec() * 0.07
	var ruido = sin(t) * cos(t * 2.3) + sin(t * 0.5)

	if ruido < -0.1:
		return 0.0

	return remap(ruido, -1.0, 1.0, 0.05, 1.3)


func _unhandled_input(event: InputEvent) -> void:
	if not juego_iniciado:
		if en_configuracion and event.is_action_pressed("ui_cancel"):
			_volver_de_configuracion()
		return

	if event.is_action_pressed("ui_cancel"):
		if get_tree().paused:
			_despausar_juego()
		else:
			_pausar_juego()


func _pausar_juego() -> void:
	get_tree().paused = true
	pause_menu.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _despausar_juego() -> void:
	get_tree().paused = false
	pause_menu.visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume_button_pressed() -> void:
	_despausar_juego()


func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_play_button_pressed() -> void:
	if en_configuracion:
		return
	juego_iniciado = true
	main_menu_layer.visible = false

	if player:
		player.set_process(true)
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_settings_button_pressed() -> void:
	if en_configuracion:
		return
	en_configuracion = true
	angulo_objetivo_y = angulo_origen_y - deg_to_rad(55.0)


func _volver_de_configuracion() -> void:
	en_configuracion = false
	angulo_objetivo_y = angulo_origen_y


func _on_back_button_pressed() -> void:
	if not en_configuracion:
		return
	_volver_de_configuracion()


func _on_exit_button_pressed() -> void:
	get_tree().quit()
