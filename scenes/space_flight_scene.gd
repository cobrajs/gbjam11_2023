extends Node2D

@onready var star_field: StarField = $StarField
@onready var ship: Ship = $Ship
@onready var block_holder := $BlockHolder
@onready var debris_count_label := $Control/DebrisCount
@onready var animation := $AnimationPlayer

@onready var a_button_action := $Controls/AButtonAction
@onready var b_button_action := $Controls/BButtonAction

@onready var FallingBlockPre := preload("res://game_objects/falling_block.tscn")

@onready var timer := $Timer

var debris_count := 10

func _ready():
	pass


func _process(_delta):
	if !ship.can_control:
		emit_thrust()


func _unhandled_input(event):
	if event.is_action_pressed("game_select"):
		add_falling_block()


func add_falling_block():
	var falling_block: FallingBlock = FallingBlockPre.instantiate()
	var size := get_viewport().get_visible_rect().size
	falling_block.position.x = -randi_range(5, 20)
	falling_block.position.y = randi_range(20, size.y - 20)
	#falling_block.position.y = floor(size.y / 2)
	block_holder.add_child(falling_block)
	debris_count -= 1
	debris_count_label.text = 'Debris: ' + str(debris_count)
	falling_block.connect("debris_away", _on_ship_collected_debris)


func emit_thrust() -> void:
	ship.thrust.emit(Vector2.RIGHT)


func start_scene() -> void:
	ship.thrust_end.emit()
	if GameState.player_config["planet"].has("get_debris_count") and \
		GameState.player_config["planet"]["get_debris_count"] is Callable:
		debris_count = GameState.player_config["planet"]["get_debris_count"].call()
	add_falling_block()
	timer.start()


func end_scene() -> void:
	ship.check_baddies()
	animation.play("ship_exit_scene")


func change_scene() -> void:
	get_tree().change_scene_to_file("res://scenes/trading_scene.tscn")


func _on_ship_change_can_rotate(value: bool):
	if value:
		a_button_action.frame_coords.y = 6
		b_button_action.frame_coords.y = 6
	else:
		a_button_action.frame_coords.y = 7
		b_button_action.frame_coords.y = 7


func _on_ship_collected_debris():
	print("Collected!")
	if remaining_blocks():
		return
	if debris_count <= 0:
		end_scene()
	else:
		add_falling_block()


func _on_timer_timeout():
	print("timerout")
	if remaining_blocks():
		return
	if debris_count <= 0:
		end_scene()
	else:
		add_falling_block()


func remaining_blocks() -> bool:
	for child in block_holder.get_children():
		if child is FallingBlock:
			return true
	
	return false
