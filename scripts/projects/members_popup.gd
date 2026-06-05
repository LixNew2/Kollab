extends ColorRect

func _ready():
#	$Panel/AnimationPlayer.play("popup")
	members_load()
			
func _on_close_btn_pressed():
#	$Panel/AnimationPlayer.play_backwards("popup")
#	await $Panel/AnimationPlayer.animation_finished
	queue_free()

func members_load():
	unload_members()
	var users = await ProjectsManager.get_users_project()
	if users == null:
		return
	for user in users:
		var members_item = preload("res://scenes/projects/member_item.tscn").instantiate()
		members_item.get_node("container/user_id").text = user
		
		if user == Global.uid:
			members_item.get_node("container/btn/delete").hide()
			if TranslationServer.get_locale() == "fr":
				members_item.get_node("container/username").text = users[user] + " (créateur)"
			else:
				members_item.get_node("container/username").text = users[user] + " (owner)"
		else:
			members_item.get_node("container/username").text = users[user]

		members_item.set_name(user)
		get_node("Panel/VBoxContainer/ScrollContainer/VBoxContainer").add_child(members_item)


func unload_members():
	for i in $Panel/VBoxContainer/ScrollContainer/VBoxContainer.get_children():
		i.queue_free()
