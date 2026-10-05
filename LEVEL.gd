extends Node3D

@export var vies_maximum := 3

var vies_restantes := 0

@onready var balle = $balle
@onready var vies_label: Label = $UI/vies
@onready var ecran_game_over: ColorRect = $UI/ecranGameOver
@onready var game_over_label: Label = $UI/ecranGameOver/GameOverLabel

@onready var menu_accueil: Control = $UI/MenuAcceuil
@onready var bouton_jouer: Button = $UI/MenuAcceuil/ButtonJouer

var jeu_commence := false
var jeu_termine := false

func _ready() -> void:
	vies_restantes = vies_maximum
	_actualiser_interface()
	balle.balle_perdue.connect(_on_balle_perdue)
	
	menu_accueil.visible = true
	ecran_game_over.visible = false
	bouton_jouer.pressed.connect(_on_bouton_jouer_pressed)
	balle.arreter_balle()


func _process(_delta: float) -> void:
	if jeu_termine and Input.is_action_just_pressed("ui_accept"):
		_retourner_au_menu()

func _on_bouton_jouer_pressed() -> void:
	menu_accueil.visible = false
	ecran_game_over.visible = false

	jeu_commence = true
	jeu_termine = false
	balle.demarrer_compte_a_rebours()

func _on_balle_perdue() -> void:
	if vies_restantes <= 0:
		return
	vies_restantes -= 1
	_actualiser_interface()
	if vies_restantes == 0:
		_afficher_game_over()

func _actualiser_interface() -> void:
	vies_label.text = "VIES : " + str(vies_restantes)

func _afficher_game_over() -> void:
	jeu_termine = true
	jeu_commence = false
	balle.arreter_balle()
	ecran_game_over.visible = true
	game_over_label.visible = true

func _retourner_au_menu() -> void:
	jeu_termine = false
	jeu_commence = false

	ecran_game_over.visible = false
	menu_accueil.visible = true

	vies_restantes = vies_maximum
	_actualiser_interface()
	balle.arreter_balle()
	
	
	
