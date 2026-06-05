extends Control


var projects_version := {}
var base_http := HTTPRequest.new()
var base_http_2 := HTTPRequest.new()

var project_size = 0
var number_of_files = 0
var processed_file_count = 0
var files = []
var old_file : String
var finished = false
var id_thread : String
var t1 : Thread
const FILES_PER_BATCH = 10


func _ready():
	add_child(base_http_2)
	add_child(base_http)

func get_projects() -> Dictionary:
	base_http_2.request(Global.api_url + "/get_projects_list/", Global.token_header, HTTPClient.METHOD_GET)

	var result = await base_http_2.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		await check_versions(json.get_data())
		return json.get_data()
	return {}

func create_project(project_uid: String, project_name: String, project_desc: String, project_plat: String, project_bpm: int, selected_version: String, project_folder: String, project_max_user: int, date : String, public : bool):
	var body = JSON.stringify({"project_uid": project_uid, "project_name": project_name, "project_desc": project_desc, "project_plat": project_plat, "project_bpm": project_bpm, "project_plat_version": selected_version, "project_version": 0, "project_max_user": project_max_user, "project_date" : date, "public" : public, "creator" : Global.username, "max_size" : 1500 if Global.key_type == 3 else (500 if Global.key_type == 2 else (250 if Global.key_type == 1 else 100))})
	base_http.request(Global.api_url + "/create_project/", Global.token_header, HTTPClient.METHOD_POST, body)
	await base_http.request_completed

	var data_path = "user://" + project_uid + ".dat"
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_var({"project_uid": project_uid, "project_folder": project_folder, "local_version": 0})
	file.close()

	await push_project(project_uid)


func join_project(project_uid: String, project_folder: String, lvl : int):
	if lvl == 0:
		print("join ", project_uid, project_folder)

	#	var body = JSON.stringify({"project_uid": project_uid, "project_name": project_name, "project_desc": project_desc, "project_plat": project_plat, "project_bpm": project_bpm, "project_plat_version": selected_version, "project_version": 0})
		base_http.request(Global.api_url + "/join_project/?project_uid=" + project_uid, Global.token_header, HTTPClient.METHOD_POST)
		await base_http.request_completed

	var data_path = "user://" + project_uid + ".dat"
	var file = FileAccess.open(data_path, FileAccess.WRITE)
	file.store_var({"project_uid": project_uid, "project_folder": project_folder, "local_version": 0})
	file.close()

	await pull_project(project_uid)


func get_project_info(project_uid: String):
	print("get_infos ", project_uid)
	var http := HTTPRequest.new()
	add_child(http)
	http.request(Global.api_url + "/get_projects_infos/?project_uid=" + str(project_uid) , Global.token_header, HTTPClient.METHOD_GET)
	var result = await http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		return json.get_data()


func check_versions(projects):
	for project_uid in projects:
		#get local version
		var data_path = "user://" + project_uid + ".dat"
		
		if !FileAccess.file_exists(data_path):
			await join_project(project_uid, OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP), 1)
			
		var file = FileAccess.open(data_path, FileAccess.READ)
		var local_data = file.get_var()
		file.close()
		var local_version = local_data.local_version

		#get online version
		var online_version = projects[project_uid].project_version

		projects_version[project_uid] = {"online_version": online_version, "local_version": local_version, "update": online_version == local_version}


