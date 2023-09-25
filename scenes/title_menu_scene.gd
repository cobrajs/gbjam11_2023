extends Node2D

@onready var menu := $Menu

func _ready():
	pass


func _process(delta):
	if Input.is_action_just_pressed("game_start") or \
		Input.is_action_just_pressed("game_select") or \
		Input.is_action_just_pressed("game_a") or \
		Input.is_action_just_pressed("game_b"):
		get_tree().change_scene_to_file("res://scenes/space_flight_scene.tscn")
