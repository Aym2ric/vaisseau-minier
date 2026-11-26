extends Node
## Données de jeu — GDD V3.

var ARENA: Vector2

const MAP_SIZE := Vector2(3840.0, 2160.0)

func _ready() -> void:
	ARENA = get_viewport().get_visible_rect().size
	get_viewport().size_changed.connect(func() -> void: ARENA = get_viewport().get_visible_rect().size)

# Couches de collision (bits).
const LAYER_PLAYER := 1
const LAYER_ROCKS  := 2
const LAYER_ENEMIES := 4
const LAYER_WALLS  := 8

const OUTLINE := Color(0.071, 0.043, 0.039)

## Réglages du rythme et de la difficulté.
const CONFIG := {
	"hull":            60.0,
	"ship_speed":      215.0,
	"ship_accel":      1250.0,
	"dash_speed":      820.0,
	"dash_cooldown":   1.2,
	"threat_rate":     0.5,    # points de menace / seconde
	"spawn_base":      3.5,    # secondes entre vagues au départ
	"rocks":           22,     # roches présentes en même temps
	"extract_time":    10.0,   # secondes à l'arrêt pour extraire
	"magnet_radius":   55.0,
	"discover_radius": 220.0,  # rayon de révélation du brouillard
	"recycle_dist":    2500.0, # distance hors-écran pour recycler un ennemi
	"enemy_cap":       60,     # nombre max d'ennemis simultanés
}

const RESOURCES := {
	# Communes (partagées)
	"fer":        {"name": "Fer",          "color": Color(0.824, 0.655, 0.486), "base": 10,  "rare": false, "weight": 1},
	"cuivre":     {"name": "Cuivre",       "color": Color(0.780, 0.440, 0.220), "base": 12,  "rare": false, "weight": 1},
	"carbone":    {"name": "Carbone",      "color": Color(0.300, 0.300, 0.320), "base": 8,   "rare": false, "weight": 1},
	"silicium":   {"name": "Silicium",     "color": Color(0.560, 0.620, 0.720), "base": 15,  "rare": false, "weight": 1},
	"cristal":    {"name": "Cristal",      "color": Color(0.561, 0.910, 1.0),   "base": 22,  "rare": false, "weight": 1},
	"helium":     {"name": "Hélium-3",     "color": Color(0.788, 0.608, 1.0),   "base": 36,  "rare": false, "weight": 1},
	"magma":      {"name": "Magma",        "color": Color(1.0, 0.416, 0.122),   "base": 55,  "rare": false, "weight": 1},
	# Peu communes (partagées)
	"aluminium":  {"name": "Aluminium",    "color": Color(0.780, 0.820, 0.850), "base": 28,  "rare": false, "weight": 2},
	"nickel":     {"name": "Nickel",       "color": Color(0.470, 0.520, 0.350), "base": 22,  "rare": false, "weight": 2},
	"lithium":    {"name": "Lithium",      "color": Color(0.900, 0.880, 0.950), "base": 35,  "rare": false, "weight": 2},
	"cobalt":     {"name": "Cobalt",       "color": Color(0.250, 0.420, 0.780), "base": 40,  "rare": false, "weight": 2},
	# Rares (partagées)
	"titane":     {"name": "Titane",       "color": Color(0.875, 0.906, 0.949), "base": 60,  "rare": true,  "weight": 3},
	"tungstene":  {"name": "Tungstène",    "color": Color(0.380, 0.400, 0.450), "base": 65,  "rare": true,  "weight": 3},
	"uranium":    {"name": "Uranium",      "color": Color(0.450, 0.850, 0.220), "base": 75,  "rare": true,  "weight": 3},
	"platine":    {"name": "Platine",      "color": Color(0.900, 0.920, 0.950), "base": 90,  "rare": true,  "weight": 3},
	"cryonite":   {"name": "Cryonite",     "color": Color(0.247, 0.722, 1.0),   "base": 80,  "rare": true,  "weight": 3},
	"plasma":     {"name": "Plasma",       "color": Color(1.0, 0.478, 0.851),   "base": 100, "rare": true,  "weight": 3},
	"obsidienne": {"name": "Obsidienne",   "color": Color(0.486, 0.420, 1.0),   "base": 130, "rare": true,  "weight": 3},
	# Épiques (partagées)
	"iridium":    {"name": "Iridium",      "color": Color(0.550, 0.300, 0.780), "base": 120, "rare": true,  "weight": 4},
	"diamant":    {"name": "Diamant",      "color": Color(0.700, 0.950, 1.0),   "base": 160, "rare": true,  "weight": 4},
	"etherium":   {"name": "Étherium",     "color": Color(0.850, 0.400, 1.0),   "base": 200, "rare": true,  "weight": 4},
	# Légendaires (partagées)
	"exonium":    {"name": "Exonium",      "color": Color(1.0, 0.850, 0.200),   "base": 350, "rare": true,  "weight": 5},
	"asterium":   {"name": "Astérium",     "color": Color(0.920, 0.950, 1.0),   "base": 450, "rare": true,  "weight": 5},
	# Exclusives planétaires
	"basaltite":  {"name": "Basaltite",    "color": Color(0.400, 0.320, 0.280), "base": 45,  "rare": true,  "weight": 3},
	"ferrite":    {"name": "Ferrite noire","color": Color(0.350, 0.280, 0.250), "base": 55,  "rare": true,  "weight": 3},
	"givre":      {"name": "Givre dense",  "color": Color(0.780, 0.900, 1.000), "base": 50,  "rare": true,  "weight": 3},
	"xenon":      {"name": "Xénon pur",    "color": Color(0.820, 0.700, 1.000), "base": 60,  "rare": true,  "weight": 3},
	"cendrite":   {"name": "Cendrite",     "color": Color(0.550, 0.380, 0.300), "base": 70,  "rare": true,  "weight": 3},
	# Boss — noyau générique (gardien)
	"noyau":          {"name": "Noyau de gardien",    "color": Color(1.0, 0.820, 0.400), "base": 300, "rare": true, "weight": 5},
	# Boss noyaux planétaires (1 par planète)
	"noyau_roc":      {"name": "Noyau : Colosse",     "color": Color(0.900, 0.700, 0.200), "base": 400, "rare": true, "weight": 5},
	"noyau_glace":    {"name": "Noyau : Titan gelé",  "color": Color(0.400, 0.800, 1.000), "base": 400, "rare": true, "weight": 5},
	"noyau_gaz":      {"name": "Noyau : Léviathan",   "color": Color(0.700, 0.500, 1.000), "base": 400, "rare": true, "weight": 5},
	"noyau_volcan":   {"name": "Noyau : Cœur ardent", "color": Color(1.000, 0.200, 0.000), "base": 400, "rare": true, "weight": 5},
	"noyau_desert":   {"name": "Noyau : Mirage",      "color": Color(1.000, 0.800, 0.100), "base": 400, "rare": true, "weight": 5},
	"noyau_cristal":  {"name": "Noyau : Prisme",      "color": Color(0.700, 1.000, 0.900), "base": 400, "rare": true, "weight": 5},
	"noyau_organique":{"name": "Noyau : Matriarche",  "color": Color(0.300, 0.800, 0.200), "base": 400, "rare": true, "weight": 5},
	"noyau_radio":    {"name": "Noyau : Réacteur",    "color": Color(0.500, 1.000, 0.100), "base": 400, "rare": true, "weight": 5},
	# Nouvelles exclusives planétaires
	"solarium":       {"name": "Solarium",             "color": Color(1.000, 0.820, 0.100), "base": 55,  "rare": true,  "weight": 3},
	"sable_vitrif":   {"name": "Sable vitrifié",       "color": Color(0.900, 0.860, 0.600), "base": 45,  "rare": true,  "weight": 3},
	"prismalite":     {"name": "Prismalite",           "color": Color(0.700, 0.950, 0.800), "base": 65,  "rare": true,  "weight": 3},
	"quartz_viv":     {"name": "Quartz vivant",        "color": Color(0.550, 1.000, 0.700), "base": 50,  "rare": true,  "weight": 3},
	"biomasse":       {"name": "Biomasse fossilisée",  "color": Color(0.350, 0.650, 0.200), "base": 40,  "rare": false, "weight": 1},
	"sporite":        {"name": "Sporite",              "color": Color(0.650, 0.300, 0.800), "base": 60,  "rare": true,  "weight": 3},
	"radionite":      {"name": "Radionite",            "color": Color(0.550, 0.950, 0.100), "base": 70,  "rare": true,  "weight": 3},
	"isotope":        {"name": "Isotope noir",         "color": Color(0.200, 0.600, 0.100), "base": 75,  "rare": true,  "weight": 3},
}

