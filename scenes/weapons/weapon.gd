class_name Weapon
extends Node2D
## Base de toutes les armes. Chaque arme surcharge update_weapon().
## Les armes suivantes (laser, lance-flammes, roquettes) héritent de cette classe.

var ship: Ship
var cooldown := 0.0


func update_weapon(delta: float, _firing: bool) -> void:
	cooldown -= delta


## Position de sortie des tirs, dans le repère du secteur.
func muzzle() -> Vector2:
	return ship.position + Vector2.RIGHT.rotated(ship.rotation) * 18.0
