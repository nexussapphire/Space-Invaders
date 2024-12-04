extends CharacterBody2D

const SPEED = 250
const spawn = Vector2(640,650)

signal tank_hit

@export var missile_scene : PackedScene
var control = false

#Init
func _ready() -> void:
	global_position = spawn
	

#input
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and control:
		spawn_missile()
		
#resets y position, more stable than on physics.
func _process(delta: float) -> void:
	global_position.y = spawn.y

#physx
func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	if control:
		direction = Input.get_axis("Move left", "Move right")
	
	position = position.clamp(Vector2(392,500),Vector2(892,700))
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = 0
		
	move_and_slide()
	if get_slide_collision_count() > 0:
		$CollisionShape2D.set_deferred("disabled", true)
		tank_hit.emit()
		$AnimatedSprite2D.play("explosion")
		$AudioStreamPlayer2D.play()
	

func spawn_missile():
	if $missiles.get_child_count() == 0:
		var init = missile_scene.instantiate()
		$missiles.add_child(init)
		init.global_position = position
		


func _on_main_game_start() -> void:
	control = true
	global_position = spawn
	$AnimatedSprite2D.set_animation("default")
	


func _on_main_game_soft_reset() -> void:
	control = false
	$CollisionShape2D.set_deferred("disabled", false)


func _on_main_game_resume() -> void:
	control = true
