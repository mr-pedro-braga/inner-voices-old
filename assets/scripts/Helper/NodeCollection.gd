extends Node2D
class_name NodeCollection

@export var switch_name: String
@export var type: String, "boolean", "cutscene", "exactly", "interval", "greater than min", "less than max" = "boolean"
@export var switch_min: int
@export var switch_max: int

func _ready():
	match type:
		"boolean":
			if Gameplay.switches.has(switch_name) and Gameplay.switches[switch_name]:
				pop_children()
			else:
				queue_free()
		"cutscene":
			if not Gameplay.switches.has(switch_name) and Gameplay.switches[switch_name] > switch_min and Gameplay.switches[switch_name] < switch_max:
				queue_free()
		"interval":
			if Gameplay.switches.has(switch_name) and Gameplay.switches[switch_name] > switch_min and Gameplay.switches[switch_name] < switch_max:
				pop_children()
			else:
				queue_free()
		"greater than min":
			if Gameplay.switches.has(switch_name) and Gameplay.switches[switch_name] > switch_min:
				pop_children()
			else:
				queue_free()
		"less than max":
			if Gameplay.switches.has(switch_name) and Gameplay.switches[switch_name] < switch_max:
				pop_children()
			else:
				queue_free()

func pop_children():
	pass
