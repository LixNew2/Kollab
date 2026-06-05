extends Control

var base_http = HTTPRequest.new()

@onready var project_infos_panel := $container/project_infos_panel
@onready var btn := $container/btn
@onready var version := $container/project_version
@onready var bpm := $container/project_bpm
@onready var rights := $container/project_rights
#@onready var desc := $container/project_desc
@onready var name_p := $container/project_name
@onready var label := $container/Label
@onready var key := $container/project_infos_panel/HBoxContainer/project_right_button/sharing_key
@onready var lvl := $container/project_lvl
@onready var date := $container/project_date

var settings = {}
var project_infos = {}
var ext : String
var a = 0
var info_popup

func _ready():
	add_child(base_http)
	$size/size.text = "Calcule en cours..." if TranslationServer.get_locale() == "fr" else "Calculating in progress..."
	
func _process(delta):
	if $error.is_visible():
		await get_tree().create_timer(3).timeout
		$error.hide()
		$container.show()
		$container/btn/loading.hide()
		$container/btn/project_update.show()
		$container/btn/project_push.show()
		
func _on_more_infos_btn_pressed():
	if Global.project_more_infos_panel_index == 0:
		Global.project_more_infos_panel_index = 1
		$ColorRect2.color = "121214"
		btn.hide()
		version.hide()
		bpm.hide()
		rights.hide()
#		desc.hide()
		date.hide()
		name_p.hide()
		label.hide()
		project_infos_panel.show()
		$container/project_plat.hide()
	else:
		Global.project_more_infos_panel_index = 0
		btn.show()
		version.show()
		bpm.show()
		rights.show()
#		desc.show()
		date.show()
		name_p.show()
		label.show()
		project_infos_panel.hide()
		if label.text == "...":
			$container/project_plat.show()
			$container/Label.hide()

func _on_copy_btn_pressed():
	DisplayServer.clipboard_set(key.text)

func _on_delete_project_btn_pressed():
	var delete_popup = preload("res://scenes/projects/delete_popup.tscn").instantiate()
	get_node("/root").add_child(delete_popup)
	await delete_popup.get_node("Panel/VBoxContainer/delete_btn").pressed
	delete_popup.queue_free()
	delete_project(int(lvl.text), str(key.text))

func delete_project(lvl: int, data: String):
	if FileAccess.file_exists("user://" + key.text + ".dat"):
		DirAccess.remove_absolute("user://" + key.text + ".dat")
		
	if FileAccess.file_exists("user://" + key.text + ".7z"):
		DirAccess.remove_absolute("user://" + key.text + ".7z")
		
	if DirAccess.dir_exists_absolute("user://" + '/backups/' + key.text):
		Global.remove_dir("user://" + '/backups/' + key.text)
		
	var body = JSON.stringify({"lvl":lvl, "data":data})
	base_http.request(Global.api_url + "/delete_project/", Global.token_header, HTTPClient.METHOD_POST, body)
	await base_http.request_completed
	base_http.request(Global.api_url + "/edit_project_number/?nbr=" + str(Global.get_project_number + 1), Global.token_header, HTTPClient.METHOD_POST)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		if lvl == 0:
			var max_users_project = await ProjectsManager.get_project_max_users(data)
			print(max_users_project)
			await ProjectsManager.upload_new_max_user_project(data, max_users_project + 1)
			Firebase.get_projetc_number()
		Global.get_project_number += 1
		get_node("../../../..").load_projects()

