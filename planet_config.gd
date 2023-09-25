extends Node

var planets: Array = [
	{
		"id": 0,
		"name": "Planet 1",
		"position": Vector2(30, 30),
		"connections": [1, 2],
		"get_mineral": func():
			if randf() > 0.2:
				return Consts.BLOCKS_MINERAL_IRON
			if randf() > 0.9:
				return Consts.BLOCKS_BADDIE
			return [Consts.BLOCKS_MINERAL_CRYSTAL, Consts.BLOCKS_MINERAL_EMERALD].pick_random(),
		"get_debris_count": func():
			return randi_range(6, 10),
		"values": {
			Consts.BLOCKS_MINERAL_CRYSTAL: 1.2,
			Consts.BLOCKS_MINERAL_EMERALD: 1,
			Consts.BLOCKS_MINERAL_IRON: 0.5,
			Consts.BLOCKS_BADDIE: 1
		},
		"description1": "Metal planet",
		"description2": "Watch the baddies",
	},
	{
		"id": 1,
		"name": "Planet 2",
		"position": Vector2(80, 45),
		"connections": [0, 2, 3, 4],
		"get_mineral": func():
			return Consts.BLOCKS_MINERAL_IRON,
		"get_debris_count": func():
			return randi_range(8, 12),
		"values": {
			Consts.BLOCKS_MINERAL_CRYSTAL: 1.2,
			Consts.BLOCKS_MINERAL_EMERALD: 0.8,
			Consts.BLOCKS_MINERAL_IRON: 1.2,
			Consts.BLOCKS_BADDIE: 1.5
		},
		"description1": "Even planet",
		"description2": "All the things",
	},
	{
		"id": 2,
		"name": "Planet 3",
		"position": Vector2(40, 90),
		"connections": [0, 1],
		"get_mineral": func():
			if randf() > 0.4:
				return [Consts.BLOCKS_HULL, Consts.BLOCKS_ENGINE, Consts.BLOCKS_GUN].pick_random()
			if randf() > 0.9:
				return Consts.BLOCKS_BADDIE
			return [Consts.BLOCKS_MINERAL_CRYSTAL, Consts.BLOCKS_MINERAL_IRON, Consts.BLOCKS_MINERAL_EMERALD].pick_random(),
		"get_debris_count": func():
			return randi_range(4, 6),
		"values": {
			Consts.BLOCKS_MINERAL_CRYSTAL: 1.5,
			Consts.BLOCKS_MINERAL_EMERALD: 2.5,
			Consts.BLOCKS_MINERAL_IRON: 1.2,
			Consts.BLOCKS_BADDIE: 1
		},
		"description1": "Graveyard planet",
		"description2": "Lots of parts",
	},
	{
		"id": 3,
		"name": "Planet 4",
		"position": Vector2(130, 35),
		"connections": [1, 4],
		"get_mineral": func():
			if randf() > 0.3:
				return Consts.BLOCKS_BADDIE
			if randf() > 0.9:
				return [Consts.BLOCKS_HULL, Consts.BLOCKS_ENGINE, Consts.BLOCKS_GUN].pick_random()
			return [Consts.BLOCKS_MINERAL_CRYSTAL, Consts.BLOCKS_MINERAL_IRON, Consts.BLOCKS_MINERAL_EMERALD].pick_random(),
		"get_debris_count": func():
			return randi_range(5, 9),
		"values": {
			Consts.BLOCKS_MINERAL_CRYSTAL: 2.5,
			Consts.BLOCKS_MINERAL_EMERALD: 1.5,
			Consts.BLOCKS_MINERAL_IRON: 2,
			Consts.BLOCKS_BADDIE: 0.2
		},
		"description1": "World of baddies",
		"description2": "Low on mineral",
	},
	{
		"id": 4,
		"name": "Planet 5",
		"position": Vector2(135, 85),
		"connections": [1, 3],
		"get_mineral": func():
			if randf() > 0.2:
				return Consts.BLOCKS_MINERAL_EMERALD
			if randf() > 0.95:
				return [Consts.BLOCKS_HULL, Consts.BLOCKS_ENGINE, Consts.BLOCKS_GUN].pick_random()
			return [Consts.BLOCKS_MINERAL_CRYSTAL, Consts.BLOCKS_MINERAL_IRON].pick_random(),
		"get_debris_count": func():
			return randi_range(6, 10),
		"values": {
			Consts.BLOCKS_MINERAL_CRYSTAL: 1.2,
			Consts.BLOCKS_MINERAL_EMERALD: 0.5,
			Consts.BLOCKS_MINERAL_IRON: 1.4,
			Consts.BLOCKS_BADDIE: 2
		},
		"description1": "Emerald Planet",
		"description2": "No baddies",
	}
]

func get_planet(planet_id: int) -> Variant:
	for planet in planets:
		if planet["id"] == planet_id:
			return planet
	return null
