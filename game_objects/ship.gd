extends BlocksElement
class_name Ship

const MAX_SPEED := 100
const ACCELERATION_RATE := 4
const DECELERATION_RATE := 1

var ship_rotation := 0
var is_rotating := false
var can_rotate := true

var thrust_speed := 1
var weight := 1

signal thrust(direction)
signal thrust_end(direction)
signal shoot
signal rotating(status)
signal change_can_rotate(value)
signal collected_debris

@export var can_control := true:
	set = set_can_control

@onready var can_rotate_sensor := $CanRotateSensor
@onready var sensor_shape := $CanRotateSensor/CollisionShape2D
@onready var animation_player := $AnimationPlayer

func reset_ship() -> void:
	for child in block_holder.get_children():
		block_holder.remove_child(child)
		child.queue_free()
	
	element_config = GameState.player_config["ship_config"]
	ship_rotation = 0
	
	update_element_config()

func _ready():
	block_holder = $ShipBlockHolder
	
	element_config = GameState.player_config["ship_config"]
	
	velocity = Vector2(0, 0)

	update_element_config()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var acceleration = Vector2.ZERO
	if can_control:
		if Input.is_action_pressed("game_left"):
			thrust.emit(Vector2.LEFT)
			acceleration += Vector2.LEFT
		else:
			thrust_end.emit(Vector2.LEFT)

		if Input.is_action_pressed("game_right"):
			thrust.emit(Vector2.RIGHT)
			acceleration += Vector2.RIGHT
		else:
			thrust_end.emit(Vector2.RIGHT)

		if Input.is_action_pressed("game_up"):
			thrust.emit(Vector2.UP)
			acceleration += Vector2.UP
		else:
			thrust_end.emit(Vector2.UP)

		if Input.is_action_pressed("game_down"):
			thrust.emit(Vector2.DOWN)
			acceleration += Vector2.DOWN
		else:
			thrust_end.emit(Vector2.DOWN)
		
		if Input.is_action_just_pressed("game_a"):
			rotate_ship(-1)
		
		if Input.is_action_just_pressed("game_b"):
			rotate_ship(1)
		
		if Input.is_action_just_pressed("game_start"):
			reset_ship()
	
	var weight_log = log(weight + 1) / 2
	
	velocity += acceleration.normalized() * ACCELERATION_RATE * (thrust_speed / weight_log)
	
	velocity = velocity.limit_length(MAX_SPEED)
	
	velocity -= velocity.normalized() * DECELERATION_RATE * weight_log
	
	if velocity.length() < 1:
		velocity = Vector2.ZERO
	
	position += velocity * delta
	position.x = position.x


func add_element_block(position_id: Vector2, block_config: Dictionary) -> ShipBlock:
	var block: ShipBlock = super(position_id, block_config)
	if block_config["type"] == Consts.BLOCKS_ENGINE:
		thrust.connect(block.on_thrust)
		thrust_end.connect(block.on_end_thrust)
	
	rotating.connect(block.on_rotating)
	block.connect("area_entered", Callable(on_block_collide).bind(block, position_id))
	
	if ship_rotation > 0:
		block.position = block.position.rotated(ship_rotation * PI / 2).round()
	
	print("New block: ", block, block.position, block_config.get("old_position", "none"))
	if block_config.has("old_position"):
		block.disable()
		var new_position = block.position
		block.position = block_config["old_position"] - position
		var tween = get_tree().create_tween()
		tween.tween_property(block, "position", new_position, 0.1)
		await tween.finished
		block.enable()
		if not element_config.has(block.position_id):
			block.delete()
	
	block.connect("input_event", Callable(on_block_input_event).bind(position_id))
	
	block.collision_mask = 2
	block.collision_layer = 1
	
	return block


func update_element_config() -> void:
	super()
	var max_position := Vector2.ZERO
	for position_id in element_config.keys():
		if position_id.length() > max_position.length():
			max_position = position_id
	
	sensor_shape.shape.radius = max_position.length() * ShipBlock.BLOCK_SIZE

	weight = element_config.size()
	thrust_speed = get_ship_speed()
	
	var groups_to_remove := groups.filter(func(group): return can_collect(group["type"]) and group["items"].size() >= 4)
	if groups_to_remove.size() == 0:
		return
	
	for group in groups_to_remove:
		var group_value = group["items"].size()
		if group_value == 5:
			group_value = 6
		if group_value == 6:
			group_value = 8
		GameState.player_config["hold"]["items"].append({
			"type": group["type"],
			"value": 10,
			"count": group_value
		})
		clear_group(group)
		
	for group in groups.filter(func(group): return not group_connected(group)):
		print("Separated: ", group)
		separate_group(group)
		
	update_element_config()


func clear_group(group: Dictionary) -> void:
	for position_id in group["items"]:
		element_config.erase(position_id)
	var blocks := block_holder.get_children().filter(func(block): return group["items"].has(block.position_id))
	for group_id in group["joined_to"]:
		var other_group = get_group_id(group_id)
		if not other_group:
			continue
		other_group["joined_to"].erase(group["id"])
	groups.erase(group)
	for block in blocks:
		block_holder.remove_child(block)
		block.disable()
		get_parent().add_child(block)
		block.delete()


