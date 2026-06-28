extends Node2D

# --- CONFIGURACIÓN DE TIEMPOS ---
# Tiempos para "Mental"
@export var duracion_fade_in_mental: float = 1.75
@export var duracion_visible_mental: float = 3.60
@export var duracion_fade_out_mental: float = 1.10

# Tiempos para "Company"
@export var duracion_fade_in_company: float = 3.0
@export var duracion_fade_out_company: float = 2.0

# --- RUTA DE LA ESCENA SIGUIENTE ---
@export_file("*.tscn") var ESCENA_JUEGO_PATH: String = "res://scenes/game/game_level.tscn"

# --- REFERENCIAS DE NODOS ---
@onready var fondo_negro: ColorRect = $CanvasLayer/FondoNegro
@onready var label_mental: Label = $CanvasLayer/CenterContainer/LabelMental
@onready var label_company: Label = $CanvasLayer/CenterContainer/LabelCompany
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	# ... (resto de tu lógica de _ready se mantiene igual)
	if fondo_negro:
		fondo_negro.modulate.a = 1.0
		fondo_negro.visible = true
	if label_mental:
		label_mental.modulate.a = 0.0
		label_mental.visible = true
	if label_company:
		label_company.modulate.a = 0.0
		label_company.visible = true

	if audio_player:
		audio_player.stream = load("res://res/audio/empezar juego (justo despues de darle a jugar).wav")
		audio_player.finished.connect(_cambiar_a_nivel)
		audio_player.play()

	_iniciar_secuencia_intro()

func _iniciar_secuencia_intro() -> void:
	var secuencia = create_tween()
	
	# --- PARTE 1: APARICIÓN DE "MENTAL" (Ahora con duraciones independientes) ---
	if label_mental:
		secuencia.tween_property(label_mental, "modulate:a", 1.0, duracion_fade_in_mental).set_trans(Tween.TRANS_LINEAR)
		secuencia.tween_interval(duracion_visible_mental)
		secuencia.tween_property(label_mental, "modulate:a", 0.0, duracion_fade_out_mental).set_trans(Tween.TRANS_LINEAR)

	# --- PARTE 2: APARICIÓN DE "COMPANY" ---
	if label_company && audio_player && audio_player.stream:
		# Calculamos el tiempo total ya transcurrido por "Mental"
		var tiempo_transcurrido: float = duracion_fade_in_mental + duracion_visible_mental + duracion_fade_out_mental
		var tiempo_espera_restante: float = 6.32 - tiempo_transcurrido
		
		if tiempo_espera_restante > 0:
			secuencia.tween_interval(tiempo_espera_restante)
		
		secuencia.tween_property(label_company, "modulate:a", 1.0, duracion_fade_in_company).set_trans(Tween.TRANS_LINEAR)
		
		var duracion_total_audio: float = audio_player.stream.get_length()
		var tiempo_restante_audio: float = duracion_total_audio - (6.32 + duracion_fade_in_company)
		
		var margen_anticipacion: float = 0.5 
		var nuevo_tiempo_visible: float = tiempo_restante_audio - margen_anticipacion - duracion_fade_out_company
		
		secuencia.tween_interval(max(0.1, nuevo_tiempo_visible))
		
		secuencia.tween_property(label_company, "modulate:a", 0.0, duracion_fade_out_company).set_trans(Tween.TRANS_LINEAR)

func _cambiar_a_nivel() -> void:
	get_tree().change_scene_to_file(ESCENA_JUEGO_PATH)
