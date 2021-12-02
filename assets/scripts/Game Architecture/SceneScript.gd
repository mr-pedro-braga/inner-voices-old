#
#
#			Scene Script 1.0.0
#				by Pedro Braga
#
#
# An utility class made to parse SceneScript
#  and SceneScript Object Notation (SSON).

class_name SceneScript






#
# @ Cutscene extraction and parsing from *.sc and *.sson files.
#

#@ Parses a *.sson file into a list of objects
static func parse_sson_dictionary(raw):
	var regex = RegEx.new()
	var _error = regex.compile("(?m)^ *--(?<key>\\w+): *(?<block>(?:\\n\\t.*)*)")
	var results := {}
	
	for m in regex.search_all(raw):
		var names = m.get_names()
		
		var object = parse_dictionary(unindent(
			m.get_string(names["block"])
		))
		if not object == {}:
			results[m.get_string(names["key"]).to_lower()] = object
	return results


#@ Parses a list of keys and values in the SSON dictionary specification.
static func parse_dictionary(raw):
	var regex = RegEx.new()
	regex.compile("(?m)^ *(?<key>[\\w|\\*]+): *((?<value>.*)(?<block>(?:\\n\\t.*)*)?)?")
	var results := {}
	for m in regex.search_all(raw):
		var sub_dict = {}
		var names = m.get_names()
		var block = m.get_string(names["block"])
		
		if block:
			sub_dict = parse_dictionary(unindent(block))
			results[m.get_string(names["key"])] = sub_dict
			continue
		
		results[m.get_string(names["key"]).to_lower()] = value_format(m.get_string(names["value"]))
	
	return results

#@ Parses a *.sson file into a list of cutscene objects.
static func parse_sson_cutscene(raw):
	var regex = RegEx.new()
	var _error = regex.compile("(?m)^ *--(?<key>[\\w|\\*]+) *((?<value>.*)(?<block>(?:\\n\\t.*)*)?)?")
	
	var results := {}
	
	for m in regex.search_all(raw):
		var names = m.get_names()
		
		var cutscene = parse_cutscene(unindent(
			m.get_string(names["block"])
		))
		
		if not cutscene == []:
			results[m.get_string(names["key"])] = cutscene
	
	return results

#@ Parses a cutscene from scene script into JSON
static func parse_cutscene(raw):
	var regex = RegEx.new()
	regex.compile("(?m)^ *(?<command>[\\w|\\*]+) *((?<params>.*)(?<block>(?:\\n\\t.*)*)?)?")
	var results = []
	
	for m in regex.search_all(raw):
		var line = parse_cutscene_entry(m)
		if not line == {}:
			results.push_back(
				line
			)
	
	return results

#@ Parses a single cutscene entry by comparing it against a list of regexprs.
static func parse_cutscene_entry(raw_match):
	var names = raw_match.get_names()
	var r = {}
	
	var command:String = raw_match.get_string(names["command"])
	var params = raw_match.get_string(names["params"])
	var block = raw_match.get_string(names["block"])
	
	# Match Dialogs
	var match_dialog = quick_match(params, " *\\( *(?<expression>\\w*) *\\): *(?<text>.*)")
	
	if match_dialog:
		var match_names = match_dialog.get_names()
		if block:
			var choices = parse_choices(unindent(block))
			r = {
				"type": "dialog",
				"character": command.to_lower(),
				"expression": match_dialog.get_string(match_names["expression"]),
				"content": match_dialog.get_string(match_names["text"]),
				"prefix": "- ",
				"has_default": false,
				"icons": choices.icons,
				"texts": choices.texts,
				"answers": choices.answers,
				"has_choice": true,
			}
			
			if r.character == "clio":
				r.prefix = "* "
		else:
			r = {
				"type": "dialog",
				"character": command.to_lower(),
				"expression": match_dialog.get_string(match_names["expression"]),
				"content": match_dialog.get_string(match_names["text"]),
				"prefix": "- ",
				"has_choice": false,
			}
		return r
	
	# Match Variable Manipulation
	var match_vm = quick_match(params, " *(?<op>=|\\+=|-=|\\*=|/=|\\^=)\\s*(?<expr>.*)?$")
	
