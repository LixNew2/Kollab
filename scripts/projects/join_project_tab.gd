extends ColorRect

var project_uid := ""
var project_data := {}
@onready var error_key := $container/key/error_key
var base_http := HTTPRequest.new()

func _ready():
	add_child(base_http)


func get_projects_infos():
	$container/key/confirm_key_btn.disabled = true
	project_uid = get_node("container/key/key").text
	var tmp_data = await ProjectsManager.get_project_info(project_uid)
	print(tmp_data)
	if project_uid == "":
		error_key.show()
		get_node("container/project_info").hide()
		diabled_confirm_key_btn()
		return
		
	if tmp_data.project_data == null:
		error_key.show()
		get_node("container/project_info").hide()
		diabled_confirm_key_btn()
		return
		
	error_key.hide()
	project_data = tmp_data["project_data"]
	project_uid = tmp_data["project_uid"]

	get_node("container/project_info/pj_title").text = project_data["project_name"]
	get_node("container/project_info/pj_desc").text = project_data["project_desc"]
	get_node("container/project_info/pj_plat").text = project_data["project_plat"]

	get_node("container/project_info").show()
	diabled_confirm_key_btn()
	
func diabled_confirm_key_btn():
	await get_tree().create_timer(3).timeout
	$container/key/confirm_key_btn.disabled = false
	
func join_project():
	$container/project_info/NativeFileDialog.show()

func _on_native_file_dialog_dir_selected(dir):
	var max_users_project = await ProjectsManager.get_project_max_users($container/key/key.text)
	var check_dir = DirAccess.open(dir)
	var list_dire = check_dir.list_dir_begin()
	var is_empty = true
	
	while true:
		var file = check_dir.get_next()
		if file == "":
			break
		if file != "":
			is_empty = false
			break
		
	if is_empty:
		$container/project_info/error2.hide()
		if project_uid in Global.project_user:
			$container/project_info/error.show()
			return
		
		if max_users_project == 0:
			var full_users_project_popup = preload("res://scenes/projects/project_users_max_popup.tscn").instantiate()
			get_node("/root").add_child(full_users_project_popup)
			return
		$container/project_info/loading.show()
		$container/project_info/join_project_btn.hide()
		
		button_status(true)
		await ProjectsManager.join_project(project_uid, dir, 0)
		$container/project_info/loading.hide()
		$container/project_info/join_project_btn.show()
		button_status(false)
		
		base_http.request(Global.api_url + "/edit_project_number/?nbr=" + str(Global.get_project_number - 1), Global.token_header, HTTPClient.METHOD_POST)
		var result = await base_http.request_completed as Array
		if result[1] == 200:
			await ProjectsManager.upload_new_max_user_project($container/key/key.text, max_users_project - 1) 
			Firebase.get_projetc_number()
			get_node("..")._on_my_project_btn_pressed()
			get_node("container/project_info").hide()
			get_node("container/key/key").text = ""
			Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").button_pressed = true
	else:
		$container/project_info/error2.show()
		return
		
func button_status(statut):
	Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").disabled = statut
	Global.home.get_node("container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/my_project_btn").disabled = statut
	Global.home.get_node("container/container/body/projects/top_bar/container/Home/create_btn").disabled = statut
	Global.home.get_node("container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/create_btn").disabled = statut
	$container/key/confirm_key_btn.disabled = statut
	
func _on_key_text_changed(new_text):
	$container/project_info/error.hide()

func _on_file_dialog_dir_selected(dir):
	var max_users_project = await ProjectsManager.get_project_max_users($container/key/key.text)
	var check_dir = DirAccess.open(dir)
	var list_dire = check_dir.list_dir_begin()
	var is_empty = true
	
	while true:
		var file = check_dir.get_next()
		if file == "":
			break
		if file != "":
			is_empty = false
			break
		
	if is_empty:
		$container/project_info/error2.hide()
		if project_uid in Global.project_user:
			$container/project_info/error.show()
			return
		
		if max_users_project == 0:
			var full_users_project_popup = preload("res://scenes/projects/project_users_max_popup.tscn").instantiate()
			get_node("/root").add_child(full_users_project_popup)
			return
		$container/project_info/loading.show()
		$container/project_info/join_project_btn.hide()
		
		button_status(true)
		await ProjectsManager.join_project(project_uid, dir, 0)
		$container/project_info/loading.hide()
		$container/project_info/join_project_btn.show()
		button_status(false)
		
		base_http.request(Global.api_url + "/edit_project_number/?nbr=" + str(Global.get_project_number - 1), Global.token_header, HTTPClient.METHOD_POST)
		var result = await base_http.request_completed as Array
		if result[1] == 200:
			await ProjectsManager.upload_new_max_user_project($container/key/key.text, max_users_project - 1) 
			Firebase.get_projetc_number()
			get_node("..")._on_my_project_btn_pressed()
			get_node("container/project_info").hide()
			get_node("container/key/key").text = ""
			Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").button_pressed = true
	else:
		$container/project_info/error2.show()
		return
