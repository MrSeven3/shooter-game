extends Control
signal resume_game

func _ready() -> void:
	visible = false
	if Utils.debug_mode == true:
		$DevEscapeMenu.visible = true
	else:
		$DevEscapeMenu.visible = false

func pause() -> void: #called from main player script
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true

func resume() -> void:
	visible = false
	resume_game.emit()

func reset() -> void:
	get_tree().reload_current_scene()

func quit() -> void:
	get_tree().change_scene_to_file("res://Scenes/MainMenu/main_menu.tscn")
