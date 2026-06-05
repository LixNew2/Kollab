extends VBoxContainer

var projects : Dictionary

func visibility_changed():
	if visible:
		load_projects()
	else:
		unload_projects()

func _ready():
	await get_tree().create_timer(2).timeout
	load_projects()

func load_projects():
	unload_projects()
	Firebase.get_projetc_number()
	Global.project_user = []
	Global.project_number = 0
	Global.project_more_infos_panel_index = 0
	
	get_node("HBoxContainer/container/loading").show()
	get_node("HBoxContainer/container/ColorRect").hide()
	get_node("HBoxContainer/container/project_container").hide()
	get_node("HBoxContainer/container/bottom_bg").hide()
	
	projects = sort_project(await ProjectsManager.get_projects())
	var nbr_projects = 0
	
	for project in projects:
		nbr_projects += 1
		var project_node = preload("res://scenes/projects/project_item.tscn").instantiate()
		project_node.get_node("container/project_name").text = projects[project].project_name
#		project_node.get_node("container/project_desc").text = projects[project].project_desc
		project_node.get_node("container/project_rights").text = projects[project].type
		project_node.get_node("container/project_bpm").text = str(projects[project].project_bpm)
		project_node.get_node("container/project_version").text = projects[project].project_plat_version
		project_node.get_node("container/Label").text = projects[project].project_plat
		project_node.get_node("container/project_infos_panel/HBoxContainer/project_right_button/sharing_key").text = project
		project_node.get_node("container/project_date").text = get_time(projects, project)
		project_node.get_node("container/size").text = str(projects[project].max_size)
		Global.project_user.append(project)

		if projects[project].project_plat == "...":
			project_node.get_node("container/project_plat").show()
			project_node.get_node("container/Label").hide()
			
		if projects[project].type == "member":
			project_node.get_node("container/project_infos_panel/HBoxContainer/delete_project_btn").text = "leave_project"
			project_node.get_node("container/project_infos_panel/HBoxContainer/project_right_button").hide()
			project_node.get_node("container/project_infos_panel/HBoxContainer/infos_project").hide()
			project_node.get_node("container/project_lvl").text = "0"
		else:
			project_node.get_node("container/project_lvl").text = "1"
		
		project_node.get_node("container/btn/project_update").disabled = ProjectsManager.projects_version[project].update

		project_node.get_node("container/btn/project_update").connect("pressed", pull.bind(project))
		project_node.get_node("container/btn/project_push").connect("pressed", push.bind(project, project_node, projects[project].max_size))

		project_node.set_name(project)
		get_node("HBoxContainer/container/project_container").add_child(project_node)
		Global.project_number += 1
		
	get_node("HBoxContainer/container/loading").hide()
	if nbr_projects < 1:
		get_node("HBoxContainer/container/not_projects").show()
		get_node("HBoxContainer/container/ColorRect").hide()
		get_node("HBoxContainer/container/project_container").hide()
		get_node("HBoxContainer/container/bottom_bg").hide()
	else:
		get_node("HBoxContainer/container/not_projects").hide()
		get_node("HBoxContainer/container/ColorRect").show()
		get_node("HBoxContainer/container/project_container").show()
		get_node("HBoxContainer/container/bottom_bg").show()
		

func pull(project: String):
	var result = check_path(project, 1)
	if result:
		get_node("HBoxContainer/container/project_container/" + project + "/container/btn/project_update").hide()
		get_node("HBoxContainer/container/project_container/" + project + "/container/btn/project_push").hide()
		get_node("HBoxContainer/container/project_container/" + project + "/container/btn/loading").show()
		await ProjectsManager.pull_project(project)
		await load_projects()

func push(project: String, node, max_size):
	var result = check_path(project, 0)
	if result:
		get_node("HBoxContainer/container/project_container/" + project + "/container/btn/project_update").hide()
		get_node("HBoxContainer/container/project_container/" + project + "/container/btn/project_push").hide()
		get_node("HBoxContainer/container/project_container/" + project + "/container/btn/loading").show()
		await ProjectsManager.push_project(project, 1, node, projects[project].max_size)
		if Global.push_is_ok:
			await load_projects()

