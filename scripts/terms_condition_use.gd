extends Control

var base_http := HTTPRequest.new()
var lang = TranslationServer.get_locale()

func _ready():
	add_child(base_http)
	var conditions = await Firebase.conditons_of_use(lang)
	$Panel/VBoxContainer/RichTextLabel.append_text(conditions)

	$Panel/AnimationPlayer.play("popup")

func _on_close_btn_pressed():
	$Panel/AnimationPlayer.play_backwards("popup")
	await $Panel/AnimationPlayer.animation_finished
	queue_free()

func _on_title_line_edit_text_changed(new_text):
	$Panel/VBoxContainer/error.hide()
