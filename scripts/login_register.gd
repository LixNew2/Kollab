extends Control
var base_http := HTTPRequest.new()

var border := preload("res://assets/themes/border.tres")
var error_border_color := preload("res://assets/themes/error_border.tres")
@onready var line_edits = [$VBoxContainer2/vbox_2/key,
						   $VBoxContainer2/vbox_2/username,
						   $VBoxContainer2/vbox_2/password,
						   $VBoxContainer2/vbox_2/email,
						   $VBoxContainer2/vbox_2/confirm_password]
var eye = load("res://assets/ressources/eye.png")
var eye_pressed = load("res://assets/ressources/eye_pressed.png")
var pressed = false

func _ready():
	TranslationServer.set_locale(Global.langague)
	add_child(base_http)
	
func _input(event):
	if !pressed:
		if event is InputEventKey:
			var keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
			if OS.get_keycode_string(keycode) == "Enter":
				_on_confirm_btn_pressed()

func _process(delta):
	if $VBoxContainer2/vbox_2/HBoxContainer3/condition_of_use.is_pressed():
		$VBoxContainer2/vbox_3/HBoxContainer3/condition_error.hide()
	for line in line_edits:
		if line.has_focus():
			$VBoxContainer2/vbox_3/HBoxContainer3/info.hide()
			line.add_theme_stylebox_override("normal", border)
	
func basic_color_border():
	for line in line_edits:
		$VBoxContainer2/vbox_3/HBoxContainer3/info.hide()
		line.add_theme_stylebox_override("normal", border)
		
func _on_sign_up_btn_pressed():
	basic_color_border()
	if Global.sign_log_index == 0:
		Global.sign_log_index = 1
	else:
		Global.sign_log_index = 0
	
	if Global.sign_log_index == 1:
		$VBoxContainer2/vbox_1/Label.set_text("register_subtitle")
		$VBoxContainer2/vbox_2/password.set_placeholder("password_placeholder_lineedit_register")
#		$VBoxContainer2/vbox_2/HBoxContainer.show()
#		$VBoxContainer2/vbox_2/key.show()
		$VBoxContainer2/vbox_2/username.show()
		$VBoxContainer2/vbox_2/confirm_password.show()
		$VBoxContainer2/vbox_3/HBoxContainer/sign_up_btn.set_text("login_btn")
		$VBoxContainer2/vbox_3/HBoxContainer/Label2.set_text("have_account")
		$VBoxContainer2/vbox_2/CheckBox.hide()
		$VBoxContainer2/vbox_2/HBoxContainer3.show()
		$VBoxContainer2/vbox_3/HBoxContainer2.hide()
	else:
		$VBoxContainer2/vbox_1/Label.set_text("login_subtitle")
		$VBoxContainer2/vbox_2/password.set_placeholder("password_placeholder_lineedit")
#		$VBoxContainer2/vbox_2/HBoxContainer.hide()
#		$VBoxContainer2/vbox_2/key.hide()
		$VBoxContainer2/vbox_2/username.hide()
		$VBoxContainer2/vbox_2/confirm_password.hide()
		$VBoxContainer2/vbox_3/HBoxContainer/sign_up_btn.set_text("sign_up_btn")
		$VBoxContainer2/vbox_3/HBoxContainer/Label2.set_text("not_account")
		$VBoxContainer2/vbox_2/CheckBox.show()
		$VBoxContainer2/vbox_2/HBoxContainer3.hide()
		$VBoxContainer2/vbox_3/HBoxContainer2.show()

