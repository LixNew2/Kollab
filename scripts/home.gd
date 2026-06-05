extends Control

@onready var label := $container/container/side_bar/HBoxContainer/TextureRect/Label
@onready var logout_container := $container/container/side_bar/HBoxContainer/TextureRect/logout_container
@onready var type_key := $container/container/side_bar/HBoxContainer/TextureRect/Label3
var base_http := HTTPRequest.new()

func _ready():
	TranslationServer.set_locale(Global.langague)
	get_node("container/container/side_bar/VBoxContainer/Label").text = "Version : " + Global.soft_version
	add_child(base_http)
	await get_random_icon()
	$container/container/side_bar/HBoxContainer/TextureRect.texture_normal = Global.icon
	Global.user_uid = await Firebase.get_user_id()
	label.text = Global.username
	match Global.key_type:
		1:
			Global.user_plan = "Basic Plan"
		2:
			Global.user_plan = "Standard Plan"
		3:
			Global.user_plan = "Premium Plan"
	
	if Global.account_activation_value == 2:
		Global.user_plan = tr("free_trial").format({"time": str(14 - Global.days_free_trial) + tr("date_day")})
		
	var conditions = await Firebase.conditons_of_use(TranslationServer.get_locale())
	if FileAccess.open("user://conditions.dat", FileAccess.READ).get_as_text() != conditions:
		var change_condition = preload("res://scenes/terms_condition_of_use/terms_condition_use_change.tscn").instantiate()
		get_node("/root").add_child(change_condition)
		
func _process(delta):
	type_key.text = Global.user_plan
			
func _on_home_btn_pressed():
	if Global.index_home_shortcut_btn == 0:
		Global.index_home_shortcut_btn = 1
		$container/container/side_bar/VBoxContainer/HBoxContainer.show()
	else:
		Global.index_home_shortcut_btn = 0
		$container/container/side_bar/VBoxContainer/HBoxContainer.hide()

	Global.index_social_btn = 0
	$container/container/side_bar/VBoxContainer/social_btn_other.hide()
	$container/container/body/settings.hide()
	$container/container/body/public_projects.hide()
	$container/container/body/social.hide()
	$container/container/body/projects.show()
	$container/container/body/user_profile.hide()
	Global.crt_scene = ""

func _on_settings_btn_pressed():
	$container/container/side_bar/VBoxContainer/HBoxContainer.hide()
	$container/container/side_bar/VBoxContainer/social_btn_other.hide()
	$container/container/body/user_profile.hide()
	Global.index_home_shortcut_btn = 0
	Global.project_more_infos_panel_index = 0
	Global.index_social_btn = 0
	$container/container/body/projects.hide()
	$container/container/body/public_projects.hide()
	$container/container/body/social.hide()
	$container/container/body/settings.show()
	Global.crt_scene = ""

func _on_social_btn_pressed():
	if Global.index_social_btn == 0:
		$container/container/side_bar/VBoxContainer/social_btn_other.show()
		Global.index_social_btn = 1
	else:
		$container/container/side_bar/VBoxContainer/social_btn_other.hide()
		Global.index_social_btn = 0
	Global.index_home_shortcut_btn = 0
	get_node("container/container/body/social/top_bar/container/Home/my_profile_btn").button_pressed = true
	$container/container/side_bar/VBoxContainer/HBoxContainer.hide()
	$container/container/body/settings.hide()
	$container/container/body/public_projects.hide()
	$container/container/body/social.show()
	$container/container/body/projects.hide()
	$container/container/body/user_profile.hide()
	Global.crt_scene = "res://scenes/projects/my_profile.tscn"

func _on_texture_rect_pressed():
	if Global.logout_value == 0:
		Global.logout_value = 1
		logout_container.show()
		label.hide()
		$container/container/side_bar/HBoxContainer/TextureRect/Label3.hide()
		$container/container/side_bar/HBoxContainer/TextureRect.texture_normal = Global.icon_pressed

	else:
		Global.logout_value = 0
		logout_container.hide()
		label.show()
		$container/container/side_bar/HBoxContainer/TextureRect/Label3.show()
		$container/container/side_bar/HBoxContainer/TextureRect.texture_normal = Global.icon

func _on_logout_btn_pressed():
	DirAccess.remove_absolute("user://connect.dat")
	Global.index_stay_connected = 0
	Global.stay_connected.stay_connected = false
	Global.stay_connected.email = ""
	Global.stay_connected.password = ""
	Global.logout_value = 0
	Global.login = preload("res://scenes/login_register.tscn").instantiate()
	get_node("/root").add_child(Global.login)
	queue_free()

