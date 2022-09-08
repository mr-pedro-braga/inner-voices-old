extends DefaultScene

func scene_ready():
	SoundtrackCore.load_music("mus_starfall_village.mp3", "Starfall City")

func evt_starfall_enter(_id, _parameter, _arguments):
	SoundtrackCore.bgm_resume()
