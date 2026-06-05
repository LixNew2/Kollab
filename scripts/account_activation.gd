extends Control

var base_http := HTTPRequest.new()
var border := preload("res://assets/themes/border.tres")
var error_border_color := preload("res://assets/themes/error_border.tres")
var pressed = false

func _ready():
	add_child(base_http)
	
	base_http.request(Global.api_url + "/get_free_trial_start_time/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		
		if json.get_data() != 0:
			$VBoxContainer/VBoxContainer/free_trial_btn.hide()
	
func _process(delta):
	if $VBoxContainer/key.has_focus():
		$VBoxContainer/VBoxContainer/error_key.hide()
		$VBoxContainer/key.add_theme_stylebox_override("normal", border)

func _on_buy_key_btn_pressed():
	OS.shell_open("https://kollabsound.com/view-pricing/")

func _on_confirm_key_pressed():
	var link_machine_popup = preload("res://scenes/projects/link_machine_popup.tscn").instantiate()
	get_node("/root").add_child(link_machine_popup)
	await link_machine_popup.get_node("Panel/VBoxContainer/link_btn").pressed
	$VBoxContainer/VBoxContainer/confirm_key.disabled = true
	var body = JSON.stringify({"key": str($VBoxContainer/key.text), "unique_id": str(OS.get_unique_id()).replace("{","").replace("}",""), "hostname": str(OS.get_environment("COMPUTERNAME") if OS.get_name() == "Windows" else OS.get_environment("HOSTNAME")), "timestemp":Time.get_unix_time_from_system()})
	base_http.request(Global.api_url + "/active_account/", Global.token_header, HTTPClient.METHOD_POST, body)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		await Firebase.get_projetc_number()
		var user_active_projects = await Firebase.get_user_project_active()
		base_http.request(Global.api_url + "/edit_project_number/?nbr=" + str(int(Global.get_project_number) - int(user_active_projects)), Global.token_header, HTTPClient.METHOD_POST)
		var result2 = await base_http.request_completed as Array
		if result2[1] == 200:
			await Firebase.get_projetc_number()
		
		var result_body = int(result[3].get_string_from_ascii())
		if result_body == 1:
				Firebase.get_projetc_number()
				match await Firebase.get_key_type():
					1:
						Global.user_plan = "Basic Plan"
					2:
						Global.user_plan = "Standard Plan"
					3:
						Global.user_plan = "Premium Plan"
				Global.home = preload("res://scenes/home.tscn").instantiate()
				get_node("/root").add_child(Global.home)
				var thanks_popup = preload("res://scenes/projects/thanks_popup.tscn").instantiate()
				get_node("/root").add_child(thanks_popup)
				enable_confirm_btn()
				queue_free()
		else:
			$VBoxContainer/key.add_theme_stylebox_override("normal", error_border_color)
			$VBoxContainer/VBoxContainer/error_key.show()
			enable_confirm_btn()
	enable_confirm_btn()
	
func enable_confirm_btn():
	await get_tree().create_timer(3).timeout
	$VBoxContainer/VBoxContainer/confirm_key.disabled = false
	
func _on_not_now_btn_pressed():
	Global.home = preload("res://scenes/login_register.tscn").instantiate()
	get_node("/root").add_child(Global.home)
	queue_free()

func _on_free_trial_btn_pressed():
	var free_trial_popup = preload("res://scenes/projects/free_trial_validation_popup.tscn").instantiate()
	get_node("/root").add_child(free_trial_popup)
