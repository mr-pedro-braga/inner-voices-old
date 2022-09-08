extends Node

var display_events := false

func _process(_delta):
	if Input.is_action_just_pressed("debug_menu"):
		DialogHandler.playc("", "",
			[
				"Display Events",
				"...",
				"...",
				"..."
			],
			["edit", "question", "question", "question"],
				-16, 0)
		await DCCore.choice_selected
		match DCCore.choice_result:
			0:
				display_events = not display_events
				print("Toggled Display Events: ", display_events)
