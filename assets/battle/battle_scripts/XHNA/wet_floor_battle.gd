extends Node

func battle_turn_select(c, battle_round):
	var file = File.new()
	file.open("res://assets/battle/battle_scripts/battle_demo.battle", file.READ)
	var text = file.get_as_text()
	var test_json_conv = JSON.new()
	test_json_conv.parse(text)["rain"]
	return test_json_conv.get_data()