const PLANETS := {
	"roc": {
		"name": "Rocheuse", "res": "fer", "rare": "basaltite", "special": "",
		"bg": Color(0.227, 0.165, 0.122), "spot": Color(0.200, 0.145, 0.106), "rock": Color(0.627, 0.478, 0.369),
		"friction": 6.0, "wind": 0.0, "exclusive": ["basaltite", "ferrite"], "boss_noyau": "noyau_roc",
	},
	"glace": {
		"name": "Glacée", "res": "cristal", "rare": "givre", "special": "ice",
		"bg": Color(0.122, 0.196, 0.259), "spot": Color(0.102, 0.169, 0.224), "rock": Color(0.498, 0.592, 0.671),
		"friction": 1.4, "wind": 0.0, "exclusive": ["cryonite", "givre"], "boss_noyau": "noyau_glace",
	},
	"gaz": {
		"name": "Gazeuse", "res": "helium", "rare": "xenon", "special": "gas",
		"bg": Color(0.173, 0.122, 0.239), "spot": Color(0.149, 0.102, 0.208), "rock": Color(0.541, 0.478, 0.639),
		"friction": 4.0, "wind": 260.0, "exclusive": ["plasma", "xenon"], "boss_noyau": "noyau_gaz",
	},
	"volcan": {
		"name": "Volcanique", "res": "magma", "rare": "cendrite", "special": "magma",
		"bg": Color(0.227, 0.102, 0.071), "spot": Color(0.192, 0.082, 0.055), "rock": Color(0.420, 0.290, 0.251),
		"friction": 6.0, "wind": 0.0, "exclusive": ["obsidienne", "cendrite"], "boss_noyau": "noyau_volcan",
	},
	"desert": {
		"name": "Désertique", "res": "carbone", "rare": "solarium", "special": "heat",
		"bg": Color(0.235, 0.188, 0.082), "spot": Color(0.200, 0.157, 0.063), "rock": Color(0.671, 0.588, 0.329),
		"friction": 5.0, "wind": 200.0, "exclusive": ["solarium", "sable_vitrif"], "boss_noyau": "noyau_desert",
	},
	"cristalline": {
		"name": "Cristalline", "res": "cristal", "rare": "prismalite", "special": "crystal",
		"bg": Color(0.071, 0.165, 0.200), "spot": Color(0.055, 0.137, 0.173), "rock": Color(0.400, 0.639, 0.698),
		"friction": 7.0, "wind": 0.0, "exclusive": ["prismalite", "quartz_viv"], "boss_noyau": "noyau_cristal",
	},
	"organique": {
		"name": "Organique", "res": "biomasse", "rare": "sporite", "special": "bio",
		"bg": Color(0.071, 0.157, 0.059), "spot": Color(0.055, 0.129, 0.047), "rock": Color(0.302, 0.502, 0.247),
		"friction": 3.0, "wind": 0.0, "exclusive": ["biomasse", "sporite"], "boss_noyau": "noyau_organique",
	},
	"radioactive": {
		"name": "Radioactive", "res": "uranium", "rare": "radionite", "special": "rad",
		"bg": Color(0.067, 0.157, 0.059), "spot": Color(0.051, 0.129, 0.043), "rock": Color(0.286, 0.522, 0.212),
		"friction": 5.0, "wind": 0.0, "exclusive": ["radionite", "isotope"], "boss_noyau": "noyau_radio",
	},
}

## Roches : points de vie de base, rayon min/max, poids de tirage.
const ROCKS := {
	"rock":   {"hp": 3.0,  "radius": [24.0, 38.0], "weight": 5.0,  "xp": 0, "mineable": false},
	"ore":    {"hp": 4.0,  "radius": [24.0, 34.0], "weight": 4.5,  "xp": 0, "mineable": true},
	"hard":   {"hp": 10.0, "radius": [34.0, 44.0], "weight": 1.0,  "xp": 0, "mineable": false},
	"gold":   {"hp": 6.0,  "radius": [24.0, 24.0], "weight": 0.35, "xp": 0, "mineable": true},
	"chest":  {"hp": 4.0,  "radius": [20.0, 20.0], "weight": 0.3,  "xp": 0, "mineable": false},
	"repair": {"hp": 3.0,  "radius": [19.0, 19.0], "weight": 0.25, "xp": 0, "mineable": false},
}

## Modificateurs élite — appliqués aléatoirement à partir du niveau de menace 2.
const ELITE_MODIFIERS := {
	"blinde":         {"name": "Blindé",         "hp_mult": 2.5, "speed_mult": 0.9,  "dmg_mult": 1.0, "xp_mult": 2, "color": Color("4477ff")},
	"frenetique":     {"name": "Frénétique",     "hp_mult": 1.0, "speed_mult": 2.0,  "dmg_mult": 1.5, "xp_mult": 2, "color": Color("ff3333")},
	"regenerant":     {"name": "Régénérant",     "hp_mult": 2.0, "speed_mult": 1.0,  "dmg_mult": 1.0, "xp_mult": 2, "color": Color("33ff88"), "regen": 0.5},
	"explosif":       {"name": "Explosif",       "hp_mult": 1.5, "speed_mult": 1.0,  "dmg_mult": 1.5, "xp_mult": 3, "color": Color("ffaa00"), "explosion_r": 80.0, "explosion_dmg": 15.0},
	"geant":          {"name": "Géant",          "hp_mult": 4.0, "speed_mult": 0.65, "dmg_mult": 2.0, "xp_mult": 5, "color": Color("bb44cc"), "scale": 1.6},
	"vampirique":     {"name": "Vampirique",     "hp_mult": 1.5, "speed_mult": 1.0,  "dmg_mult": 1.0, "xp_mult": 3, "color": Color("ff66cc"), "vamp_ratio": 0.5},
	"multiplicateur": {"name": "Multiplicateur", "hp_mult": 1.5, "speed_mult": 1.0,  "dmg_mult": 1.0, "xp_mult": 3, "color": Color("ffee22")},
	"protecteur":     {"name": "Protecteur",     "hp_mult": 3.0, "speed_mult": 0.8,  "dmg_mult": 1.0, "xp_mult": 4, "color": Color("44aaff")},
}

const ENEMIES := {
	"mite":     {"hp": 2.0,  "speed": 150.0, "damage": 8.0,  "radius": 16.0, "xp": 1},
	"gunner":   {"hp": 6.0,  "speed": 100.0, "damage": 10.0, "radius": 25.0, "xp": 4},
	"rammer":   {"hp": 5.0,  "speed": 540.0, "damage": 14.0, "radius": 22.0, "xp": 3},
	"tank":     {"hp": 20.0, "speed": 55.0,  "damage": 18.0, "radius": 36.0, "xp": 8},
	"sniper":   {"hp": 4.0,  "speed": 80.0,  "damage": 12.0, "radius": 20.0, "xp": 5, "range": 420.0, "shot_cooldown": 2.5},
	"guardian": {"hp": 30.0, "speed": 450.0, "damage": 25.0, "radius": 55.0, "xp": 15},
	"boss":     {"hp": 300.0, "speed": 40.0,  "damage": 50.0, "radius": 70.0, "xp": 50},
}

const WEAPONS := {
	"blaster":  {"name": "Blaster",       "cooldown": 0.26, "damage": 1.0,  "speed": 720.0, "life": 0.75,
				 "mining_damage": 0.6},
	"laser":    {"name": "Laser",         "cooldown": 0.0,  "damage": 10.0, "speed": 0.0,   "life": 0.0,
				 "range": 340.0, "heat_rate": 0.85, "cool_rate": 1.3,
				 "mining_damage": 6.0},
	"launcher": {"name": "Roquettes",     "cooldown": 1.6,  "damage": 8.0,  "speed": 190.0, "life": 3.5,
				 "explosion_radius": 55.0, "explosion_damage": 5.0,
				 "mining_damage": 5.0},
	"flame":    {"name": "Lance-flammes", "cooldown": 0.0,  "damage": 25.0, "speed": 0.0,   "life": 0.0,
				 "range": 160.0, "angle": 50.0, "fuel_rate": 0.65, "cool_rate": 0.9,
				 "mining_damage": 8.0},
}

## 6 archétypes de vaisseau. Statistiques de base ; multiplicateurs combat/minage appliqués en run.
const SHIPS := {
	"polyvalent": {"name": "Polyvalent",  "hull": 60.0,  "speed": 215.0, "accel": 1250.0, "pickup_radius": 55.0,  "combat_mult": 1.0, "mining_mult": 1.0, "desc": "Équilibré. Bon pour débuter."},
	"mobile":     {"name": "Mobile",      "hull": 45.0,  "speed": 290.0, "accel": 1600.0, "pickup_radius": 55.0,  "combat_mult": 0.9, "mining_mult": 0.9, "desc": "Très rapide, plus fragile."},
	"mineur":     {"name": "Mineur",      "hull": 65.0,  "speed": 185.0, "accel": 1100.0, "pickup_radius": 65.0,  "combat_mult": 0.8, "mining_mult": 1.6, "desc": "Minage ×1.6, combat −20 %."},
	"offensif":   {"name": "Offensif",    "hull": 50.0,  "speed": 220.0, "accel": 1300.0, "pickup_radius": 50.0,  "combat_mult": 1.5, "mining_mult": 0.8, "desc": "Combat ×1.5, hull réduit."},
	"resistant":  {"name": "Résistant",   "hull": 100.0, "speed": 170.0, "accel": 900.0,  "pickup_radius": 55.0,  "combat_mult": 0.9, "mining_mult": 1.0, "desc": "Hull ×1.6, lent."},
	"collecteur": {"name": "Collecteur",  "hull": 60.0,  "speed": 200.0, "accel": 1100.0, "pickup_radius": 120.0, "combat_mult": 0.8, "mining_mult": 1.1, "desc": "Ramassage très large."},
}

