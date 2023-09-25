extends BlocksElement
class_name ChaffBlocks

# Called when the node enters the scene tree for the first time.
func _ready():
	block_holder = self


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var screen_size := get_viewport().get_visible_rect().size

	position += velocity * 50 * delta
	
	if position.x > screen_size.x:
		position.x -= screen_size.x


func from_blocks(blocks: Array) -> void:
	if blocks.size() == 0:
		return

	var base_position_id: Vector2 = blocks[0].position_id
	for block in blocks:
		var position_id: Vector2 = block.position_id - base_position_id
		element_config[position_id] = {
			"type": block.type
		}
		add_child(block)
	
	update_element_config()