func push_project(project_uid: String, type : int = 0, node = "", max_size = 0):
	print("Push")
	var projects := await get_projects()

	var online_version = projects[project_uid].project_version

	var data_path = "user://" + project_uid + ".dat"
	var file = FileAccess.open(data_path, FileAccess.READ)
	var local_data = file.get_var()
	file.close()
	
	if type == 1 and str(node) != "":
		node.get_node("container").hide()
		node.get_node("size").show()
		check_project_data(local_data.project_folder)
		while finished != true:
			await get_tree().process_frame
		node.get_node("container").show()
		node.get_node("size").hide()
		var confirm_size = check_size_with_key_type(max_size)
		if !confirm_size:
			if max_size < 1000:
				node.get_node("error/error").text = tr("size_file_error_push").format({"size": str(max_size)})
			else:
				node.get_node("error/error").text = tr("size_file_error_push_gb").format({"size": str(max_size/1000.00)})
			node.get_node("container").hide()
			node.get_node("error").show()
			Global.push_is_ok = false
			return
			
	var new_version = online_version + 1

	file = FileAccess.open(data_path, FileAccess.WRITE)
	local_data["local_version"] = new_version
	file.store_var(local_data)
	file.close()

	var headers = [
		"Content-Type: multipart/form-data; boundary=BodyBoundaryHere",
		"Authorization: Bearer " + Global.token
	]
	
	Global.push_is_ok = true
	base_http.request_raw(Global.api_url + "/push_project/?project_uid=" + project_uid + "&project_version=" + str(new_version) + "&project_date=" + str(Time.get_unix_time_from_system()), headers, HTTPClient.METHOD_POST, await upload_folder(project_uid, local_data.project_folder))
	await base_http.request_completed

func pull_project(project_uid: String):
	print("Pull")
	var projects := await get_projects()

	var data_path = "user://" + project_uid + ".dat"
	var file = FileAccess.open(data_path, FileAccess.READ)
	var local_data = file.get_var()
	file.close()

	await download_folder(project_uid, local_data.project_folder)

	file = FileAccess.open(data_path, FileAccess.WRITE)
	local_data["local_version"] = projects[project_uid].project_version
	file.store_var(local_data)
	file.close()
	await get_tree().process_frame


func upload_folder(project_uid: String, folder_path : String):
	var tmp_file := OS.get_user_data_dir() + "/" + project_uid + ".7z"
	DirAccess.remove_absolute(tmp_file)
	var file_path := await compress_folder(project_uid, folder_path)
	var file_name := project_uid + ".7z"

	var file = FileAccess.open(file_path, FileAccess.READ)
	var file_content = file.get_buffer(file.get_length())

	var body = PackedByteArray()
	body.append_array("\r\n--BodyBoundaryHere\r\n".to_utf8_buffer())
	body.append_array(("Content-Disposition: form-data; name=\"file\"; filename=\"%s\"\r\n" % file_name).to_utf8_buffer())
	body.append_array("Content-Type: image/png\r\n\r\n".to_utf8_buffer())
	body.append_array(file_content)
	body.append_array("\r\n--BodyBoundaryHere--\r\n".to_utf8_buffer())

	return body

func compress_folder(project_uid: String, folder_path: String) -> String:
	if DirAccess.dir_exists_absolute(OS.get_user_data_dir() + "/backups") != true:
		DirAccess.make_dir_absolute(OS.get_user_data_dir() + "/backups")
		
	if DirAccess.dir_exists_absolute(OS.get_user_data_dir() + "/backups/" + project_uid) != true:
		DirAccess.make_dir_absolute(OS.get_user_data_dir() + "/backups/" + project_uid)
	
	if OS.get_name() == "Windows":
		var cmd = ""
		
		#compress
		if folder_path.get_extension() == "":
			cmd = '"' + Global.zip_path + '" a "' + OS.get_user_data_dir() + '/' + project_uid + '.7z" "' + folder_path + '/*" -y && echo.>"' + OS.get_user_data_dir() + '/compress_' + project_uid + '"'
		else:
			cmd = '"' + Global.zip_path + '" a "' + OS.get_user_data_dir() + '/' + project_uid + '.7z" "' + folder_path + '/*" -y && echo.>"' + OS.get_user_data_dir() + '/compress_' + project_uid + '"'

		OS.create_process("CMD.exe", ["/C", cmd])
		while !FileAccess.file_exists('user://compress_' + project_uid):
			await get_tree().process_frame
		DirAccess.remove_absolute('user://compress_' + project_uid)
		
		#backups
		cmd = '"' + Global.zip_path + '" a "' + OS.get_user_data_dir() + '/backups/' + project_uid + "/" + str(Time.get_datetime_string_from_system().replace("-","_").replace(":","_").replace("T", "_")) + '.7z" "' + folder_path + '/*" -y && echo.>"' + OS.get_user_data_dir() + '/compress_' + project_uid + '"'
		OS.create_process("CMD.exe", ["/C", cmd])
		while !FileAccess.file_exists('user://compress_' + project_uid):
			await get_tree().process_frame
		DirAccess.remove_absolute('user://compress_' + project_uid)
	else:
		var cmd = ""
		
		#compress
		cmd = ["a", OS.get_user_data_dir() + "/" + project_uid + ".7z", folder_path + "/*"]
		OS.execute(Global.zip_path, cmd, [], true)
		while !FileAccess.file_exists(OS.get_user_data_dir() + "/" + project_uid + ".7z"):
			await get_tree().process_frame
			
		#backup
		cmd = ["a", OS.get_user_data_dir() + "/backups/" + project_uid  + "/" + str(Time.get_datetime_string_from_system().replace("-","_").replace(":","_").replace("T", "_")) + ".7z", folder_path + "/*"]
		OS.execute(Global.zip_path, cmd, [], true)
		while !FileAccess.file_exists(OS.get_user_data_dir() + "/" + project_uid + ".7z"):
			await get_tree().process_frame

	return OS.get_user_data_dir() + "/" + project_uid + ".7z"

