extends VBoxContainer

func _on_username_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		Global.pseudo_social = $HBoxContainer/username.text
		Global.get_social_type = 1
		Global.crt_scene = "res://scenes/projects/commentary.tscn"
		get_node("/root/home/container/container/body/user_profile").show()
		get_node("/root/Control").hide()
		await get_node("/root/home/container/container/body/user_profile/settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/profil/back_btn").pressed
		get_node("/root/Control").show()
