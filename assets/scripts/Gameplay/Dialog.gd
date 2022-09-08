extends Node

var text_speed_scale = 0.5
@onready var dialog_box : RichTextLabel = get_node(^"/root/GameRoot/HUD/bottom_black_bar/Dialog Label")
@onready var dialog_face := get_node(^"/root/GameRoot/HUD/TextIndicators/Portrait")
var _dialog_face_on_screen := false

signal dialog_ok
signal dialog_cancel
signal dialog_okcancel
signal dialog_finished
signal dialog_section_finished
signal wait(level)

func format(string) -> String:
	var regex = RegEx.new()
	regex.compile("%(?<c>\\S*)%")
	var r = string
	for m in regex.search_all(string):
		r = regex.sub(string, DCCore.strings[m.get_string("c")])
	regex.compile("\\\\n")
	for m in regex.search_all(string):
		r = regex.sub(r, "\n")
	
	return r

func _process(_delta):
	if Input.is_action_just_pressed("ok"):
		emit_signal("dialog_ok")
		emit_signal("dialog_okcancel")
	if Input.is_action_just_pressed("back"):
		emit_signal("dialog_cancel")
		emit_signal("dialog_okcancel")

var last_character_mroute = ""

#@ Play a DIALOG/Cutscene sequence (with move_routes, choices, all that good stuff) supplied in JSON form.
func play(in_dialog, sub_id, is_master=true, level = 0):
	var dialog
	if in_dialog is Dictionary and is_master and not in_dialog.has(sub_id):
		Utils.throw_error("Dialog key " + str(sub_id) + " doesn't exist in the given file:")
		print(in_dialog.keys())
	else:
		if in_dialog is Dictionary and is_master or not sub_id == "":
			dialog = in_dialog[sub_id]
		else:
			dialog = in_dialog
		#print(JSON.print(dialog, "\t"))
		for k in dialog:
			match k.type:
				"checkpoint":
					Utils.emit_signal("checkpoint", k["name"])
				"speech_delay":
					dialog_box.text_delay = k["amount"]
					SpeechSynth._set_rate(
							min(
								1 / (max(k["amount"], 0.03) * 20 * text_speed_scale),
								1.2
							)
						)
				"move":
					if not Characters.map_characters.has(k["character"]):
						continue
					last_character_mroute = k["character"]
					Characters.map_characters[k["character"]].move_route(k["route"])
				"await":
					await Characters.map_characters[last_character_mroute].route_finished
				"pose":
					if not Characters.map_characters.has(k["character"]):
						continue
					if k.has("angle"):
						var old_angle = Characters.map_characters[k["character"]].get_animation_property("ovw_angle")
						var new_angle = float(k.angle)
						var d = abs(new_angle-old_angle)
						var pi4 = PI/4
						for i in range(d):
							var a = lerp_angle(old_angle*pi4, new_angle*pi4, (i+1)/d)/pi4
							Characters.map_characters[k["character"]].set_animation_property("ovw_angle", a)
							Characters.map_characters[k["character"]].update_animation()
							await get_tree().create_timer(0.05).timeout
						Characters.map_characters[k.character].set_animation_property("ovw_angle", int(new_angle) % 8)
					if k.has("action"):
						Characters.map_characters[k["character"]].set_animation_property("ovw_action", k["action"])
					Characters.map_characters[k["character"]].update_animation()
				"pose":
					if not Characters.map_characters.has(k["character"]):
						continue
					match k.action:
						"join":
							Characters.add_party_member(k.character)
						"add":
							Characters.add_party_member(k.character)
						"remove_at":
							Characters.remove_party_member(k.character)
				"wait":
					dialog_box.text = ""
					slide_faces_out()
					await get_tree().create_timer(k.amount).timeout
				"dialog":
					# Checks if the dialog gives any bust sprite
					if k.has("bust_left"):
						if k["bust_left"] == "none":
							if get_node(^"/root/GameRoot/HUD/LeftBust").on_screen:
								get_node(^"/root/GameRoot/HUD/LeftBust").on_screen = false
								get_node(^"/root/GameRoot/HUD/LeftBust/Anim").play_backwards("in_right")
						elif not get_node(^"/root/GameRoot/HUD/LeftBust").on_screen:
							get_node(^"/root/GameRoot/HUD/LeftBust").on_screen = true
							get_node(^"/root/GameRoot/HUD/LeftBust/Anim").play("in_right")
					if k.has("bust_right"):
						if k["bust_right"] == "none":
							if get_node(^"/root/GameRoot/HUD/RightBust").on_screen:
								get_node(^"/root/GameRoot/HUD/RightBust").on_screen = false
								get_node(^"/root/GameRoot/HUD/RightBust/Anim").play_backwards("in_right")
						elif not get_node(^"/root/GameRoot/HUD/RightBust").on_screen:
							get_node(^"/root/GameRoot/HUD/RightBust").on_screen = true
							get_node(^"/root/GameRoot/HUD/RightBust/Anim").play("in_right")

					var portrait_name
					var voice
					# If the dialog gives a speaking character, update DCCore::speaking_character
					# Fetch the portrait from Utils::character_specs
					if k.has("character"):
						DCCore.speaking_character = k.character
						portrait_name = Utils.get_specs(k.character.to_lower()).portrait
						voice = Utils.get_specs(k.character.to_lower()).voice
					else:
						DCCore.speaking_character = "clio"
						portrait_name = "none"
						voice = "narrator"

					# Creates the face animation using the portrait at the specs, and appending the given expression
					var face_anim = portrait_name if portrait_name == "none" or k.expression == "" else portrait_name + "_" + k.expression

					if face_anim == "none" or not DCCore.use_portraits:
						if _dialog_face_on_screen:
							dialog_face.get_node(^"Anim").play("out")
						_dialog_face_on_screen = false
					else:
						if not _dialog_face_on_screen:
							dialog_face.get_node(^"Anim").play("in")
						_dialog_face_on_screen = true
						if dialog_face.frames.has_animation(face_anim):
							dialog_face.animation = face_anim

					var content = format(k.content)

					# Writes to the dialog box using a special prefix.
					if k.has("prefix"):
						write_to(dialog_box, k.prefix + content, voice)
					else:
						write_to(dialog_box, content, voice)
					await dialog_box.finished

					if k.has("has_choice"):
						if k.has_choice:
							# The choice part
							DCCore.choice(k.prefix + content, k.texts, k.icons, -16, dialog_box)
							var _choice_accepted = await DCCore.choice_finished

							# In case there are answers, play the selected one and wait
							# until the answers finish.
							play(k.answers[DCCore.choice_result], "", false, level + 1)
							while await self.wait != level + 1:
								pass
				"switch":
					Memory.switch(k.switch_type, k.name, k.value)
				"sfx":
					AudioManager.play(k.name)
				"function":
					var scene = get_node(^"/root/GameRoot/World3D/Scene/")
					if not scene.has_method(k.name):
						Utils.throw_error("The current scene does not have the function "+str(k.name))
						continue
					scene.call(k.name)
				"soundtrack":
					match k["action"]:
						"pause":
							SoundtrackCore.bgm_pause()
						"resume":
							SoundtrackCore.bgm_resume()
						"restart":
							SoundtrackCore.bgm_restart()
						"load":
							SoundtrackCore.load_music(
								k.file, k.name
							)
				"screen":
					var t = get_node(^"/root/GameRoot/Transition/TransitionPlayer")
					match k["action"]:
						"turn":
							if k.parameter:
								t.play("fade_black")
							else:
								t.play("fade_black_out")
						"transition":
							t.play(k.parameter)
						"shake":
							ScreenCore.global_camera.shake(0.5, 15, 4)
				"item":
					MenuCore.inventories["claire"].give_item(k.item, k.count)
	if is_master:
		DCCore.on_dialog_finished()
		if not Gameplay.GAMEMODE == Gameplay.GM.BATTLE and not DCCore.in_cutscene and not MenuCore.in_mmenu:
			get_node(^"/root/GameRoot/HUD/black_bars").play("dialog_pop_out")
			get_node(^"/root/GameRoot/HUD/black_bars_top").play("menu_out")
		dialog_box.clear()
		slide_faces_out()
	else:
		emit_signal("wait", level)

