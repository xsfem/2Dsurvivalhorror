extends CharacterBody2D

var max_health = 100
var current_health = max_health


func take_damage(damage: int):
	if current_health == null:
		current_health = 100
	
	current_health = current_health - damage
	print("Враг получил урон: ", damage, " Здоровье: ", current_health)
	
	if current_health <= 0:
		die()

func die():
	if current_health > 0:
		print("DEAD")
