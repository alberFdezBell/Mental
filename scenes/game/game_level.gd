extends Node3D

const MAIN_MENU_PATH = "res://scenes/main_menu/main_menu.tscn"

@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu
@onready var main_menu_layer: CanvasLayer = $MainMenuLayer
@onready var player: Node3D = $Player

# --- VARIABLES PARA EL PARPADEO Y APAGONES ---
@onready var omni_light: OmniLight3D = $OmniLight3D
@onready var area_light_1: AreaLight3D = $AreaLight3D
@onready var area_light_2: AreaLight3D = $AreaLight3D2

var base_omni_energy: float
var base_area1_energy: float
var base_area2_energy: float

# Definimos los estados posibles del sistema eléctrico
enum EstadoLuz { NORMAL, PARPADEO_ESTANDAR, PRE_APAGON, APAGON_TOTAL, POST_APAGON }
var estado_actual: EstadoLuz = EstadoLuz.NORMAL

var tiempo_proximo_evento: float = 2.0

# RANGOS DE CONFIGURACIÓN
const TIEMPO_ESPERA_MIN = 4.0   # Tiempo mínimo entre sustos/eventos
const TIEMPO_ESPERA_MAX = 8.0   # Tiempo máximo entre sustos/eventos
const DURACION_FALLO_MIN = 0.3  # Duración del parpadeo común corto
const DURACION_FALLO_MAX = 1.0  # Duración del parpadeo común largo

# CONFIGURACIÓN DEL GRAN APAGÓN
const PROB_APAGON_TOTAL = 0.35  # 35% de probabilidad de sufrir el gran apagón
const DURACION_APAGON = 1.5     # Tiempo que se queda 100% a oscuras
const DURACION_RAFAGA_MIN = 0.3 # Mínimo tiempo parpadeando antes/después
const DURACION_RAFAGA_MAX = 0.6 # Máximo tiempo parpadeando antes/después
# --------------------------------------------------

var juego_iniciado: bool = false

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
	
	randomize()
	
	# Guardar intensidades originales
	base_omni_energy = omni_light.light_energy
	base_area1_energy = area_light_1.light_energy
	base_area2_energy = area_light_2.light_energy
	
	# Primer tiempo de espera
	tiempo_proximo_evento = randf_range(TIEMPO_ESPERA_MIN, TIEMPO_ESPERA_MAX)


func _process(delta: float) -> void:
	if get_tree().paused: return
	
	tiempo_proximo_evento -= delta
	
	# Control de transiciones de estado cuando el temporizador llega a cero
	if tiempo_proximo_evento <= 0:
		match estado_actual:
			EstadoLuz.NORMAL:
				if randf() < PROB_APAGON_TOTAL:
					estado_actual = EstadoLuz.PRE_APAGON
					tiempo_proximo_evento = randf_range(DURACION_RAFAGA_MIN, DURACION_RAFAGA_MAX)
				else:
					estado_actual = EstadoLuz.PARPADEO_ESTANDAR
					tiempo_proximo_evento = randf_range(DURACION_FALLO_MIN, DURACION_FALLO_MAX)
			
			EstadoLuz.PARPADEO_ESTANDAR:
				_restaurar_luces_normales()
				
			EstadoLuz.PRE_APAGON:
				estado_actual = EstadoLuz.APAGON_TOTAL
				tiempo_proximo_evento = DURACION_APAGON
				_apagar_luces_por_completo()
				
			EstadoLuz.APAGON_TOTAL:
				estado_actual = EstadoLuz.POST_APAGON
				tiempo_proximo_evento = randf_range(DURACION_RAFAGA_MIN, DURACION_RAFAGA_MAX)
				
			EstadoLuz.POST_APAGON:
				_restaurar_luces_normales()

	# Ejecución de la lógica visual de cada estado en cada frame
	match estado_actual:
		EstadoLuz.PARPADEO_ESTANDAR, EstadoLuz.PRE_APAGON, EstadoLuz.POST_APAGON:
			var factor_ruido = _calcular_ruido_parpadeo()
			omni_light.light_energy = base_omni_energy * factor_ruido
			area_light_1.light_energy = base_area1_energy * factor_ruido
			area_light_2.light_energy = base_area2_energy * factor_ruido


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


func _calcular_ruido_parpadeo() -> float:
	var t = Time.get_ticks_msec() * 0.07
	var ruido = sin(t) * cos(t * 2.3) + sin(t * 0.5)
	
	if ruido < -0.1:
		return 0.0
		
	return remap(ruido, -1.0, 1.0, 0.05, 1.3)


# --- CONTROL DE MENÚ DE PAUSA ---
func _unhandled_input(event: InputEvent) -> void:
	if not juego_iniciado: return
	
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


# --- SEÑALES DE LOS BOTONES DEL MENÚ IZQUIERDO ---
func _on_play_button_pressed() -> void:
	juego_iniciado = true
	main_menu_layer.visible = false
	
	if player:
		player.set_process(true)
		player.set_physics_process(true)
		player.set_process_unhandled_input(true)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_settings_button_pressed() -> void:
	print("Abriendo Configuración...")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