func edit_project():
	var edit_project_popup = preload("res://scenes/projects/edit_projet_popup.tscn").instantiate()
	get_node("/root").add_child(edit_project_popup)
	
	#var project infos
	var tmp_infos_project = await ProjectsManager.get_project_info(str(key.text))
	var project_data = tmp_infos_project["project_data"]
	var project_ext := edit_project_popup.get_node("Panel/VBoxContainer/exts")
	var project_name := edit_project_popup.get_node("Panel/VBoxContainer/title_line_edit")
	var project_desc := edit_project_popup.get_node("Panel/VBoxContainer/desc_project_line_edti")
	var project_bpm := edit_project_popup.get_node("Panel/VBoxContainer/bpm")
	var platform_version := edit_project_popup.get_node("Panel/VBoxContainer/version_platform_line_edit")
	var users_max := edit_project_popup.get_node("Panel/VBoxContainer/users_max")
	var public_btn := edit_project_popup.get_node("Panel/VBoxContainer/HBoxContainer/public_btn")
	
	#get project info
	project_ext.add_item(project_data["project_plat"]) 
	project_name.text = project_data["project_name"]
	project_desc.text = project_data["project_desc"]
	project_bpm.value = int(project_data["project_bpm"])
	platform_version.text = project_data["project_plat_version"]
	users_max.value = int(project_data["project_max_user"])
	public_btn.button_pressed = project_data["public"]
	
	if project_data["public"]:
			edit_project_popup.get_node("Panel/VBoxContainer/users_max").hide()
			edit_project_popup.get_node("Panel/VBoxContainer/users_max_label").hide()
			edit_project_popup.public = 1
			
	#Set value exts
	var exts = [".flp", ".als", ".logic", ".cpr", ".rpp", ".song"]
	for ext in exts:
		if ext != project_ext.get_item_text(0):
			project_ext.add_item(ext)
	
	while true:
		await edit_project_popup.get_node("Panel/VBoxContainer/edit_btn").pressed
		
		#set new project infos
		if project_name.text != "":
			var max_users_project = await ProjectsManager.get_project_max_users(key.text)
			var body = JSON.stringify({"project_uid": key.text, "project_name": project_name.text, "project_desc": project_desc.text, "project_bpm": int(project_bpm.value), "project_plat_version": platform_version.text, "project_max_user": int(users_max.value), "project_plat" : project_ext.get_item_text(project_ext.get_selected()), "project_date" : Time.get_unix_time_from_system(), "public" : public_btn.button_pressed})
			base_http.request(Global.api_url + "/edit_project/", Global.token_header, HTTPClient.METHOD_POST, body)
			await base_http.request_completed
			
			#Clear project extension
			if project_ext.get_item_text(project_ext.get_selected()) != project_data["project_plat"]:
				if FileAccess.file_exists("user://" + key.text + ".dat"):
					var project_values = FileAccess.open("user://" + key.text + ".dat", FileAccess.READ).get_var()
					if project_values.has("exe_path"):
						project_values.erase("exe_path")
						FileAccess.open("user://" + key.text + ".dat", FileAccess.WRITE).store_var(project_values)
					
			info_popup.queue_free()
			get_node("../../../..").load_projects()
			info_popup.queue_free()
			edit_project_popup.queue_free()
		
		edit_project_popup.get_node("Panel/VBoxContainer/error").show()

func infos_project():
	Global.key_project_uuid = key.text
	var member_popup = preload("res://scenes/projects/members_popup.tscn").instantiate()
	get_node("/root").add_child(member_popup)

func _on_infos_project_pressed():
	info_popup = preload("res://scenes/projects/infos_project_popup.tscn").instantiate()
	get_node("/root").add_child(info_popup)
	info_popup.get_node("Panel/VBoxContainer/edit_project_btn").connect("pressed", edit_project.bind())
	info_popup.get_node("Panel/VBoxContainer/infos_btn").connect("pressed", infos_project.bind())


