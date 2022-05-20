extends Control

enum MOUSE_MODE {
	CAPTURED = Input.MOUSE_MODE_CAPTURED,
	VISIBLE = Input.MOUSE_MODE_VISIBLE
}

export(MOUSE_MODE) var unpaused_mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ready():
	HUDSingleton.is_paused = false
	visible = false


func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	HUDSingleton.is_paused = !HUDSingleton.is_paused
	visible = HUDSingleton.is_paused
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if HUDSingleton.is_paused else unpaused_mouse_mode)


func _on_ResumeButton_pressed():
	toggle_pause()


func _on_OptionsButton_pressed():
	pass # Replace with function body.


func _on_QuitButton_pressed():
	get_tree().quit()