#func convert_date_time(backup: String, type : int) -> String:
	#var parts := backup.split("_")
	#
	#var date : String
	#print(parts)
	#var year := parts[0]
	#var day := parts[2]
	#var month := parts[1]
	#var hour := parts[3].to_int()
	#var minute := parts[4]
	#
	#if OS.get_locale_language() == "fr":
		#date += str(day) + "-" + str(month) + "-" + str(year) + " " + str(hour) + ":" + str(minute)
	#else:
		#if hour <=11 :
			#date += str(month) + "-" + str(day) + "-" + str(year) + " " + str(hour) + ":" + str(minute) + "AM"
		#else:
			#if hour == 24 or hour == 00:
				#date += str(month) + "-" + str(day) + "-" + str(year) + " " + str(12) + ":" + str(minute) + "PM"
			#else:
				#date += str(month) + "-" + str(day) + "-" + str(year) + " " + str(hour-12) + ":" + str(minute) + "PM"
#
	#return date if type == 0 else date.replace(":","_").replace(" ","_").replace("-","_")

func download_folder(project_uid: String, folder_path: String):
	var tmp_file := OS.get_user_data_dir() + "/" + project_uid + ".7z"
	DirAccess.remove_absolute(tmp_file)
	base_http.download_file = tmp_file
	base_http.request(Global.api_url + "/download_file/?project_uid=" + project_uid)
	await base_http.request_completed

	uncompress_folder(project_uid, folder_path)
	

func download_history(project_uid: String, filename_project : String, folder_path: String):
	var tmp_file := folder_path + "/" + filename_project + ".7z"
	base_http.download_file = tmp_file
	base_http.request(Global.api_url + "/download_history/?uid=" + project_uid + "&filename_project=" + filename_project)
	await base_http.request_completed

func download_public_project(project_uid: String, folder_path: String, name : String):
	var banned_char = ['\\', '/', ':', '*', '?', '<', '>', '|', '"', " "]

	for char in name:
		if char in banned_char:
			name = name.replace(char, "_")
			
	print(name)
	var tmp_file := folder_path + "/" + name + ".7z"
	base_http.download_file = tmp_file
	base_http.request(Global.api_url + "/download_file/?project_uid=" + project_uid)
	await base_http.request_completed

func clear_old_folder(folder_path: String):
	OS.move_to_trash(folder_path)


