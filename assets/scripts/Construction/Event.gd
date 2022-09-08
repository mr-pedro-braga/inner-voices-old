@tool
extends EventReference
class_name SceneEvent

#
# @ General Events Class!
# Useful for general events here and there.
#

@export var event_name = ""
@export var event_parameter = ""
@export var event_arguments = []


func _process(_delta):
	if not texture:
		texture = preload("res://assets/images/editor_only/icon_event.png")
	if not color:
		color = Color(1, 0.815686, 0.098039, 0.321569)
	update()

func _draw():
	
	if not draw_debug:
		return
	
	var text = event_name + "(" + event_parameter + ")"
	
	if event_name == "":
		text = "(!) Empty"
	
	draw_set_transform(- trigger_area / 2 - Vector2(0, 4), 0, Vector2(0.3, 0.3))
	draw_string(
		font,
		Vector2.ZERO,
		text,
		Color.WHITE
	)

# When this event gets activated
func _on_activated():
	
	if event_name == "":
		return
	
	var scene = get_node(^"/root/GameRoot/World3D/Scene")
	if not scene.has_method("evt_" + event_name):
		print("(!) There is no event named '"+event_name+"' in the scene "+scene.scene_name)
		return
	
	scene.call("evt_" + event_name, self, event_parameter, event_arguments)
