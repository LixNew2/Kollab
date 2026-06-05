extends VBoxContainer

var id_btn : String
@onready var file_dialog := $settings_box/settings_container/exe_container/exe/file_dialog
@onready var fl_path := $settings_box/settings_container/exe_container/exe/exe_path_container/left_box/fl_studio/HBoxContainer/fl_path
@onready var als_path := $settings_box/settings_container/exe_container/exe/exe_path_container/left_box/albeton_live/HBoxContainer/als_path
@onready var logic_path := $settings_box/settings_container/exe_container/exe/exe_path_container/left_box/logic_pro/HBoxContainer/logic_path
@onready var cubase_path := $settings_box/settings_container/exe_container/exe/exe_path_container/right_box/cubase/HBoxContainer/cubase_path
@onready var reaper_path := $settings_box/settings_container/exe_container/exe/exe_path_container/right_box/reaper/HBoxContainer/reaper_path
@onready var studio_path := $settings_box/settings_container/exe_container/exe/exe_path_container/right_box/studio_one/HBoxContainer/studio_path
var border := preload("res://assets/themes/border.tres")
var error_border_color := preload("res://assets/themes/error_border.tres")
var base_http := HTTPRequest.new()
@onready var type_key = get_node("../../../../container/container/side_bar/HBoxContainer/TextureRect/Label3")

func _process(delta):
	if $settings_box/settings_container/new_key_container/HBoxContainer/new_key.has_focus():
		$settings_box/settings_container/new_key_container/error_key.hide()
		$settings_box/settings_container/new_key_container/HBoxContainer/new_key.add_theme_stylebox_override("normal", border)
		
func _ready():
	#Set value exts
	set_option_btn_lang()
	
	if OS.get_name() == "macOS":
		$settings_box/settings_container/exe_container.hide()
		
	add_child(base_http)
	fl_path.text = Global.settings_var.fl_path
	als_path.text = Global.settings_var.als_path
	logic_path.text = Global.settings_var.logic_path
	cubase_path.text = Global.settings_var.cubase_path
	reaper_path.text = Global.settings_var.reaper_path
	studio_path.text = Global.settings_var.studio_path
	
	if Global.account_activation_value == 1:
		$settings_top/VBoxContainer/HBoxContainer/HBoxContainer.show()
		$settings_top/VBoxContainer/HBoxContainer/HBoxContainer/Label2.text = str(365 - Global.days_acctivation) + tr("date_day")

func settings_btns_pressed(id):
	id_btn = id
	var exts = $settings_box/settings_container/exe_container/exe/NativeFileDialog.get_filters()
	if "*.exe ; .exe" not in exts :
		$settings_box/settings_container/exe_container/exe/NativeFileDialog.add_filter("*.exe", ".exe")
	$settings_box/settings_container/exe_container/exe/NativeFileDialog.show()

func _on_native_file_dialog_file_selected(path):
	if path.ends_with(".exe"):
		$settings_box/settings_container/exe_container/exe/error.hide()
		if id_btn == "fl":
				fl_path.text = path
				Global.settings_var.fl_path = path
		elif id_btn == "als":
				als_path.text = path
				Global.settings_var.als_path = path
		elif id_btn == "logic":
				logic_path.text = path
				Global.settings_var.logic_path = path
		elif id_btn == "cubase":
				cubase_path.text = path
				Global.settings_var.cubase_path = path
		elif id_btn == "reaper":
				reaper_path.text = path
				Global.settings_var.reaper_path = path
		elif id_btn == "studio":
				studio_path.text = path
				Global.settings_var.studio_path = path
	else:
		$settings_box/settings_container/exe_container/exe/error.show()

