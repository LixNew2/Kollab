extends Node

const API_KEY := ""
const PROJECT_ID := ""

const REGISTER_URL := "https://www.googleapis.com/identitytoolkit/v3/relyingparty/signupNewUser?key=" + API_KEY
const LOGIN_URL := "https://www.googleapis.com/identitytoolkit/v3/relyingparty/verifyPassword?key=" + API_KEY


var base_http = HTTPRequest.new()
var connected = false


func _init():
	add_child(base_http)

#func _ready():
#	login("lixnew@kollabsound.com", "Despensh1506/")
#	login("nicolas@vedg.site", "test1234")
#	register("nicolas@vedg.site", "test1234", "Noiros")


func register(email: String, password: String, pseudo: String) -> String:
	var body := '{"email":"' + email + '", "password":"' + password + '"}'
	base_http.request(REGISTER_URL, [], HTTPClient.METHOD_POST, str(body))
	var result := await base_http.request_completed as Array

	var result_body = result[3].get_string_from_ascii()
	var json = JSON.new()
	json.parse(result_body)
	var data = json.get_data()

	if result[1] == 200:
		print_rich("[b][Firebase][/b] " + "Registered")
		Global.username = pseudo
		Global.token = data['idToken']
		Global.token_header = PackedStringArray(["Content-Type: application/json","Authorization: Bearer " + Global.token])
		Global.uid = data['localId']
		connected = true
		
		await get_tree().create_timer(.5).timeout
		while true:
			print_rich("[b][Firebase][/b] " + "Request account creation")
			var set_user_icons = get_random_user_icon()
			body = JSON.stringify({"pseudo": pseudo, "normal":set_user_icons[0], "pressed":set_user_icons[1]})
			base_http.request(Global.api_url + "/create_account/", Global.token_header, HTTPClient.METHOD_POST, body)
			result = await base_http.request_completed as Array
			if result[1] == 200:
				Global.stay_connected.email = email
				Global.stay_connected.password = password
				result_body = result[3].get_string_from_ascii()
				json = JSON.new()
				json.parse(result_body)
				if json.get_data() == "created" or json.get_data() == "exist":
					print_rich("[b][Firebase][/b] " + "Account created")
					break
					
		return "register"
		
	return data.error.message


func login(email: String, password: String) -> String:
	var body := '{"email":"' + email + '","password":"' + password + '","returnSecureToken": true}'
	base_http.request(LOGIN_URL, [], HTTPClient.METHOD_POST, str(body))
	var result := await base_http.request_completed as Array

	var result_body = result[3].get_string_from_ascii()
	var json = JSON.new()
	json.parse(result_body)
	var data = json.get_data()

	if result[1] == 200:
		print_rich("[b][Firebase][/b] " + "Logged")
		Global.stay_connected.email = email
		Global.stay_connected.password = password
		Global.token = data['idToken']
		Global.token_header = PackedStringArray(["Content-Type: application/json","Authorization: Bearer " + Global.token])
		Global.uid = data['localId']
		Global.email = data['email']
		connected = true
		await get_key_type()
		await get_activation_account_time()
		await get_free_trial_start_time()
		await get_username()
		await get_activation_account()
		await get_projetc_number()
		if not FileAccess.file_exists("user://conditions.dat"):
			FileAccess.open("user://conditions.dat", FileAccess.WRITE)
		return "login"
	return data.error.message


func get_username():
	base_http.request(Global.api_url + "/get_username/", Global.token_header, HTTPClient.METHOD_GET)

	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse((result_body))
		var user_dict = json.get_data()
		Global.username = user_dict.pseudo

func get_activation_account():
	base_http.request(Global.api_url + "/get_account_activation/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		Global.account_activation_value = int(result[3].get_string_from_ascii())

func get_projetc_number():
	base_http.request(Global.api_url + "/get_project_number/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		Global.get_project_number = int(result[3].get_string_from_ascii())
		
func get_key_type():
	base_http.request(Global.api_url + "/get_key_type/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		Global.key_type = int(result[3].get_string_from_ascii())
		
func get_user_id():
	base_http.request(Global.api_url + "/get_user_id/", Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		return result[3].get_string_from_ascii().replace('"', "")
		
func get_random_user_icon():
	var icons := {"res://assets/ressources/icons/1.png":"res://assets/ressources/icons/1_pressed.png",
				  "res://assets/ressources/icons/2.png":"res://assets/ressources/icons/2_pressed.png",
				  "res://assets/ressources/icons/3.png":"res://assets/ressources/icons/3_pressed.png",
				  "res://assets/ressources/icons/4.png":"res://assets/ressources/icons/4_pressed.png",
				  "res://assets/ressources/icons/5.png":"res://assets/ressources/icons/5_pressed.png",
				  "res://assets/ressources/icons/6.png":"res://assets/ressources/icons/6_pressed.png",
				  "res://assets/ressources/icons/7.png":"res://assets/ressources/icons/7_pressed.png",
				  "res://assets/ressources/icons/8.png":"res://assets/ressources/icons/8_pressed.png",
				  "res://assets/ressources/icons/9.png":"res://assets/ressources/icons/9_pressed.png",
				  "res://assets/ressources/icons/10.png":"res://assets/ressources/icons/10_pressed.png",}

	var keys := icons.keys()
	var random_int := randi() % icons.size()
	var normal = keys[random_int]
	var pressed = icons[normal]
	return [normal, pressed]
	
func conditons_of_use(lang : String):
	base_http.request(Global.api_url + "/conditons_of_use/?lang=" + str(lang), Global.token_header, HTTPClient.METHOD_GET)
	
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		return result[3].get_string_from_utf8().replace('"', "").replace("\\n", "\n").replace('\"', '')

func reset_password(email: String):
	base_http.request(Global.api_url + "/reset_password/?email=" + str(email), Global.token_header, HTTPClient.METHOD_PUT)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse((result_body))
		return json.get_data()
	return "error"
	
func get_unique_id():
	base_http.request(Global.api_url + "/get_unique_id/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse((result_body))
		return json.get_data()
		
func set_unique_id():
	var hostname = []
	OS.execute("HOSTNAME", [], hostname)
	base_http.request(Global.api_url + "/set_unique_id/?unique_id=" + str(OS.get_unique_id()).replace("{","").replace("}","") + "&hostname=" + hostname[0].replace("\r","").replace("\n",""), Global.token_header, HTTPClient.METHOD_POST)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		return
		
func get_hostname():
	base_http.request(Global.api_url + "/get_hostname/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse((result_body))
		return json.get_data()
		
func get_user_project_active():
	base_http.request(Global.api_url + "/get_project_number_active/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse((result_body))
		return json.get_data()
		
func get_activation_account_time():
	base_http.request(Global.api_url + "/get_activation_account_time/", Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse((result_body))
		var time_delta = int(Time.get_unix_time_from_system() - json.get_data())
		Global.days_acctivation = time_delta / (60 * 60 * 24)
		
func get_free_trial_start_time():
	base_http.request(Global.api_url + "/get_free_trial_start_time/", Global.token_header, HTTPClient.METHOD_GET)
	var result3 = await base_http.request_completed as Array
	if result3[1] == 200:
		var result_body = result3[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var time_delta = int(Time.get_unix_time_from_system() - json.get_data())
		Global.days_free_trial = time_delta / (60 * 60 * 24)

func check_pseudo(pseudo : String):
	base_http.request(Global.api_url + "/check_pseudo/?pseudo=" + pseudo, Global.token_header, HTTPClient.METHOD_GET)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		return int(result[3].get_string_from_ascii())
		
