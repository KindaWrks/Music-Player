extends Node2D

@onready var fd_open = $FD_OPENfiles
@onready var fd_folder = $FD_OPENfolder

@onready var music_time_label = $HBoxContainer/MusicTimeLabel
@onready var music_total_time = $HBoxContainer/MusicTotalTimeLabel

# Add this variable to keep track of the currently playing song index
var current_playing_index = -1

@export var audio_bus_name := "Master" #Makes the var Master audio bus
@onready var _bus := AudioServer.get_bus_index(audio_bus_name) #Sets bus index to Master

var musicarray = [] # Initialize array only
var musicindex = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	fd_filters()
	

func fd_filters():
	fd_open.current_dir = "/"  #Set current dir as Root
	fd_open.add_filter("*.mp3 ; Music") #Set filter for MP3 files
	fd_folder.current_dir = "/"
	fd_folder.add_filter("*.mp3 ; Music") #Set filter for MP3 files
	

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
	

func _on_button_show_pressed(): # Replace with function body. #Show Filedialog
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

 ## save playlist to a file ##
func save_playlist(_file_path: String):
	var file = FileAccess.open("user://Playlist.save", FileAccess.WRITE)
	if file != null:
		for song_path in musicarray:
			file.store_line(song_path)
		file.close()
	else:
		print("Error: Unable to save playlist")

func _on_button_save_playlist_pressed():
	var file_path = "user://Playlist.save"  # Set your desired file path here
	save_playlist(file_path)


##	load the playlist from a file and start playing the first song ##
func load_playlist(_file_path: String):
	var file = FileAccess.open("user://Playlist.save", FileAccess.READ)
	if file != null:
		clear_playlist()  # Clear existing playlist
		$song_list.clear()  # Clear the song list in the GUI

		while not file.eof_reached():
			var line = file.get_line().strip_edges()  # Read each line from the file
			if line != "":
				musicarray.append(line)  # Add song paths to the playlist
				$song_list.add_item(line.get_file().get_basename())  # Add song to the song list
		file.close()
	else:
		print("Error: Unable to load playlist")

# Function to clear the existing playlist
func clear_playlist():
	musicarray.clear()

func _on_button_load_playlist_pressed():
	var file_path = "user://Playlist.save"
	load_playlist(file_path)

# Add this function to shuffle the songs in the playlist
func shuffle_songs():
	if musicarray.size() > 0:
		musicarray.shuffle()
		update_song_list_appearance()

# Called when the shuffle button is pressed
func _on_button_shuffle_pressed():
	shuffle_songs()
	if musicarray.size() > 0:
		musicindex = 0
		play_next_song()
		
	## Load MP3s from a folder
func _on_fd_ope_nfolder_dir_selected(path):
	var dirc = DirAccess.open(path)
	if dirc:
		dirc.list_dir_begin()
		var file_name = dirc.get_next()
		while file_name != "":
			if not dirc.current_is_dir():
				# Check if the file is an MP3 file
				if file_name.get_file().ends_with(".mp3"):
					print("Found MP3 file: " + file_name)
					# Add the file path to the music array
					musicarray.append(dirc.get_current_dir() + "/" + file_name)
					$song_list.add_item(file_name)
			file_name = dirc.get_next()

		# Play the first song if the array is not empty
		if musicarray.size() > 0:
			play_next_song()
	else:
		print("An error occurred when trying to access the path.")
		
		
func _on_button_folder_pressed():
	fd_folder.visible = true