func check_path(project: String, id: int):
	var file = FileAccess.open("user://" + project + ".dat", FileAccess.READ)
	var local_data = file.get_var()
	
	var file_not_found = preload("res://scenes/projects/file_not_found_popup.tscn").instantiate()
	if id == 0:
		if local_data.project_folder.get_extension() != "":
			print("file")
			if FileAccess.file_exists(local_data.project_folder) != true:
				file_not_found.get_node("Panel/VBoxContainer/Label2").text = local_data.project_folder
				file_not_found.get_node("Panel/VBoxContainer/Label").text = "files_not_found"
				get_node("/root").add_child(file_not_found)
				return
		else:
			print("dir")
			if DirAccess.dir_exists_absolute(local_data.project_folder) != true:
				file_not_found.get_node("Panel/VBoxContainer/Label2").text = local_data.project_folder
				get_node("/root").add_child(file_not_found)
				return
	else:
		if local_data.project_folder.get_extension() != "":
			print("file")
			if DirAccess.dir_exists_absolute(local_data.project_folder.get_base_dir()) != true:
				file_not_found.get_node("Panel/VBoxContainer/Label2").text = local_data.project_folder.get_base_dir()
				get_node("/root").add_child(file_not_found)
				return
		else:
			print("dir")
			if DirAccess.dir_exists_absolute(local_data.project_folder) != true:
				file_not_found.get_node("Panel/VBoxContainer/Label2").text = local_data.project_folder
				get_node("/root").add_child(file_not_found)
				return

	return true
	
func unload_projects():
	for i in get_node("HBoxContainer/container/project_container").get_children():
		i.queue_free()

func sync_pressed():
	$top_bar/HBoxContainer/sync.disabled = true
	load_projects()
	await get_tree().create_timer(3).timeout
	$top_bar/HBoxContainer/sync.disabled = false
	
func get_time(projets : Dictionary, project : String):
	var time_stamp_project = int(projets[project].project_date)
	var current_time_stamp = int(Time.get_unix_time_from_system())
	var time_delta = current_time_stamp - time_stamp_project
	
	var days = time_delta / (60 * 60 * 24)
	var hours = (time_delta / (60 * 60)) % 24
	var minutes = (time_delta / 60) % 60
	var seconds = time_delta % 60
	
	if days >= 1:
		if days >= 365:
			return tr("ago_text").format({"time": str(days) + tr("date_year")})
		elif days >= 30:
			return tr("ago_text").format({"time": str(days) + tr("date_month")})
		else:
			return tr("ago_text").format({"time": str(days) + tr("date_day")})
	elif hours >= 1:
		return tr("ago_text").format({"time": str(hours) + tr("date_hour")})
	elif minutes >= 1:
		return tr("ago_text").format({"time": str(minutes) + tr("date_minute")})
	else:
		return tr("ago_text").format({"time": str(seconds) + tr("date_second")})

func sort_project(projects : Dictionary):

	var time_stamps_project = {}
	var time_sort = {}
	var sorted_projects = {}
	
	for project in projects:
		time_stamps_project[project] = get_time(projects, project)
		if time_stamps_project[project].ends_with('y') or time_stamps_project[project].ends_with('an'):
			time_sort[project] = int(time_stamps_project[project]) * 31536000
		elif time_stamps_project[project].ends_with('m'):
			time_sort[project] =  int(time_stamps_project[project]) * 2592000
		elif time_stamps_project[project].ends_with('d') or time_stamps_project[project].ends_with('j'):
			time_sort[project] =  int(time_stamps_project[project]) * 86400
		elif time_stamps_project[project].ends_with('h'):
			time_sort[project] =  int(time_stamps_project[project]) * 3600
		elif time_stamps_project[project].ends_with('min'):
			time_sort[project] =  int(time_stamps_project[project]) * 60
		else:
			time_sort[project] =  int(time_stamps_project[project])
	
	var sorted = []
	
	for i in time_sort:
		var inserted = false
		for j in range(sorted.size()):
			if time_sort[i] < time_sort[sorted[j]]:
				sorted.insert(j, i)
				inserted = true
				break
		if not inserted:
			sorted.append(i)
	
	for project in sorted:
		sorted_projects[project] = {
			"project_bpm" : projects[project].project_bpm,
			"project_date" : projects[project].project_date,
			"project_desc" : projects[project].project_desc,
			"project_max_user" : projects[project].project_max_user,
			"project_max_user_edit" : projects[project].project_max_user_edit,
			"project_name" : projects[project].project_name,
			"project_plat" : projects[project].project_plat,
			"project_plat_version" : projects[project].project_plat_version,
			"project_version" : projects[project].project_version,
			"max_size": projects[project].max_size,
			"type" : projects[project].type
		}

	return sorted_projects