func open_project():
	project_infos = FileAccess.open("user://" + key.text + ".dat", FileAccess.READ).get_var()
	var file_not_found = preload("res://scenes/projects/file_not_found_popup.tscn").instantiate()
	
	if not FileAccess.file_exists("user://settings.dat"):
		FileAccess.open("user://settings.dat", FileAccess.WRITE).store_var(Global.settings_var)
	
	if label.text != "...":
		var exts = $container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.get_filters()
		match label.text:
			".flp" :
				if "*.flp ; .flp" not in exts :
					$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.add_filter("*.flp", ".flp")
				$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.set_title("title_filedialog_flp")
				ext = ".flp" 
				
				if OS.get_name() == "Windows":
					if Global.settings_var.fl_path != "":
						if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
							var t1 = Thread.new()
							t1.start(lanch_plat.bind(Global.settings_var.fl_path, project_infos.exe_path))
						else:
							if project_infos.has("exe_path"):
								await if_project_not_valid(file_not_found)
							$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
					else:
						var exe_error_popup = preload("res://scenes/projects/exe_error_popup.tscn").instantiate()
						get_node("/root").add_child(exe_error_popup)
						await exe_error_popup.get_node("Panel/VBoxContainer/set_executable_btn").pressed
						get_node("../../../../../../../../..")._on_settings_btn_pressed()
						exe_error_popup.queue_free()
				else:
					if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
						var t1 = Thread.new()
						t1.start(lanch_plat.bind("open", project_infos.exe_path))
					else:
						if project_infos.has("exe_path"):
							await if_project_not_valid(file_not_found)
						$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
			".als" : 
				if "*.als ; .als" not in exts :
					$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.add_filter("*.als", ".als")
				$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.set_title("title_filedialog_als") 
				ext = ".als" 
				
				if OS.get_name() == "Windows":
					if Global.settings_var.als_path != "":
						if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
							var t1 = Thread.new()
							t1.start(lanch_plat.bind(Global.settings_var.als_path, project_infos.exe_path))
						else:
							if project_infos.has("exe_path"):
								await if_project_not_valid(file_not_found)
							$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
					else:
						var exe_error_popup = preload("res://scenes/projects/exe_error_popup.tscn").instantiate()
						get_node("/root").add_child(exe_error_popup)
						await exe_error_popup.get_node("Panel/VBoxContainer/set_executable_btn").pressed
						get_node("../../../../../../../../..")._on_settings_btn_pressed()
						exe_error_popup.queue_free()
				else:
					if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
						var t1 = Thread.new()
						t1.start(lanch_plat.bind("open", project_infos.exe_path))
					else:
						if project_infos.has("exe_path"):
							await if_project_not_valid(file_not_found)
						$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
			".logic" :
				if "*.logic ; .logic" not in exts :
					$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.add_filter("*.logic", ".logic")
				$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.set_title("title_filedialog_logic") 
				ext = ".logic" 
				
				if OS.get_name() == "Windows":
					if Global.settings_var.logic_path != "":
						if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
							var t1 = Thread.new()
							t1.start(lanch_plat.bind(Global.settings_var.als_path, project_infos.exe_path))
						else:
							if project_infos.has("exe_path"):
								await if_project_not_valid(file_not_found)
							$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
					else:
						var exe_error_popup = preload("res://scenes/projects/exe_error_popup.tscn").instantiate()
						get_node("/root").add_child(exe_error_popup)
						await exe_error_popup.get_node("Panel/VBoxContainer/set_executable_btn").pressed
						get_node("../../../../../../../../..")._on_settings_btn_pressed()
						exe_error_popup.queue_free()
				else:
					if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
						var t1 = Thread.new()
						t1.start(lanch_plat.bind("open", project_infos.exe_path))
					else:
						if project_infos.has("exe_path"):
							await if_project_not_valid(file_not_found)
						$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
			".cpr" :
				if "*.cpr ; .cpr" not in exts :
					$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.add_filter("*.cpr", ".cpr")
				$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.set_title("title_filedialog_cpr") 
				ext = ".cpr" 
				
				if OS.get_name() == "Windows":
					if Global.settings_var.cubase_path != "":
						if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
							var t1 = Thread.new()
							t1.start(lanch_plat.bind(Global.settings_var.cubase_path, project_infos.exe_path))
						else:
							if project_infos.has("exe_path"):
								await if_project_not_valid(file_not_found)
							$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
					else:
						var exe_error_popup = preload("res://scenes/projects/exe_error_popup.tscn").instantiate()
						get_node("/root").add_child(exe_error_popup)
						await exe_error_popup.get_node("Panel/VBoxContainer/set_executable_btn").pressed
						get_node("../../../../../../../../..")._on_settings_btn_pressed()
						exe_error_popup.queue_free()
				else:
					if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
						var t1 = Thread.new()
						t1.start(lanch_plat.bind("open", project_infos.exe_path))
					else:
						if project_infos.has("exe_path"):
							await if_project_not_valid(file_not_found)
						$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
			".rpp" : 
				if "*.rpp ; .rpp" not in exts :
					$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.add_filter("*.rpp", ".rpp")
				$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.set_title("title_filedialog_rpp") 
				ext = ".rpp" 
				
				if OS.get_name() == "Windows":
					if Global.settings_var.reaper_path != "":
						if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
							var t1 = Thread.new()
							t1.start(lanch_plat.bind(Global.settings_var.reaper_path, project_infos.exe_path))
						else:
							if project_infos.has("exe_path"):
								await if_project_not_valid(file_not_found)
							$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
					else:
						var exe_error_popup = preload("res://scenes/projects/exe_error_popup.tscn").instantiate()
						get_node("/root").add_child(exe_error_popup)
						await exe_error_popup.get_node("Panel/VBoxContainer/set_executable_btn").pressed
						get_node("../../../../../../../../..")._on_settings_btn_pressed()
						exe_error_popup.queue_free()
				else:
					if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
						var t1 = Thread.new()
						t1.start(lanch_plat.bind("open", project_infos.exe_path))
					else:
						if project_infos.has("exe_path"):
							await if_project_not_valid(file_not_found)
						$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
			".song":
				if "*.song ; .song" not in exts :
					$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.add_filter("*.song", ".song")
				$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.set_title("title_filedialog_song") 
				ext = ".song" 
				
				if OS.get_name() == "Windows":
					if Global.settings_var.studio_path != "":
						if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
							var t1 = Thread.new()
							t1.start(lanch_plat.bind(Global.settings_var.studio_path, project_infos.exe_path))
						else:
							if project_infos.has("exe_path"):
								await if_project_not_valid(file_not_found)
							$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
					else:
						var exe_error_popup = preload("res://scenes/projects/exe_error_popup.tscn").instantiate()
						get_node("/root").add_child(exe_error_popup)
						await exe_error_popup.get_node("Panel/VBoxContainer/set_executable_btn").pressed
						get_node("../../../../../../../../..")._on_settings_btn_pressed()
						exe_error_popup.queue_free()
				else:
					if project_infos.has("exe_path") and FileAccess.file_exists(project_infos.exe_path):
						var t1 = Thread.new()
						t1.start(lanch_plat.bind("open", project_infos.exe_path))
					else:
						if project_infos.has("exe_path"):
							await if_project_not_valid(file_not_found)
						$container/project_infos_panel/HBoxContainer/open_btn/NativeFileDialog.show()
	else:
		if project_infos.project_folder.get_extension() != "":
			if DirAccess.dir_exists_absolute(project_infos.project_folder.get_base_dir()):
				if OS.get_name() == "Windows":
					OS.shell_open(project_infos.project_folder.get_base_dir())
				elif OS.get_name() == "macOS":
					OS.execute("open", [project_infos.project_folder.get_base_dir()])
			else:
				file_not_found.get_node("Panel/VBoxContainer/Label2").text = project_infos.project_folder.get_base_dir()
				get_node("/root").add_child(file_not_found)
		else:
			if DirAccess.dir_exists_absolute(project_infos.project_folder):
				if OS.get_name() == "Windows":
					OS.shell_open(project_infos.project_folder)
				elif OS.get_name() == "macOS":
					OS.execute("open", [project_infos.project_folder])
			else:
				file_not_found.get_node("Panel/VBoxContainer/Label2").text = project_infos.project_folder
				get_node("/root").add_child(file_not_found)
			