func slide_faces_out():
	if get_node(^"/root/GameRoot/HUD/LeftBust").on_screen:
		get_node(^"/root/GameRoot/HUD/LeftBust").on_screen = false
		get_node(^"/root/GameRoot/HUD/LeftBust/Anim").play_backwards("in_right")
	if get_node(^"/root/GameRoot/HUD/RightBust").on_screen:
		get_node(^"/root/GameRoot/HUD/RightBust").on_screen = false
		get_node(^"/root/GameRoot/HUD/RightBust/Anim").play_backwards("in_right")
	if _dialog_face_on_screen:
		_dialog_face_on_screen = false
		dialog_face.get_node(^"Anim").play("out")

func playc(id, sub_id, choices, icons, offset, mode=0):
	dialog_box = DCCore.dialog_box
	if id != "":
		var file = File.new()
		file.open("res://assets/dialogs/" + DCCore.lang + "/" + id + ".json", file.READ)
		var text = file.get_as_text()
		var json = JSON.new()
		json.parse(text)
		var current_dialog = json.get_data()
		file.close()
		var in_dialog = current_dialog
		var dialog = in_dialog[sub_id]
		Gameplay.in_dialog = true
		if(dialog == []):
			emit_signal("dialog_section_finished")
			return
		var k = dialog[0]
		
		write_to(dialog_box, k["content"], k["speaker"])
		
		await dialog_box.finished
		DCCore.choice(k["content"], choices, icons, offset, dialog_box, mode)
	else:
		DCCore.choice("", choices, icons, offset, dialog_box, mode)
	dialog_box.text = ""
	emit_signal("dialog_section_finished")
	dialog_box.text_delay = 0.05

func simple_choice(choices, icons, offset, mode=0, text_pos=0, question="...?"):
	dialog_box = DCCore.dialog_box
	DCCore.choice(question, choices, icons, offset, dialog_box, mode, text_pos)
	await DCCore.choice_finished
	Gameplay.in_dialog = false
	emit_signal("dialog_section_finished")

func simple_char_choice(chars, text_pos=0, question="On whom...?"):
	dialog_box = DCCore.dialog_box
	DCCore.char_choice(question, chars, text_pos)
	await DCCore.choice_finished
	Gameplay.in_dialog = false
	emit_signal("dialog_section_finished")

# Write something step by step in a dialog box
func write_to(db:RichTextLabel, content, voice):
	DCCore.is_writing = true
	
	db.write(content)
	var dbbeep = db.get_node_or_null("beep")
	if dbbeep:
		dbbeep.stream = load("res://assets/sounds/voices/"+voice+".wav")
	
	#@ If Acessibility Settings :: Text to Speech is enabled, speak the text out loud!
	if Utils.is_narrating:
		SpeechSynth.stop()
		Utils.speak(db.text.replace("* ", "").replace("- ", ""))
	
	await db.finished
	
	DCCore.is_writing = false
