extends Node
var debug_mode:bool = true

func close_game() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST) #tells other things that the game is closing
	get_tree().quit() #closes the program
