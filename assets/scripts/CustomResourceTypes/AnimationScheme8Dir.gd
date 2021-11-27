extends Resource
class_name AnimationScheme8Dir

var state = {}

func _init(p_angle=0):
	state.ovw_angle = p_angle

func get_animation_name():
	var t = ("" if state.prefix == "" else state.prefix + "_") + state.ovw_action + ("_" + str(state.ovw_angle) if state.using_angle else "")
	return t