func _on_confirm_btn_pressed():
	var key = str($VBoxContainer2/vbox_2/key.text)
	var username = str($VBoxContainer2/vbox_2/username.text)
	var email = str($VBoxContainer2/vbox_2/email.text)
	var password = str($VBoxContainer2/vbox_2/password.text)
	var confirm_password = str($VBoxContainer2/vbox_2/confirm_password.text)
	
	if Global.sign_log_index == 1:
		if $VBoxContainer2/vbox_2/HBoxContainer3/condition_of_use.is_pressed() != true:
			$VBoxContainer2/vbox_3/HBoxContainer3/info.hide()
			$VBoxContainer2/vbox_3/HBoxContainer3/condition_error.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/condition_error.set_text("error_condition_of_use")
			return
		if password != confirm_password or password == "":
			$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/info.set_text("password_error_same_missing")
			$VBoxContainer2/vbox_2/password.add_theme_stylebox_override("normal", error_border_color)
			$VBoxContainer2/vbox_2/confirm_password.add_theme_stylebox_override("normal", error_border_color)
			return
		if username == "":
			$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/info.set_text("username_error")
			$VBoxContainer2/vbox_2/username.add_theme_stylebox_override("normal", error_border_color)
			return
		if 	await Firebase.check_pseudo(username) == 1:
			$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/info.set_text("username_check_error")
			$VBoxContainer2/vbox_2/username.add_theme_stylebox_override("normal", error_border_color)
			return
		if email == "":
			$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/info.set_text("email_error")
			$VBoxContainer2/vbox_2/email.add_theme_stylebox_override("normal", error_border_color)
			return
		
		$VBoxContainer2/vbox_3/confirm_btn.disabled = true
		pressed = true
		var result = await Firebase.register(email, password, username)
		if result == "register":
			_on_sign_up_btn_pressed()
			var conditions = await Firebase.conditons_of_use(TranslationServer.get_locale())
			FileAccess.open("user://conditions.dat", FileAccess.WRITE).store_string(conditions)
			enable_confirm_btn()
		else:
			$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/info.set_text(result)
			enable_confirm_btn()
			
			if "PASSWORD" in result:
				$VBoxContainer2/vbox_2/password.add_theme_stylebox_override("normal", error_border_color)
				$VBoxContainer2/vbox_2/confirm_password.add_theme_stylebox_override("normal", error_border_color)
				enable_confirm_btn()
			elif "EMAIL" in result:
				$VBoxContainer2/vbox_2/email.add_theme_stylebox_override("normal", error_border_color)	
				enable_confirm_btn()
#		else:				
#			$VBoxContainer2/vbox_2/error.show()
#			$VBoxContainer2/vbox_2/error.set_text("key_error")
#			$VBoxContainer2/vbox_2/key.add_theme_stylebox_override("normal", error_border_color)
#			return
	else:
		$VBoxContainer2/vbox_3/confirm_btn.disabled = true
		pressed = true
		var result = await Firebase.login(email, password)
		if result == "login":
			if Global.stay_connected.stay_connected == true:
				Global.stay_connected.email = email
				Global.stay_connected.password = password
				
				FileAccess.open_encrypted_with_pass("user://connect.dat", FileAccess.WRITE, "").store_var(Global.stay_connected)
			if Global.account_activation_value == 1 or Global.account_activation_value == 2:
				var account_activation = preload("res://scenes/account_activation.tscn").instantiate()
				if Global.account_activation_value == 2:
						if Global.days_free_trial > 14:
							get_node("/root").add_child.call_deferred(account_activation)
							var popup_free_trial_ended = preload("res://scenes/projects/free_trial_ended_popup.tscn").instantiate()
							get_node("/root").add_child.call_deferred(popup_free_trial_ended)
							enable_confirm_btn()
							queue_free()
							return
						else:
							var home = preload("res://scenes/home.tscn").instantiate()
							get_node("/root").add_child.call_deferred(home)
							enable_confirm_btn()
							queue_free()
							return
				else:
					if Global.days_acctivation > 365:
						get_node("/root").add_child.call_deferred(account_activation)
						var popup_free_trial_ended = preload("res://scenes/projects/account_activation_time_error_popup.tscn").instantiate()
						get_node("/root").add_child.call_deferred(popup_free_trial_ended)
						enable_confirm_btn()
						queue_free()
						return
					else:
						var unique_id = await Firebase.get_unique_id()
						if unique_id == "":
							var link_machine_popup = preload("res://scenes/projects/link_machine_popup.tscn").instantiate()
							get_node("/root").add_child(link_machine_popup)
							await link_machine_popup.get_node("Panel/VBoxContainer/link_btn").pressed
							await Firebase.set_unique_id()
						unique_id = await Firebase.get_unique_id()
						if unique_id == str(OS.get_unique_id().replace("{","").replace("}","")):
							Global.home = preload("res://scenes/home.tscn").instantiate()
							get_node("/root").add_child(Global.home)
							enable_confirm_btn()
							queue_free()
						else:
							var link_popup_error = preload("res://scenes/projects/link_machine_error_popup.tscn").instantiate()
							get_node("/root").add_child(link_popup_error)
							link_popup_error.get_node("Panel/VBoxContainer/Label2").text = tr("link_machine_error_message").format({"hostname": await Firebase.get_hostname()})
							enable_confirm_btn()
			else:
				Global.account_activation = preload("res://scenes/account_activation.tscn").instantiate()
				get_node("/root").add_child(Global.account_activation)
				enable_confirm_btn()
				queue_free()
		else:
			$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
			$VBoxContainer2/vbox_3/HBoxContainer3/info.set_text("login_error")
			$VBoxContainer2/vbox_2/email.add_theme_stylebox_override("normal", error_border_color)
			$VBoxContainer2/vbox_2/password.add_theme_stylebox_override("normal", error_border_color)
			$VBoxContainer2/vbox_2/password.text = ""
			enable_confirm_btn()
			
			
