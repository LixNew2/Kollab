extends VBoxContainer

var projects : Dictionary
var base_http = HTTPRequest.new()
var uid_project_to_download : String
var node_project_to_download
var name_project_to_download : String

func _on_visibility_changed():
	if visible:
		load_projects()
	else:
		unload_projects()

func _ready():
	add_child(base_http)

func load_projects():
	unload_projects()
	
	get_node("public_project_box/HBoxContainer/loading").show()
	get_node("public_project_box/ScrollContainer").hide()
	
	var public_projects = await ProjectsManager.get_public_project()
	var nbr_projects = 0
	
	if typeof(public_projects) != 27:
		return
		
	projects = sort_project(public_projects)
	
	for project in projects:
		nbr_projects += 1
		var project_node = preload("res://scenes/projects/public_project_item.tscn").instantiate()
		project_node.get_node("container/project_name").text = projects[project].project_name
		project_node.get_node("container/project_bpm").text = str(projects[project].project_bpm)
		project_node.get_node("container/project_version").text = projects[project].project_plat_version
		project_node.get_node("container/Label").text = projects[project].project_plat
		project_node.get_node("container/username").text = projects[project].creator
		project_node.get_node("container/btn/upvote/Label").text = str(projects[project].upvote)
		project_node.get_node("container/key").text = project
		
		if Global.crt_scene == "res://scenes/projects/commentary.tscn":
			print("ok")
			project_node.get_node("container/btn/commentary").hide()
			
		project_node.get_node("container/btn/upvote/upvote_btn").connect("pressed", ProjectsManager.upvote_project.bind(project, project_node))
		project_node.get_node("container/btn/download_btn").connect("pressed", download.bind(project, project_node, projects[project].project_name))
		
		await ProjectsManager.check_upvote_project_user(project, project_node)
		
		project_node.set_name(project)
		get_node("public_project_box/ScrollContainer/settings_container").add_child(project_node)
	
	get_node("public_project_box/HBoxContainer/loading").hide()
	if nbr_projects < 1:
		get_node("public_project_box/HBoxContainer/not_public_projects").show()
		get_node("public_project_box/ScrollContainer").hide()
	else:
		get_node("public_project_box/HBoxContainer/not_public_projects").hide()
		get_node("public_project_box/ScrollContainer").show()
		
func download(uid, node, name):
	uid_project_to_download = uid
	node_project_to_download = node
	name_project_to_download = name
	$NativeFileDialog.show()
	
func unload_projects():
	for i in get_node("public_project_box/ScrollContainer/settings_container").get_children():
		i.queue_free()

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
			"creator" : projects[project].creator,
			"upvote" : projects[project].upvote
		}

	return sorted_projects

func _on_native_file_dialog_dir_selected(dir):
	node_project_to_download.get_node("container/btn/loading").show()
	node_project_to_download.get_node("container/btn/download_btn").hide()
	await ProjectsManager.download_public_project(uid_project_to_download, dir, name_project_to_download)
	node_project_to_download.get_node("container/btn/loading").hide()
	node_project_to_download.get_node("container/btn/download_btn").show()
