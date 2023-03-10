extends Node2D

const PlayerScene = preload("res://Player/Player.tscn")

var player_spawn_location = Vector2.ZERO

onready var camera = $Camera2D
onready var player = $Player
onready var timer = $RespawnTimer


func _ready():
	player.connect_camera(camera)
	player_spawn_location = player.global_position
	Globals.connect("player_died", self, "_on_player_died")
	Globals.connect("hit_checkpoint", self, "_on_hit_checkpoint")

func _on_player_died():
	timer.start(1.0)
	yield(timer, "timeout")
	var player = PlayerScene.instance()
	player.global_position = player_spawn_location
	add_child(player)
	player.connect_camera(camera)

func _on_hit_checkpoint(checkpoint_position):
	player_spawn_location = checkpoint_position