func enable_confirm_btn():
	await get_tree().create_timer(3).timeout
	$VBoxContainer2/vbox_3/confirm_btn.disabled = false
	pressed = false
	
func _on_purchase_key_pressed():
	OS.shell_open("https://kollabsound.com/view-pricing/")

func _on_show_password_pressed():
	if Global.secret_password_index == 0:
		Global.secret_password_index = 1
		$VBoxContainer2/vbox_2/password.secret = false
		$VBoxContainer2/vbox_2/confirm_password.secret = false
		$VBoxContainer2/vbox_2/password/show_password.set_texture_normal(eye_pressed)
	else:
		Global.secret_password_index = 0
		$VBoxContainer2/vbox_2/password.secret = true
		$VBoxContainer2/vbox_2/confirm_password.secret = true
		$VBoxContainer2/vbox_2/password/show_password.set_texture_normal(eye)

func _on_check_box_pressed():
	if Global.index_stay_connected == 0:
		Global.index_stay_connected = 1
		Global.stay_connected.stay_connected = true
	else:
		Global.index_stay_connected = 0
		Global.stay_connected.stay_connected = false

func _on_terms_of_use_pressed():
	$VBoxContainer2/vbox_2/HBoxContainer3/terms_of_use.disabled = true
	var licenses = preload("res://scenes/terms_condition_of_use/terms_condition_use.tscn").instantiate()
	get_node("/root").add_child(licenses)
	await get_tree().create_timer(3).timeout
	$VBoxContainer2/vbox_2/HBoxContainer3/terms_of_use.disabled = false

func _on_reset_password_btn_pressed():
	var email = $VBoxContainer2/vbox_2/email.text
	$VBoxContainer2/vbox_3/HBoxContainer2/reset_password_btn.disabled = true
	
	if email == "":
		$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
		$VBoxContainer2/vbox_3/HBoxContainer3/info.text = "email_error"
		disabled_reste_password_btn()
		return
		
	var send = await Firebase.reset_password(email)
	
	if send == "send":
		$VBoxContainer2/vbox_3/HBoxContainer3/info.text = "reset_password_email_send"
		$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
		$VBoxContainer2/vbox_3/HBoxContainer3/info.modulate = Color(255, 255, 255)
		disabled_reste_password_btn()
		return
	else:
		$VBoxContainer2/vbox_3/HBoxContainer3/info.show()
		$VBoxContainer2/vbox_3/HBoxContainer3/info.text = "INVALID_EMAIL"
		disabled_reste_password_btn()
		return
	
func disabled_reste_password_btn():
	await get_tree().create_timer(3).timeout
	$VBoxContainer2/vbox_3/HBoxContainer2/reset_password_btn.disabled = false
	$VBoxContainer2/vbox_3/HBoxContainer3/info.hide()
	$VBoxContainer2/vbox_3/HBoxContainer3/info.modulate = Color(251, 0, 0)