## Nombre d'upgrades arme (rate/multi/dmg) pour déclencher une évolution.
const EVOLUTION_THRESHOLD := 3

## Évolutions d'arme disponibles en run. 6 par arme : 2 offensives, 2 minières, 2 hybrides.
## orientation : "offensive" | "miniere" | "hybride"
const RUN_EVOLUTIONS := {
	# --- Blaster ---
	"blaster_heavy":     {"name": "Canon lourd",    "desc": "Dégâts ×2, cadence ÷2.",                        "weapon": "blaster",  "icon": "◆", "orientation": "offensive"},
	"blaster_gatling":   {"name": "Gatling",         "desc": "Cadence ×2, dégâts −30 %.",                     "weapon": "blaster",  "icon": "⚙", "orientation": "offensive"},
	"blaster_excavator": {"name": "Excavateur",      "desc": "Minage ×3, dégâts −50 %.",                      "weapon": "blaster",  "icon": "⛏", "orientation": "miniere"},
	"blaster_drill":     {"name": "Foreuse",          "desc": "Minage ×2, +1 projectile.",                     "weapon": "blaster",  "icon": "⛏", "orientation": "miniere"},
	"blaster_scatter":   {"name": "Dispersion",       "desc": "+2 projectiles en éventail, dégâts −25 %.",     "weapon": "blaster",  "icon": "✦", "orientation": "hybride"},
	"blaster_burst":     {"name": "Rafale",           "desc": "Combat ×1.3, minage ×1.3, cadence −33 %.",      "weapon": "blaster",  "icon": "✦", "orientation": "hybride"},
	# --- Laser ---
	"laser_overload":    {"name": "Surcharge",        "desc": "Dégâts +75 %, chauffe ×1,5.",                   "weapon": "laser",    "icon": "◆", "orientation": "offensive"},
	"laser_focused":     {"name": "Focalisation",     "desc": "Dégâts +50 %, portée +30 %.",                   "weapon": "laser",    "icon": "▶", "orientation": "offensive"},
	"laser_cutter":      {"name": "Découpeur",        "desc": "Minage ×2.5, dégâts −50 %, portée −20 %.",      "weapon": "laser",    "icon": "⛏", "orientation": "miniere"},
	"laser_deep":        {"name": "Forage profond",   "desc": "Minage ×2, portée +50 %, dégâts −40 %.",        "weapon": "laser",    "icon": "⛏", "orientation": "miniere"},
	"laser_sustained":   {"name": "Flux continu",     "desc": "Combat ×1.3, minage ×1.3, chauffe +30 %.",      "weapon": "laser",    "icon": "✦", "orientation": "hybride"},
	"laser_prism":       {"name": "Prisme",           "desc": "Combat ×1.2, minage ×1.2, portée +50 %.",       "weapon": "laser",    "icon": "✦", "orientation": "hybride"},
	# --- Launcher ---
	"launcher_swarm":    {"name": "Essaim",           "desc": "+2 roquettes, dégâts −40 %.",                   "weapon": "launcher", "icon": "⊞", "orientation": "offensive"},
	"launcher_heavy":    {"name": "Ogive lourde",     "desc": "Dégâts ×2, rayon d'exp. ×1,5.",               "weapon": "launcher", "icon": "◆", "orientation": "offensive"},
	"launcher_bore":     {"name": "Foreuse",          "desc": "Minage ×2.5, dégâts −50 %.",                   "weapon": "launcher", "icon": "⛏", "orientation": "miniere"},
	"launcher_cluster":  {"name": "Sous-munitions",   "desc": "Minage ×2, +1 roquette, rayon −30 %.",          "weapon": "launcher", "icon": "⛏", "orientation": "miniere"},
	"launcher_napalm":   {"name": "Napalm",           "desc": "Combat ×1.2, minage ×1.2, rayon +30 %.",        "weapon": "launcher", "icon": "✦", "orientation": "hybride"},
	"launcher_salvo":    {"name": "Salve",            "desc": "+1 roquette, combat ×0.9, minage ×0.9.",         "weapon": "launcher", "icon": "✦", "orientation": "hybride"},
	# --- Flame ---
	"flame_furnace":     {"name": "Fournaise",        "desc": "Dégâts +75 %, carburant ×1,5.",                 "weapon": "flame",    "icon": "◆", "orientation": "offensive"},
	"flame_range":       {"name": "Jet long",         "desc": "Portée +60 %.",                                 "weapon": "flame",    "icon": "▶", "orientation": "offensive"},
	"flame_acid":        {"name": "Acide",            "desc": "Minage ×2.5, dégâts −50 %.",                   "weapon": "flame",    "icon": "⛏", "orientation": "miniere"},
	"flame_wide":        {"name": "Cône large",       "desc": "Minage ×2, angle du cône +50 %.",              "weapon": "flame",    "icon": "⛏", "orientation": "miniere"},
	"flame_torrent":     {"name": "Torrent",          "desc": "Combat ×1.3, minage ×1.3, portée +20 %.",       "weapon": "flame",    "icon": "✦", "orientation": "hybride"},
	"flame_inferno":     {"name": "Inferno",          "desc": "Combat ×1.5, minage ×1.3, conso +40 %.",        "weapon": "flame",    "icon": "✦", "orientation": "hybride"},
}

## Améliorations temporaires proposées à la montée de niveau.
const RUN_UPGRADES := {
	"repair": {"name": "Réparation rapide",    "desc": "Restaure 20 PV."},
	"armor":  {"name": "Blindage renforcé",    "desc": "+20 PV maximum."},
	"speed":  {"name": "Propulseur turbo",     "desc": "+15 % de vitesse."},
	"magnet": {"name": "Aimant étendu",        "desc": "Rayon d'attraction ×1,5."},
	"rate":   {"name": "Cadence améliorée",    "desc": "−20 % de rechargement."},
	"multi":  {"name": "Double canon",         "desc": "+1 projectile par tir.", "weapons": ["blaster", "launcher"]},
	"dmg":    {"name": "Munitions perforantes","desc": "+25 % de dégâts de tir."},
	"mult":   {"name": "Scanner de minerai",   "desc": "+0,25 multiplicateur de butin."},
	"mine":   {"name": "Forage intensif",      "desc": "+40 % de vitesse de minage."},
}

