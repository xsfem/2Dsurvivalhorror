extends CanvasLayer

@onready var glitch_material = $ColorRect.material

func trigger_glitch():
	glitch_material.set_shader_parameter("glitch_strength", 0.8)
	await get_tree().create_timer(0.2).timeout
	glitch_material.set_shader_parameter("glitch_strength", 0.0)
