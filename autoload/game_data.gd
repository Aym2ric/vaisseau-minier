extends Node
## Données de jeu, reprises du prototype validé.
## Plus tard, chaque catégorie pourra devenir une Resource (.tres) éditable dans l'inspecteur.

const ARENA := Vector2(960, 600)

# Couches de collision (bits) : voir aussi [layer_names] dans project.godot.
const LAYER_PLAYER := 1
const LAYER_ROCKS := 2
const LAYER_ENEMIES := 4
const LAYER_WALLS := 8

const OUTLINE := Color(0.071, 0.043, 0.039)

## Réglages du rythme et de la difficulté.
const CONFIG := {
	"hull": 60.0,              # coque de départ
	"keep_on_death": 0.4,      # part de la soute sauvée si la coque lâche
	"ship_speed": 215.0,
	"ship_accel": 1250.0,
	"dash_speed": 820.0,
	"dash_cooldown": 1.2,
	"quota_base": 20,          # ressources à ramasser au secteur 1
	"quota_growth": 1.4,       # quota multiplié par secteur
	"mult_step": 0.5,          # multiplicateur de butin : +0,5 par secteur
	"threat_rate": 0.6,        # montée de la menace par seconde
	"threat_step": 0.3,        # +30 % de montée par secteur
	"spawn_base": 3.2,         # secondes entre deux vagues au début
	"rocks": 14,               # roches présentes en même temps
	"extract_time": 1.5,       # secondes sur la balise pour partir
	"magnet_radius": 55.0,
	"event_min": 14.0,
	"event_max": 22.0,
}

const RESOURCES := {
	"fer": {"name": "Fer", "color": Color(0.824, 0.655, 0.486), "base": 10, "rare": false},
	"cristal": {"name": "Cristal", "color": Color(0.561, 0.910, 1.0), "base": 22, "rare": false},
	"helium": {"name": "Hélium-3", "color": Color(0.788, 0.608, 1.0), "base": 36, "rare": false},
	"magma": {"name": "Magma", "color": Color(1.0, 0.416, 0.122), "base": 55, "rare": false},
	"titane": {"name": "Titane", "color": Color(0.875, 0.906, 0.949), "base": 60, "rare": true},
	"cryonite": {"name": "Cryonite", "color": Color(0.247, 0.722, 1.0), "base": 80, "rare": true},
	"plasma": {"name": "Plasma", "color": Color(1.0, 0.478, 0.851), "base": 100, "rare": true},
	"obsidienne": {"name": "Obsidienne", "color": Color(0.486, 0.420, 1.0), "base": 130, "rare": true},
	"noyau": {"name": "Noyau de gardien", "color": Color(1.0, 0.820, 0.400), "base": 300, "rare": true},
}

const PLANETS := {
	"roc": {
		"name": "Rocheuse", "res": "fer", "rare": "titane", "special": "",
		"bg": Color(0.227, 0.165, 0.122), "spot": Color(0.200, 0.145, 0.106), "rock": Color(0.627, 0.478, 0.369),
		"friction": 6.0, "wind": 0.0,
	},
	"glace": {
		"name": "Glacée", "res": "cristal", "rare": "cryonite", "special": "ice",
		"bg": Color(0.122, 0.196, 0.259), "spot": Color(0.102, 0.169, 0.224), "rock": Color(0.498, 0.592, 0.671),
		"friction": 1.4, "wind": 0.0,
	},
	"gaz": {
		"name": "Gazeuse", "res": "helium", "rare": "plasma", "special": "gas",
		"bg": Color(0.173, 0.122, 0.239), "spot": Color(0.149, 0.102, 0.208), "rock": Color(0.541, 0.478, 0.639),
		"friction": 4.0, "wind": 260.0,
	},
	"volcan": {
		"name": "Volcanique", "res": "magma", "rare": "obsidienne", "special": "magma",
		"bg": Color(0.227, 0.102, 0.071), "spot": Color(0.192, 0.082, 0.055), "rock": Color(0.420, 0.290, 0.251),
		"friction": 6.0, "wind": 0.0,
	},
}

## Roches : points de vie au secteur 1, rayon min/max, poids de tirage.
const ROCKS := {
	"rock": {"hp": 3.0, "radius": [20.0, 32.0], "weight": 5.0, "xp": 1},
	"ore": {"hp": 4.0, "radius": [20.0, 28.0], "weight": 4.5, "xp": 2},
	"hard": {"hp": 10.0, "radius": [28.0, 36.0], "weight": 1.0, "xp": 3},
	"gold": {"hp": 6.0, "radius": [20.0, 20.0], "weight": 0.35, "xp": 4},
	"chest": {"hp": 4.0, "radius": [17.0, 17.0], "weight": 0.3, "xp": 2},
	"repair": {"hp": 3.0, "radius": [16.0, 16.0], "weight": 0.25, "xp": 1},
}

const ENEMIES := {
	"mite": {"hp": 2.0, "speed": 150.0, "damage": 8.0, "radius": 11.0, "credits": 1, "xp": 1},
	"gunner": {"hp": 6.0, "speed": 100.0, "damage": 10.0, "radius": 17.0, "credits": 6, "xp": 4},
	"rammer": {"hp": 5.0, "speed": 540.0, "damage": 14.0, "radius": 15.0, "credits": 4, "xp": 3},
}

const WEAPONS := {
	"blaster": {"name": "Blaster", "cooldown": 0.26, "damage": 1.0, "speed": 720.0, "life": 0.75},
}

## Effets de chaque arme, plus tard : laser, lance-flammes, roquettes (voir le document de conception).
