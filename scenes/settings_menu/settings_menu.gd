extends Node2D

# Almacenamos la ruta hacia el menú principal
const MAIN_MENU_PATH = "res://scenes/main_menu/main_menu.tscn"

func _ready() -> void:
	print("Menú de ajustes abierto.")

# Esta función se ejecutará cuando pulsemos el botón de volver
func _on_back_button_pressed() -> void:
	# Verificamos si la escena existe antes de cambiar para evitar crasheos
	if ResourceLoader.exists(MAIN_MENU_PATH):
		get_tree().change_scene_to_file(MAIN_MENU_PATH)
	else:
		print("Error: No se encontró la escena del menú principal en: ", MAIN_MENU_PATH)


func _on_button_pressed() -> void:
	pass # Replace with function body.
