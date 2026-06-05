extends Control
var base_http := HTTPRequest.new()

func _ready():
	add_child(base_http)
	
func _on_close_btn_pressed():
	queue_free()

func _on_free_trial_btn_popup_pressed():
	base_http.request(Global.api_url + "/active_free_trial/?timestemp=" + str(Time.get_unix_time_from_system()), Global.token_header, HTTPClient.METHOD_POST)
	var result = await base_http.request_completed as Array
	if result[1] == 200:
		Firebase.get_projetc_number()
		base_http.request(Global.api_url + "/get_free_trial_start_time/", Global.token_header, HTTPClient.METHOD_GET)
		var result2 = await base_http.request_completed as Array
		if result2[1] == 200:
			var result_body = result2[3].get_string_from_ascii()
			var json = JSON.new()
			json.parse(result_body)
			var remaining = 14 - int((Time.get_unix_time_from_system() - json.get_data())/ (60 * 60 * 24))
			Global.user_plan = tr("free_trial").format({"time": str(remaining) + tr("date_day")})
		Global.home = preload("res://scenes/home.tscn").instantiate()
		get_node("/root").add_child(Global.home)
