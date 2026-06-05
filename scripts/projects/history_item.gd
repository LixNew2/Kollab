extends Control

func _on_gui_input(event):
	toggle_item_project(event)
	
func toggle_item_project(event):
	if event is InputEventMouseButton and event.pressed:
		for child in get_parent().get_children():
			var colorrect = child.get_node("ColorRect2")
			if get_instance_id() != child.get_instance_id():
				colorrect.color = '121214'
			if get_instance_id() == child.get_instance_id():
				colorrect.color = '020a31'

func _on_mouse_entered():
	if $ColorRect2.color != Color('020a31'):
		$ColorRect2.color = "232426"

func _on_mouse_exited():
	if $ColorRect2.color != Color('020a31'):
		$ColorRect2.color = "121214"
