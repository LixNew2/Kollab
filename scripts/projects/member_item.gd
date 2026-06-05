extends Control

var members_popup = preload("res://scenes/projects/members_popup.tscn").instantiate()

func _on_delete_pressed():
	var delete_member_node = preload("res://scenes/projects/delete_member_popup.tscn").instantiate()
	get_node("/root").add_child(delete_member_node)
	
	await delete_member_node.get_node("Panel/VBoxContainer/delete_btn").pressed
	await ProjectsManager.delete_user_project(Global.key_project_uuid, $container/user_id.text)
	get_node("../../../../../").members_load()
	delete_member_node.queue_free()
