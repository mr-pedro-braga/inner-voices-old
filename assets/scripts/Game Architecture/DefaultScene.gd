tool
class_name DefaultScene
extends EventEssentials

export var scene_name = "Scene 1"
export var scene_initial_zoom = 1.0
var initial_zoom = 0.0

func scene_ready():
	if not Engine.editor_hint:
		ScreenCore.update_zoom(scene_initial_zoom)

func _get_property_list():
	var properties = []
	properties.append({
			name = "Scene",
			type = TYPE_NIL,
			hint_string = "scene_",
			usage = PROPERTY_USAGE_GROUP | PROPERTY_USAGE_SCRIPT_VARIABLE
	})
	return properties

func add_node_to_events(node):
	if has_node("Events"):
		add_child(node)
