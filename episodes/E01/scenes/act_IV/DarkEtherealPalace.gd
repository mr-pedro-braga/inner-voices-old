extends DefaultScene

func _ready():
	pass

var time = 0

func _process(delta):
	time += delta
	
	$CanvasModulate2.color = Color.from_hsv(time / 10.0, 0.5, 1.0)
	$Background/CanvasModulate.color = $CanvasModulate2.color
