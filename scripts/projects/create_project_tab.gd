extends ColorRect

var selected_plat : String
var selected_title : String
var selected_file : String
var selected_desc : String
var selected_bpm : int
var selected_version : String
var selected_max_user := 99999

#Error
@onready var platform_error = $container/left_side/platform/error
@onready var title_error = $container/left_side/title/error
@onready var file_error = $container/left_side/file/error
var error := false

var base_http := HTTPRequest.new()
var uid : String

var plat_type = 0
var public = 0

var project_size = 0
var number_of_files = 0
var processed_file_count = 0
var files = []
var confirm_size = false
var old_file : String
var finished = false
var id_thread : String
var t1 : Thread
var size_project = 0
const FILES_PER_BATCH = 10

func _ready():
	if Global.key_type == 1:
		size_project = 250
	elif Global.key_type == 2:
		size_project = 500
	elif Global.key_type == 3:
		size_project = 1500
	else:
		size_project = 100
		return
	
	var spin_box_get_line_edit = $container/right_side/bpm/bpm.get_line_edit()
	var spin_box_get_line_edit1 = $container/right_side/max_users/max_users.get_line_edit()
	spin_box_get_line_edit.context_menu_enabled = false
	spin_box_get_line_edit1.context_menu_enabled = false
	get_viewport().files_dropped.connect(on_files_dropped)
	add_child(base_http)
	
func _process(delta):
	if finished:
		var language = TranslationServer.get_locale()
		var size_mo = project_size/1048576
		if size_mo <=0 : 
			$container/left_side/file/bg_panel/VBoxContainer/size.text = "< 0Mo" if language == "fr" else "< 0MB"
		elif size_mo >=1 and size_mo <=999:
			$container/left_side/file/bg_panel/VBoxContainer/size.text = str(size_mo) + "Mo" if language == "fr" else str(size_mo) + "MB"
		else:
			$container/left_side/file/bg_panel/VBoxContainer/size.text = str(snapped(size_mo/float(1024), 0.01)) + "Go" if language == "fr" else str(snapped(size_mo/float(1024), 0.01)) + "GB"
		$container/right_side/create_project_container/create_project_btn.disabled = false
		$container/right_side/create_project_container/back_btn.disabled = false
		button_status(false)
		confirm_size = check_size_with_key_type()
		finished = false
		
func create_project():
	var date = str(Time.get_unix_time_from_system())

	#if TranslationServer.get_locale() == "fr":
		#date = str(date.day) + "/" + str(date.month) + "/" + str(date.year)
	#else:
		#date = str(date.month) + "/" + str(date.day) + "/" + str(date.year)
		
	if plat_type == 0:
		if selected_plat == "" :
			platform_error.show()
			error = true
	else:
		selected_plat = "..."
			
	if selected_title == "" :
		title_error.show()
		error = true
	if selected_file == "" :
		file_error.show()
		error = true
	if !confirm_size:
		if size_project < 1000:
			$container/left_side/file/error2.text = tr("size_file_error").format({"size": str(size_project)})
		else:
			$container/left_side/file/error2.text = tr("size_file_error_gb").format({"size": str(size_project/1000.00)})
		$container/left_side/file/error2.show()
		error = true
		
	if error:
		error = false
		return
	
	var file_not_found = preload("res://scenes/projects/file_not_found_popup.tscn").instantiate()
	if selected_file.get_extension() != "":
		print("file")
		if FileAccess.file_exists(selected_file) != true:
			file_not_found.get_node("Panel/VBoxContainer/Label2").text = selected_file
			file_not_found.get_node("Panel/VBoxContainer/Label").text = "files_not_found"
			get_node("/root").add_child(file_not_found)
			return
	else:
		print("dir")
		if DirAccess.dir_exists_absolute(selected_file) != true:
			file_not_found.get_node("Panel/VBoxContainer/Label2").text = selected_file
			get_node("/root").add_child(file_not_found)
			return

	print(selected_plat, selected_title, selected_file, selected_desc, selected_bpm, selected_version, selected_max_user)
	$container/right_side/create_project_container/back_btn.hide()
	uid = Global.generate_uuid_v4()
	$container/right_side/create_project_container/loading.show()
	$container/right_side/create_project_container/create_project_btn.hide()
	button_status(true)
	base_http.request(Global.api_url + "/edit_project_number/?nbr=" + str(Global.get_project_number - 1), Global.token_header, HTTPClient.METHOD_POST)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		await ProjectsManager.create_project(uid, selected_title, selected_desc, selected_plat, selected_bpm, selected_version, selected_file, selected_max_user, date, $container/right_side/public/public_btn.button_pressed)
		Firebase.get_projetc_number()
		get_node("..")._on_my_project_btn_pressed()
		Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").button_pressed = true
		$container/right_side/create_project_container/back_btn.show()
		clear_all()
	$container/right_side/create_project_container/loading.hide()
	$container/right_side/create_project_container/create_project_btn.show()
	button_status(false)
		
