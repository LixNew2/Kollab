extends Node

var soft_version := "2.3.0"

var home := preload("res://scenes/home.tscn").instantiate()
var login := preload("res://scenes/login_register.tscn").instantiate()
var social := preload("res://scenes/projects/social.tscn").instantiate()
var path : String = OS.get_user_data_dir()
var account_activation := preload("res://scenes/account_activation.tscn").instantiate()

var token : String 
var email : String
var password : String
var uid : String
var token_header : PackedStringArray

const api_url := ""
#const api_url := ""

#Create project
var extension : String 
var project_path : String
var title : String
var description : String
var bpm : int
var version : String
var uuid : String

func generate_uuid_v4() -> String:
	var uuid : String = ""
	var character := "0123456789abcdef"
	
	for i in range(31):
		var random_int := randi_range(0, character.length() -1)
		var random_string := character.substr(random_int, 1)
		uuid += random_string
	
	uuid = uuid.insert(8, "-")
	uuid = uuid.insert(13, "-")
	uuid = uuid.insert(14, "4")
	uuid = uuid.insert(18, "-")
	uuid = uuid.insert(23, "-")
	
	return uuid

#Home
var index_home_shortcut_btn = 0
var index_social_btn = 0
var project_user = []
var icon = Texture2D
var icon_pressed = Texture2D

#Join project
var user_sharing_key : String

#Settings
var settings_var := {"fl_path" : "",
					 "als_path" : "",
					 "logic_path" : "",
					 "cubase_path" : "",
					 "reaper_path" : "",
					 "studio_path" : ""}
var langague : String

#Switch scene
var index := 0

#Close logout
var logout_value := 0

#Login / Register / Activate
var sign_log_index := 0
var username : String
var index_stay_connected = 0
var stay_connected := {"stay_connected" : false,
						"email" : "",
						"password" : ""}
var account_activation_value : int
var key_type : int
var get_project_number : int
var project_number : int
var user_plan : String
var user_uid : String
var days_acctivation : int
var days_free_trial : int

var zip_path := ""

#Secret password
var secret_password_index := 0

#Project
var project_more_infos_panel_index = 0

func _ready():
	var window_size = Vector2i(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()).y / 1.5 / 0.5625, DisplayServer.screen_get_size(DisplayServer.window_get_current_screen()).y / 1.5)
	DisplayServer.window_set_size(window_size)
	var crurrent_screen = DisplayServer.window_get_current_screen()
	DisplayServer.window_set_position(DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())/2.0 - window_size/2.0)
	DisplayServer.window_set_current_screen(crurrent_screen)
	DisplayServer.window_set_min_size(window_size)

	if FileAccess.file_exists("user://language.txt"):
		langague = FileAccess.open("user://language.txt", FileAccess.READ).get_as_text()
	else:
		langague = OS.get_locale_language()
		
	if FileAccess.file_exists("user://settings.dat"):
		settings_var = FileAccess.open("user://settings.dat", FileAccess.READ).get_var()

	if FileAccess.file_exists("user://connect.dat"):
		stay_connected = FileAccess.open_encrypted_with_pass("user://connect.dat", FileAccess.READ, "").get_var()

	match OS.get_name():
		"Windows":
			zip_path = OS.get_user_data_dir() + "/libs/7zr.exe"
		"macOS":
			zip_path = OS.get_user_data_dir() + "/libs/7zz"


func remove_dir(path):
	if !DirAccess.dir_exists_absolute(path):
		return
	var files = []
	var dir = DirAccess.open(path)
	dir.list_dir_begin()

	while true:
		var file = dir.get_next()
		if file == "":
			break
		elif not file.begins_with("."):
			files.append(file)

	dir.list_dir_end()

	for file in files:
		DirAccess.remove_absolute(path + "/" + file)
	DirAccess.remove_absolute(path)
	
#Edit project
var edit_projet_index := 0

#Edit member
var key_project_uuid : String

var isClicked = false

#On close window
func _notification(what):
	if Global != null and Global.account_activation_value == 2:
		if what == 1006:
			OS.shell_open("https://kollabsound.com/view-pricing")

#set comment
var project_key_selected : String

var push_is_ok = true

var crt_scene : String
var pseudo_social : String
var get_social_type = 0
