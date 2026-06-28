Carpeta /game:
- `game_level.tscn`: escena 3D principal del nivel. Contiene el entorno jugable básico, con iluminación global, suelos y paredes mediante `CSGBox3D`, una lámpara decorativa/funcional y la instancia del jugador. También integra una capa de pausa persistente con interfaz de reanudación y retorno al menú principal.
- `game_level.gd`: controlador central del nivel. Coordina el arranque de la partida desde el menú interno, habilita o deshabilita el `Player`, intercepta la tecla de pausa, y controla una máquina de estados de iluminación con parpadeos, apagón total y restauración progresiva. Además, centraliza el cambio de escena hacia el menú principal.
- `player.tscn`: escena del personaje en 3D. Define un `CharacterBody3D` con `CollisionShape3D` en forma de cápsula, un nodo `Head` para la cámara y una malla cápsula de referencia. La jerarquía está pensada para separar rotación corporal, rotación vertical de la vista y colisión física.
- `player.gd`: script de movimiento del jugador. Implementa control FPS con ratón, movimiento en cuatro direcciones, salto, agacharse y sprint condicionado por avance frontal. Ajusta de forma gradual la altura de la cápsula de colisión y la posición de la cámara para evitar cambios bruscos.

Carpeta /main_menu:
- `main_menu.tscn`: escena principal de menú en 3D. Reutiliza la misma base espacial del juego como escenario de fondo, pero añade una interfaz completa de navegación: botones de jugar, configuración y salir, panel de opciones con resolución, pantalla completa y volumen, además de audio de fondo y un sistema de fundido visual.
- `main_menu.gd`: controlador del menú principal. Gestiona dos flujos principales: acceso a la partida y acceso a configuración. Inicializa las opciones gráficas y de audio desde el estado actual del sistema, anima el desplazamiento de paneles mediante rotación de cámara/UI y ejecuta una secuencia de inicio con parpadeos de luces, sonido de bombilla rota y transición a la escena de carga.

Carpeta /pantalla_carga_iniciar_juego:
- `carga.tscn`: escena de introducción/carga. Presenta una composición mínima sobre fondo negro con dos etiquetas de marca y un reproductor de audio. Su objetivo es funcionar como puente audiovisual entre el menú de inicio y el nivel de juego.
- `carga.gd`: script de intro. Controla una secuencia temporal basada en `Tween`, ajustando la opacidad de los textos en sincronía con el audio. La transición está pensada para mantener ritmo narrativo y, al terminar la reproducción, cargar automáticamente la escena de juego.

Carpeta /settings_menu:
- `settings_menu.tscn`: escena de ajustes mínima en 2D. Contiene un encabezado, un contenedor vertical y un botón de retorno. Está planteada como menú auxiliar independiente, sin depender visualmente de la escena 3D principal.
- `settings_menu.gd`: script de navegación simple. Actúa como controlador de salida de la pantalla de ajustes, comprobando que la escena del menú principal exista antes de realizar la transición para evitar errores de carga.
