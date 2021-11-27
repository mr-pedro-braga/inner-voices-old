extends Node

func battle_turn_select(c, battle_round):
	var file = File.new()
	file.open("res://assets/battle/battle_scripts/battle_demo.battle", file.READ)
	var text = file.get_as_text()
	return parse_json(text)["rain"]