func uncompress_folder(project_uid: String, folder_path: String) -> String:
	var tmp_file := OS.get_user_data_dir() + "/" + project_uid + ".7z"
	
	#clear_old_folder(folder_path)
	if OS.get_name() == "Windows":
		var cmd = '"' + Global.zip_path + '" x "' + tmp_file + '" -o"' + folder_path + '" -aoa -y && echo.>"' + OS.get_user_data_dir() + '/uncompress_' + project_uid + '"'
		OS.create_process("CMD.exe", ["/C", cmd])
		while !FileAccess.file_exists('user://uncompress_' + project_uid):
			await get_tree().process_frame
		DirAccess.remove_absolute('user://uncompress_' + project_uid)
	else:
		var cmd = ["x", OS.get_user_data_dir() + "/" + project_uid + ".7z", "-o" + folder_path, "-aoa"]
		OS.execute(Global.zip_path, cmd, [], true)
		await get_tree().create_timer(5).timeout

	await get_tree().create_timer(1).timeout
	return OS.get_user_data_dir() + "/" + project_uid + ".7z"


func get_users_project():
	base_http.request(Global.api_url + "/get_users_project/?key=" + Global.key_project_uuid, Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		return json.get_data()

func delete_user_project(key : String, uid : String):
	var body = JSON.stringify({"key": key, "uid": uid})
	base_http.request(Global.api_url + "/delete_user_project/", Global.token_header, HTTPClient.METHOD_POST, body)
	await base_http.request_completed

func get_project_max_users(key : String):
	var http := HTTPRequest.new()
	add_child(http)
	http.request(Global.api_url + "/get_project_max_users/?key=" + key, Global.token_header, HTTPClient.METHOD_GET)
	var result = await http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		return int(result_body)

func upload_new_max_user_project(key : String, max_user_project : int):
	var body = JSON.stringify({"key": key, "max_user_project": max_user_project})
	base_http.request(Global.api_url + "/upload_new_max_user_project/", Global.token_header, HTTPClient.METHOD_POST, body)
	await base_http.request_completed
	
func get_public_project():
	base_http.request(Global.api_url + "/get_public_projects_list/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		return json.get_data()

func upvote_project(uid : String, node):
	base_http.request(Global.api_url + "/upvote_projets/?uid=" + str(uid), Global.token_header, HTTPClient.METHOD_POST)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var data = json.get_data()
		node.get_node("container/btn/upvote/Label").text = str(data[0])
		if data[1] == 1:
			node.get_node("container/btn/upvote/upvote_btn").texture_normal = load("res://assets/ressources/upvoted.png")
		else:
			node.get_node("container/btn/upvote/upvote_btn").texture_normal = load("res://assets/ressources/up.png")
			
func check_upvote_project_user(uid : String, node):
	base_http.request(Global.api_url + "/check_project_upvote/?uid=" + str(uid), Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var data = json.get_data()
		if typeof(data) == 3: #Bypassa bug upvote (disable this conditon to see)
			if data == 1:
				node.get_node("container/btn/upvote/upvote_btn").texture_normal = load("res://assets/ressources/upvoted.png")

func get_time():
	base_http.request(Global.api_url + "/get_time/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		return json.get_data()

func get_project_size(path : String):
	var stack = [path]
	
	while stack.size() > 0:
		var current_path = stack.pop_back()

		var dir = DirAccess.open(current_path)
		dir.list_dir_begin()
		while true:
			var elementname = dir.get_next()
			if elementname == "":
				break
			var elementpath = current_path + "/" + elementname
			if FileAccess.file_exists(elementpath):
				var f = FileAccess.open(elementpath, FileAccess.READ)
				project_size += f.get_length()
			if dir.current_is_dir():
				if elementname != "." and elementname != "..":
					stack.append(elementpath)
	finished = true

func check_project_data(selected_file : String):
	files = []
	project_size = 0
	number_of_files = 0
	processed_file_count = 0
	finished = false
	t1 = Thread.new()
	t1.start(get_project_size.bind(selected_file))
	
func check_size_with_key_type(max_size : int):
	if int(project_size/1048576) <= max_size:
		return true
	else:
		print("Error account activation value")
		return false
		
func get_user_public_projet():
	base_http.request(Global.api_url + "/get_user_public_project/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		return json.get_data()
