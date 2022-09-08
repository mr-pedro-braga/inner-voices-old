extends Node

# Minigame System

signal minigame_end

func minigame(scene):
	var obj = scene.instantiate()
	obj.name = "Minigame"
	get_node(^"/root/GameRoot/HUD/Overlay").add_child(obj)

func end_minigame():
	get_node(^"/root/GameRoot/HUD/Overlay").remove_child(get_node(^"/root/GameRoot/HUD/Overlay").get_node(^"Minigame"))
	emit_signal("minigame_end")
