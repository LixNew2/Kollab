extends Control

#func _ready():
#	$Panel/AnimationPlayer.play("popup")
	
func _on_close_btn_pressed():
#	$Panel/AnimationPlayer.play_backwards("popup")
#	await $Panel/AnimationPlayer.animation_finished
	queue_free()
	


func _on_buy_btn_pressed():
	OS.shell_open("https://kollabsound.com/view-pricing")


func _on_contact_support_pressed():
	OS.shell_open("mailto:support@kollabsound.com")