func check_baddies() -> void:
	for group in groups:
		if group["type"] != Consts.BLOCKS_BADDIE:
			continue
		
		var baddie_size: int = group["items"].size()
		if baddie_size == 2:
			clear_group(group)
		elif baddie_size == 1 or baddie_size == 3:
			for group_id in group["joined_to"]:
				var other_group = get_group_id(group_id)
				if other_group:
					clear_group(other_group)
			clear_group(group)


func set_can_control(new_value: bool) -> void:
	can_control = new_value
	if not animation_player:
		return
	
	if new_value:
		animation_player.stop()
	else:
		animation_player.play("hover")


func can_collect(block_type: int) -> bool:
	return block_type == Consts.BLOCKS_MINERAL_CRYSTAL or \
		block_type == Consts.BLOCKS_MINERAL_EMERALD or \
		block_type == Consts.BLOCKS_MINERAL_IRON or \
		block_type == Consts.BLOCKS_BADDIE


func get_ship_speed() -> float:
	var speed := 0.0
	for block_config in element_config.values():
		if block_config["type"] == Consts.BLOCKS_ENGINE:
			speed += 1.0
	return speed


const ROTATION_SPEED := 20.0
func rotate_ship(direction: int) -> void:
	if is_rotating or not can_rotate:
		return
	is_rotating = true
	rotating.emit(is_rotating)
	ship_rotation = wrap(ship_rotation + direction, 0, 4)
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	var ship_blocks := block_holder.get_children()
	var rotation_speed: float = clamp(ROTATION_SPEED * weight / 2, ROTATION_SPEED * 2, ROTATION_SPEED * 5) / 1000
	for block in ship_blocks:
		var new_position = block.position.rotated(direction * PI / 2).round()
		tween.tween_property(block, "position", new_position, rotation_speed).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	
	await tween.finished
	is_rotating = false
	rotating.emit(is_rotating)
	redraw_blocks.emit()


func get_neighbors(position: Vector2) -> Dictionary:
	var neighbors := {}
	for direction in Consts.NEIGHBOR_DIRECTIONS:
		if element_config.has(position + direction):
			neighbors[direction.rotated(ship_rotation * PI / 2).round()] = true
	return neighbors


func on_block_collide(body: Node2D, block: Node2D, element_position: Vector2):
	if not can_control:
		return
	if not body.get_parent() is FallingBlock:
		return
	var blocks: FallingBlock = body.get_parent()
	var offset: Vector2 = (body.global_position - block.global_position).normalized()
	#.round().rotated(ship_rotation * PI / 2).round()
	if abs(offset.x) > abs(offset.y):
		offset.x = sign(offset.x)
		offset.y = 0
	else:
		offset.y = sign(offset.y)
		offset.x = 0
	#print("Velocities: ", blocks.velocity, velocity)
	#print("Offset: ", offset, "Rotated: ", offset.rotated(ship_rotation * PI / 2), "Raw: ", (body.global_position - block.global_position))
	#offset = offset.rotated(ship_rotation * PI / 2)
	offset = (-blocks.velocity).rotated(-ship_rotation * PI / 2).normalized().round()
	#print("Offset: ", (-blocks.velocity), "Rotated: ", offset)
	var start_position := Vector2(element_position) + offset
	#print("start position: ", start_position, body.position_id)
	for block_configs in blocks.get_element_blocks(body.position_id):
		var new_position: Vector2 = start_position + block_configs.position.rotated(-ship_rotation * PI / 2).round()
		#print("New position: ", new_position, body.global_position, position)
		if element_config.has(new_position):
			#print("We've already got one! ", new_position, start_position)
			pass
		else:
			element_config[new_position] = block_configs.config.duplicate()
			element_config[new_position]["old_position"] = body.global_position + block_configs.position * ShipBlock.BLOCK_SIZE
	#print("New config: ", element_config.keys())
	blocks.queue_free()
	update_element_config()
	
	collected_debris.emit()

func on_block_input_event(viewport: Node, event: InputEvent, shape_idx: int, block_position: Vector2) -> void:
	return
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == 1:
			print("You clicked me! Event: ", event, "Block position: ", block_position)
			var temp_group = get_group_position_id(block_position)
			if not temp_group:
				return
			print("  ...this group: ", temp_group)
			for position_id in temp_group["items"]:
				element_config.erase(position_id)
			var blocks := block_holder.get_children().filter(func(block): return temp_group["items"].has(block.position_id))
			print("  ...these blocks: ", blocks)
			groups.erase(temp_group)
			for block in blocks:
				var old_position: Vector2 = block.global_position
				block_holder.remove_child(block)
				block.disable()
				get_parent().add_child(block)
				block.position = old_position
				block.delete()
			
			for group in groups.filter(func(group): return not group_connected(group)):
				print("Separated: ", group)
				separate_group(group)
			
			update_element_config()


func _on_can_rotate_sensor_area_entered(_area):
	can_rotate = false
	change_can_rotate.emit(false)


func _on_can_rotate_sensor_area_exited(_area):
	can_rotate = true
	change_can_rotate.emit(true)
