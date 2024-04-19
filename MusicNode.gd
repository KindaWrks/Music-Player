extends Node2D

@onready var fd_open = $FD_OPEN
@onready var music_label = $MusicLabel
@onready var music_time_label = $MusicTimeLabel

@export var audio_bus_name := "Master" #Makes the var Master audio bus
@onready var _bus := AudioServer.get_bus_index(audio_bus_name) #Sets bus index to Master

# Called when the node enters the scene tree for the first time.
func _ready():
	fd_o_filters()
	fd_open.visible = true
	music_label.visible = false

func fd_o_filters():
	fd_open.current_dir = "/"  #Set current dir as Root
	fd_open.add_filter("*.mp3 ; Music") #Set filter for MP3 files

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	music_label.text = fd_open.current_file.get_basename() #Gets the current file and removes the .MP3
	music_time_label.text = str(int($AudioStreamPlayer.get_playback_position())) #Make time count in int rather then flaot
	
func _on_fd_open_file_selected(path):
	var snd_file = FileAccess.open(path, FileAccess.READ) #Open path and reaf from the file
	var stream = AudioStreamMP3.new() #Create a bew MP3 Audio stream
	stream.data = snd_file.get_buffer(snd_file.get_length()) # Load entire song into memory(not ideal)
	snd_file.close() #Close file.
	$AudioStreamPlayer.stream = stream  #The loaded song in memeory
	$AudioStreamPlayer.play()
	music_label.visible = true


func _on_h_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(_bus,linear_to_db(value)) #Control volume as a float