func if_project_not_valid(file_not_found):
	file_not_found.get_node("Panel/VBoxContainer/Label2").text = project_infos.exe_path
	file_not_found.get_node("Panel/VBoxContainer/Label").text = "project_not_found"
	file_not_found.get_node("Panel/VBoxContainer/Label3").show()
	file_not_found.get_node("Panel/VBoxContainer/reconfig_btn").show()
	get_node("/root").add_child(file_not_found)
	await file_not_found.get_node("Panel/VBoxContainer/reconfig_btn").pressed
	file_not_found.queue_free()

func _on_native_file_dialog_file_selected(path):
	project_infos["exe_path"] = path
	FileAccess.open("user://" + key.text + ".dat", FileAccess.WRITE).store_var(project_infos)
	var t1 = Thread.new()
	match ext:
		".flp" :
			if OS.get_name() == "Windows":
				t1.start(lanch_plat.bind(Global.settings_var.fl_path, path))
			else:
				t1.start(lanch_plat.bind("open", path))
		".als":
			if OS.get_name() == "Windows":
				t1.start(lanch_plat.bind(Global.settings_var.als_path, path))
			else:
				t1.start(lanch_plat.bind("open", path))
		".logic":
			if OS.get_name() == "Windows":
				t1.start(lanch_plat.bind(Global.settings_var.logic_path, path))
			else:
				t1.start(lanch_plat.bind("open", path))
		".cpr":
			if OS.get_name() == "Windows":
				t1.start(lanch_plat.bind(Global.settings_var.cubase_path, path))
			else:
				t1.start(lanch_plat.bind("open", path))
		".rpp":
			if OS.get_name() == "Windows":
				t1.start(lanch_plat.bind(Global.settings_var.reaper_path, path))
			else:
				t1.start(lanch_plat.bind("open", path))
		".song":
			if OS.get_name() == "Windows":
				t1.start(lanch_plat.bind(Global.settings_var.studio_path, path))
			else:
				t1.start(lanch_plat.bind("open", path))

