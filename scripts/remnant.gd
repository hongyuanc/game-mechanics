extends Sprite2D

@onready var sprite = $AnimatedSprite2D  # Make sure this matches the name of your sprite node in the Remnant scene
var direction: int = 1  # 1 for right, -1 for left

func _ready():
	if not sprite:
		push_error("AnimatedSprite2D node not found in Remnant scene")

func set_direction(new_direction: int):
	direction = new_direction
	update_sprite()

func get_direction() -> int:
	return direction

func update_sprite():
	if sprite:
		sprite.flip_h = (direction < 0)

func _physics_process(delta):
	update_sprite()
