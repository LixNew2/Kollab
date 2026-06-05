extends VBoxContainer

@onready var create_project := $create_project
@onready var my_project := $my_projects
@onready var join_project :=$join_project

func _process(delta):
	#if Global.get_project_number > 20:
		#$top_bar/container/Home/HBoxContainer/nbr2.hide()
		#$top_bar/container/Home/HBoxContainer/infini.show()
	#else:
		#$top_bar/container/Home/HBoxContainer/nbr2.show()
		#$top_bar/container/Home/HBoxContainer/infini.hide()
		
	$top_bar/container/Home/HBoxContainer/nbr1.text = str(Global.project_number)
	$top_bar/container/Home/HBoxContainer/nbr2.text = str(Global.get_project_number)
	
func _on_my_project_btn_pressed():
	get_node("../../../../container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/my_project_btn").button_pressed = true
	Global.project_more_infos_panel_index = 0
	my_project.show()
	create_project.hide()
	join_project.hide()

func _on_create_btn_pressed():
	if Global.get_project_number != 0:
		get_node("../../../../container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/create_btn").button_pressed = true
		Global.project_more_infos_panel_index = 0
		my_project.hide()
		create_project.show()
		join_project.hide()
	else:
		Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").button_pressed = true
		if Global.key_type != 3:
			var full_project_popup = preload("res://scenes/projects/full_project_popup.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)
			await full_project_popup.get_node("Panel/VBoxContainer/buy_btn").pressed
			OS.shell_open("https://kollabsound.com/view-pricing/")
			full_project_popup.queue_free()
		else:
			var full_project_popup = preload("res://scenes/projects/full_project_popup_premium.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)

func _on_join_btn_pressed():
	if Global.get_project_number != 0:
		get_node("../../../../container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/join_btn").button_pressed = true
		Global.project_more_infos_panel_index = 0
		my_project.hide()
		create_project.hide()
		join_project.show()
	else:
		Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").button_pressed = true
		if Global.key_type != 3:
			var full_project_popup = preload("res://scenes/projects/full_project_popup.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)
			await full_project_popup.get_node("Panel/VBoxContainer/buy_btn").pressed
			OS.shell_open("https://kollabsound.com/view-pricing/")
			full_project_popup.queue_free()
		else:
			var full_project_popup = preload("res://scenes/projects/full_project_popup_premium.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)
