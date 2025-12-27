extends Camera2D

# Плавное смещение камеры по x, с опред временем
func smooth_offset(target_x: float, duration: float):
	var tween = create_tween()
	tween.tween_property(self, "offset:x", target_x, duration)  # 1.0 секунда