func _on_timer_timeout():
	Firebase.login(Global.stay_connected.email, Global.stay_connected.password)


func _on_button_pressed():
	OS.shell_open("https://kollabsound.com")

func _on_my_project_btn_pressed():
	get_node("container/container/body/projects")._on_my_project_btn_pressed()
	Global.home.get_node("container/container/body/projects/top_bar/container/Home/my_project_btn").button_pressed = true
	var create_project = preload("res://scenes/projects/create_project_tab.tscn").instantiate()
	create_project.get_node("choice_plat").show()
	create_project.get_node("container").hide()

func _on_create_btn_pressed():
	if Global.get_project_number != 0:
		get_node("container/container/body/projects")._on_create_btn_pressed()
		Global.home.get_node("container/container/body/projects/top_bar/container/Home/create_btn").button_pressed = true
	else:
		$container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/my_project_btn.button_pressed = true
		if Global.key_type != 3:
			var full_project_popup = preload("res://scenes/projects/full_project_popup.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)
			await full_project_popup.get_node("Panel/VBoxContainer/buy_btn").pressed
			OS.shell_open("https://kollabsound.com/view-pricing/")
			full_project_popup.queue_free()
		else:
			var full_project_popup = preload("res://scenes/projects/full_project_popup_premium.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)

func _on_join_btn_pressed():
	if Global.get_project_number != 0:
		get_node("container/container/body/projects")._on_join_btn_pressed()
		Global.home.get_node("container/container/body/projects/top_bar/container/Home/join_btn").button_pressed = true
	else:
		$container/container/side_bar/VBoxContainer/HBoxContainer/VBoxContainer/my_project_btn.button_pressed = true
		if Global.key_type != 3:
			var full_project_popup = preload("res://scenes/projects/full_project_popup.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)
			await full_project_popup.get_node("Panel/VBoxContainer/buy_btn").pressed
			OS.shell_open("https://kollabsound.com/view-pricing/")
			full_project_popup.queue_free()
		else:
			var full_project_popup = preload("res://scenes/projects/full_project_popup_premium.tscn").instantiate()
			get_node("/root").add_child(full_project_popup)
		
func get_random_icon():
	base_http.request(Global.api_url + "/get_user_icons/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var icons = json.get_data()
		
		Global.icon = load(icons["normal"])
		Global.icon_pressed = load(icons["pressed"])

#func get_process_pid(process_name : String) -> int:
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
#	OS.execute("tasklist", ["/FI", "IMAGENAME eq " + process_name], output, true)
#	regex.compile(pattern)
#	var match_pid = regex.search(str(output))
#	return int(match_pid.get_string())


func send_email():
	OS.shell_open("mailto:support@kollabsound.com")

func _on_discord_pressed():
	OS.shell_open("https://discord.gg/ZpU4SSpk2m")
	
func _on_public_projects_btn_pressed():
	if Global.key_type == 3:
		$container/container/side_bar/VBoxContainer/HBoxContainer.hide()
		$container/container/side_bar/VBoxContainer/social_btn_other.hide()
		Global.index_home_shortcut_btn = 0
		Global.index_social_btn = 0
		Global.project_more_infos_panel_index = 0
		$container/container/body/projects.hide()
		$container/container/body/settings.hide()
		$container/container/body/social.hide()
		$container/container/body/public_projects.show()
		$container/container/body/user_profile.hide()
		Global.crt_scene = ""
	else:
		var public_project_popup = preload("res://scenes/projects/public_project_popup.tscn").instantiate()
		add_child(public_project_popup)

func _on_my_profile_btn_pressed():
	get_node("container/container/body/social")._on_my_profile_btn_pressed()
	get_node("container/container/body/social/top_bar/container/Home/my_profile_btn").button_pressed = true
	Global.crt_scene = "res://scenes/projects/my_profile.tscn"

func _on_chat_btn_pressed():
	get_node("container/container/body/social")._on_chat_btn_pressed()
	get_node("container/container/body/social/top_bar/container/Home/chat_btn").button_pressed = true
	Global.crt_scene = ""

func _on_my_friends_btn_pressed():
	get_node("container/container/body/social")._on_my_friends_btn_pressed()
	get_node("container/container/body/social/top_bar/container/Home/my_friends_btn").button_pressed = true
	Global.crt_scene = ""

func _on_add_firends_btn_pressed():
	get_node("container/container/body/social")._on_add_firends_btn_pressed()
	get_node("container/container/body/social/top_bar/container/Home/add_firends_btn").button_pressed = true
	Global.crt_scene = ""


func _on_user_profile_visibility_changed():
	if visible:
		$container/container/body/user_profile.load_projects()
	else:
		$container/container/body/user_profile.unload_projects()
