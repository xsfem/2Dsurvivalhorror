extends CharacterBody2D

# Параметры движения
const WALK_SPEED = 35.0
const RUN_SPEED = 150.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0


var current_health = 100
@export var attack_cooldown = 1.5
var is_hurt = false

# Гравитация
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Состояния
var is_running = false
var is_attacking = false
var attack_type = ""
var enemy = null
var enemy_in_attack_range = false
var can_attack = true

# Узлы
@onready var anim_sprite = $AnimatedSprite2D
@onready var attack_area2d = $AttackArea2D
@onready var camera = get_node("Camera2D")

# Рандомайзер легких аттак анимаций
var animations = ["Attack1", "Attack1_L"]
var animations_light_attacks = animations.pick_random()


func _ready():
	add_to_group("player")
	
	if attack_area2d:
		print("AttackArea2D найдена")
		attack_area2d.body_entered.connect(_on_attack_area_entered)
		attack_area2d.body_exited.connect(_on_attack_area_exited)
	else:
		print("ОШИБКА: AttackArea не найдена!")

func _physics_process(delta):
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Если атакуем, блокируем движение
	if is_hurt or is_attacking:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
		await get_tree().create_timer(0.5).timeout
		is_hurt = false
		return
	
	# Атаки
	if Input.is_action_just_pressed("light_attack") and is_on_floor():
		perform_attack("light")
	elif Input.is_action_just_pressed("heavy_attack") and is_on_floor():
		perform_attack("heavy")
	
	# Получаем направление движения
	var direction = Input.get_axis("move_left", "move_right")
	
	# Проверяем бег
	is_running = Input.is_action_pressed("run")
	var current_speed = RUN_SPEED if is_running else WALK_SPEED
	
	# Применяем движение
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * current_speed, ACCELERATION * delta)
		anim_sprite.flip_h = direction < 0
		
		# Плавный поворот камеры при повороте с x:40 до x:-40 в рамках 1.75 секунд
		if direction > 0:
			camera.smooth_offset(40,1.75)
		if direction < 0:
			camera.smooth_offset(-40,1.75) 
		
		
		# Анимации движения (только если не прыгаем и не атакуем)
		if is_on_floor() and not is_attacking:
			if is_running:
				anim_sprite.play("Run")
			else:
				anim_sprite.play("Walk")
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
		# Анимация idle
		if is_on_floor() and not is_attacking:
			anim_sprite.play("Idle")
	
	move_and_slide()

func perform_attack(type: String):
	is_attacking = true
	attack_type = type
	
	if type == "light":
		anim_sprite.play(animations_light_attacks)
		deal_damage()
		await get_tree().create_timer(0.5).timeout
	else:
		anim_sprite.play("Attack2")
	
	# Ждем окончания анимации атаки 0.5 секунд
	is_attacking = false

# Этот метод можно вызвать из AnimationPlayer для нанесения урона
func deal_damage():
	can_attack = false
	
	is_attacking = true
	var damage = 50 if attack_type == "light" else 25
	print("Урон нанесен: ", damage)
	
	# Нанесение урона
	if enemy:
		print("Enemy существует")
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
			print("Урон нанесён: ", damage)
		else:
			print("ОШИБКА: У игрока НЕТ метода take_damage!")
	else:
		print("ОШИБКА: player = null")
	
	return damage

func take_damage(damage: int):
	if current_health == null:
		current_health = 100
	
	current_health -= damage
	
	is_hurt = true
	velocity.x = 0  # Останавливаем движение
	
	# Проигрываем анимацию урона
	anim_sprite.play("Hurt")
	await get_tree().create_timer(0.5).timeout
	
	# Возвращаем управление
	is_hurt = false
	print("Игрок получил урон: ", damage, " Здоровье: ", current_health)
	
	if current_health <= 0:
		die()
	

func _on_attack_area_entered(body):
	if body.is_in_group("enemy"):
		enemy = body
		enemy_in_attack_range = true
		print("Враг в зоне атаки")

func _on_attack_area_exited(body):
	if body.is_in_group("enemy"):
		enemy = body
		enemy_in_attack_range = false
		print("Враг вышел из зоны атаки")
		
func die():
	# Останавливаем все процессы
	set_physics_process(false)  # Отключаем физику
	set_process(false)  # Отключаем _process (если используется)
	
	# Проигрываем анимацию смерти
	anim_sprite.play("Die")
	await get_tree().create_timer(1).timeout  # Остановка через 1 секунду
	anim_sprite.pause()
	get_tree().reload_current_scene()
