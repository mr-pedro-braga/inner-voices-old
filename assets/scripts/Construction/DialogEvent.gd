tool
extends EventReference
class_name DialogEvent

#
# @ Dialog Events Class!
#
# Useful for setting up simple talking events with minimal setup.
#

export(String, FILE, "*.sson") var dialog_sson_file
export(Array, String) var dialog_keys

#@ The current dialog from the list
var dialog_index = 0

#@ If this dialog calls or activate some switch.
export(String) var switch = ""

# Load the correct event icon
func _process(_delta):
	if not texture:
		texture = preload("res://assets/images/editor_only/icon_event_dialogue.png")
	if not color:
		color = Color(1, 0.098039, 0.182598, 0.321569)
	update()

func _draw():
	
	if not draw_debug:
		return
	
	var file = ""#dialog_sson_file.replace("res://episodes/E01/dialogue/world/", "")
	#file = file.replace(".sson", "")
	
	if dialog_keys.size() > 0:
		file += ":: " + dialog_keys[0]
	
	draw_set_transform(- trigger_area / 2 - Vector2(0, 4), 0, Vector2(0.3, 0.3))
	draw_string(
		font,
		Vector2.ZERO,
		file,
		Color.white
	)

# When this event gets activated
func _on_activated():
	Utils.enter_event()
	DCCore.add_dialog_caller(self)
	DCCore.dialog_by_file(
		dialog_sson_file,
		dialog_keys[dialog_index]
	)

func _deactivate():
	Utils.leave_event()

	if switch != "":
		Gameplay.switches[switch] = true

	if dialog_index < dialog_keys.size() - 1:
		dialog_index += 1
