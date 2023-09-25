extends Area2D
class_name ShipBlock

const BLOCK_SIZE := 10

@export var type := 0

@export var position_id: Vector2

@export var thrusting := {}

@export var rotating := false

@onready var collider := $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var over_rendering: Node2D = $OverRendering
@onready var emitter: CPUParticles2D = $Particles

var anim_offset := 0

const TYPE_TO_FRAME := {
	Consts.BLOCKS_MAIN: 0,
	Consts.BLOCKS_ENGINE: 1,
	Consts.BLOCKS_GUN: 2,
	Consts.BLOCKS_HULL: 3,
	Consts.BLOCKS_MINERAL_CRYSTAL: [10, 11, 12],
	Consts.BLOCKS_MINERAL_EMERALD: [20, 21, 22],
	Consts.BLOCKS_MINERAL_IRON: [30, 31, 32],
	Consts.BLOCKS_BADDIE: 50
}

const TYPE_TO_PARTICLE := {
	Consts.BLOCKS_MAIN: 0,
	Consts.BLOCKS_ENGINE: 0,
	Consts.BLOCKS_GUN: 0,
	Consts.BLOCKS_HULL: 0,
	Consts.BLOCKS_MINERAL_CRYSTAL: 1,
	Consts.BLOCKS_MINERAL_EMERALD: 2,
	Consts.BLOCKS_MINERAL_IRON: 3,
	Consts.BLOCKS_BADDIE: 3
}

func _ready():
	var circleCollider: CircleShape2D = collider.shape
	circleCollider.radius = (BLOCK_SIZE / 2) - 2
	if type:
		var frame = TYPE_TO_FRAME.get(type, 99)
		if frame is Array:
			frame = frame.pick_random()
		sprite.frame = frame
		
		var particle = TYPE_TO_PARTICLE.get(type, 0)
		
		emitter.texture.region.position.x = 40 + (particle % 2) * 5
		emitter.texture.region.position.y = floor(particle / 2) * 5

	over_rendering.connect("draw", on_over_rendering_draw)


func _process(_delta):
	pass


func on_over_rendering_draw():
	if thrusting.size() > 0:
		for direction in thrusting:
			over_rendering.draw_set_transform(Vector2.ZERO, (direction).angle())
			over_rendering.draw_texture_rect_region(
				sprite.texture, 
				Rect2(-BLOCK_SIZE / 2, -BLOCK_SIZE / 2, BLOCK_SIZE, BLOCK_SIZE),
				Rect2((5 + (floor(anim_offset / 2) % 4)) * 10, 0, BLOCK_SIZE, BLOCK_SIZE)
			)
	over_rendering.draw_set_transform(Vector2.ZERO)


#func _draw():
	#over_rendering.draw_rect(Rect2(-5, -5, 10, 10), Consts.COLOR_WHITE)

"""
func _draw():
	if type < 10:
		draw_rect(Rect2(-BLOCK_SIZE / 2 + 1, -BLOCK_SIZE / 2 + 1, BLOCK_SIZE  -2, BLOCK_SIZE - 2), Consts.COLOR_WHITE)
	if type == Consts.BLOCKS_ENGINE:
		if thrusting.size() > 0:
			for direction in thrusting:
				draw_line(Vector2(0, 0), direction * -6, Consts.COLOR_RED, 2)
		draw_circle(Vector2(0, 0), 2, Consts.COLOR_BLACK)
	elif type == Consts.BLOCKS_SHIELD:
		draw_circle(Vector2.ZERO, 2, Consts.COLOR_RED)
	elif type == Consts.BLOCKS_GUN:
		draw_line(Vector2.ZERO, Vector2.RIGHT * 3, Consts.COLOR_BLACK, 2)
	elif type == Consts.BLOCKS_MAIN:
		draw_circle(Vector2(0, 0), BLOCK_SIZE / 2 - 1, Consts.COLOR_GREY)
	if type == Consts.BLOCKS_BADDIE:
		draw_circle(Vector2.ZERO, BLOCK_SIZE / 2 - 1, Consts.COLOR_GREY)
		draw_circle(Vector2.ZERO, BLOCK_SIZE / 2 - 2, Consts.COLOR_RED)
	if type == Consts.BLOCKS_MINERAL_EMERALD:
		draw_circle(Vector2.ZERO, BLOCK_SIZE / 2 - 1, Consts.COLOR_GREY)
	if type == Consts.BLOCKS_MINERAL_CRYSTAL:
		draw_circle(Vector2.ZERO, BLOCK_SIZE / 2 - 1, Consts.COLOR_WHITE)
	if type == Consts.BLOCKS_MINERAL_IRON:
		draw_circle(Vector2.ZERO, BLOCK_SIZE / 2 - 1, Consts.COLOR_RED)
	
	if not rotating:
		var parent := find_parent("Ship")
		if parent and parent.has_method("get_neighbors") and position_id != null:
			var neighbors: Dictionary = parent.get_neighbors(position_id)
			for position in neighbors:
				draw_line(position * (BLOCK_SIZE / 2 - 1), position * (BLOCK_SIZE / 2 + 1), Consts.COLOR_GREY, 3)
"""


func on_redraw() -> void:
	queue_redraw()


func on_thrust(direction: Vector2) -> void:
	thrusting[direction] = true
	queue_redraw()
	over_rendering.queue_redraw()


func on_end_thrust(direction: Vector2) -> void:
	if thrusting.has(direction):
		thrusting.erase(direction)
		queue_redraw()
		over_rendering.queue_redraw()


func on_rotating(value: bool) -> void:
	rotating = value
	if value:
		disable()
	else:
		enable()
	queue_redraw()
	over_rendering.queue_redraw()


func disable() -> void:
	set_deferred("monitorable", false)
	set_deferred("monitoring", false)


func enable() -> void:
	set_deferred("monitorable", true)
	set_deferred("monitoring", true)


func delete() -> void:
	sprite.visible = false
	emitter.emitting = true
	await get_tree().create_timer(0.5).timeout
	queue_free()


func _on_timer_timeout():
	anim_offset += 1
	if anim_offset > 1048:
		anim_offset = 0