#	if match_vm:
#		var match_names = match_vm.get_names()
#		r = {
#			"type": "variable_modify",
#			"variable": command,
#			"mode": match_vm.get_string(match_names["op"]),
#			"value": match_vm.get_string(match_names["expr"])
#		}
#		return r
	
	# Match Normal Commands
	match command:
		"*":
			if block:
				var choices = parse_choices(unindent(block))
				r = {
					"type": "dialog",
					"character": "narrator",
					"expression": "none",
					"prefix": "* ",
					"content": params,
					"has_default": false,
					"icons": choices.icons,
					"texts": choices.texts,
					"answers": choices.answers,
					"has_choice": true,
				}
			else:
				r = {
					"type": "dialog",
					"character": "narrator",
					"expression": "none",
					"prefix": "* ",
					"content": params,
					"has_choice": false,
				}
		"-":
			if block:
				var choices = parse_choices(unindent(block))
				r = {
					"type": "dialog",
					"character": "narrator",
					"expression": "none",
					"prefix": "- ",
					"content": params,
					"has_default": false,
					"icons": choices.icons,
					"texts": choices.texts,
					"answers": choices.answers,
					"has_choice": true,
				}
			else:
				r = {
					"type": "dialog",
					"character": "narrator",
					"expression": "none",
					"prefix": "- ",
					"content": params,
					"has_choice": false,
				}
		"wait":
			if quick_match(params, "\\d+(\\.\\d+)?"):
				r = {
					"type": "wait",
					"amount": float(params)
				}
			elif quick_match(params, "\\w+"):
				r = {
					"type": "wait_for_signal",
					"amount": params
				}
			else:
				r = {
					"type": "await"
				}
		"pose":
			var terms = get_terms(params)
			r = {
				"type": "pose",
				"character": terms[0],
				"action": terms[1],
				"angle": terms[2]
			}
		"move":
			var route = parse_move_route(unindent(block))
			r = {
				"type": "move",
				"character": params,
				"route": route,
			}
		"text_mode":
			r = {
				"type": "set_" + params
			}
		"speech_delay":
			r = {
				"type": "speech_delay",
				"amount": float(params)
			}
		"bgm":
			var terms = get_terms(params)
			if terms[0] == "load":
				r = {
					"type": "soundtrack",
					"action": "load",
					"file": terms[1],
					"name": terms[2].replace("_", " ")
				}
				return r
			r = {
				"type": "soundtrack",
				"action": terms[0]
			}
		"sfx":
			var terms = get_terms(params)
			r = {
				"type": "sfx",
				"name": terms[0]
			}
		"call":
			r = {
				"type": "function",
				"name": params
			}
		"item":
			var terms = get_terms(params)
			r = {
				"type": "item",
				"action": terms[0],
				"item": terms[1],
				"count": terms[2]
			}
		"menu":
			var choices = parse_choices(unindent(block))
			r = {
				"type": "choice",
				"has_default": choices.has_default,
				"question": params,
				"icons": choices.icons,
				"texts": choices.texts,
				"answers": choices.answers,
				"default_answer": choices.default
			}
		"if":
			r = {
				"type": "if",
				"condition": params,
				"content": parse_cutscene(unindent(block))
			}
		"unless":
			r = {
				"type": "unless",
				"condition": params,
				"content": parse_cutscene(unindent(block))
			}
		"compare":
			r = {
				"type": "compare",
				"condition": params,
				# (!) Unfinished!
				"content": parse_cutscene(unindent(block))
			}
		"else":
			r = {
				"type": "else",
				"content": parse_cutscene(unindent(block))
			}
		"switch":
			var terms = get_terms(params)
			var switch_types = {"permanent": Memory.PERMANENT,"episode": Memory.EPISODE,"session": Memory.SESSION}
			r = {
				# (!) Needs implementation!
				"type": "switch",
				"switch_type": switch_types[terms[0]],
				"name": terms[1],
				"value": value_format(terms[2])
			}
		"function":
			var terms = get_terms(params)
			r = {
				"type": "function",
				"name": terms[0]
			}
		"screen":
			var terms = get_terms(params)
			r = {
				"type": "screen",
				"action": terms[0],
				"parameter": value_format(terms[1])
			}
		_:
			r = {}
	return r

