extends BlocksElement
class_name FallingBlock

signal debris_away

func _ready():
	block_holder = self
	
	element_config = {
		Vector2(0, 0): {
			"type": random_mineral()
		}
	}
	
	if randi() % 2 == 0:
		element_config[Vector2(-1, 0)] = {
			"type": random_mineral()
		}
	else:
		element_config[Vector2(0, -1)] = {
			"type": random_mineral()
		}
	
	update_element_config()
	
	velocity = Vector2.RIGHT


func _process(delta):
	var viewport_size := get_viewport().get_visible_rect().size

	position += velocity * 50 * delta
	
	if position.x > viewport_size.x + size.size.x:
		debris_away.emit()
		call_deferred("queue_free")
	

func random_mineral() -> int:
	if GameState.player_config["planet"].has("get_mineral"):
		return GameState.player_config["planet"]["get_mineral"].call()
	if randf() > 0.8:
		return Consts.BLOCKS_BADDIE
	if randf() > 0.95:
		return [Consts.BLOCKS_HULL, Consts.BLOCKS_ENGINE, Consts.BLOCKS_GUN].pick_random()
	return [Consts.BLOCKS_MINERAL_CRYSTAL, Consts.BLOCKS_MINERAL_EMERALD, Consts.BLOCKS_MINERAL_IRON].pick_random()
