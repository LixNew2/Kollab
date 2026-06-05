extends Control

@onready var http_rq : HTTPRequest = get_node("HTTPRequest")
var part_count : int

var tmp_uncompress_folder : String = Global.path + "/tmp_uncompress"
var tmp_folder : String = Global.path

var win_url : String = "https://vedgserver.space/Kollab/windows/kollab.7z"

var version_url : String = "https://vedgserver.space/Kollab/version.dat"

var online_version_path : String = Global.path + "/online_version.dat"
var online_version : String

var MacOs = false

var base_http := HTTPRequest.new()

func _ready():
	print(Time.get_datetime_string_from_system().replace("-","_").replace(":","_").replace("T", "_"))
	add_child(base_http)
	if OS.get_name() == "Windows" and OS.get_executable_path().get_base_dir() != OS.get_user_data_dir():
		if OS.get_cmdline_args().size() > 1 and OS.get_cmdline_args()[1] == "dev":
			init()
			return
		var cmd : Array = ["/C","timeout /t 1 /nobreak" + " && " + '"' + Global.path + '/kollab.exe"']
		OS.create_process("CMD.exe", cmd)
		get_tree().quit()
	else:
		init()

func init():
	DirAccess.make_dir_absolute(Global.path + "/libs")

#	Check if 7z.exe or 7zz exist
	match OS.get_name():
		"Windows":
			if !FileAccess.file_exists(Global.path + "/libs/7zr.exe"):
				await download_7z()
		"macOS":
			if !FileAccess.file_exists(Global.path + "/libs/7zz"):
				await download_7z()

	if await check_update():
		if OS.get_name() == "Windows":
			await download_7z()
			await donwload_files()
			await uncompress_files()
			await install_update()
		if OS.get_name() == "macOS":
			var update_popup = preload("res://scenes/projects/update_popup.tscn").instantiate()
			get_node("/root").add_child(update_popup)
		return

	clear_tmp_files()

	if Global.stay_connected.stay_connected == true:
		await Firebase.login(Global.stay_connected.email, Global.stay_connected.password)
		
		if Global.account_activation_value == 1 or Global.account_activation_value == 2:
			if Global.account_activation_value == 2:
					if Global.days_free_trial > 14:
						get_node("/root").add_child.call_deferred(Global.account_activation)
						var popup_free_trial_ended = preload("res://scenes/projects/free_trial_ended_popup.tscn").instantiate()
						get_node("/root").add_child.call_deferred(popup_free_trial_ended)
						queue_free()
						return
					else:
						get_node("/root").add_child.call_deferred(Global.home)
						queue_free()
						return
			else:
				if Global.days_acctivation > 365:
					get_node("/root").add_child.call_deferred(Global.account_activation)
					var popup_free_trial_ended = preload("res://scenes/projects/account_activation_time_error_popup.tscn").instantiate()
					get_node("/root").add_child.call_deferred(popup_free_trial_ended)
					queue_free()
					return
				else:
					var unique_id = await Firebase.get_unique_id()
					if unique_id == "":
						var login_register = preload("res://scenes/login_register.tscn").instantiate()
						get_node("/root").add_child(login_register)
						var link_machine_popup = preload("res://scenes/projects/link_machine_popup.tscn").instantiate()
						get_node("/root").add_child(link_machine_popup)
						await link_machine_popup.get_node("Panel/VBoxContainer/link_btn").pressed
						await Firebase.set_unique_id()
						unique_id = await Firebase.get_unique_id()
					if unique_id == str(OS.get_unique_id().replace("{","").replace("}","")):
						get_node("/root").add_child.call_deferred(Global.home)
						queue_free()
					else:
						var login_register = preload("res://scenes/login_register.tscn").instantiate()
						get_node("/root").add_child(login_register)
						var link_popup_error = preload("res://scenes/projects/link_machine_error_popup.tscn").instantiate()
						get_node("/root").add_child(link_popup_error)
						link_popup_error.get_node("Panel/VBoxContainer/Label2").text = tr("link_machine_error_message").format({"hostname": await Firebase.get_hostname()})
		else: 
			get_node("/root").add_child.call_deferred(Global.account_activation)
			queue_free()
		return

	get_node("/root").add_child(Global.login)
	queue_free()

func download_7z():
	var exe_url : String

	match OS.get_name():
		"Windows":
			exe_url = "http://vedgserver.space/Libs/7zr.exe"
			http_rq.download_file = Global.path + "/libs/7zr.exe"
		"macOS":
			MacOs = true
			exe_url = "http://vedgserver.space/Libs/7zz.tar.xz"
			http_rq.download_file = Global.path + "/libs/7zz.tar.xz"

	http_rq.request(exe_url)
	await http_rq.request_completed
	
	if MacOs:
		OS.execute("tar", ["-xvf", Global.path + "/libs/7zz.tar.xz", "-C", Global.path + "/libs"])


func check_update():
	http_rq.download_file = online_version_path
	http_rq.request(version_url)
	await http_rq.request_completed
	online_version = FileAccess.open(online_version_path, FileAccess.READ).get_as_text()

	return online_version != Global.soft_version


func donwload_files():
	DirAccess.make_dir_absolute(tmp_folder)

	var progress_bar = get_node("body/ProgressBar")
	progress_bar.show()

	http_rq.download_file = tmp_folder + "/kollab.7z"
	http_rq.request(win_url)

	await get_tree().create_timer(1).timeout
	progress_bar.max_value = http_rq.get_body_size()
	while http_rq.get_body_size() != http_rq.get_downloaded_bytes():
		progress_bar.value = http_rq.get_downloaded_bytes()
		await get_tree().process_frame


func uncompress_files():
	DirAccess.make_dir_absolute(tmp_uncompress_folder)

	var cmd = '"' + Global.zip_path + '" x "' + tmp_folder + "/kollab.7z" + '" -o"' + tmp_uncompress_folder + '" -aoa -y && echo.>"' + OS.get_user_data_dir() + '/uncompress"'
	OS.create_process("CMD.exe", ["/C", cmd])
	while !FileAccess.file_exists('user://uncompress'):
		await get_tree().process_frame
	DirAccess.remove_absolute('user://uncompress')

	await get_tree().create_timer(1).timeout


func install_update():
	http_rq.download_file = Global.soft_version
	http_rq.request(version_url)
	await http_rq.request_completed

	var cmd : Array = ["/C",'xcopy /y "' + (tmp_uncompress_folder + '/*" "' + Global.path + '/*"').replace("/", "\\") + " && " + "timeout /t 3 /nobreak" + " && " + '"' + Global.path + '/kollab.exe"']
	OS.create_process("CMD.exe", cmd)

	get_tree().quit()


func clear_tmp_files():
	DirAccess.remove_absolute(tmp_folder + "/kollab.7z")
	Global.remove_dir(tmp_uncompress_folder)


func mac_download_btn_pressed():
	OS.shell_open("https://kollabsound.com/download/")
	await get_tree().create_timer(2).timeout
	get_tree().quit()
