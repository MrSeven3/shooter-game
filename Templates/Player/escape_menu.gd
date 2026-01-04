extends Control
signal resume_game 



func pause() -> void: #called from main player script
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true

func resume() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false
	resume_game.emit()

func reset() -> void:
	get_tree().reload_current_scene()

func quit() -> void:
	Utils.close_game()
