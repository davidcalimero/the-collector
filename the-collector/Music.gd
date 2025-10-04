extends AudioStreamPlayer

@export var default_stream: AudioStream
@export var default_volume_db: float = -6.0

var _current: AudioStream = null

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	bus = "Music"
	volume_db = default_volume_db
	if default_stream:
		play_music(default_stream)

func play_music(stream: AudioStream, loop := true) -> void:
	if stream == null:
		return
	if _current == stream and playing:
		return
	_current = stream
	self.stream = stream
	self.stream.loop = loop
	play()

func fade_to(stream: AudioStream, duration := 0.6, loop := true) -> void:
	# fade out -> troca -> fade in
	var from_vol := volume_db
	var t := create_tween()
	t.tween_property(self, "volume_db", -60.0, duration * 0.5)
	t.connect("finished", func ():
		play_music(stream, loop)
		create_tween().tween_property(self, "volume_db", from_vol, duration * 0.5)
	)
