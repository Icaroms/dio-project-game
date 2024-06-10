class_name Player
extends CharacterBody2D

@export_category("Movement")
@export var speed: float = 3
@export_category("Sword")
@export var sword_damage: int = 2
@export_category("Aura")
@export var aura_damage:int = 2
@export var aura_interval: float = 30
@export var aura_scene: PackedScene
@export_category("Life")
@export var health: int = 100
@export var max_health: int = 100
@export var death_prefab: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sword_area: Area2D = $SwordArea
@onready var hitbox_area: Area2D = $HitboxArea
@onready var health_progress_bar: ProgressBar = $HealthProgressBar

var input_vector: Vector2 = Vector2(0, 0)
var is_running: bool = false
var was_running: bool = false
var is_attacking: bool = false
var attack_cooldown: float = 0.0
var hitbox_cooldown: float = 0.0
var aura_cooldown: float = 0.0

signal meat_collected(value: int)

func _ready():
	GameManager.player = self
	meat_collected.connect(func(value: int): GameManager.meat_counter += 1)

func _process(delta: float) -> void:
	
	GameManager.player_position = position
	
	# ler input
	read_input()
	
	# processar ataque
	update_attack_cooldown(delta)
	if Input.is_action_just_pressed("attack"):
		attack()
	
	# Processar animação e rotação de sprite
	play_run_idle_animation()
	if not is_attacking:
		rotate_sprite()
		
	# Processar Dano
	update_hitbox_detection(delta)
		
	# Aura
	update_aura(delta)		
	
	#Atualizar Health Bar
	health_progress_bar.max_value = max_health
	health_progress_bar.value = health
	
#func _process(delta: float):
	#if Input.is_action_just_pressed("move_up"):
		#if is_running:
			#animation_player.play("idle")
			#is_running = false
		#else:
			#animation_player.play("run")
			#is_running = true
			
func _physics_process(delta: float) -> void:
	# Modificar a Velocidade
	var target_velocity = input_vector * speed * 100
	if is_attacking:
		target_velocity *= 0.25
	velocity = lerp(velocity, target_velocity, 0.05)
	move_and_slide()
	
func update_attack_cooldown(delta: float) -> void:	
	# Atualizar o temporizador do ataque
	if is_attacking:
		attack_cooldown -= delta
		if attack_cooldown <= 0.0:
			is_attacking = false
			is_running = false
			animation_player.play("idle")

func update_aura(delta: float):
	aura_cooldown -= delta
	if aura_cooldown >0: return
	aura_cooldown = aura_interval
	
	# Criar Ritual
	var aura = aura_scene.instantiate()
	aura.damage_amount = aura_damage
	add_child(aura)
	pass
			
func read_input() -> void:	
	# Obter o Input Vector
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	# Remover deadzone do input_vector
	var deadzone = 0.15
	if abs(input_vector.x) < 0.15:
		input_vector.x - 0.0
	if abs(input_vector.y) < 0.15:
		input_vector.y = 0.0
		
	# Atualizar is_running
	was_running = is_running
	is_running = not input_vector.is_zero_approx()
		
func play_run_idle_animation() -> void:	
	# Tocar Animação
	if not is_attacking:
		if was_running != is_running:
			if is_running:
				animation_player.play("run")
			else:
				animation_player.play("idle")			

func rotate_sprite() -> void:	
	# Inverter Sprite
	if input_vector.x > 0:
		# Desmarcar flip_h do Sprite2D
		sprite.flip_h = false
	elif input_vector.x < 0:
		# Marcar flip_h do Sprite2D
		sprite.flip_h = true
		
func attack() -> void:
	if is_attacking:
		return
		
	# Tocar animação
	animation_player.play("attack_side_1")
	
	# Configurar temporizador
	attack_cooldown = 0.6
	
	# Marcar Ataque
	is_attacking = true

func deal_damage_to_enemies() -> void:
	var bodies = sword_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemies"):
			var enemy: Enemy = body
			
			var direction_to_enemy = (enemy.position - position).normalized()
			var attack_direction: Vector2
			if sprite.flip_h:
				attack_direction = Vector2.LEFT
			else:
				attack_direction = Vector2.RIGHT
			var dot_product = direction_to_enemy.dot(attack_direction)
			# print("Dot: ", dot_product)
			if dot_product >= 0.3:
				enemy.damage(sword_damage)

func update_hitbox_detection(delta: float) -> void:	
		# Temporizador
		hitbox_cooldown -= delta
		if hitbox_cooldown > 0: return
		
		# Frequencia (2x por segundo)
		hitbox_cooldown = 0.5
		
		# Detectar Inimigos
		var bodies = hitbox_area.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("enemies"):
				var enemy: Enemy = body
				var damage_amount = 1
				damage(damage_amount)

func damage(amount: int) -> void:
	if health <= 0: return
	
	health -= amount
	print("Player recebeu dano de ", amount, ". A vida total é de ", health)
	
	# Cor de Dano
	modulate = Color.RED
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(tween.TRANS_QUINT)
	tween = create_tween().tween_property(self, "modulate", Color.WHITE, 0.3)

# Processar Morte
	if health <= 0:
		die()
	
func die() -> void:
	GameManager.end_game()
	
	if death_prefab:
		var death_object = death_prefab.instantiate()
		death_object.position = position
		get_parent().add_child(death_object)
		
	print("O Jogador morreu!")
	queue_free()
	
func heal(amount: int) -> int:
	health += amount
	if health > max_health:
		health = max_health
	print("Player recebura de ", amount, "A vda total é de ", health, "/", max_health)
	return health
	
