extends Control

#func _ready():
#	$Panel/AnimationPlayer.play("popup")
	
func _on_close_btn_pressed():
#	$Panel/AnimationPlayer.play_backwards("popup")
#	await $Panel/AnimationPlayer.animation_finished
	queue_free()