func lanch_plat(open_path, file_path):
	#var file_not_found_popup = preload("res://scenes/projects/file_not_found_popup.tscn").instantiate()
	#file_not_found_popup.get_node("Panel/VBoxContainer/Label").text = "file_not_found2"
	#
	#if OS.get_name() == "Windows":
		#if !FileAccess.file_exists(open_path):
			#file_not_found_popup.get_node("Panel/VBoxContainer/Label2").text = open_path
			#get_node("/root").add_child(file_not_found_popup)
			#return
	
	OS.execute(open_path, [file_path])

#func get_process_pid(process_name : String):
#	var regex = RegEx.new()
#	var output = []
#	var pattern = "\\d{1,5}"
#
#	match OS.get_name():
#		"Windows": 
#			pass
#		"MacOS":
#			pass
#
#	OS.execute("tasklist", ["/FI", "IMAGENAME eq cmd.exe"], output, true)
#	regex.compile(pattern)
#	var match_pid = regex.search(str(output))
#	return match_pid.get_string()

func _on_mouse_entered():
	if $ColorRect2.color != Color('020a31'):
		$ColorRect2.color = "232426"

func _on_mouse_exited():
	if $ColorRect2.color != Color('020a31'):
		$ColorRect2.color = "121214"

func _on_gui_input(event):
	toggle_item_project(event)

func toggle_item_project(event):
	if event is InputEventMouseButton and event.pressed:
		for child in get_parent().get_children():
			var colorrect = child.get_node("ColorRect2")
			if get_instance_id() != child.get_instance_id():
				colorrect.color = '121214'
			if get_instance_id() == child.get_instance_id():
				colorrect.color = '020a31'

func get_event(event):
	if event is InputEventMouseButton and event.double_click == true and event.button_index == 1 :
		open_project()

func _on_sharing_key_gui_input(event):
	if event is InputEventMouseButton and event.pressed == true:
		var sharing_key = $container/project_infos_panel/HBoxContainer/project_right_button/sharing_key.text
		DisplayServer.clipboard_set(key.text)
		if TranslationServer.get_locale() == "fr":
			$container/project_infos_panel/HBoxContainer/project_right_button/sharing_key.text = "Copié !"
		else:
			$container/project_infos_panel/HBoxContainer/project_right_button/sharing_key.text = "Copied !"
		await get_tree().create_timer(1.5).timeout
		$container/project_infos_panel/HBoxContainer/project_right_button/sharing_key.text = sharing_key

func _on_history_btn_pressed():
	if OS.get_name() == "Windows":
		OS.shell_open(OS.get_user_data_dir() + "/backups/" + $container/project_infos_panel/HBoxContainer/project_right_button/sharing_key.text)
	elif OS.get_name() == "macOS":
		OS.execute("open", [OS.get_user_data_dir() + "/backups/" + $container/project_infos_panel/HBoxContainer/project_right_button/sharing_key.text])
