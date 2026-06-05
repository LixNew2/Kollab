extends Control

func _ready():
	if Global.crt_scene == "res://scenes/projects/commentary.tscn" or Global.crt_scene == "res://scenes/projects/my_profile.tscn" or Global.crt_scene == "res://scenes/projects/user_profile.tscn":
		$container/btn/download_btn.hide()
		$container/btn/commentary.hide()
		
func _on_container_gui_input(event):
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

func _on_commentary_pressed():
	Global.project_key_selected = $container/key.text
	var commentary = preload("res://scenes/projects/commentary.tscn").instantiate()
	get_node("/root").add_child(commentary)
	Global.crt_scene = "res://scenes/projects/commentary.tscn"

func _on_gui_input(event):
	if event is InputEventMouseButton and event.double_click:
		if Global.crt_scene != "res://scenes/projects/user_profile.tscn" and Global.crt_scene != "res://scenes/projects/my_profile.tscn" and Global.crt_scene != "res://scenes/projects/commentary.tscn":
			Global.project_key_selected = $container/key.text
			Global.crt_scene = "res://scenes/projects/user_profile.tscn"
			Global.get_social_type = 0
			get_node("../../../../../../../../container/container/body/user_profile").show()

func _on_username_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		if Global.crt_scene != "res://scenes/projects/user_profile.tscn" and Global.crt_scene != "res://scenes/projects/my_profile.tscn" and Global.crt_scene != "res://scenes/projects/commentary.tscn":
			Global.project_key_selected = $container/key.text
			Global.crt_scene = "res://scenes/projects/user_profile.tscn"
			Global.get_social_type = 0
			get_node("../../../../../../../../container/container/body/user_profile").show()
