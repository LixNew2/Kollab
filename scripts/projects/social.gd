extends VBoxContainer


func _on_my_profile_btn_pressed():
	get_node("../../../../container/container/side_bar/VBoxContainer/social_btn_other/VBoxContainer/my_profile_btn").button_pressed = true
	$my_profile.show()
	$chat.hide()
	$add_firends.hide()
	$my_firends.hide()
	Global.crt_scene = "res://scenes/projects/my_profile.tscn"

func _on_chat_btn_pressed():
	get_node("../../../../container/container/side_bar/VBoxContainer/social_btn_other/VBoxContainer/chat_btn").button_pressed = true
	$my_profile.hide()
	$chat.show()
	$add_firends.hide()
	$my_firends.hide()
	Global.crt_scene = ""
	
func _on_my_friends_btn_pressed():
	get_node("../../../../container/container/side_bar/VBoxContainer/social_btn_other/VBoxContainer/my_friends_btn").button_pressed = true
	$my_profile.hide()
	$chat.hide()
	$my_firends.show()
	$add_firends.hide()
	Global.crt_scene = ""
	
func _on_add_firends_btn_pressed():
	get_node("../../../../container/container/side_bar/VBoxContainer/social_btn_other/VBoxContainer/add_firends_btn").button_pressed = true
	$my_profile.hide()
	$chat.hide()
	$my_firends.hide()
	$add_firends.show()
	Global.crt_scene = ""
	
func _on_visibility_changed():
	if visible:
		$my_profile.load_projects()
	else:
		$my_profile.unload_projects()
