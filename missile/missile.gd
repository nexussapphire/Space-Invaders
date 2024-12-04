extends RigidBody2D

const speed = 600
const face_up = deg_to_rad(90)

var invader_missile = false

# Init
func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 1
	

# calls collision function if goes past play area.
func _process(delta: float) -> void:
	if global_position.y < 50:
		_on_body_entered(null)

#physx
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	state.linear_velocity = Vector2.from_angle(global_rotation - face_up) * speed


## Sets colision for parent scene if it is an invader(enemy)
func is_invader():
		#mask values
		set_collision_mask_value(1,true)
		set_collision_mask_value(2,false)
		set_collision_mask_value(3,false)
		set_collision_mask_value(4,true)
		#layer values
		set_collision_layer_value(3,true)
		set_collision_layer_value(4,false)
		$AudioStreamPlayer2D.set_pitch_scale(randf_range(.7,1.3))
		if randi() % 2:
			$AnimatedSprite2D.play("EnemySpear")
		else:
			$AnimatedSprite2D.play("EnemyZigZag")		
		


func _on_body_entered(body: Node) -> void:
	$CollisionShape2D.set_deferred("disabled",true)
	linear_velocity = Vector2.ZERO
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
	
	
func free_all():
	queue_free()
