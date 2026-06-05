extends ColorRect

var http = HTTPRequest.new()
var pressed = false

func _ready():
	add_child(http)
	load_comments()

	
func _input(event):
	if !pressed:
		if event is InputEventKey:
			var keycode = DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
			if OS.get_keycode_string(keycode) == "Enter":
				_on_send_commentary_pressed()
				
func _on_close_btn_pressed():
	queue_free()

func _on_send_commentary_pressed():
	var pressed = true
	var text = $Panel/VBoxContainer/HBoxContainer/commentary_text.text
	
	if text == "":
		$Panel/VBoxContainer/error.show()
		return
	
	$Panel/VBoxContainer/HBoxContainer/set_comment.disabled = true
	await set_comment(Global.uid, Global.project_key_selected, Global.username, text)
	$Panel/VBoxContainer/HBoxContainer/set_comment.disabled = false
	
	var commentary = preload("res://scenes/projects/commentary_item.tscn").instantiate()
	commentary.get_node("Panel/HBoxContainer/delete_btn_comments").show()
	commentary.get_node("Panel/HBoxContainer/Control").show()
	commentary.get_node("Panel/HBoxContainer/Control2").hide()
	get_node("Panel/VBoxContainer/not_comments").hide()
	get_node("Panel/VBoxContainer/ScrollContainer").show()
	commentary.get_node("HBoxContainer/username").text = Global.username
	commentary.get_node("text").text = text
	commentary.get_node("HBoxContainer/time").text = get_time(int(Time.get_unix_time_from_system()))
	get_node("Panel/VBoxContainer/ScrollContainer/VBoxContainer").add_child(commentary)
	$Panel/VBoxContainer/HBoxContainer/commentary_text.text = ""
	pressed = false
	
func set_comment(uid : String, key : String, username : String, text : String):
	var body = JSON.stringify({"uid" : uid, "key" : key, "username" : username, "text" : text, "timestamp" : str(Time.get_unix_time_from_system())})
	http.request(Global.api_url + "/set_comment/", Global.token_header, HTTPClient.METHOD_POST, body)
	await http.request_completed

func get_comments():
	http.request(Global.api_url + "/get_comments/?key=" + Global.project_key_selected, Global.token_header, HTTPClient.METHOD_GET)
	var result = await http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		return json.get_data() 
		
func load_comments():
	unload_comments()
	
	get_node("Panel/VBoxContainer/loading").show()
	get_node("Panel/VBoxContainer/ScrollContainer").hide()
	
	var comments = await get_comments()
	var nbr_comments = 0
	
	if typeof(comments) != 27:
		return
		
	comments = sort_com(comments) 
	
	for com in comments:
		nbr_comments += 1
		var commentary = preload("res://scenes/projects/commentary_item.tscn").instantiate()
		commentary.get_node("text").text = comments[com].text
		commentary.get_node("HBoxContainer/username").text = comments[com].username
		commentary.get_node("Panel/HBoxContainer/upvotes_nbr").text = str(comments[com].upvotes)
		commentary.get_node("id").text = com
		commentary.get_node("HBoxContainer/time").text = get_time(0, comments, com)
		
		if com.split("_")[1] == Global.uid:
			commentary.get_node("Panel/HBoxContainer/delete_btn_comments").show()
			commentary.get_node("Panel/HBoxContainer/Control").show()
			commentary.get_node("Panel/HBoxContainer/Control2").hide()
		else:
			commentary.get_node("Panel/HBoxContainer/delete_btn_comments").hide()
			commentary.get_node("Panel/HBoxContainer/Control").hide()
			commentary.get_node("Panel/HBoxContainer/Control2").show()
			
		commentary.get_node("Panel/HBoxContainer/upvotes").connect("pressed", upvote.bind(com, commentary))
		commentary.get_node("Panel/HBoxContainer/delete_btn_comments").connect("pressed", delete_comment.bind(com))
		
		await check_upvote_com_user(com, commentary)
		
		commentary.set_name(com)
		get_node("Panel/VBoxContainer/ScrollContainer/VBoxContainer").add_child(commentary)
	
	get_node("Panel/VBoxContainer/loading").hide()
	if nbr_comments < 1:
		get_node("Panel/VBoxContainer/not_comments").show()
		get_node("Panel/VBoxContainer/ScrollContainer").hide()
	else:
		get_node("Panel/VBoxContainer/not_comments").hide()
		get_node("Panel/VBoxContainer/ScrollContainer").show()
		
