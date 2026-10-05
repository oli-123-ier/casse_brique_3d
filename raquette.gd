extends AnimatableBody3D

@export var speed := 10.0

func _physics_process(delta: float) -> void:
	# Récupère la direction (-1 gauche, 1 droite, 0 aucune)
	var direction = Input.get_axis("left", "right")
	# Calcule le déplacement sur l'axe X
	var motion := Vector3(direction * speed * delta, 0, 0)
	# Déplace la raquette et s'arrête au contact des murs
	move_and_collide(motion)
