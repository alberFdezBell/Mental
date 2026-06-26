extends Node3D

const MAIN_MENU_PATH = "res://scenes/main_menu/main_menu.tscn"

@onready var pause_menu: Control = $PauseMenuLayer/PauseMenu

func _ready() -> void:
	pause_menu.visible = false
	get_tree().paused = false
	
	# Permite que este nodo siga recibiendo input cuando el juego está pausado
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
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