func upvote(uid : String, node):
	http.request(Global.api_url + "/upvote_comments/?key=" + Global.project_key_selected + "&uid_comment=" + uid, Global.token_header, HTTPClient.METHOD_POST)
	var result = await http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var data = json.get_data()
		node.get_node("Panel/HBoxContainer/upvotes_nbr").text = str(data[0])
		if data[1] == 1:
			node.get_node("Panel/HBoxContainer/upvotes").texture_normal = load("res://assets/ressources/upvoted.png")
		else:
			node.get_node("Panel/HBoxContainer/upvotes").texture_normal = load("res://assets/ressources/up.png")

func delete_comment(uid : String):
	var delete_popup = preload("res://scenes/projects/delete_comment_popup.tscn").instantiate()
	get_node("/root").add_child(delete_popup)
	await delete_popup.get_node("Panel/VBoxContainer/delete_btn").pressed
	http.request(Global.api_url + "/delete_comment/?uid_comment=" + uid + "&key=" + Global.project_key_selected, Global.token_header, HTTPClient.METHOD_POST)
	await http.request_completed
	delete_popup.queue_free()
	load_comments()

func check_upvote_com_user(uid : String, node):
	http.request(Global.api_url + "/check_comment_upvote/?uid_comment=" + str(uid), Global.token_header, HTTPClient.METHOD_GET)
	var result = await http.request_completed as Array
	if result[1] == 200:
		var result_body = result[3].get_string_from_ascii()
		var json = JSON.new()
		json.parse(result_body)
		var data = json.get_data()
		if data == 1:
			node.get_node("Panel/HBoxContainer/upvotes").texture_normal = load("res://assets/ressources/upvoted.png")

func unload_comments():
	for i in get_node("Panel/VBoxContainer/ScrollContainer/VBoxContainer").get_children():
		i.queue_free()


func get_time(timestamp : int = 0, comments : Dictionary = {}, com : String = ""):
	var time_stamp_com : int
	
	if timestamp == 0:
		time_stamp_com = int(comments[com].timestamp)
	else:
		time_stamp_com = timestamp
		
	var current_time_stamp = int(Time.get_unix_time_from_system())
	var time_delta = current_time_stamp - time_stamp_com
	
	var days = time_delta / (60 * 60 * 24)
	var hours = (time_delta / (60 * 60)) % 24
	var minutes = (time_delta / 60) % 60
	var seconds = time_delta % 60
	
	if days >= 1:
		if days >= 365:
			return tr("ago_text").format({"time": str(days) + tr("date_year")})
		elif days >= 30:
			return tr("ago_text").format({"time": str(days) + tr("date_month")})
		else:
			return tr("ago_text").format({"time": str(days) + tr("date_day")})
	elif hours >= 1:
		return tr("ago_text").format({"time": str(hours) + tr("date_hour")})
	elif minutes >= 1:
		return tr("ago_text").format({"time": str(minutes) + tr("date_minute")})
	else:
		return tr("ago_text").format({"time": str(seconds) + tr("date_second")})

func sort_com(comments : Dictionary):

	var time_stamps_com = {}
	var time_sort = {}
	var sorted_comments = {}
	
	for com in comments:
		time_stamps_com[com] = get_time(0, comments, com)
		if time_stamps_com[com].ends_with('y') or time_stamps_com[com].ends_with('an'):
			time_sort[com] = int(time_stamps_com[com]) * 31536000
		elif time_stamps_com[com].ends_with('m'):
			time_sort[com] =  int(time_stamps_com[com]) * 2592000
		elif time_stamps_com[com].ends_with('d') or time_stamps_com[com].ends_with('j'):
			time_sort[com] =  int(time_stamps_com[com]) * 86400
		elif time_stamps_com[com].ends_with('h'):
			time_sort[com] =  int(time_stamps_com[com]) * 3600
		elif time_stamps_com[com].ends_with('min'):
			time_sort[com] =  int(time_stamps_com[com]) * 60
		else:
			time_sort[com] =  int(time_stamps_com[com])
	
	var sorted = []
	
	for i in time_sort:
		var inserted = false
		for j in range(sorted.size()):
			if time_sort[i] < time_sort[sorted[j]]:
				sorted.insert(j, i)
				inserted = true
				break
		if not inserted:
			sorted.append(i)
	
	for com in sorted:
		sorted_comments[com] = {
			"upvotes" : str(comments[com].upvotes),
			"username" : comments[com].username,
			"text" : comments[com].text,
			"timestamp" : comments[com].timestamp}

	return sorted_comments


func _on_commentary_text_text_changed(new_text):
	$Panel/VBoxContainer/error.hide()
