extends VBoxContainer

var base_http = HTTPRequest.new()
var projects : Dictionary
var uid_project_to_download : String
var node_project_to_download
var name_project_to_download : String

@onready var social_fields = [
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/right/Discord/Discord_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/left/Instagram/Instagram_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/left/SoundCloud/SoundCloud_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/left/Spotify/Spotify_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/right/Tiktok/Tiktok_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/right/Twitch/Twitch_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/HBoxContainer/description_user2,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/left/X/X_URL,
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/links/right/Youtube/Youtube_URL,]

var icon = Texture2D

func _ready():
	add_child(base_http)
	await get_social()
	await get_random_icon()
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/profil/Label.text = Global.username
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/profil/icon.texture = icon
	
func confirm_btn():
	var body = JSON.stringify({"user_desc": social_fields[6].text, "instagram_url": social_fields[1].text, "spotify_url": social_fields[3].text, "soundcloud_url": social_fields[2].text, "x_url": social_fields[7].text, "youtube_url": social_fields[8].text, "discord_url": social_fields[0].text, "tiktok_url": social_fields[4].text, "twitch_url" : social_fields[5].text})
	base_http.request(Global.api_url + "/set_social/", Global.token_header, HTTPClient.METHOD_POST, body)
	await base_http.request_completed
	
func get_social():
	base_http.request(Global.api_url + "/get_social/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var data = json.get_data()
		var data_list = data.values() #Parse dict to list
		for i in social_fields.size():
			if data_list[i] == "null":
				social_fields[i].text = ""
			else:
				social_fields[i].text = data_list[i]
			
		$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/HBoxContainer/Label.text = str((social_fields[6].text).length()) + "/199"

func get_random_icon():
	base_http.request(Global.api_url + "/get_user_icons/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var icons = json.get_data()
		print(icons["normal"])
		icon = load(icons["normal"])

func _on_description_user_2_text_changed(new_text):
	$settings_box/ScrollContainer/VBoxContainer/HBoxContainer/profil_box/HBoxContainer/Label.text = str(new_text.length()) + "/199"

func load_projects():
	unload_projects()
	
	get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/loading").show()
	get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/VBoxContainer").hide()
	
	var public_projects = await ProjectsManager.get_user_public_projet()
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

		project_node.get_node("container/btn/upvote/upvote_btn").connect("pressed", ProjectsManager.upvote_project.bind(project, project_node))
		project_node.get_node("container/btn/download_btn").connect("pressed", download.bind(project, project_node, projects[project].project_name))
		
		await ProjectsManager.check_upvote_project_user(project, project_node)
		
		project_node.set_name(project)
		get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/VBoxContainer").add_child(project_node)
	
	get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/loading").hide()
	if nbr_projects < 1:
		get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/not_public_projects").show()
		get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/VBoxContainer").hide()
	else:
		get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/not_public_projects").hide()
		get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/VBoxContainer").show()
		
func download(uid, node, name):
	uid_project_to_download = uid
	node_project_to_download = node
	name_project_to_download = name
	$NativeFileDialog.show()
	
func unload_projects():
	for i in get_node("settings_box/ScrollContainer/VBoxContainer/HBoxContainer2/projects/VBoxContainer").get_children():
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
