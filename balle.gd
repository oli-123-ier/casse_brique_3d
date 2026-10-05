extends RigidBody3D

signal balle_perdue


@export var speed := 8.0
@export var acceleration := 0.4
@export var vitesse_maximum := 14.0
@export var angle_minimum_deg := 20.0
@export var duree_compte_a_rebours := 3.0
@export var limite_x := 31.0
@export var limite_y_superieure := 21.0
@export var offset_sur_raquette := Vector3(0, 0.8, 0)
@export var raquette_path: NodePath = "../raquette"
@export var compte_a_rebours_path: NodePath = "../CompteARebours"
# Demi-largeur de la raquette (taille X = 3 → 1.5)
@export var demi_largeur_raquette := 1.5
@export var distance_perte_sous_raquette := 1.0

var started := false
var raquette: AnimatableBody3D
var compte_a_rebours: Label
var vitesse_actuelle := 0.0
var temps_restant := 0.0
var dernier_chiffre := -1

func _ready() -> void:
	# Désactive la gravité (jeu en 2D)
	gravity_scale = 0
	# Active la détection des collisions
	contact_monitor = true
	max_contacts_reported = 4
	# Évite que la balle traverse les murs à haute vitesse
	continuous_cd = true
	
	raquette = get_node(raquette_path) as AnimatableBody3D
	compte_a_rebours = get_node_or_null(compte_a_rebours_path) as Label
	body_entered.connect(_on_body_entered)
	vitesse_actuelle = speed
	
	# La balle reste figée sur la raquette tant qu'elle n'est pas lancée
	freeze = true
	_suivre_raquette()


func _physics_process(delta: float) -> void:
	# Garde la balle sur le plan 2D (axe Z bloqué)
	linear_velocity.z = 0
	position.z = 0
	
	if !started:
		_suivre_raquette()
		# Lance la balle avec Espace (ui_accept)
		if temps_restant > 0:
			temps_restant -= delta
			_actualiser_compte_a_rebours()
			if temps_restant <= 0:
				_lancer_balle()
		elif Input.is_action_just_pressed("ui_accept"):
			demarrer_compte_a_rebours()
	else:
		vitesse_actuelle = minf(vitesse_actuelle + acceleration * delta, vitesse_maximum)
		var balle_hors_limites := (
			global_position.y < raquette.global_position.y - distance_perte_sous_raquette
			or absf(global_position.x) > limite_x
			or global_position.y > limite_y_superieure
		)
		if balle_hors_limites:
			_reinitialiser_balle()
			return

		# Maintient une vitesse constante sans casser la direction du rebond
		var vel = linear_velocity
		if vel.length() > 0.1:
			linear_velocity = _corriger_angle(vel).normalized() * vitesse_actuelle


func demarrer_compte_a_rebours() -> void:
	if started:
		return
	temps_restant = duree_compte_a_rebours
	dernier_chiffre = -1
	_actualiser_compte_a_rebours()
	
	
func _suivre_raquette() -> void:
	# Place la balle au-dessus de la raquette
	global_position = raquette.global_position + offset_sur_raquette
	linear_velocity = Vector3.ZERO

func _lancer_balle() -> void:
	started = true
	freeze = false
	vitesse_actuelle = speed
	_tenir_texte_compte_a_rebours("")
	
	# Angle entre 40° et 140° (0° = droite, 90° = haut, 180° = gauche)
	var angle_deg := randf_range(40.0, 140.0)
	var angle_rad := deg_to_rad(angle_deg)
	var direction := Vector3(cos(angle_rad), sin(angle_rad), 0)
	linear_velocity = _corriger_angle(direction).normalized() * vitesse_actuelle

func _reinitialiser_balle() -> void:
	balle_perdue.emit()
	
	started = false
	freeze = true
	vitesse_actuelle = speed
	temps_restant = 0.0
	dernier_chiffre = -1
	_suivre_raquette()
	_tenir_texte_compte_a_rebours("ESPACE POUR RELANCER")

func _actualiser_compte_a_rebours() -> void:
	var chiffre := maxi(1, ceili(temps_restant))
	if chiffre != dernier_chiffre:
		dernier_chiffre = chiffre
		_tenir_texte_compte_a_rebours(str(chiffre))

func _tenir_texte_compte_a_rebours(texte: String) -> void:
	if compte_a_rebours:
		compte_a_rebours.text = texte

func _corriger_angle(direction: Vector3) -> Vector3:
	var direction_corrigee := direction.normalized()
	var composante_y_minimum := sin(deg_to_rad(angle_minimum_deg))
	if absf(direction_corrigee.y) < composante_y_minimum:
		var signe_y := signf(direction_corrigee.y)
		if signe_y == 0:
			signe_y = 1.0
		direction_corrigee.y = signe_y * composante_y_minimum
		direction_corrigee = direction_corrigee.normalized()
	return direction_corrigee

func _on_body_entered(body: Node) -> void:
	if not started:
		return
	# Rebond contrôlé uniquement sur la raquette
	if body == raquette:
		_rebond_sur_raquette()
	#controller le robond et la destrucution des briques
	if body.is_in_group("briques"):
		body.queue_free()

func _rebond_sur_raquette() -> void:
	# Ignore si la balle monte déjà (évite de re-déclencher chaque frame)
	if linear_velocity.y > 0.5:
		return
	
	# Position relative sur la raquette : -1 = gauche, +1 = droite
	var relative_x := clampf(
		(global_position.x - raquette.global_position.x) / demi_largeur_raquette,
		-1.0,
		1.0
	)
	
	# Gauche → 140°, centre → 90°, droite → 40° (toujours vers le haut)
	var angle_deg := lerpf(140.0, 40.0, (relative_x + 1.0) * 0.5)
	var angle_rad := deg_to_rad(angle_deg)
	linear_velocity = _corriger_angle(Vector3(cos(angle_rad), sin(angle_rad), 0)).normalized() * vitesse_actuelle

func arreter_balle() -> void:
	started = false
	freeze = true
	temps_restant = 0.0
	vitesse_actuelle = speed
	linear_velocity = Vector3.ZERO
	_suivre_raquette()
	_tenir_texte_compte_a_rebours("")
