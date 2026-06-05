extends Control

var public = 0

func _ready():
	var spin_box_line_edit = $Panel/VBoxContainer/bpm.get_line_edit()
	var spin_box_line_edit1 = $Panel/VBoxContainer/users_max.get_line_edit()
	spin_box_line_edit.context_menu_enabled = false
	spin_box_line_edit1.context_menu_enabled = false
	
#	$Panel/AnimationPlayer.play("popup")

func _on_close_btn_pressed():
#	$Panel/AnimationPlayer.play_backwards("popup")
#	await $Panel/AnimationPlayer.animation_finished
	queue_free()

func _on_title_line_edit_text_changed(new_text):
	$Panel/VBoxContainer/error.hide()


func _on_public_btn_pressed():
	if Global.key_type == 3:
		if public == 0:
			$Panel/VBoxContainer/users_max.hide()
			$Panel/VBoxContainer/users_max_label.hide()
			public = 1
		else:
			$Panel/VBoxContainer/users_max.show()
			$Panel/VBoxContainer/users_max_label.show()
			public = 0
	else:
		var public_project_popup = preload("res://scenes/projects/public_project_popup.tscn").instantiate()
		add_child(public_project_popup)
		$Panel/VBoxContainer/HBoxContainer/public_btn.button_pressed = false
