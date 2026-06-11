class_name SoundManager
extends Node
## 音效管理器

signal sound_played(sound_name: String)

@export var enabled: bool = true
@export var master_volume: float = 1.0

var _audio_players: Dictionary = {}


func _ready() -> void:
	# 预创建音频播放器
	for i in range(10):
		var player := AudioStreamPlayer.new()
		add_child(player)
		_audio_players["player_" + str(i)] = player


func play_sound(sound_name: String, stream: AudioStream = null) -> void:
	if not enabled:
		return
	
	# 查找空闲的播放器
	for key in _audio_players:
		var player: AudioStreamPlayer = _audio_players[key]
		if not player.playing:
			if stream != null:
				player.stream = stream
			player.volume_db = linear_to_db(master_volume)
			player.play()
			sound_played.emit(sound_name)
			return
	
	# 如果没有空闲播放器，使用第一个
	var first_player: AudioStreamPlayer = _audio_players.values()[0]
	if stream != null:
		first_player.stream = stream
	first_player.volume_db = linear_to_db(master_volume)
	first_player.play()
	sound_played.emit(sound_name)


func play_card_play() -> void:
	play_sound("card_play")


func play_damage() -> void:
	play_sound("damage")


func play_block() -> void:
	play_sound("block")


func play_turn_end() -> void:
	play_sound("turn_end")


func play_victory() -> void:
	play_sound("victory")


func play_defeat() -> void:
	play_sound("defeat")


func set_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)


func set_enabled(is_enabled: bool) -> void:
	enabled = is_enabled