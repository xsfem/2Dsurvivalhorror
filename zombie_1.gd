extends CharacterBody2D

# Параметры врага
const CHASE_SPEED = 50.0
const DETECTION_RANGE = 300.0

# Параметры атаки
@export var attack_damage = 25

# Здоровье
@export var max_health = 100
var current_health = max_health

# Гравитация
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Состояния
var is_chasing = false
var player = null
var is_dead = false

# Состояния атаки
var can_attack = true
var player_in_attack_range = false

# Узлы
@onready var anim_sprite = $AnimatedSprite2D
@onready var growl_sound = $GrowlSound

# Узлы Area
@onready var detection_area = $DetectionArea
@onready var attack_area = $AttackArea


func _ready():
	
	if is_dead:
		return
	
	add_to_group("enemy")
	
	if detection_area:
		print("DetectionArea найдена")
		detection_area.body_entered.connect(_on_player_detected)
		detection_area.body_exited.connect(_on_player_lost)
	else:
		print("ОШИБКА: DetectionArea не найдена!")
	
	if attack_area:
		print("AttackArea найдена")
		attack_area.body_entered.connect(_on_attack_area_entered)
		attack_area.body_exited.connect(_on_attack_area_exited)
	else:
		print("ОШИБКА: AttackArea не найдена!")
		
	

func _physics_process(delta):
	
	if is_dead:
		return
	
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Отладочная информация 
	if player:
		print("Игрок найден. is_chasing: ", is_chasing, " | player_in_attack_range: ", player_in_attack_range, " | can_attack: ", can_attack)
	
	# Если преследуем игрока
	if is_chasing and player:
		if player_in_attack_range:
			# Остановка и атака
			velocity.x = 0
			print("УСЛОВИЕ АТАКИ ВЫПОЛНЕНО")
			if can_attack:
				print("ВЫЗОВ АТАКИ")
				attack()
			else:
				print("НЕ МОГУ АТАКОВАТЬ - ПЕРЕЗАРЯДКА")
		else:
			chase_player()
	else:
		# Стоим на месте
		velocity.x = move_toward(velocity.x, 0, 500 * delta)
		anim_sprite.play("Idle")
	
	move_and_slide()

func chase_player():
	# Бежим к игроку
	var direction = sign(player.global_position.x - global_position.x)
	velocity.x = direction * CHASE_SPEED
	
	# Поворачиваем спрайт
	anim_sprite.flip_h = direction < 0
	anim_sprite.play("Run")


# Когда игрок входит в зону обнаружения
func _on_player_detected(body):
	if body.is_in_group("player"):
		player = body
		is_chasing = true
		# Начинаем с 0.0 секунды звук 
		growl_sound.play(0.0)
		
		# Останавливаем через 2 секунды
		await get_tree().create_timer(7.0).timeout
		growl_sound.stop()
		print("Враг обнаружил игрока!")

# Когда игрок выходит из зоны обнаружения
func _on_player_lost(body):
	if body == player:
		is_chasing = false
		player = null
		growl_sound.stop()
		print("Враг потерял игрока")
		

func _on_attack_area_entered(body):
	if body.is_in_group("player"):
		player = body
		player_in_attack_range = true
		print("Игрок в зоне атаки")

func _on_attack_area_exited(body):
	if body.is_in_group("player"):
		player = body
		player_in_attack_range = false
		print("Игрок вышел из зоны атаки")
		
func take_damage(damage: int):
	if is_dead:
		return
	anim_sprite.stop()
	if current_health == null:
		current_health = 100
	
	current_health = current_health - damage
	anim_sprite.play("Hurt")
	print("Враг получил урон: ", damage, " Здоровье: ", current_health)
	
	if current_health <= 0:
		die()

func attack():
	if is_dead:
		return
	
	can_attack = false	
	
	# Анимация атаки
	anim_sprite.play("Attack")
	
	# Нанесение урона
	if player:
		print("Игрок существует")
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
			print("Урон нанесён: ", attack_damage)
		else:
			print("ОШИБКА: У игрока НЕТ метода take_damage!")
	else:
		print("ОШИБКА: player = null")
	
	# Перезарядка
	await get_tree().create_timer(1).timeout
	can_attack = true

func die():
	if is_dead:
		return
	is_dead = true  # ПЕРВОЕ действие - ставим флаг!
	
	# Останавливаем все процессы
	set_physics_process(false)  # Отключаем физику
	set_process(false)  # Отключаем _process (если используется)
	
	# Убираем коллизии
	collision_layer = 0
	collision_mask = 0
	
	# Проигрываем анимацию смерти
	anim_sprite.play("Dead")
	
	await get_tree().create_timer(1).timeout  # Остановка через 1 секунду
	anim_sprite.pause()