## Compétences permanentes — débloquées en dépensant des ressources dans les 4 arbres.
const SKILLS := {
	# ============================================================
	# ARBRE NAVIGATION  (60 nœuds)
	# ============================================================
	# --- Vitesse & Maniabilité ---
	"thrust":             {"name": "Propulseurs",           "desc": "+8 % de vitesse par rang.",                "cost": 10, "cost_res": "fer",        "max": 5, "tab": "navigation", "prereqs": []},
	"sprint_boost":       {"name": "Sprint",                "desc": "+12 % de vitesse max par rang.",           "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": ["thrust"]},
	"inertia_damp":       {"name": "Amortisseurs",          "desc": "-10 % d'inertie, réponse plus précise.",   "cost": 10, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": ["thrust"]},
	"afterburner":        {"name": "Postcombustion",        "desc": "+10 % de vitesse max par rang.",           "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "navigation", "prereqs": ["sprint_boost"]},
	"nav_momentum":       {"name": "Vitesse de croisière",  "desc": "+5 % de vitesse de croisière.",            "cost": 8,  "cost_res": "fer",        "max": 5, "tab": "navigation", "prereqs": []},
	"nav_gyro":           {"name": "Gyroscope",             "desc": "Virage 15 % plus précis par rang.",        "cost": 12, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": ["inertia_damp"]},
	"nav_reactor":        {"name": "Réacteur avancé",       "desc": "+5 % vitesse et accélération par rang.",   "cost": 20, "cost_res": "cristal",    "max": 2, "tab": "navigation", "prereqs": ["afterburner"]},
	"nav_autopilot":      {"name": "Pilote automatique",    "desc": "+3 % vitesse en déplacement direct.",      "cost": 10, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": ["nav_momentum"]},
	"nav_haste":          {"name": "Élan",                  "desc": "+5 % vitesse au démarrage de run.",        "cost": 8,  "cost_res": "fer",        "max": 3, "tab": "navigation", "prereqs": ["nav_momentum"]},
	"nav_perf":           {"name": "Performance max",       "desc": "+3 % toutes stats navigation.",            "cost": 25, "cost_res": "cristal",    "max": 3, "tab": "navigation", "prereqs": ["nav_reactor"]},
	# --- Esquive ---
	"dash":               {"name": "Esquive",               "desc": "Débloque la compétence d'esquive.",        "cost": 20, "cost_res": "fer",        "max": 1, "tab": "navigation", "prereqs": []},
	"dash_cooldown_skill":{"name": "Esquive rapide",        "desc": "-15 % cooldown d'esquive par rang.",       "cost": 15, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": ["dash"]},
	"dash_speed_skill":   {"name": "Dash rapide",           "desc": "+20 % vitesse lors de l'esquive.",         "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "navigation", "prereqs": ["dash"]},
	"dash_charge":        {"name": "Charge d'esquive",      "desc": "+1 charge d'esquive supplémentaire.",      "cost": 20, "cost_res": "cristal",    "max": 2, "tab": "navigation", "prereqs": ["dash_cooldown_skill"]},
	"dash_invuln":        {"name": "Esquive invincible",    "desc": "+0.1 s d'invincibilité après esquive.",    "cost": 15, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": ["dash_speed_skill"]},
	"phase_shift":        {"name": "Déphasage",             "desc": "-30 % dégâts reçus pendant l'esquive.",   "cost": 25, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["dash_charge"]},
	"nav_reflex":         {"name": "Réflexes",              "desc": "-0.05 s délai invincibilité après dégât.", "cost": 15, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": ["dash_invuln"]},
	"nav_warp":           {"name": "Téléportation",         "desc": "Dash traverse les murs friables.",         "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["phase_shift"]},
	"nav_boost_wave":     {"name": "Onde de choc",          "desc": "Dash repousse les ennemis proches.",       "cost": 25, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["nav_warp"]},
	"nav_boost_cap":      {"name": "Capacité de décharge",  "desc": "+1 capacité run extra upgrade.",           "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_perf"]},
	# --- Furtivité & Menace ---
	"threat_slow":        {"name": "Furtivité",             "desc": "-12 % taux de menace par rang.",           "cost": 20, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": ["thrust"]},
	"ghost_drive":        {"name": "Propulsion fantôme",    "desc": "-15 % taux de menace par rang.",           "cost": 18, "cost_res": "cryonite",   "max": 3, "tab": "navigation", "prereqs": ["threat_slow"]},
	"threat_delay":       {"name": "Brouillage radar",      "desc": "Repousse de 15 % la prochaine vague.",     "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "navigation", "prereqs": ["ghost_drive"]},
	"nav_cloak":          {"name": "Camouflage",            "desc": "2 s d'invisibilité après extraction.",     "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["ghost_drive"]},
	"nav_stealth_ext":    {"name": "Furtivité avancée",     "desc": "-10 % menace supplémentaire par rang.",    "cost": 15, "cost_res": "cryonite",   "max": 2, "tab": "navigation", "prereqs": ["ghost_drive"]},
	"nav_silent":         {"name": "Propulsion silencieuse","desc": "-8 % taux de menace passif par rang.",     "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": ["threat_slow"]},
	# --- Extraction ---
	"extract_boost":      {"name": "Turbine d'extraction",  "desc": "-15 % temps d'extraction par rang.",       "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": []},
	"nav_refuel":         {"name": "Ravitaillement",        "desc": "+20 PV récupérés à l'extraction.",         "cost": 15, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": ["extract_boost"]},
	"bulk_extract":       {"name": "Chargement lourd",      "desc": "+15 % ressources en cargo à l'extraction.","cost": 15, "cost_res": "cryonite",   "max": 2, "tab": "navigation", "prereqs": ["extract_boost"]},
	"safe_extract":       {"name": "Extraction précoce",    "desc": "Extraction disponible dès 50 % mission.",  "cost": 20, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["bulk_extract"]},
	"extract_field":      {"name": "Champ d'extraction",    "desc": "Zone d'extraction repousse petits ennemis.","cost": 25, "cost_res": "cryonite",  "max": 1, "tab": "navigation", "prereqs": ["nav_refuel"]},
	"nav_reserve":        {"name": "Réserve d'énergie",     "desc": "+10 % PV récupérés au démarrage de run.",  "cost": 12, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": ["nav_refuel"]},
	"nav_cargo_boost":    {"name": "Soute améliorée",       "desc": "+1 emplacement cargo virtuel.",             "cost": 18, "cost_res": "cryonite",   "max": 2, "tab": "navigation", "prereqs": ["bulk_extract"]},
	# --- Exploration ---
	"nav_scan":           {"name": "Capteurs avancés",      "desc": "+20 % portée de détection.",               "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "navigation", "prereqs": []},
	"nav_map":            {"name": "Cartographie",          "desc": "+1 secteur révélé au départ de run.",      "cost": 15, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": ["nav_scan"]},
	"nav_xp_scan":        {"name": "Analyse terrain",       "desc": "+5 % XP par zone explorée par rang.",      "cost": 12, "cost_res": "cristal",    "max": 2, "tab": "navigation", "prereqs": ["nav_map"]},
	"nav_shortcut":       {"name": "Raccourci",             "desc": "-1 difficulté effective pour exploration.", "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_map"]},
	"nav_elite_scan":     {"name": "Scanner élite",         "desc": "Révèle les ennemis élites sur la carte.",  "cost": 20, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["nav_scan"]},
	"nav_drop_chance":    {"name": "Opportuniste",          "desc": "+10 % chance de loot ennemi par rang.",    "cost": 10, "cost_res": "fer",        "max": 3, "tab": "navigation", "prereqs": []},
	"nav_magnet_ext":     {"name": "Aimant étendu",         "desc": "+15 % portée d'aimant.",                   "cost": 10, "cost_res": "aluminium",  "max": 2, "tab": "navigation", "prereqs": []},
	"nav_circuit":        {"name": "Circuit intégré",       "desc": "-5 % rechargement armes par rang.",        "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "navigation", "prereqs": ["nav_reactor"]},
	"nav_mass":           {"name": "Blindage composite",    "desc": "+10 % PV max par rang.",                   "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "navigation", "prereqs": ["nav_reactor"]},
	# --- Planètes ---
	"nav_glace":          {"name": "Cap Glaciaire",         "desc": "Débloque la planète Glacée.",              "cost": 25, "cost_res": "fer",        "max": 1, "tab": "navigation", "prereqs": ["thrust"], "unlocks_planet": "glace"},
	"nav_volcan":         {"name": "Cap Volcanique",        "desc": "Débloque la planète Volcanique.",          "cost": 20, "cost_res": "titane",     "max": 1, "tab": "navigation", "prereqs": ["nav_glace"], "unlocks_planet": "volcan"},
	"nav_gaz":            {"name": "Cap Gazeux",            "desc": "Débloque la planète Gazeuse.",             "cost": 20, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_glace"], "unlocks_planet": "gaz"},
	"nav_desert":         {"name": "Cap Désertique",        "desc": "Débloque la planète Désertique.",          "cost": 25, "cost_res": "fer",        "max": 1, "tab": "navigation", "prereqs": ["thrust"], "unlocks_planet": "desert"},
	"nav_cristal":        {"name": "Cap Cristallin",        "desc": "Débloque la planète Cristalline.",         "cost": 30, "cost_res": "tungstene",  "max": 1, "tab": "navigation", "prereqs": ["nav_desert"], "unlocks_planet": "cristalline"},
	"nav_organique":      {"name": "Cap Organique",         "desc": "Débloque la planète Organique.",           "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_glace"], "unlocks_planet": "organique"},
	"nav_radio":          {"name": "Cap Radioactif",        "desc": "Débloque la planète Radioactive.",         "cost": 35, "cost_res": "uranium",    "max": 1, "tab": "navigation", "prereqs": ["nav_organique"], "unlocks_planet": "radioactive"},
	"nav_toxique":        {"name": "Cap Toxique",           "desc": "Débloque la planète Toxique.",             "cost": 40, "cost_res": "uranium",    "max": 1, "tab": "navigation", "prereqs": ["nav_organique"], "unlocks_planet": "toxique"},
	# --- Vaisseaux ---
	"ship_mobile":        {"name": "Vaisseau Mobile",       "desc": "Débloque le Vaisseau Mobile.",             "cost": 30, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["sprint_boost"], "unlocks_ship": "mobile"},
	"ship_mineur":        {"name": "Vaisseau Minier",       "desc": "Débloque le Vaisseau Minier.",             "cost": 30, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["nav_scan"], "unlocks_ship": "mineur"},
	"ship_offensif":      {"name": "Vaisseau Offensif",     "desc": "Débloque le Vaisseau Offensif.",           "cost": 35, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["afterburner"], "unlocks_ship": "offensif"},
	"ship_resistant":     {"name": "Vaisseau Résistant",    "desc": "Débloque le Vaisseau Résistant.",          "cost": 35, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["dash_charge"], "unlocks_ship": "resistant"},
	"ship_collecteur":    {"name": "Vaisseau Collecteur",   "desc": "Débloque le Vaisseau Collecteur.",         "cost": 35, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["bulk_extract"], "unlocks_ship": "collecteur"},
	# --- Finale ---
	"nav_upgrade_start":  {"name": "Préparation",           "desc": "+1 upgrade run offert au départ.",         "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_boost_cap"]},
	"nav_coolant":        {"name": "Refroidissement nav.",  "desc": "-10 % surchauffe armes énergie.",          "cost": 15, "cost_res": "cryonite",   "max": 2, "tab": "navigation", "prereqs": ["nav_reactor"]},
	"nav_fleet_perk":     {"name": "Flotte coordonnée",     "desc": "-20 % prix upgrade vaisseau.",             "cost": 25, "cost_res": "cristal",    "max": 1, "tab": "navigation", "prereqs": ["ship_mobile"]},
	"nav_boost_all":      {"name": "Superpropulseur",       "desc": "+5 % toutes stats navigation.",            "cost": 40, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_perf", "nav_cloak"]},
	"nav_finale":         {"name": "Navigation maîtrisée",  "desc": "+10 % vitesse, -10 % menace.",             "cost": 50, "cost_res": "cryonite",   "max": 1, "tab": "navigation", "prereqs": ["nav_boost_all"]},
	# ============================================================
	# ARBRE LOGISTIQUE  (60 nœuds)
	# ============================================================
	# --- Hull & Survie ---
	"hull":               {"name": "Blindage",              "desc": "+15 PV max.",                              "cost": 15, "cost_res": "fer",        "max": 5, "tab": "logistique", "prereqs": []},
	"hull_ext":           {"name": "Blindage épais",        "desc": "+10 PV max par rang.",                     "cost": 10, "cost_res": "fer",        "max": 5, "tab": "logistique", "prereqs": ["hull"]},
	"repair_nano":        {"name": "Nanorobots",            "desc": "Régénère 0.5 PV/s en run par rang.",       "cost": 25, "cost_res": "platine",    "max": 3, "tab": "logistique", "prereqs": ["hull"]},
	"hull_regen":         {"name": "Nanoréparation+",       "desc": "+0.3 PV/s par rang.",                      "cost": 20, "cost_res": "platine",    "max": 3, "tab": "logistique", "prereqs": ["repair_nano"]},
	"damage_absorb":      {"name": "Absorption",            "desc": "-5 % dégâts reçus par rang.",              "cost": 20, "cost_res": "titane",     "max": 3, "tab": "logistique", "prereqs": ["hull_ext"]},
	"insure":             {"name": "Récupération",          "desc": "+12 % cargo sauvé à mort.",                "cost": 15, "cost_res": "titane",     "max": 3, "tab": "logistique", "prereqs": ["hull"]},
	"insure_ext":         {"name": "Assurance renforcée",   "desc": "+5 % cargo sauvé à mort par rang.",        "cost": 15, "cost_res": "titane",     "max": 3, "tab": "logistique", "prereqs": ["insure"]},
	"heal_kill":          {"name": "Pillage vital",         "desc": "+2 PV récupérés par kill ennemi.",         "cost": 15, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": ["hull"]},
	"invuln_ext":         {"name": "Bouclier temporel",     "desc": "+0.1 s invincibilité après dégât.",        "cost": 15, "cost_res": "aluminium",  "max": 2, "tab": "logistique", "prereqs": ["damage_absorb"]},
	"emergency_repair":   {"name": "Réparation d'urgence",  "desc": "Récupère 10 PV si PV < 20 %.",            "cost": 25, "cost_res": "platine",    "max": 1, "tab": "logistique", "prereqs": ["hull_regen"]},
	"hull_finale":        {"name": "Forteresse",            "desc": "+30 PV max et +1 PV/s supplémentaire.",    "cost": 40, "cost_res": "platine",    "max": 1, "tab": "logistique", "prereqs": ["emergency_repair", "invuln_ext"]},
	"log_hull_mass":      {"name": "Structure renforcée",   "desc": "+8 PV max par rang.",                      "cost": 10, "cost_res": "fer",        "max": 3, "tab": "logistique", "prereqs": ["hull_ext"]},
	# --- Aimant & Collecte ---
	"magnet":             {"name": "Aimant",                "desc": "+30 % de portée d'aimant.",                "cost": 8,  "cost_res": "fer",        "max": 5, "tab": "logistique", "prereqs": []},
	"magnet2":            {"name": "Aimant puissant",       "desc": "+20 % portée d'aimant par rang.",          "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": ["magnet"]},
	"collect_speed":      {"name": "Attraction rapide",     "desc": "Ressources attirées 30 % plus vite.",      "cost": 12, "cost_res": "aluminium",  "max": 2, "tab": "logistique", "prereqs": ["magnet"]},
	"gold_magnet":        {"name": "Aimant or",             "desc": "Attire les gisements d'or depuis plus loin.","cost": 20, "cost_res": "cristal",  "max": 1, "tab": "logistique", "prereqs": ["magnet2"]},
	"aoe_collect":        {"name": "Collecte de zone",      "desc": "Rayon de ramassage +50 %.",                "cost": 20, "cost_res": "cristal",    "max": 2, "tab": "logistique", "prereqs": ["collect_speed"]},
	"log_magnet_fin":     {"name": "Aimant final",          "desc": "+30 % portée d'aimant finale.",            "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["gold_magnet", "aoe_collect"]},
	# --- Ressources & Cargo ---
	"cargo_mult":         {"name": "Cargo optimisé",        "desc": "+10 % ressources ramassées par rang.",     "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": []},
	"lucky_drop":         {"name": "Veine de chance",       "desc": "+10 % chance double ressource.",           "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["cargo_mult"]},
	"cargo_save2":        {"name": "Bouclier cargo",        "desc": "+3 % cargo sauvé à mort par rang.",        "cost": 15, "cost_res": "titane",     "max": 3, "tab": "logistique", "prereqs": ["insure_ext"]},
	"storage_ext":        {"name": "Entrepôt étendu",       "desc": "+20 % espace inventaire permanent.",       "cost": 20, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": []},
	"run_income":         {"name": "Pillage de guerre",     "desc": "+15 % ressources des ennemis.",            "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["cargo_mult"]},
	"bonus_res":          {"name": "Collecteur avancé",     "desc": "+5 % de toutes les ressources collectées.","cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["run_income"]},
	"cargo_finale":       {"name": "Cargo maximal",         "desc": "+20 % toutes ressources collectées.",      "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["bonus_res"]},
	"log_cargo_plus":     {"name": "Suremballage",          "desc": "+1 unité bonus par ressource collectée.",  "cost": 20, "cost_res": "cristal",    "max": 2, "tab": "logistique", "prereqs": ["lucky_drop"]},
	# --- XP & Progression ---
	"xp_boost":           {"name": "Capteurs XP",           "desc": "+10 % XP gagné par rang.",                 "cost": 10, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": []},
	"pickup_xp":          {"name": "Analyseur de minerai",  "desc": "+1 XP par ressource ramassée.",            "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": []},
	"pickup_xp2":         {"name": "Scan approfondi",       "desc": "+2 XP supplémentaire par ressource.",      "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "logistique", "prereqs": ["pickup_xp"]},
	"xp_boost2":          {"name": "Analyse poussée",       "desc": "+10 % XP supplémentaire par rang.",        "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["xp_boost"]},
	"xp_combat":          {"name": "Expertise combat",      "desc": "+5 % XP des kills par rang.",              "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["xp_boost"]},
	"xp_mine":            {"name": "Expertise minage",      "desc": "+5 % XP du minage par rang.",              "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["xp_boost"]},
	"run_choice":         {"name": "Choix stratégique",     "desc": "+1 choix d'upgrade par niveau.",           "cost": 25, "cost_res": "cryonite",   "max": 2, "tab": "logistique", "prereqs": ["xp_boost2"]},
	"level_bonus":        {"name": "Montée en puissance",   "desc": "+2 XP bonus par niveau gagné.",            "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["xp_boost2"]},
	"xp_start":           {"name": "Avance sur le terrain", "desc": "+10 XP au démarrage de run.",              "cost": 10, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": []},
	"xp_finale":          {"name": "Expertise totale",      "desc": "+20 % XP global.",                         "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["run_choice", "level_bonus"]},
	"log_fast_level":     {"name": "Accélération",          "desc": "-5 % XP requis pour le prochain niveau.",  "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "logistique", "prereqs": ["xp_start"]},
	"log_xp_cargo":       {"name": "Analyse rare",          "desc": "+1 XP par ressource rare ramassée.",       "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["xp_mine"]},
	# --- Économie & Hub ---
	"skill_reduce":       {"name": "Économiste",            "desc": "-5 % coût compétences permanentes.",       "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": []},
	"skill_reduce2":      {"name": "Expert en réductions",  "desc": "-5 % coût supplémentaire par rang.",       "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["skill_reduce"]},
	"buy_refund":         {"name": "Remboursement partiel", "desc": "10 % de remboursement sur chaque achat.",  "cost": 20, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["skill_reduce"]},
	"hub_synergy":        {"name": "Synergie du hub",       "desc": "+2 % toutes stats hub par compétence.",    "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["skill_reduce2"]},
	"crafting":           {"name": "Recyclage",             "desc": "Débloque le recyclage de ressources.",     "cost": 20, "cost_res": "aluminium",  "max": 1, "tab": "logistique", "prereqs": ["storage_ext"]},
	"recycle_res":        {"name": "Recyclage optimisé",    "desc": "+15 % ressources récupérées en recyclage.","cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "logistique", "prereqs": ["crafting"]},
	"economy_finale":     {"name": "Économie parfaite",     "desc": "-10 % tous coûts de compétences.",         "cost": 40, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["hub_synergy", "recycle_res"]},
	# --- Modules ---
	"module_slot_1":      {"name": "Module 1",              "desc": "Débloque l'emplacement de module 1.",      "cost": 25, "cost_res": "cristal",    "max": 1, "tab": "logistique", "prereqs": []},
	"module_slot_2":      {"name": "Module 2",              "desc": "Débloque l'emplacement de module 2.",      "cost": 30, "cost_res": "cristal",    "max": 1, "tab": "logistique", "prereqs": ["module_slot_1"]},
	"module_slot_3":      {"name": "Module 3",              "desc": "Débloque l'emplacement de module 3.",      "cost": 35, "cost_res": "cristal",    "max": 1, "tab": "logistique", "prereqs": ["module_slot_2"]},
	"module_slot_4":      {"name": "Module 4",              "desc": "Débloque l'emplacement de module 4.",      "cost": 40, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["module_slot_3"]},
	"module_power":       {"name": "Puissance modules",     "desc": "+15 % efficacité des modules par rang.",   "cost": 20, "cost_res": "cristal",    "max": 3, "tab": "logistique", "prereqs": ["module_slot_1"]},
	"module_sync":        {"name": "Synchro modules",       "desc": "Synchro modules : +5 % toutes stats.",     "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["module_power", "module_slot_2"]},
	"module_upgrade":     {"name": "Amélioration modules",  "desc": "Permet d'améliorer les modules une fois.", "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["module_sync"]},
	"module_link":        {"name": "Lien modules",          "desc": "Lie 2 modules pour effet combiné.",        "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["module_upgrade"]},
	# --- Divers & Finale ---
	"repair_fast":        {"name": "Maintenance accélérée", "desc": "Réparation hors run -20 % plus rapide.",   "cost": 15, "cost_res": "aluminium",  "max": 1, "tab": "logistique", "prereqs": ["repair_nano"]},
	"fleet_insurance":    {"name": "Assurance flotte",      "desc": "Ressources de mission garanties en échec.","cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["cargo_save2"]},
	"log_scan":           {"name": "Scanner logistique",    "desc": "Révèle les ressources rares sur la minimap.","cost": 20, "cost_res": "cristal",  "max": 1, "tab": "logistique", "prereqs": ["pickup_xp2"]},
	"log_boost":          {"name": "Booster logistique",    "desc": "+5 % toutes stats logistiques par rang.",  "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "logistique", "prereqs": ["cargo_finale"]},
	"log_res_sense":      {"name": "Sixième sens",          "desc": "Détecte les ressources rares à proximité.","cost": 20, "cost_res": "cristal",    "max": 1, "tab": "logistique", "prereqs": ["log_scan"]},
	"log_res_safe":       {"name": "Cargo blindé",          "desc": "+5 % ressources sécurisées en mort.",      "cost": 15, "cost_res": "cryonite",   "max": 2, "tab": "logistique", "prereqs": ["fleet_insurance"]},
	"log_finale":         {"name": "Logistique maîtrisée",  "desc": "Tous bonus logistiques ×1.1.",              "cost": 60, "cost_res": "cryonite",   "max": 1, "tab": "logistique", "prereqs": ["log_boost", "economy_finale", "xp_finale", "hull_finale"]},
	# ============================================================
	# ARBRE ARMEMENT  (60 nœuds)
	# ============================================================
	# --- Général ---
	"reroll":             {"name": "Reconfigurateur",       "desc": "+1 actualisation/run.",                    "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": []},
	"fire_rate_perm":     {"name": "Module de cadence",     "desc": "-8 % rechargement toutes armes.",          "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": []},
	"global_dmg":         {"name": "Puissance brute",       "desc": "+5 % dégâts toutes armes par rang.",       "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": []},
	"global_fire_rate":   {"name": "Cadence globale",       "desc": "-5 % rechargement toutes armes par rang.", "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["fire_rate_perm"]},
	"crit_chance":        {"name": "Visée précise",         "desc": "+3 % chance critique globale par rang.",   "cost": 20, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["global_dmg"]},
	"crit_dmg":           {"name": "Impact critique",       "desc": "+20 % multiplicateur critique par rang.",  "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "armement",  "prereqs": ["crit_chance"]},
	"weapon_synergy":     {"name": "Tir continu",           "desc": "+5 % dégâts si tir continu > 2 s.",       "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "armement",  "prereqs": ["global_fire_rate"]},
	"dual_weapon":        {"name": "Double armement",       "desc": "Débloque un slot d'arme secondaire.",      "cost": 50, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["weapon_synergy"]},
	"overpower":          {"name": "Surpuissance",          "desc": "Run : +3 choix d'armes au niveau up.",     "cost": 20, "cost_res": "cristal",    "max": 1, "tab": "armement",  "prereqs": ["reroll"]},
	"arm_mastery":        {"name": "Maîtrise armement",     "desc": "+10 % toutes armes.",                      "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["global_dmg", "crit_dmg"]},
	"weapon_cooldown":    {"name": "Refroidissement arme",  "desc": "-10 % rechargement global.",               "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["global_fire_rate"]},
	"arm_finale":         {"name": "Maîtrise combat",       "desc": "+15 % dégâts, +10 % cadence globale.",     "cost": 60, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["arm_mastery", "dual_weapon"]},
	# --- Blaster ---
	"blaster_dmg":        {"name": "Calibre",               "desc": "+20 % de dégâts.",                         "cost": 15, "cost_res": "cristal",    "max": 5, "tab": "armement",  "prereqs": []},
	"blaster_multi":      {"name": "Double canon",          "desc": "+1 projectile.",                           "cost": 20, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["blaster_dmg"]},
	"blaster_crit":       {"name": "Visée blaster",         "desc": "+5 % chance critique blaster par rang.",  "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["blaster_dmg"]},
	"blaster_pen":        {"name": "Perforation",           "desc": "Projectiles traversent les ennemis.",      "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["blaster_multi"]},
	"blaster_range":      {"name": "Portée blaster",        "desc": "+20 % portée de tir par rang.",            "cost": 12, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["blaster_dmg"]},
	"blaster_speed":      {"name": "Vélocité",              "desc": "+15 % vitesse des projectiles par rang.",  "cost": 10, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["blaster_dmg"]},
	"blaster_impact":     {"name": "Choc cinétique",        "desc": "Effet recul sur hit ennemi.",              "cost": 20, "cost_res": "cristal",    "max": 1, "tab": "armement",  "prereqs": ["blaster_pen"]},
	"blaster_boost":      {"name": "Surcharge blaster",     "desc": "+10 % dégâts blaster supplémentaires.",   "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["blaster_crit"]},
	"blaster_finale":     {"name": "Blaster maîtrisé",      "desc": "+10 % dégâts et portée.",                  "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["blaster_impact", "blaster_speed"]},
	"evo_blaster_heavy":  {"name": "Évo : Blaster Lourd",   "desc": "Débloque l'évolution Blaster Lourd.",      "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["blaster_dmg"],    "unlocks_evo": "blaster_heavy"},
	"evo_blaster_gatling":{"name": "Évo : Blaster Gatling", "desc": "Débloque l'évolution Blaster Gatling.",    "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["blaster_multi"],  "unlocks_evo": "blaster_gatling"},
	"evo_blaster_scatter":{"name": "Évo : Blaster Dispersé","desc": "Débloque l'évolution Blaster Dispersé.",   "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["blaster_range"],  "unlocks_evo": "blaster_scatter"},
	# --- Laser ---
	"laser_dmg":          {"name": "Laser surpuissant",     "desc": "+20 % de dégâts/s.",                       "cost": 15, "cost_res": "cristal",    "max": 5, "tab": "armement",  "prereqs": []},
	"laser_cool":         {"name": "Dissipateur",           "desc": "+15 % refroidissement.",                   "cost": 12, "cost_res": "cristal",    "max": 4, "tab": "armement",  "prereqs": ["laser_dmg"]},
	"laser_range_ext":    {"name": "Portée laser",          "desc": "+20 % portée laser par rang.",             "cost": 12, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["laser_dmg"]},
	"laser_pierce":       {"name": "Laser pénétrant",       "desc": "Laser traverse plusieurs ennemis.",        "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["laser_cool"]},
	"laser_pulse":        {"name": "Laser impulsionnel",    "desc": "Pic de dégâts laser toutes 0.5 s.",        "cost": 20, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["laser_dmg"]},
	"laser_efficiency":   {"name": "Efficacité thermique",  "desc": "-10 % consommation de chaleur par rang.",  "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["laser_cool"]},
	"laser_heat_resist":  {"name": "Résistance thermique",  "desc": "-10 % surchauffe laser par rang.",         "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["laser_efficiency"]},
	"laser_boost":        {"name": "Surcharge laser",       "desc": "+10 % dégâts laser supplémentaires.",     "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["laser_dmg"]},
	"laser_finale":       {"name": "Laser maîtrisé",        "desc": "+15 % dégâts et -15 % surchauffe.",        "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["laser_heat_resist", "laser_pulse"]},
	"evo_laser_overload":  {"name": "Évo : Laser Surcharge", "desc": "Débloque l'évolution Laser Surcharge.",   "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["laser_dmg"],         "unlocks_evo": "laser_overload"},
	"evo_laser_focused":   {"name": "Évo : Laser Focalisé",  "desc": "Débloque l'évolution Laser Focalisé.",    "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["laser_range_ext"],   "unlocks_evo": "laser_focused"},
	"evo_laser_sustained": {"name": "Évo : Laser Continu",   "desc": "Débloque l'évolution Laser Continu.",     "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["laser_efficiency"],  "unlocks_evo": "laser_sustained"},
	# --- Lance-Roquettes ---
	"launcher_dmg":       {"name": "Ogive renforcée",       "desc": "+20 % de dégâts.",                         "cost": 15, "cost_res": "cristal",    "max": 5, "tab": "armement",  "prereqs": []},
	"explosion_dmg":      {"name": "Ogive avancée",         "desc": "+20 % dégâts d'explosion.",                "cost": 15, "cost_res": "tungstene",  "max": 3, "tab": "armement",  "prereqs": ["launcher_dmg"]},
	"launcher_radius":    {"name": "Souffle étendu",        "desc": "+15 % rayon d'explosion par rang.",        "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["launcher_dmg"]},
	"launcher_homing":    {"name": "Guidage amélioré",      "desc": "Meilleur ciblage des roquettes.",          "cost": 20, "cost_res": "cristal",    "max": 1, "tab": "armement",  "prereqs": ["explosion_dmg"]},
	"launcher_reload":    {"name": "Chargement rapide",     "desc": "-10 % rechargement lance-roquettes.",      "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["launcher_dmg"]},
	"launcher_chain":     {"name": "Réaction en chaîne",    "desc": "Explosion en chaîne si 2 cibles proches.", "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["launcher_radius"]},
	"launcher_arming":    {"name": "Détonation directe",    "desc": "Roquette explose dès contact.",            "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["launcher_chain"]},
	"launcher_boost":     {"name": "Propulsion avancée",    "desc": "+10 % dégâts roquette supplémentaires.",  "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["launcher_dmg"]},
	"launcher_finale":    {"name": "Lance-roquettes maîtrisé","desc": "+10 % dégâts et rayon.",                 "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["launcher_arming", "launcher_homing"]},
	"evo_launcher_swarm":  {"name": "Évo : Lance-Essaim",   "desc": "Débloque l'évolution Lance-Essaim.",       "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["launcher_dmg"],       "unlocks_evo": "launcher_swarm"},
	"evo_launcher_heavy":  {"name": "Évo : Lance Lourd",    "desc": "Débloque l'évolution Lance Lourd.",        "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["launcher_radius"],    "unlocks_evo": "launcher_heavy"},
	"evo_launcher_napalm": {"name": "Évo : Napalm",         "desc": "Débloque l'évolution Napalm.",             "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["explosion_dmg"],      "unlocks_evo": "launcher_napalm"},
	# --- Flamme ---
	"flame_dmg":          {"name": "Carburant enrichi",     "desc": "+20 % de dégâts.",                         "cost": 15, "cost_res": "cristal",    "max": 5, "tab": "armement",  "prereqs": []},
	"flame_fuel":         {"name": "Réservoir étendu",      "desc": "+15 % refroidissement.",                   "cost": 12, "cost_res": "cristal",    "max": 4, "tab": "armement",  "prereqs": ["flame_dmg"]},
	"flame_range_ext":    {"name": "Flamme longue portée",  "desc": "+20 % portée flamme par rang.",            "cost": 12, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["flame_dmg"]},
	"flame_burn":         {"name": "Brûlure persistante",   "desc": "Brûlure : +1 dégât/s par rang.",           "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "armement",  "prereqs": ["flame_dmg"]},
	"flame_width":        {"name": "Flamme étendue",        "desc": "+20 % angle de projection par rang.",      "cost": 12, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["flame_fuel"]},
	"flame_ignite":       {"name": "Ignition",              "desc": "Chance 20 % d'enflammer une zone.",        "cost": 20, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["flame_burn"]},
	"flame_heat_wall":    {"name": "Mur de chaleur",        "desc": "Chaleur crée un bouclier thermique.",      "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["flame_ignite"]},
	"flame_boost":        {"name": "Surcharge flamme",      "desc": "+10 % dégâts flamme supplémentaires.",    "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "armement",  "prereqs": ["flame_dmg"]},
	"flame_finale":       {"name": "Flamme maîtrisée",      "desc": "+15 % dégâts et portée.",                  "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["flame_heat_wall", "flame_burn"]},
	"evo_flame_furnace":  {"name": "Évo : Fournaise",       "desc": "Débloque l'évolution Fournaise.",          "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["flame_dmg"],          "unlocks_evo": "flame_furnace"},
	"evo_flame_range":    {"name": "Évo : Flamme Longue",   "desc": "Débloque l'évolution Flamme Longue Portée.","cost": 30, "cost_res": "cryonite",  "max": 1, "tab": "armement",  "prereqs": ["flame_range_ext"],    "unlocks_evo": "flame_range"},
	"evo_flame_torrent":  {"name": "Évo : Torrent",         "desc": "Débloque l'évolution Torrent de Feu.",     "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "armement",  "prereqs": ["flame_width"],        "unlocks_evo": "flame_torrent"},
	# ============================================================
	# ARBRE MINAGE  (60 nœuds)
	# ============================================================
	# --- Vitesse & Efficacité ---
	"mine_speed":         {"name": "Forage accéléré",       "desc": "+20 % vitesse de minage.",                 "cost": 10, "cost_res": "fer",        "max": 5, "tab": "minage",    "prereqs": []},
	"drill_speed":        {"name": "Forage intensif",       "desc": "+15 % vitesse de forage par rang.",        "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "minage",    "prereqs": ["mine_speed"]},
	"mine_burst":         {"name": "Forage en rafale",      "desc": "Forage en rafale (+30 % efficacité).",     "cost": 20, "cost_res": "cristal",    "max": 1, "tab": "minage",    "prereqs": ["drill_speed"]},
	"mine_cooldown":      {"name": "Impact fréquent",       "desc": "-10 % délai entre impacts de minage.",     "cost": 12, "cost_res": "aluminium",  "max": 2, "tab": "minage",    "prereqs": ["mine_speed"]},
	"mine_efficiency":    {"name": "Rendement d'impact",    "desc": "+5 % ressource bonus par impact.",         "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["mine_cooldown"]},
	"overcharge_mine":    {"name": "Surcharge de forage",   "desc": "+50 % dégâts minage pendant 3 s.",         "cost": 25, "cost_res": "cristal",    "max": 1, "tab": "minage",    "prereqs": ["mine_burst"]},
	"mine_momentum":      {"name": "Élan de forage",        "desc": "+5 % dégâts minage accumulé par rang.",    "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["drill_speed"]},
	"mine_overdrive":     {"name": "Forage overdrive",      "desc": "+20 % dégâts sur gisement déjà touché.",  "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "minage",    "prereqs": ["mine_momentum"]},
	"speed_mine_finale":  {"name": "Forage express",        "desc": "+25 % vitesse de minage totale.",          "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["overcharge_mine", "mine_overdrive"]},
	"mine_scan":          {"name": "Scan de gisement",      "desc": "Révèle les gisements cachés.",              "cost": 15, "cost_res": "aluminium",  "max": 1, "tab": "minage",    "prereqs": ["mine_speed"]},
	"mine_range_boost":   {"name": "Portée forage",         "desc": "+15 % portée de minage (toutes armes).",   "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["mine_scan"]},
	"mine_coolant":       {"name": "Refroidissement forage","desc": "-15 % rechargement armes de minage.",      "cost": 12, "cost_res": "cristal",    "max": 2, "tab": "minage",    "prereqs": ["mine_speed"]},
	# --- Rendement & Loot ---
	"mine_yield":         {"name": "Rendement optimisé",    "desc": "+10 % ressources par minerai.",            "cost": 10, "cost_res": "fer",        "max": 5, "tab": "minage",    "prereqs": []},
	"yield_boost":        {"name": "Veine profonde",        "desc": "+8 % ressources supplémentaires.",         "cost": 12, "cost_res": "aluminium",  "max": 3, "tab": "minage",    "prereqs": ["mine_yield"]},
	"double_vein":        {"name": "Double veine",          "desc": "10 % de chance de doubler une veine.",    "cost": 20, "cost_res": "cristal",    "max": 2, "tab": "minage",    "prereqs": ["mine_yield"]},
	"jackpot":            {"name": "Jackpot",               "desc": "5 % de chance de tripler une veine.",     "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["double_vein"]},
	"gold_rush":          {"name": "Ruée vers l'or",        "desc": "+20 % ressources des gisements d'or.",    "cost": 20, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["ore_luck"]},
	"mine_xp":            {"name": "Expérience minière",    "desc": "+5 % XP du minage par rang.",              "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["mine_yield"]},
	"vein_sense":         {"name": "Flair minier",          "desc": "Détecte les types de minerais à l'avance.","cost": 20, "cost_res": "cristal",    "max": 1, "tab": "minage",    "prereqs": ["rare_find"]},
	"loot_finale":        {"name": "Rendement maximal",     "desc": "+15 % toutes ressources minées.",          "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["jackpot", "gold_rush"]},
	"mine_legendary":     {"name": "Minerai légendaire",    "desc": "1 % chance de ressource légendaire.",      "cost": 30, "cost_res": "cryonite",   "max": 2, "tab": "minage",    "prereqs": ["loot_finale"]},
	"mine_rare_vein":     {"name": "Veine rare",            "desc": "+20 % ressources de gisements rares.",    "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "minage",    "prereqs": ["yield_boost"]},
	"rare_find":          {"name": "Prospecteur",           "desc": "+10 % chance de ressource rare.",          "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["ore_luck"]},
	# --- Spécialisation ---
	"mine_range":         {"name": "Dégâts de forage",      "desc": "+15 % dégâts de minage par rang.",         "cost": 12, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": []},
	"aoe_mine":           {"name": "Forage de zone",        "desc": "+10 % dégâts minage environnants.",        "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "minage",    "prereqs": ["mine_range"]},
	"mine_crit":          {"name": "Forage critique",       "desc": "+5 % chance critique de minage.",          "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["mine_range"]},
	"crit_mine_dmg":      {"name": "Critique minier",       "desc": "+30 % dégâts sur coup critique minage.",   "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "minage",    "prereqs": ["mine_crit"]},
	"mine_deep":          {"name": "Forage profond",        "desc": "+15 % dégâts sur gisement dur (hard).",    "cost": 15, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["mine_range"]},
	"mine_explosive":     {"name": "Forage explosif",       "desc": "Explosion lors de la destruction d'un gisement.", "cost": 25, "cost_res": "cryonite", "max": 1, "tab": "minage", "prereqs": ["aoe_mine"]},
	"mine_chain":         {"name": "Forage en chaîne",      "desc": "Minage en chaîne : détruit les voisins.",  "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_explosive"]},
	"mine_penetrate":     {"name": "Forage perforant",      "desc": "Projectiles perforent les gisements.",     "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_deep"]},
	"resonance":          {"name": "Résonance",             "desc": "+10 % dégâts minage sur gisements proches.","cost": 20, "cost_res": "cryonite",  "max": 2, "tab": "minage",    "prereqs": ["mine_penetrate"]},
	"spec_finale":        {"name": "Spécialiste minier",    "desc": "+20 % dégâts minage totaux.",              "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["resonance", "mine_chain"]},
	"mine_vortex":        {"name": "Vortex minier",         "desc": "Aspire les ressources lors d'une explosion.","cost": 20, "cost_res": "cristal",  "max": 1, "tab": "minage",    "prereqs": ["mine_explosive"]},
	"mine_impact":        {"name": "Impact renforcé",       "desc": "+10 % dégâts premiers impacts sur gisement.","cost": 12, "cost_res": "cristal",  "max": 2, "tab": "minage",    "prereqs": ["mine_range"]},
	# --- Évolutions minières ---
	"evo_blaster_excavator":{"name": "Évo : Excavateur",   "desc": "Débloque l'évolution Blaster Excavateur.", "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_speed"],    "unlocks_evo": "blaster_excavator"},
	"evo_blaster_drill":    {"name": "Évo : Foreuse",       "desc": "Débloque l'évolution Blaster Foreuse.",    "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["drill_speed"],   "unlocks_evo": "blaster_drill"},
	"evo_blaster_burst":    {"name": "Évo : Rafale minière","desc": "Débloque l'évolution Blaster Rafale.",     "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["yield_boost"],   "unlocks_evo": "blaster_burst"},
	"evo_laser_cutter":     {"name": "Évo : Laser Coupeur", "desc": "Débloque l'évolution Laser Coupeur.",      "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_range"],    "unlocks_evo": "laser_cutter"},
	"evo_laser_deep":       {"name": "Évo : Laser Perforant","desc": "Débloque l'évolution Laser Perforant.",   "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_deep"],     "unlocks_evo": "laser_deep"},
	"evo_laser_prism":      {"name": "Évo : Laser Prisme",  "desc": "Débloque l'évolution Laser Prisme.",       "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_crit"],     "unlocks_evo": "laser_prism"},
	"evo_launcher_bore":    {"name": "Évo : Lance-Foreuse", "desc": "Débloque l'évolution Lance-Foreuse.",      "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["aoe_mine"],      "unlocks_evo": "launcher_bore"},
	"evo_launcher_cluster": {"name": "Évo : Lance-Grappe",  "desc": "Débloque l'évolution Lance-Grappe.",       "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_crit"],     "unlocks_evo": "launcher_cluster"},
	"evo_launcher_salvo":   {"name": "Évo : Salve minière", "desc": "Débloque l'évolution Salve Minière.",      "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_momentum"], "unlocks_evo": "launcher_salvo"},
	"evo_flame_acid":       {"name": "Évo : Flamme Acide",  "desc": "Débloque l'évolution Flamme Acide.",       "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_speed"],    "unlocks_evo": "flame_acid"},
	"evo_flame_wide":       {"name": "Évo : Flamme Large",  "desc": "Débloque l'évolution Flamme Large.",       "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["aoe_mine"],      "unlocks_evo": "flame_wide"},
	"evo_flame_inferno":    {"name": "Évo : Inferno",       "desc": "Débloque l'évolution Inferno.",             "cost": 30, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_overdrive"],"unlocks_evo": "flame_inferno"},
	# --- Boss & Rares ---
	"ore_luck":           {"name": "Veine",                 "desc": "+15 % chance de gisement rare.",           "cost": 20, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["mine_speed"]},
	"boss_loot":          {"name": "Pillage de boss",       "desc": "+20 % ressources des boss par rang.",      "cost": 20, "cost_res": "cristal",    "max": 3, "tab": "minage",    "prereqs": ["ore_luck"]},
	"boss_weak":          {"name": "Point faible",          "desc": "Révèle les points faibles des boss.",      "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["boss_loot"]},
	"boss_speed":         {"name": "Chasseur de boss",      "desc": "+10 % dégâts aux boss par rang.",          "cost": 20, "cost_res": "cryonite",   "max": 3, "tab": "minage",    "prereqs": ["boss_weak"]},
	"noyau_find":         {"name": "Collecteur de noyaux",  "desc": "+15 % chance de noyau après boss.",        "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "minage",    "prereqs": ["boss_loot"]},
	"rare_scan":          {"name": "Scan rare",             "desc": "Révèle les gisements rares sur la carte.", "cost": 20, "cost_res": "cristal",    "max": 1, "tab": "minage",    "prereqs": ["ore_luck"]},
	"epic_vein":          {"name": "Veine épique",          "desc": "+20 % ressources des gisements épiques.",  "cost": 20, "cost_res": "cryonite",   "max": 2, "tab": "minage",    "prereqs": ["rare_scan"]},
	"legendary_magnet":   {"name": "Aimant légendaire",     "desc": "Ressources légendaires attirées de plus loin.","cost": 25, "cost_res": "cryonite","max": 1, "tab": "minage",  "prereqs": ["epic_vein"]},
	"boss_mine":          {"name": "Forage de noyaux",      "desc": "Noyaux forés donnent double ressources.",  "cost": 25, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["noyau_find"]},
	"boss_finale":        {"name": "Chasseur légendaire",   "desc": "Boss vaincu : ressources doublées 30 s.",  "cost": 35, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["boss_speed", "boss_mine"]},
	"mine_mastery":       {"name": "Minage maîtrisé",       "desc": "+15 % toutes ressources minées.",          "cost": 40, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["speed_mine_finale", "loot_finale", "spec_finale"]},
	"mine_circuit":       {"name": "Circuit minier",        "desc": "-10 % rechargement armes pendant minage.", "cost": 15, "cost_res": "cristal",    "max": 2, "tab": "minage",    "prereqs": ["mine_speed"]},
	"mine_finale":        {"name": "Expertise minière",     "desc": "+10 % toutes stats minage.",               "cost": 60, "cost_res": "cryonite",   "max": 1, "tab": "minage",    "prereqs": ["mine_mastery", "boss_finale", "mine_legendary"]},
}

