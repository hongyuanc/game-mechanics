extends CharacterBody2D

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var timer = $Timer

var remnant_scene = preload("res://scenes/remnant.tscn")
var current_remnant: Node = null

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var is_attacking = false
var is_flashing = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

var remnant_position: Vector2 = Vector2.ZERO
var remnant_active = false
var remnant_duration = 5.0  # How long the remnant lasts in seconds
var remnant_direction = 1

func _ready():
	animated_sprite_2d.animation_finished.connect(_on_animation_finished)
	if remnant_scene is PackedScene:
		print("remnant_scene is a valid PackedScene")
	else:
		print("Error: remnant_scene is not a valid PackedScene")

	animated_sprite_2d.animation_finished.connect(_on_animation_finished)

func _physics_process(delta):
	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	var direction = Input.get_axis("left", "right")
	
	if Input.is_action_just_pressed("flash"):
		if remnant_active:
			animated_sprite_2d.play("flash")
			flash_to_remnant()
		else:
			place_remnant()

	if not is_attacking or not is_on_floor():
		# Allow movement if not attacking or if in the air
		if direction:
			velocity.x = direction * SPEED
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		# Allow jumping when not attacking and on floor
		if not is_attacking and is_on_floor() and Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY

	if direction > 0:
		animated_sprite_2d.flip_h = false
		remnant_direction = 1
	elif direction < 0:
		animated_sprite_2d.flip_h = true
		remnant_direction = -1

	# Handle attack input
	if Input.is_action_just_pressed("attack") and not is_attacking:
		start_attack()
	elif not is_attacking and not is_flashing:
		update_animation(direction)

	# Apply movement
	move_and_slide()
	
func place_remnant():
	remnant_position = global_position
	remnant_active = true
	print("Remnant placed at ", remnant_position)
	# Create a visual indicator for the remnant
	if remnant_scene is PackedScene:
		current_remnant = remnant_scene.instantiate()
		current_remnant.global_position = remnant_position
		current_remnant.set_direction(remnant_direction)
		get_parent().add_child(current_remnant)
		
		remnant_position = global_position
		remnant_active = true
	else:
		print("Error: remnant_scene is not a PackedScene")

func flash_to_remnant():
	if remnant_active:
		global_position = remnant_position
		print("Flashed to ", remnant_position)
		if current_remnant.get_direction() == 1:
			animated_sprite_2d.flip_h = false
		else:
			animated_sprite_2d.flip_h = true
		remove_remnant()
		is_flashing = true
		animated_sprite_2d.play("flash")
		# Wait for the flash animation to finish
		await animated_sprite_2d.animation_finished
		is_flashing = false

func remove_remnant():
	remnant_active = false
	if current_remnant:
		current_remnant.queue_free()
		current_remnant = null
	print("Remnant removed")
	# Remove the visual indicator for the remnant here

func update_animation(direction):
	if is_flashing:
		return
	if not is_on_floor():
		animated_sprite_2d.play("jump")
	elif direction != 0:
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")

func start_attack():
	is_attacking = true
	animated_sprite_2d.play("attack")
	if is_on_floor():
		# Only stop horizontal movement if on the ground
		velocity.x = 0
	timer.start(0.5)  # Adjust based on attack animation length

func _on_animation_finished():
	if animated_sprite_2d.animation == "attack":
		end_attack()

func _on_timer_timeout():
	if is_attacking:
		end_attack()

func end_attack():
	is_attacking = false
	timer.stop()
	update_animation(Input.get_axis("left", "right"))
