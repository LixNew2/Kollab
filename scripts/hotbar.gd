extends Panel

var following = false
var dragging_start_position = Vector2()


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.get_button_index() == 1:
			following = !following
			dragging_start_position = get_local_mouse_position()

func _process(_delta):
	if following:
		DisplayServer.window_set_position(DisplayServer.window_get_position() + Vector2i(get_global_mouse_position()) - Vector2i(dragging_start_position))


func _on_close_pressed():
	get_tree().quit()


func _on_min_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)


func _on_maximize_btn_pressed():
	if DisplayServer.window_get_size() == DisplayServer.screen_get_size():
		var window_size = Vector2i(DisplayServer.screen_get_size().y / 1.5 / 0.5625, DisplayServer.screen_get_size().y / 1.5)
		DisplayServer.window_set_size(window_size)
		DisplayServer.window_set_position(DisplayServer.screen_get_size()/2.0 - window_size/2.0)
	else:
		DisplayServer.window_set_size(DisplayServer.screen_get_size())
		DisplayServer.window_set_position(Vector2i(0, 0))
