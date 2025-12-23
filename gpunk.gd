extends CharacterBody2D

# Параметры движения
const WALK_SPEED = 100.0
const RUN_SPEED = 350.0
const ACCELERATION = 1500.0
const FRICTION = 1200.0


@export var max_health = 100
var current_health = max_health

# Гравитация
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

# Состояния
var is_running = false
var is_attacking = false
var attack_type = ""

# Узлы
@onready var anim_sprite = $AnimatedSprite2D

# Рандомайзер легких аттак анимаций
var animations = ["Attack1", "Attack1_L"]
var animations_light_attacks = animations.pick_random()


func _ready():
	add_to_group("player")
	current_health = max_health

func _physics_process(delta):
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y += gravity * delta
	
	# Если атакуем, блокируем движение
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		move_and_slide()
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
		await get_tree().create_timer(0.5).timeout
	else:
		anim_sprite.play("Attack2")
	
	# Ждем окончания анимации атаки 0.5 секунд
	is_attacking = false

# Этот метод можно вызвать из AnimationPlayer для нанесения урона
func deal_damage():
	var damage = 10 if attack_type == "light" else 25
	print("Урон нанесен: ", damage)
	
	# Здесь можно добавить логику обнаружения врагов
	# Например, через Area2D или RayCast2D

func take_damage(damage: int):
	current_health -= damage
	anim_sprite.play("Hurt")
	print("Игрок получил урон: ", damage, " Здоровье: ", current_health)
	
	if current_health <= 0:
		die()


func die():
	anim_sprite.play("Die")
	get_tree().reload_current_scene()