#@ Parses a single entry of choices
static func parse_choices(list):
	var obj = {
		"icons": [],
		"texts": [],
		"answers": [],
		"default": [],
		"has_default": false
	}
	
	var regex = RegEx.new()
	regex.compile("(?m)^(?<text>\\S.*) *\\( *(?<icon>\\w*) *\\):(?<answer>(?:\\n\\t.*)*)")
	
	for m in regex.search_all(list):
		var names = m.get_names()
		obj.icons.append(m.get_string(names["icon"]))
		obj.texts.append(m.get_string(names["text"]))
		obj.answers.append(
			parse_cutscene(unindent(m.get_string(names["answer"])))
		)
	
	regex.compile("(?m)^default *:(?<answer>(?:\n\t.*)*)")
	var m = regex.search(list)
	if m:
		var names = m.get_names()
		obj.default = parse_cutscene(unindent(m.get_string(names["answer"])))
		obj.has_default = true
	
	return obj

#@ Parses an indented block of move routes
static func parse_move_route(list):
	var regex = RegEx.new()
	regex.compile("(?m)^ *(?<command>[\\w|\\*]+) *((?<params>.*)(?<block>(?:\\n\\t.*)*)?)?")
	var results = []
	
	for m in regex.search_all(list):
		var line = parse_move_route_entry(m)
		if not line == {}:
			results.push_back(
				line
			)
	
	return results

#@ Parses a single entry of a move route sequence
static func parse_move_route_entry(raw_match):
	var names = raw_match.get_names()
	var r = {}
	
	var command:String = raw_match.get_string(names["command"])
	var params = raw_match.get_string(names["params"])
	var _block = raw_match.get_string(names["block"])
	
	# Match Normal Commands
	match command:
		"goto":
			r = {
				"type": "goto",
				"line": int(params)
			}
		"wait":
			r = {
				"type": "wait",
				"amount": float(params)
			}
		"mvto":
			var terms = get_terms(params)
			
			r = {
				"type": "absolute",
				"target": [float(terms[0]), float(terms[1])]
			}
		"mvadd":
			var terms = get_terms(params)
			
			r = {
				"type": "delta",
				"target": [float(terms[0]), float(terms[1])]
			}
		"mvspeed":
			r = {
				"type": "speed",
				"value": float(params)
			}
		"turn":
			var terms = get_terms(params)
			if terms[0] == "lock":
				r = {
					"type": "lock_angle"
				}
			elif terms[0] == "unlock":
				r = {
					"type": "unlock_angle"
				}
			else:
				r = {
					"type": "dir",
					"angle": int(terms[0])
				}
		"face":
			var terms = get_terms(params)
			if Characters.map_characters.has(terms[0]):
				var target_position = Characters.map_characters[terms[0]].position
				r = {
					"type": "face_position",
					"position": target_position
				}
				return r
			r = {
				"type": "face_position",
				"position": Vector2(terms[0], terms[1])
			}
		"action":
			var terms = get_terms(params)
			
			r = {
				"type": "action",
				"value": terms[0]
			}
		"anim":
			r = {
				"type": "name",
				"value": params
			}
		"dialog":
			var terms = get_terms(params)
			
			r = {
				"type": "dialog",
				"file": terms[0],
				"block": terms[1]
			}
		"path":
			var terms = get_terms(params)
			if terms[0] == "append":
				r = {
					"type": "append_path",
					"path": terms[1]
				}
			else:
				r = {
					"type": "path",
					"path": params
				}
		"destroy":
			r = {
				"type": "destroy"
			}
		_:
			r = {}
	return r









#
# @ Cutscene extraction and parsing from *.json files into cutscene *.sson
#



# (!) To implement!



#
# @ Utility static functions!
#

#@ Parses a string into a boolean or a number if possible
static func value_format(string:String):
	# Match Booleans!
	if quick_match(string, "\\s+(?:true|yes|on)\\s+"):
		return true
	if quick_match(string, "\\s+(?:false|no|off)\\s+"):
		return true
	# Match Integers!
	if quick_match(string, "\\s*\\d+\\s*"):
		return int(string)
	# Match Floats
	if quick_match(string, "\\s*\\d+.\\d+f?\\s*"):
		return float(string)
	# Match Hexadecimal!
	if quick_match(string, "\\s*0x[\\d\\w]+\\s*"):
		return int(string)
		
	# When all else fails... then it must be a string anyways.
	return string

#@ Gets the terms from a string separated by spaces.
static func get_terms(string:String):
	return string.split(" ", false)

#@ Matches a string against a regular expression
static func quick_match(string, regex):
	var r = RegEx.new()
	r.compile(regex)
	return (r.search(string))

#@ Unindents an indented block
static func unindent(string, indentation_character="\t"):
	var r = RegEx.new()
	r.compile("(?m)^"+indentation_character)
	return r.sub(string, "", true)
