extends Node2D
class_name BlocksElement

var ShipBlockPre := preload("res://game_objects/ship_block.tscn")

var element_config := {}
var groups := []

var block_holder: Node2D

var velocity: Vector2
var size: Rect2i

signal redraw_blocks

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


func update_element_config() -> void:
	var position_id_list := []
	for block in block_holder.get_children():
		if not element_config.has(block.position_id):
			block_holder.remove_child(block)
			block.queue_free()
		else:
			position_id_list.append(block.position_id)

	for position_id in element_config:
		if not position_id_list.has(position_id):
			add_element_block(position_id, element_config[position_id])
	
	redraw_blocks.emit()

	var main_block: Dictionary = element_config.get(Vector2.ZERO)
	groups = find_groups([{
		"id": 0,
		"items": [Vector2.ZERO],
		"type": main_block.type,
		"complete": false,
		"joined_to": []
	}])
	print("Groups! ")
	for group in groups:
		print("  Group: ", group)
	
	for block in block_holder.get_children():
		var position_id = block.position_id
		if groups.filter(func (group): return group["items"].has(position_id)).is_empty():
			separate_blocks([block])
	
	var min_position: Vector2 = Vector2.ZERO
	var max_position: Vector2 = Vector2.ZERO
	for position_id in element_config:
		if position_id < min_position:
			min_position = position_id
		if position_id > max_position:
			max_position = position_id
	size = Rect2(min_position * ShipBlock.BLOCK_SIZE, Vector2(abs(max_position.x - min_position.x) + 1, abs(max_position.y - min_position.y) + 1) * ShipBlock.BLOCK_SIZE)


func add_element_block(position_id: Vector2, block_config: Dictionary) -> ShipBlock:
	var block: ShipBlock = ShipBlockPre.instantiate()
	block.type = block_config["type"]
	redraw_blocks.connect(block.on_redraw)
	
	block.position_id = position_id
	block.position.x = position_id.x * ShipBlock.BLOCK_SIZE
	block.position.y = position_id.y * ShipBlock.BLOCK_SIZE
	block_holder.call_deferred("add_child", block)
	return block


func get_element_blocks(from_position: Vector2 = Vector2.ZERO) -> Array:
	var blocks := []
	for position_id in element_config:
		blocks.append({
			"position": position_id - from_position,
			"config": element_config[position_id]
		})
	
	return blocks


func get_weight() -> int:
	return element_config.keys().size()


func find_groups(temp_groups: Array):
	for group in temp_groups:
		if group["complete"]:
			continue

		var new_members := []
		var group_complete := true
		for position_id in group["items"]:
			for direction in Consts.NEIGHBOR_DIRECTIONS:
				var new_position_id: Vector2 = position_id + direction
				#print("new position: ", new_position_id, element_config.has(new_position_id))
				if element_config.has(new_position_id):
					var neighbor: Dictionary = element_config.get(new_position_id)
					if neighbor.type == group.type:
						if not group["items"].has(new_position_id):
							new_members.append(new_position_id)
							group_complete = false
					else:
						var groups_with_item := temp_groups.filter(func (group): return group["items"].has(new_position_id))
						if groups_with_item.size() == 0:
							temp_groups.append({
								"id": temp_groups.reduce(func(accum, group): return max(accum, group["id"]), 0) + 1,
								"items": [new_position_id],
								"type": neighbor.type,
								"complete": false,
								"joined_to": [group["id"]]
							})
						else:
							for other_group in groups_with_item:
								if not other_group["joined_to"].has(group["id"]):
									other_group["joined_to"].append(group["id"])
		group["items"].append_array(new_members)
		if group_complete:
			group["complete"] = true
	
	if temp_groups.filter(func (group): return not group["complete"]).size() > 0:
		temp_groups = find_groups(temp_groups)
	
	for group in temp_groups:
		for other_group in temp_groups:
			if group["id"] == other_group["id"]:
				continue
				
			var equal := true
			for item in group["items"]:
				if not other_group["items"].has(item):
					equal = false
			for item in other_group["items"]:
				if not group["items"].has(item):
					equal = false
			
			if equal:
				temp_groups.erase(other_group)
	
	for group in temp_groups:
		for id in group["joined_to"]:
			if temp_groups.filter(func(group): return group["id"] == id).is_empty():
				group["joined_to"].erase(id)
		
	for group in temp_groups:
		for joined_to_id in group["joined_to"]:
			var other_groups = temp_groups.filter(func(group): return group["id"] == joined_to_id)
			if other_groups.is_empty():
				continue
			var other_group: Dictionary = other_groups[0]
			if not other_group["joined_to"].has(joined_to_id) and other_group["id"] != joined_to_id:
				other_group["joined_to"].append(joined_to_id)
	
	return temp_groups


func get_group_id(group_id: int) -> Variant:
	for group in groups:
		if group["id"] == group_id:
			return group
	return null


func get_group_position_id(position_id: Vector2) -> Variant:
	for group in groups:
		if group["items"].has(position_id):
			return group
	return null


func group_connected(group: Dictionary, checked_groups: Array = []) -> bool:
	var base_group_id: int = get_group_position_id(Vector2.ZERO)["id"]
	for id in group["joined_to"]:
		var joined_group = get_group_id(id)
		if not joined_group:
			continue
		
		if checked_groups.has(id):
			continue
		else:
			checked_groups.append(id)
			
		if group_connected(joined_group, checked_groups):
			return true
		
		if id == base_group_id:
			return true
		
	return false


func separate_blocks(blocks: Array) -> void:
	var chaff_blocks: ChaffBlocks = load("res://game_objects/ChaffBlocks.tscn").instantiate()
	get_parent().add_child(chaff_blocks)
	chaff_blocks.from_blocks(blocks)
	chaff_blocks.position = blocks[0].global_position
	chaff_blocks.velocity = (blocks[0].global_position - global_position).normalized()
	for block in blocks:
		block_holder.remove_child(block)
		element_config.erase(block.position_id)
	

func separate_group(group: Dictionary) -> void:
	groups.erase(group)
	var blocks := get_group_blocks(group)
	if blocks.size() == 0:
		print("Couldn't find any blocks")
		return
	separate_blocks(blocks)


func get_group_blocks(group: Dictionary) -> Array:
	return block_holder.get_children().filter(func(block): return group["items"].has(block.position_id))
