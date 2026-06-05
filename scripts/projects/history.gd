extends ColorRect

var http = HTTPRequest.new()

func _ready():
	add_child(http)
	load_comments()

func unload_comments():
	for i in get_node("Panel/VBoxContainer/ScrollContainer/VBoxContainer").get_children():
		i.queue_free()

func load_comments():
	unload_comments()
	
	get_node("Panel/VBoxContainer/loading").show()
	get_node("Panel/VBoxContainer/ScrollContainer").hide()
	
	var history = await ProjectsManager.get_history_project(Global.project_key_selected)
	
	if typeof(history) != 28:
		return
		
	for his in history:
		var history_node = preload("res://scenes/projects/history_item.tscn").instantiate()
		history_node.get_node("container/Label").text = ProjectsManager.convert_date_time(his.replace(".7z", ""), 0)
		
		history_node.get_node("container/btn/download_btn").connect("pressed", open.bind(his.replace(".7z", "")))
		
		history_node.set_name(ProjectsManager.convert_date_time(his.replace(".7z", ""), 1))
		get_node("Panel/VBoxContainer/ScrollContainer/VBoxContainer").add_child(history_node)

	get_node("Panel/VBoxContainer/loading").hide()
	get_node("Panel/VBoxContainer/ScrollContainer").show()

func open(project_uid : String):
	if OS.get_name() == "Windows":
		OS.shell_open(OS.get_user_data_dir() + "/backups/" + filename_project)
	elif OS.get_name() == "macOS":
		OS.execute("open", [OS.get_user_data_dir() + "/backups/" + filename_project])

func _on_close_btn_pressed():
	queue_free()

func convert_date_time(backup: String, type : int) -> String:
	var parts := backup.split("_")
	
	var date : String
	print(parts)
	var year := parts[0]
	var day := parts[2]
	var month := parts[1]
	var hour := parts[3].to_int()
	var minute := parts[4]
	
	if TranslationServer.get_locale() == "fr" or TranslationServer.get_locale() == "fr_FR":
		date += str(day) + "-" + str(month) + "-" + str(year) + " " + str(hour+1) + ":" + str(minute)
	else:
		if hour <=11 :
			date += str(month) + "-" + str(day) + "-" + str(year) + " " + str(hour) + ":" + str(minute) + "AM"
		else:
			if hour == 24:
				date += str(month) + "-" + str(day) + "-" + str(year) + " " + str(12) + ":" + str(minute) + "PM"
			else:
				date += str(month) + "-" + str(day) + "-" + str(year) + " " + str(hour-12) + ":" + str(minute) + "PM"

	return date if type == 0 else date.replace(":","_").replace(" ","_").replace("-","_")