func button_status(statut):
	Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").disabled = statut
	Global.home.get_node("container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/my_project_btn").disabled = statut
	Global.home.get_node("container/container/body/projects/top_bar/container/Home/join_btn").disabled = statut
	Global.home.get_node("container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/join_btn").disabled = statut
	
func on_files_dropped(files):
	check_file(files)
	
func check_file(files):
	var file_node := get_node("container/left_side/file")

	if plat_type == 0:
		if DirAccess.dir_exists_absolute(str(files[0])):
			$container/left_side/file/error2.hide()
		else:
			$container/left_side/file/error2.show()
			return
	else: 
		if DirAccess.dir_exists_absolute(str(files[0])):
			$container/left_side/file/error2.hide()
		else:
			$container/left_side/file/error2.show()
			return
			
	file_node.get_node("bg_panel/VBoxContainer/path").text = str(files[0])
	selected_file = str(files[0])
	file_error.hide()
	$container/left_side/file/error2.hide()
	$container/left_side/file/bg_panel/VBoxContainer/size.show()
	$container/left_side/file/bg_panel/VBoxContainer/size.text = "Calcule en cours..." if TranslationServer.get_locale() == "fr" else "Calculating in progress..."
	$container/right_side/create_project_container/create_project_btn.disabled = true
	$container/right_side/create_project_container/back_btn.disabled = true
	button_status(true)
	await get_tree().create_timer(1).timeout
	confirm_size = await check_project_data()
	
func platform_btn_pressed(ext: String):
	platform_error.hide()
	selected_plat = ext

func title_text_changed(new_text):
	selected_title = new_text
	title_error.hide()

func set_desc():
	selected_desc = get_node("container/left_side/desc/desc").text

func bpm_value_changed(value):
	selected_bpm = value

func version_text_changed(new_text):
	selected_version = new_text

func _on_max_users_value_changed(value):
	selected_max_user = value

func choice_plat(extra_arg_0):
	$choice_plat.hide()
	$container.show()
	
	if extra_arg_0 == 1:
		plat_type = 1
		$container/left_side/platform.hide()
		$container/left_side/file/Label4.text = "choose_f_p_o"

func clear_all():
	plat_type = 0
	$container/left_side/platform.show()
	$container/left_side/file/Label4.text = "choose_f_p"
	$choice_plat.show()
	$container.hide()
	platform_error.hide()
	file_error.hide()
	title_error.hide()
	$container/left_side/file/bg_panel/VBoxContainer/path.text = "drag_and_drop"
	$container/left_side/desc/desc.clear()
	$container/left_side/title/title.clear()
	$container/right_side/bpm/bpm.value = 0
	$container/right_side/max_users/max_users.value = 99999
	$container/right_side/version/LineEdit4.clear()
	selected_plat = ""
	selected_title = ""
	selected_file = ""
	selected_desc = ""
	selected_bpm = 0
	selected_version = ""
	selected_max_user = 99999
	$container/left_side/platform/platform/HBoxContainer/fl_btn.button_pressed = false
	$container/left_side/platform/platform/HBoxContainer/als_btn.button_pressed = false
	$container/left_side/platform/platform/HBoxContainer/logic_btn.button_pressed = false
	$container/left_side/platform/platform/HBoxContainer/cubase_btn.button_pressed = false
	$container/left_side/platform/platform/HBoxContainer/reaper_btn.button_pressed = false
	$container/left_side/platform/platform/HBoxContainer/studio_btn.button_pressed = false
	$container/left_side/file/bg_panel/VBoxContainer/size.hide()
	$container/left_side/file/error2.hide()
	$container/left_side/file/error2.text = "path_dir_error"
	finished = false
	$container/right_side/max_users.show()
	public = 0
	$container/right_side/public/public_btn.button_pressed = false
	
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

func check_project_data():
	files = []
	confirm_size = false
	project_size = 0
	number_of_files = 0
	processed_file_count = 0
	t1 = Thread.new()
	t1.start(get_project_size.bind(selected_file))
	
func check_size_with_key_type():
	if int(project_size/1048576) <= size_project:
		return true
	return false

func _on_v_box_container_gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		$container/left_side/file/bg_panel/NativeFileDialog.show()
		
func _on_native_file_dialog_dir_selected(dir):
	check_file([dir])


func _on_public_btn_pressed():
	if Global.key_type == 3:
		if public == 0:
			$container/right_side/max_users.hide()
			public = 1
		else:
			$container/right_side/max_users.show()
			public = 0
	else:
		var public_project_popup = preload("res://scenes/projects/public_project_popup.tscn").instantiate()
		add_child(public_project_popup)
		$container/right_side/public/public_btn.button_pressed = false
