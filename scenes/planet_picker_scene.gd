extends Node2D

@onready var texture: = load("res://assets/tiles.png")
@onready var selector := $Selector

@onready var travel_button := $TravelStuff/TravelButton
@onready var travel_label := $TravelStuff/TravelLabel

@onready var planet_info := $PlanetInfo

var selected_planet = PlanetConfig.get_planet(0)

# Called when the node enters the scene tree for the first time.
func _ready():
	if selected_planet:
		update_planet_text()
		var tween = get_tree().create_tween()
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(selector, "position", selected_planet["position"], 0.6)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("game_left"):
		select_planet(Vector2.LEFT)

	if Input.is_action_just_pressed("game_right"):
		select_planet(Vector2.RIGHT)

	if Input.is_action_just_pressed("game_up"):
		select_planet(Vector2.UP)

	if Input.is_action_just_pressed("game_down"):
		select_planet(Vector2.DOWN)
		
	if Input.is_action_just_pressed("game_a"):
		travel_to_planet()


func travel_to_planet():
	if not can_travel_to_planet(selected_planet):
		return
	
	GameState.player_config["planet"] = selected_planet
	get_tree().change_scene_to_file("res://scenes/space_flight_scene.tscn")


func select_planet(direction: Vector2):
	var closest = 100
	var choice_planet = null
	for connection in selected_planet["connections"]:
		var other_planet = PlanetConfig.get_planet(connection)
		if not other_planet:
			continue
		
		var angle_diff = abs(direction.angle() - abs((other_planet["position"] - selected_planet["position"]).angle()))
		if angle_diff < closest:
			closest = angle_diff
			choice_planet = other_planet
	
	if not choice_planet:
		return

	selected_planet = choice_planet
	
	if can_travel_to_planet(selected_planet):
		travel_button.visible = true
		travel_label.visible = true
	else:
		travel_button.visible = false
		travel_label.visible = false
	
	update_planet_text()

	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(selector, "position", selected_planet["position"], 0.4)


func update_planet_text():
	planet_info.text = selected_planet["name"] + '\n' + \
			selected_planet["description1"] + '\n' + \
			selected_planet["description2"]


func can_travel_to_planet(planet: Dictionary) -> bool:
	var player_planet_id = GameState.player_config["planet"]["id"]
	return selected_planet["connections"].has(player_planet_id) and selected_planet["id"] != player_planet_id


const PLANET_SIZE: = Vector2(20, 10)

func _draw():
	var drawn_segments := []
	for planet in PlanetConfig.planets:
		var color := Consts.COLOR_GREY
		var current_planet: bool = planet["id"] == GameState.player_config["planet"]["id"]
		if current_planet:
			color = Consts.COLOR_WHITE
			
		var planet_draw_position: Vector2 = planet["position"] - PLANET_SIZE / 2

		if not planet["connections"].is_empty():
			for connection in planet["connections"]:
				var segment_id = str(max(connection, planet["id"])) + ':' + str(min(connection, planet["id"]))
				if drawn_segments.has(segment_id):
					continue
				drawn_segments.append(segment_id)
				
				var other_planet = PlanetConfig.get_planet(connection)
				if not other_planet:
					continue
				var line = other_planet["position"] - planet["position"]
				var segments = floor(line.length() / 7)
				var segment = line / segments
				for i in range(2, segments - 1):
					draw_texture_rect_region(texture, Rect2((planet["position"] - Vector2(2, 2)) + segment * i, Vector2(4, 4)), Rect2(Vector2(40, 10 if current_planet else 15), Vector2(4, 4)))

		draw_texture_rect_region(texture, Rect2(planet_draw_position, PLANET_SIZE), Rect2(80, 90 if current_planet else 80, 20, 10))
