extends Node2D

@onready var fd_open = $FD_OPENfiles

@onready var music_time_label = $MusicTimeLabel
@onready var music_total_time = $MusicTotalTimeLabel

# Add this variable to keep track of the currently playing song index
var current_playing_index = -1

@export var audio_bus_name := "Master" #Makes the var Master audio bus
@onready var _bus := AudioServer.get_bus_index(audio_bus_name) #Sets bus index to Master

var musicarray = [] # Initialize array only
var musicindex = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	fd_o_filters()
	fd_open.visible = true
	

func fd_o_filters():
	fd_open.current_dir = "/"  #Set current dir as Root
	fd_open.add_filter("*.mp3 ; Music") #Set filter for MP3 files
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta): 
	next_song_in_array()
	update_time_labels()
	
	
# Update the appearance of the song list
func update_song_list_appearance():
	for i in range($song_list.get_item_count()):
		var item_text = musicarray[i].get_file().get_basename()
		$song_list.set_item_text(i, item_text)
		
		# Highlight the currently playing song
		if i == current_playing_index:
			$song_list.select(i)

# Add this function to update the appearance of the song list when a new song starts playing
func update_current_playing_index(index):
	current_playing_index = index
	update_song_list_appearance()
	

func update_time_labels():
	if $AudioStreamPlayer.playing:
		var total_length = int($AudioStreamPlayer.stream.get_length())
		var current_position = int($AudioStreamPlayer.get_playback_position())
		# conversion of playback to minutes and seconds, calls error discard decimal
		var minutes = (total_length - current_position) / 60
		var seconds = (total_length - current_position) % 60
		# Display through text labels
		music_time_label.text = str(minutes).pad_zeros(1) + ":" + str(seconds).pad_zeros(2)
		music_total_time.text = str(total_length / 60).pad_zeros(1) + ":" + str(total_length % 60).pad_zeros(2)
	print(musicarray)
	

# Check if the song ended and play the next song in the queue
func next_song_in_array():
	if not $AudioStreamPlayer.playing and musicarray.size() > 0:
		musicindex += 1
		if musicindex >= musicarray.size():
			musicindex = 0
		play_next_song()
	

func _on_fd_open_files_selected(paths):
	for path in paths:
		var snd_file = FileAccess.open(path, FileAccess.READ) # Open path and read from the file
		var stream = AudioStreamMP3.new() # Create a new MP3 Audio stream
		stream.data = snd_file.get_buffer(snd_file.get_length()) # Load entire song into memory(not ideal)
		snd_file.close() # Close file.
		$AudioStreamPlayer.stream = stream  # The loaded song in memory
		$AudioStreamPlayer.play()

		# Add the selected song to the queue
		musicarray.append(path)
		
		#Add songs to itemlist
		var file_name_without_extension = path.get_file().get_basename()
		$song_list.add_item(file_name_without_extension)
	

# Function to play the next song in the queue
func play_next_song():
	var next_song_path = musicarray[musicindex]
	var snd_file = FileAccess.open(next_song_path, FileAccess.READ)
	var stream = AudioStreamMP3.new()
	stream.data = snd_file.get_buffer(snd_file.get_length())
	snd_file.close()
	$AudioStreamPlayer.stream = stream
	$AudioStreamPlayer.play()

	# Update the currently playing index and the appearance of the song list
	update_current_playing_index(musicindex)
	

func _on_buttonshow_pressed(): #Show Filedialog
	fd_open.visible = true
	

func _on_h_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(_bus,linear_to_db(value)) #Control volume as a float
	

# Called when an item in the song list is selected
func _on_song_list_item_selected(index):
	if index < musicarray.size():
		var selected_song_path = musicarray[index]
		play_song(selected_song_path)
		

# Function to play a selected song
func play_song(song_path):
	var snd_file = FileAccess.open(song_path, FileAccess.READ)
	var stream = AudioStreamMP3.new()
	stream.data = snd_file.get_buffer(snd_file.get_length())
	snd_file.close()
	$AudioStreamPlayer.stream = stream
	$AudioStreamPlayer.play()

	# Update the currently playing index and the appearance of the song list
	var index = musicarray.find(song_path)
	update_current_playing_index(index)

	
