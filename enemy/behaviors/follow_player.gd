extends Node

@export var speed: float = 1.0

var sprite: AnimatedSprite2D
var enemy: Enemy

func _ready():
	enemy = get_parent()
	sprite = enemy.get_node("AnimatedSprite2D")

func _physics_process(delta: float) -> void:
	# Ignorar Game Over
	if GameManager.is_game_over: return
	
	# Calcular Direção
	var player_position = GameManager.player_position
	var difference = player_position - enemy.position
	var input_vector = difference.normalized()
	
	# Movimento
	enemy.velocity = input_vector * speed * 100.0
	enemy.move_and_slide()
	
	# Inverter Sprite
	if input_vector.x > 0:
		# Desmarcar flip_h do Sprite2D
		sprite.flip_h = false
	elif input_vector.x < 0:
		# Marcar flip_h do Sprite2D
		sprite.flip_h = true