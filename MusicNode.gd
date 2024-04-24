extends Node2D

@onready var fd_open = $FD_OPENfiles

@onready var music_label = $MusicLabel
@onready var music_time_label = $MusicTimeLabel
@onready var music_total_time = $MusicTotalTimeLabel


@export var audio_bus_name := "Master" #Makes the var Master audio bus
@onready var _bus := AudioServer.get_bus_index(audio_bus_name) #Sets bus index to Master

var musicarray = [] # Initialize array only
var musicindex = 0

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
	music_label.text = str(musicarray).get_file().get_basename() #Gets the current file and removes the .MP3
	
	if $AudioStreamPlayer.playing: #Make time count down in int rather then float and show total time
		music_time_label.text = str(int($AudioStreamPlayer.stream.get_length()) - int($AudioStreamPlayer.get_playback_position()))
		music_total_time.text = str(int($AudioStreamPlayer.stream.get_length()))
	print(musicarray)
	
	
	# Check if the song ended and play the next song in the queue
	if not $AudioStreamPlayer.playing and musicarray.size() > 0:
		play_next_song()


func _on_fd_open_files_selected(paths):
	for path in paths:
		var snd_file = FileAccess.open(path, FileAccess.READ) # Open path and read from the file
		var stream = AudioStreamMP3.new() # Create a new MP3 Audio stream
		stream.data = snd_file.get_buffer(snd_file.get_length()) # Load entire song into memory(not ideal)
		snd_file.close() # Close file.
		$AudioStreamPlayer.stream = stream  # The loaded song in memory
		$AudioStreamPlayer.play()
		music_label.visible = true

		# Add the selected song to the queue
		musicarray.append(path)
		
		#Add song list
		#var file_name_without_extension = path.get_file().get_basename()
		#$song_list.add_item(file_name_without_extension)

func play_next_song():
	var next_song_path = musicarray[musicindex] # Get the next song from the queue
	var snd_file = FileAccess.open(next_song_path, FileAccess.READ) #Open path and read from the file
	var stream = AudioStreamMP3.new() #Create a new MP3 Audio stream
	stream.data = snd_file.get_buffer(snd_file.get_length()) # Load entire song into memory(not ideal)
	snd_file.close() #Close file.
	$AudioStreamPlayer.stream = stream  #The loaded song in memory
	$AudioStreamPlayer.play()

func _on_buttonshow_pressed():
	fd_open.visible = true
	
func _on_h_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(_bus,linear_to_db(value)) #Control volume as a float