func confirm_settings():
	if $settings_box/settings_container/new_key_container/HBoxContainer/new_key.text != "":
		var link_machine_popup = preload("res://scenes/projects/link_machine_popup.tscn").instantiate()
		get_node("/root").add_child(link_machine_popup)
		await link_machine_popup.get_node("Panel/VBoxContainer/link_btn").pressed
		var body = JSON.stringify({"key": str($settings_box/settings_container/new_key_container/HBoxContainer/new_key.text), "unique_id": str(OS.get_unique_id()).replace("{","").replace("}",""), "hostname": str(OS.get_environment("COMPUTERNAME") if OS.get_name() == "Windows" else OS.get_environment("HOSTNAME")), "timestemp":Time.get_unix_time_from_system()})
		base_http.request(Global.api_url + "/active_account/", Global.token_header, HTTPClient.METHOD_POST, body)
	
		var result = await base_http.request_completed as Array
		if result[1] == 200:
			var result_body = int(result[3].get_string_from_ascii())
			if result_body == 1:
				await Firebase.get_projetc_number()
				base_http.request(Global.api_url + "/edit_project_number/?nbr=" + str(Global.get_project_number - Global.project_number), Global.token_header, HTTPClient.METHOD_POST)
				var result2 = await base_http.request_completed as Array
				if result2[1] == 200:
					await Firebase.get_projetc_number()
					var update_version_popup = preload("res://scenes/projects/upgrade_version_popup.tscn").instantiate()
					match await Firebase.get_key_type():
						1:
							Global.user_plan = "Basic Plan"
							get_node("/root").add_child(update_version_popup)
							update_version_popup.get_node("Panel/VBoxContainer/Label2").text = "Basic Plan"
						2:
							Global.user_plan = "Standard Plan"
							get_node("/root").add_child(update_version_popup)
							update_version_popup.get_node("Panel/VBoxContainer/Label2").text = "Standard Plan"
						3:
							Global.user_plan = "Premium Plan"
							get_node("/root").add_child(update_version_popup)
							update_version_popup.get_node("Panel/VBoxContainer/Label2").text = "Premium Plan"
							
					$settings_box/settings_container/new_key_container/HBoxContainer/new_key.text = ""
			else:
				$settings_box/settings_container/new_key_container/HBoxContainer/new_key.add_theme_stylebox_override("normal", error_border_color)
				$settings_box/settings_container/new_key_container/error_key.show()
				return
		else:
			$settings_box/settings_container/new_key_container/HBoxContainer/new_key.add_theme_stylebox_override("normal", error_border_color)
			$settings_box/settings_container/new_key_container/error_key.show()
			return
	
	var all_path = [fl_path, als_path, logic_path, cubase_path, reaper_path, studio_path]
	
	for path in all_path:
		if not path.text.ends_with(".exe") and path.text != "":
			$settings_box/settings_container/exe_container/exe/error.show()
			return

	Global.settings_var.fl_path = fl_path.text
	Global.settings_var.als_path = als_path.text
	Global.settings_var.logic_path = logic_path.text
	Global.settings_var.cubase_path = cubase_path.text
	Global.settings_var.reaper_path = reaper_path.text
	Global.settings_var.studio_path = studio_path.text
	$settings_box/settings_container/exe_container/exe/error.hide()
	
	var langague = $settings_box/settings_container/language/HBoxContainer/choice_lang.get_item_text($settings_box/settings_container/language/HBoxContainer/choice_lang.get_selected())
	var lang = "fr" if langague == "Français" or langague == "French" else "en"
	Global.langague = lang
	TranslationServer.set_locale(lang)
	FileAccess.open("user://language.txt", FileAccess.WRITE).store_string(lang)
	set_option_btn_lang()
	
	FileAccess.open("user://settings.dat", FileAccess.WRITE).store_var(Global.settings_var)
	Global.home.get_node("container/container/side_bar/VBoxContainer/home_btn").button_pressed = true
	Global.home._on_home_btn_pressed()

func set_option_btn_lang():
	$settings_box/settings_container/language/HBoxContainer/choice_lang.clear()
	var langs = []
	
	if Global.langague != "":
		langs = ["Français", "Anglais"] if Global.langague == "fr" else ["English", "French"]
	else:
		langs = ["Français", "Anglais"] if OS.get_locale_language() == "fr" else ["English", "French"]

	for lang in langs:
			$settings_box/settings_container/language/HBoxContainer/choice_lang.add_item(lang)
			
func _on_buy_key_btn_pressed():
	OS.shell_open("https://kollabsound.com/view-pricing/")

func _on_terms_of_use_pressed():
	$settings_box/settings_container/confirm_btn_container/VBoxContainer2/terms_of_use.disabled = true
	var licenses = preload("res://scenes/terms_condition_of_use/terms_condition_use.tscn").instantiate()
	get_node("/root").add_child(licenses)
	await get_tree().create_timer(3).timeout
	$settings_box/settings_container/confirm_btn_container/VBoxContainer2/terms_of_use.disabled = false
