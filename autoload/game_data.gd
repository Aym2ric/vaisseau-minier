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
	# Arbre Navigation
	"dash":          {"name": "Esquive",             "desc": "Débloque l'esquive.",               "cost": 20, "cost_res": "fer",       "max": 1, "tab": "navigation", "prereqs": []},
	"thrust":        {"name": "Propulseurs",          "desc": "+8 % de vitesse.",                  "cost": 10, "cost_res": "fer",       "max": 5, "tab": "navigation", "prereqs": []},
	"extract_boost": {"name": "Turbine d'extraction", "desc": "-15 % temps d'extraction par rang.",  "cost": 12, "cost_res": "aluminium", "max": 3, "tab": "navigation", "prereqs": []},
	"threat_slow":   {"name": "Furtivité",            "desc": "-12 % taux de menace par rang.",      "cost": 20, "cost_res": "aluminium", "max": 3, "tab": "navigation", "prereqs": ["thrust"]},
	"nav_glace":     {"name": "Cap Glaciaire",         "desc": "Débloque la planète Glacée.",         "cost": 25, "cost_res": "fer",       "max": 1, "tab": "navigation", "prereqs": ["thrust"], "unlocks_planet": "glace"},
	"nav_volcan":    {"name": "Cap Volcanique",        "desc": "Débloque la planète Volcanique.",     "cost": 20, "cost_res": "titane",    "max": 1, "tab": "navigation", "prereqs": ["nav_glace"], "unlocks_planet": "volcan"},
	"nav_gaz":       {"name": "Cap Gazeux",            "desc": "Débloque la planète Gazeuse.",        "cost": 20, "cost_res": "cryonite",  "max": 1, "tab": "navigation", "prereqs": ["nav_glace"], "unlocks_planet": "gaz"},
	"nav_desert":    {"name": "Cap Désertique",        "desc": "Débloque la planète Désertique.",     "cost": 25, "cost_res": "fer",       "max": 1, "tab": "navigation", "prereqs": ["thrust"], "unlocks_planet": "desert"},
	"nav_cristal":   {"name": "Cap Cristallin",        "desc": "Débloque la planète Cristalline.",    "cost": 30, "cost_res": "tungstene", "max": 1, "tab": "navigation", "prereqs": ["nav_desert"], "unlocks_planet": "cristalline"},
	"nav_organique": {"name": "Cap Organique",         "desc": "Débloque la planète Organique.",      "cost": 25, "cost_res": "cryonite",  "max": 1, "tab": "navigation", "prereqs": ["nav_glace"], "unlocks_planet": "organique"},
	"nav_radio":     {"name": "Cap Radioactif",        "desc": "Débloque la planète Radioactive.",    "cost": 35, "cost_res": "uranium",   "max": 1, "tab": "navigation", "prereqs": ["nav_organique"], "unlocks_planet": "radioactive"},
	# Arbre Logistique
	"hull":          {"name": "Blindage",             "desc": "+15 PV max.",                       "cost": 15, "cost_res": "fer",       "max": 5, "tab": "logistique", "prereqs": []},
	"magnet":        {"name": "Aimant",               "desc": "+30 % de portée.",                  "cost": 8,  "cost_res": "fer",       "max": 5, "tab": "logistique", "prereqs": []},
	"insure":        {"name": "Récupération",         "desc": "+12 % cargo sauvé à mort.",         "cost": 15, "cost_res": "titane",    "max": 3, "tab": "logistique", "prereqs": ["hull"]},
	"xp_boost":      {"name": "Capteurs avancés",     "desc": "+10 % XP gagné par rang.",          "cost": 10, "cost_res": "aluminium", "max": 3, "tab": "logistique", "prereqs": []},
	"repair_nano":   {"name": "Nanorobots",           "desc": "Régénère 0,5 PV/s en run par rang.","cost": 25, "cost_res": "platine",   "max": 3, "tab": "logistique", "prereqs": ["hull"]},
	"pickup_xp":     {"name": "Analyseur de minerai", "desc": "+1 XP par ressource ramassée.",     "cost": 15, "cost_res": "cristal",   "max": 3, "tab": "logistique", "prereqs": []},
	# Arbre Armement
	"reroll":           {"name": "Reconfigurateur",    "desc": "+1 actualisation/run.",              "cost": 15, "cost_res": "cristal",   "max": 3, "tab": "armement", "prereqs": []},
	"fire_rate_perm":   {"name": "Module de cadence",  "desc": "-8 % rechargement toutes armes.",   "cost": 15, "cost_res": "cristal",   "max": 3, "tab": "armement", "prereqs": []},
	"blaster_dmg":      {"name": "Calibre",            "desc": "+20 % de dégâts.",                  "cost": 15, "cost_res": "cristal",   "max": 5, "tab": "armement", "prereqs": []},
	"blaster_multi":    {"name": "Double canon",       "desc": "+1 projectile.",                    "cost": 20, "cost_res": "cristal",   "max": 3, "tab": "armement", "prereqs": ["blaster_dmg"]},
	"laser_dmg":        {"name": "Laser surpuissant",  "desc": "+20 % de dégâts/s.",               "cost": 15, "cost_res": "cristal",   "max": 5, "tab": "armement", "prereqs": []},
	"laser_cool":       {"name": "Dissipateur",        "desc": "+15 % refroidissement.",            "cost": 12, "cost_res": "cristal",   "max": 4, "tab": "armement", "prereqs": ["laser_dmg"]},
	"launcher_dmg":     {"name": "Ogive renforcée",    "desc": "+20 % de dégâts.",                  "cost": 15, "cost_res": "cristal",   "max": 5, "tab": "armement", "prereqs": []},
	"explosion_dmg":    {"name": "Ogive avancée",      "desc": "+20 % dégâts d'explosion.",         "cost": 15, "cost_res": "tungstene", "max": 3, "tab": "armement", "prereqs": ["launcher_dmg"]},
	"flame_dmg":        {"name": "Carburant enrichi",  "desc": "+20 % de dégâts.",                  "cost": 15, "cost_res": "cristal",   "max": 5, "tab": "armement", "prereqs": []},
	"flame_fuel":       {"name": "Réservoir étendu",   "desc": "+15 % refroidissement.",            "cost": 12, "cost_res": "cristal",   "max": 4, "tab": "armement", "prereqs": ["flame_dmg"]},
	# Arbre Minage
	"mine_speed":    {"name": "Forage accéléré",    "desc": "+20 % vitesse de minage.",         "cost": 10, "cost_res": "fer",       "max": 5, "tab": "minage", "prereqs": []},
	"mine_yield":    {"name": "Rendement optimisé", "desc": "+10 % ressources par minerai.",    "cost": 10, "cost_res": "fer",       "max": 5, "tab": "minage", "prereqs": []},
	"mine_range":    {"name": "Forage intensif",    "desc": "+15 % dégâts de minage par rang.", "cost": 12, "cost_res": "cristal",   "max": 3, "tab": "minage", "prereqs": []},
	"ore_luck":      {"name": "Veine",              "desc": "+15 % chance de gisement rare.",   "cost": 20, "cost_res": "cristal",   "max": 3, "tab": "minage", "prereqs": ["mine_speed"]},
}
