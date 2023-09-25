extends Node2D
class_name StarField

var particles := []

@export var moving_speed: float = 40
@export var particle_count: int = 20
@export var particle_colors: Array = [
	Consts.COLOR_GREY,
	Consts.COLOR_RED#,
	#Consts.COLOR_WHITE
]

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(particle_count):
		add_particle(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var size := get_viewport().get_visible_rect().size
	for particle in particles:
		particle.position.x += (moving_speed * particle.velocity_offset * 10) * delta
		if (moving_speed > 0 and particle.position.x > size.x + moving_speed) or (moving_speed < 0 and particle.position.x < moving_speed):
			particles.erase(particle)
			add_particle(true)
	queue_redraw()


func _draw():
	for particle in particles:
		draw_line(
			particle.position,
			particle.position + Vector2.LEFT * moving_speed,
			particle.color, 1)


func add_particle(on_edge: bool = false):
	var size := get_viewport().get_visible_rect().size
	var x_pos: int
	if on_edge:
		x_pos = (signi(-moving_speed) + 1 / 2) * size.x + -signi(moving_speed) * 10
	else:
		x_pos = randi_range(0, size.x)
	var particle := {
		"position": Vector2(
			x_pos,
			randi_range(0, size.y)
		),
		"velocity_offset": randf_range(0.7, 1.3),
		"color": particle_colors.pick_random()
	}
	
	particles.append(particle)
