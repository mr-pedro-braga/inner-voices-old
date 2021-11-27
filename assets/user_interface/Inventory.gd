extends Control

var index: int = 0

func _fake_process(_delta):
	if not MenuCore.menu_open["item"]:
		return
	if Input.is_action_just_pressed("ui_up"):
		index -= 1
		AudioManager.play_sound("UI/SFX_Menu_Pan", "ogg")
	if Input.is_action_just_pressed("ui_down"):
		index += 1
		AudioManager.play_sound("UI/SFX_Menu_Pan", "ogg")
	index = int(fposmod(index, 5))
	for i in get_children():
		i.frame = 0
