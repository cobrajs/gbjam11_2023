extends Node2D


const selector_spots := [
	Vector2(9, 25),
	Vector2(9, 41),
	Vector2(9, 57),
	Vector2(9, 73),
	Vector2(9, 89),
	Vector2(9, 105),
	Vector2(9, 121),
]

var available_lines := [true, true, true, true, true, true, true]

@onready var lines := [
	$Line1,
	$Line2,
	$Line3,
	$Line4,
	$Line5,
	$Line6,
	$Line7
]

@onready var a_button := $Controls/AButton
@onready var a_button_action := $Controls/AButtonAction

@onready var selector := $SelectorHolder

@onready var bank := $Bank

var selected := 0

func _ready():
	update_items_list()
	update_bank()
	update_item_colors()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if Input.is_action_just_pressed("game_up"):
		select_item(-1)

	if Input.is_action_just_pressed("game_down"):
		select_item(1)
	
	if Input.is_action_just_pressed("game_a"):
		sell_item(null)

	if Input.is_action_just_pressed("game_b"):
		get_tree().change_scene_to_file("res://scenes/planet_picker_scene.tscn")


func select_item(direction: int) -> void:
	var new_selection = wrapi(selected + direction, 0, available_lines.filter(func(line): return line).size())
	if new_selection != selected:
		select(new_selection)


func select(new_selection):
	selected = new_selection
	var tween = get_tree().create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(selector, "position", selector_spots[selected], 0.4)
	update_item_colors()


func update_item_colors() -> void:
	for i in range(7):
		var line: Label = lines[i]
		line.remove_theme_color_override('font_color')
		line.add_theme_color_override('font_color', Consts.COLOR_WHITE if selected == i else Consts.COLOR_GREY)


func sell_item(item) -> void:
	if not item:
		item = GameState.player_config["hold"]["items"][selected]
	GameState.player_config["cash"] += planet_value(item)
	GameState.player_config["hold"]["items"].erase(item)
	update_items_list()
	update_bank()


func update_bank() -> void:
	var cash = GameState.player_config["cash"]
	if not cash:
		cash = 0
	bank.text = "$" + str(cash)


func update_items_list() -> void:
	var available_items = GameState.player_config["hold"]["items"]
	var current_line = 0
	if available_items.size() == 0:
		selector.visible = false
		a_button.visible = false
		a_button_action.visible = false
	else:
		selector.visible = true
		a_button.visible = true
		a_button_action.visible = true
	for item in available_items:
		lines[current_line].text = str(item["count"]) + " " + type_to_name(item["type"], item["count"]) + ": $" + str(planet_value(item))
		available_lines[current_line] = true
		current_line += 1
	
	if selected >= current_line:
		select(0)
	
	if current_line <= 7:
		for i in range(current_line, 7):
			lines[i].visible = false
			available_lines[i] = false


func type_to_name(item_type: int, item_count: int) -> String:
	match item_type:
		Consts.BLOCKS_BADDIE:
			return 'Baddie' + 's' if item_count != 1 else ''
		Consts.BLOCKS_MINERAL_CRYSTAL:
			return 'Crystal' + 's' if item_count != 1 else ''
		Consts.BLOCKS_MINERAL_EMERALD:
			return 'Emerald' + 's' if item_count != 1 else ''
		Consts.BLOCKS_MINERAL_IRON:
			return 'Iron' + 's' if item_count != 1 else ''
	
	return 'Unit' + 's' if item_count != 1 else ''


func planet_value(item: Dictionary) -> int:
	var planet_value_modifiers: Dictionary = GameState.player_config["planet"]["values"]
	if planet_value_modifiers[item["type"]]:
		return planet_value_modifiers[item["type"]] * item["value"] * item["count"]
	return item["value"] * item["count"]
