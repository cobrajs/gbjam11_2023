extends Node

var player_config := {
	"ship_config": {
		Vector2(0, 0): {
			"type": Consts.BLOCKS_MAIN
		},
		Vector2(1, 0): {
			"type": Consts.BLOCKS_HULL
		},
		Vector2(0, -1): {
			"type": Consts.BLOCKS_ENGINE
		},
		Vector2(0, 1): {
			"type": Consts.BLOCKS_ENGINE
		},
	},
	"hold": {
		"size": 7,
		"items": [
			{
				"type": Consts.BLOCKS_MINERAL_IRON,
				"count": 5,
				"value": 10
			},
			{
				"type": Consts.BLOCKS_MINERAL_IRON,
				"count": 5,
				"value": 10
			}
		]
	},
	"planet": PlanetConfig.get_planet(0),
	"cash": 100
}
