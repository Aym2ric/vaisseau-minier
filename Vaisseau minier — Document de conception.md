# Vaisseau minier — Document de conception

Nov 24, 2026 · @Aymeric

## Vision

**Vaisseau minier** est un roguelite d'action en vue de dessus : tu pilotes un petit vaisseau qui pille des planètes, tire sur tout ce qui bouge et doit décider à chaque instant s'il rentre avec son butin ou s'il tente plus loin.

**Pitch.** Pose-toi sur une planète, mine ses roches, repousse ses créatures, ramène ta cargaison au vaisseau-mère. Plus tu restes, plus tu gagnes, et plus tu risques de tout perdre.

**Piliers**

1. **Toujours en action** : le joueur se déplace, vise et tire en permanence ; aucun temps mort.
2. **Risque contre récompense** : rentrer maintenant ou continuer, à chaque secteur et à chaque extraction.
3. **Construire son vaisseau** : armes, équipement, compétences et vaisseaux donnent des styles de jeu différents.
4. **Chaque planète joue autrement** : physique, dangers et ressources propres.

| Élément | Choix |
| --- | --- |
| Genre | Roguelite d'action, tir à deux sticks (twin-stick) |
| Plateforme | PC sur Steam, manette et clavier-souris |
| Moteur | Godot 4 |
| Rendu | 2D avec relief (ombres portées, lumières 2D, parallaxe) |
| Style | Cartoon à contours épais, dans l'esprit de Brotato |
| Durée d'une run | 10 à 25 minutes |

**Références** : Brotato (rythme, montées de niveau, style), Deep Rock Galactic: Survivor (minage et tir), Nova Drift (construction du vaisseau), Tyrian et Jets'n'Guns (boutique et économie entre les missions).

## Boucle de jeu

Le joueur prépare son vaisseau, part piller une planète secteur après secteur, et choisit après chaque extraction entre rentrer avec tout ou continuer pour gagner plus.

&#91;embedded content: boucle de jeu · une run, de la base à la base\]

La seule sortie gratuite est de rentrer : une coque détruite ramène seulement 40 % de la soute exposée.

## Contrôles et pilotage

Le vaisseau se déplace librement sur tout l'écran, pivote et tire ; deux modes de pilotage au choix, validés par le prototype.

| Action | Clavier-souris | Manette |
| --- | --- | --- |
| Se déplacer | ZQSD / WASD / flèches | Stick gauche |
| Viser | Souris | Stick droit |
| Tirer | Clic maintenu (ou tir automatique) | Gâchette droite (ou tir automatique) |
| Esquive | Maj | Bouton A / Croix |
| Compétence active (ralenti) | E | Bouton Y / Triangle |
| Pause | Échap | Start |

- **Mode libre** (par défaut) : le vaisseau va où l'on pousse et pivote vers la visée.
- **Mode inertie** : pivoter et pousser, comme dans Asteroids ; plus technique, le vaisseau garde son élan.
- **Tir automatique** en option, pour se concentrer sur le déplacement et la visée.
- **Physique par planète** : frottement fort sur la Rocheuse, glisse sur la Glacée, vent sur la Gazeuse.
- Les touches sont reconfigurables ; la position physique des touches est utilisée, donc ZQSD fonctionne d'office sur un clavier AZERTY.

Réglages de référence du prototype : vitesse 215 px/s, accélération 1 250 px/s², esquive à 820 px/s avec 0,3 s d'invulnérabilité et 1,2 s de recharge.

## Une run en détail

Une run est une suite de secteurs sur une planète ; chaque secteur se termine par une extraction, et un gardien attend tous les 3 secteurs.

### Le secteur

1. **Atterrissage** : 1,5 s d'invulnérabilité, roches générées au hasard (14 de base).
2. **Minage et combat** : les roches lâchent du butin à ramasser en passant dessus (aimant), les ennemis arrivent par les bords.
3. **Menace** : elle monte avec le temps (+30 % de vitesse par secteur) ; chaque palier ajoute des ennemis et des types plus dangereux.
4. **Quota** : une quantité de ressources à ramasser (20 au secteur 1, ×1,4 par secteur ; une ressource rare compte triple).
5. **Balise d'extraction** : elle apparaît une fois le quota atteint ; rester 1,5 s dessus termine le secteur. Le joueur peut aussi continuer à miner, au prix d'une menace qui grimpe.

### Expérience et niveaux

- Roches et ennemis donnent de l'expérience (roche 1, minerai 2, roche rare 6 ; essaim 1, artilleur 4, kamikaze 3, gardien 40).
- Chaque niveau met le jeu en pause et propose **1 amélioration parmi 3**, valable jusqu'à la fin de la run.
- Améliorations générales (puissance, cadence, portée, vitesse, blindage, aimant, foreuse…) et améliorations propres à l'arme équipée.
- Seuil : 8 XP au niveau 1, ×1,3 par niveau.

### Entre deux secteurs

- **Rentrer** : toute la soute est ramenée au vaisseau-mère, fin de la run.
- **Continuer** : multiplicateur de butin +0,5 par secteur, puis choix de la route parmi 2 ou 3 secteurs : standard, filon riche, roche blindée, repaire pirate, zone instable, gardien, station marchande.
- **Station marchande** : met la moitié de la soute à l'abri et répare 30 de coque ; elle ne compte pas comme un secteur.

### Coque et fin de run

- La coque ne se répare pas toute seule entre les secteurs (sauf compétences et station).
- Coque à 0 : la run s'arrête et la capsule de secours sauve 40 % de la soute exposée (jusqu'à 76 % avec les compétences) ; la part mise à l'abri à la station est gardée entière.

## Planètes et ressources

Quatre planètes au lancement, chacune avec sa physique, sa ressource commune, sa ressource rare (à partir du secteur 3) et son gardien ; battre un gardien ouvre la planète suivante.

| Planète | Physique | Commune (prix) | Rare, secteur 3+ (prix) | Roche spéciale | Déblocage |
| --- | --- | --- | --- | --- | --- |
| Rocheuse | Sol stable | Fer (10 cr) | Titane (60 cr) | — | Dès le départ |
| Glacée | Le vaisseau glisse | Cristal (22 cr) | Cryonite (80 cr) | Glace : éclate en éclats qui blessent les ennemis | 400 cr + gardien de la Rocheuse |
| Gazeuse | Vents qui poussent | Hélium-3 (36 cr) | Plasma (100 cr) | Poche de gaz : explose (ennemis et joueur) | 900 cr + gardien de la Glacée |
| Volcanique | Sol stable | Magma (55 cr) | Obsidienne (130 cr) | Magma : laisse une mare de lave 6 s | 1 800 cr + gardien de la Gazeuse |

**Noyau de gardien** (300 cr) : lâché uniquement par les gardiens, il sert au craft des armes et de l'équipement avancé.

### Roches

| Roche | Rôle |
| --- | --- |
| Roche simple | Obstacle et couvert, un peu d'XP |
| Minerai | Butin de ressource commune |
| Minerai doré | Butin ×4 |
| Roche rare | Ressource rare (secteur 3+) |
| Roche blindée | Très résistante, donne des crédits |
| Coffre | Gros gain de crédits |
| Caisse de réparation | +12 de coque |

Les roches bloquent les tirs ennemis : elles servent de couvert.

### Information au joueur

- Chaque fiche de planète liste ses ressources et où les trouver (partout, secteur 3+, gardien).
- Une ressource jamais trouvée s'affiche « ??? » et se révèle à la première collecte.
- La carte des routes rappelle la ressource rare disponible dans le secteur suivant.

## Ennemis, événements et gardiens

Trois ennemis de base suffisent au prototype ; chaque planète devra en ajouter un ou deux qui lui sont propres.

| Ennemi | Comportement | Dégâts | Points de vie (secteur 1) | Apparaît |
| --- | --- | --- | --- | --- |
| Essaim | Fonce sur le joueur en groupe de 3, meurt au contact | 8 | 2 | Dès le début |
| Artilleur pirate | Garde ses distances et tire ; ses tirs sont bloqués par les roches | 8 par tir | 6 | Menace niveau 2 |
| Kamikaze | Vise (ligne rouge), charge, puis se repose | 14 | 5 | Menace niveau 2 |

Les points de vie augmentent de 20 % par secteur.

### Événements (toutes les 14 à 22 s)

- **Pluie de météores** : zones d'impact signalées, 15 de dégâts, laissent parfois du minerai.
- **Raid pirate** : 3 artilleurs arrivent d'un côté.
- **Filon d'or** : 3 roches dorées apparaissent.
- **Essaim** : 10 bestioles d'un coup.

Le type de secteur change leur fréquence (beaucoup de raids dans un repaire pirate, beaucoup de filons dans un filon riche).

### Gardiens

- Un gardien apparaît tous les 3 secteurs (secteurs 3, 6, 9…), dans un secteur sans quota.
- **Phase 1** : anneau de 14 tirs toutes les 2,8 s, appel de 3 bestioles toutes les 6 s.
- **Phase 2** (sous 50 % de vie) : anneau de 20 tirs toutes les 2 s, renforts toutes les 4 s, rafale visée de 5 tirs.
- Points de vie : 160 au premier gardien, +70 % par gardien suivant.
- Butin : Noyaux de gardien, ressources communes et rares ; la balise d'extraction n'apparaît qu'une fois le Noyau ramassé.
- À terme, **un gardien unique par planète** (le prototype n'a qu'un gardien générique teinté aux couleurs de la planète).

## Vaisseaux, emplacements et équipement

Le joueur commence avec un vaisseau faible et en débloque d'autres par des succès ; chaque vaisseau a ses statistiques, sa particularité et ses emplacements d'équipement.

| Vaisseau | Emplacements | Particularité | Déblocage (exemple) |
| --- | --- | --- | --- |
| Éclaireur | 1 arme, 1 module | Équilibré, faible (60 de coque) | Dès le départ |
| Foreuse | 1 arme, 2 extraction | +50 % de dégâts aux roches, lent | Récolter 500 Fer |
| Chasseur | 2 armes, 1 moteur | Rapide, coque fragile | Détruire 1 000 ennemis |
| Cargo | 1 arme, 1 armure | Soute très grande, peu armé | Rapporter une soute de 2 000 cr |
| Cuirassé | 2 armes, 2 armures | Très résistant, très lent | Vaincre 3 gardiens |

### Types d'emplacements

| Emplacement | Exemples d'équipement |
| --- | --- |
| Arme | Blaster, laser, lance-flammes, roquettes |
| Armure | Plaques de blindage, coque réactive |
| Moteur | Propulseur de course, propulseur d'esquive |
| Extraction | Tête de forage, aimant, scanner de minerai |
| Utilitaire | Bouclier, drone d'escorte, ralentisseur temporel |

- Le nombre d'armes équipées est limité par le vaisseau ; l'arbre de compétences peut ajouter des emplacements.
- La **soute** (capacité de transport pendant la run) dépend du vaisseau ; au-delà, surcharge progressive (voir Économie).
- L'équipement se change au hangar, entre les runs, jamais pendant.

## Armes

Quatre armes au comportement très différent sont validées par le prototype ; toutes sauf le blaster se fabriquent avec un Noyau de gardien.

| Arme | Comportement | Forces | Faiblesses | Recette |
| --- | --- | --- | --- | --- |
| Blaster | Tirs rapides et précis (1 dégât, 0,26 s) | Polyvalent | Dégâts faibles | Vaisseau de départ |
| Laser de forage | Rayon continu (6 dégâts/s, portée 340) | ×1,5 contre les roches, précis | Un seul ennemi à la fois | 300 cr, 1 Noyau, 6 Titane, 40 Fer |
| Lance-flammes | Cône court, enflamme (brûlure 2 s) | Foules, dégâts dans la durée | ×0,4 contre les roches, courte portée | 400 cr, 1 Noyau, 6 Cryonite, 30 Cristal |
| Lance-roquettes | Roquettes qui accélèrent et explosent (5 dégâts, rayon 70) | Zone, groupes de roches | Lent (0,9 s) | 600 cr, 2 Noyaux, 6 Plasma, 10 Titane |

### Améliorations en run propres à chaque arme

- Blaster : canon supplémentaire (+1 projectile).
- Laser : rayon traversant (+1 ennemi traversé).
- Lance-flammes : brûlure +50 %.
- Lance-roquettes : salve (+1 roquette).

### Armes à étudier ensuite

Canon à rail (tir chargé perçant), mines de proximité, arc électrique (chaîne entre ennemis), foreuse de contact (dégâts au corps à corps). Chaque nouvelle arme doit avoir un rôle que les autres n'ont pas.

## Arbre de compétences

L'arbre est la maîtrise permanente du pilote : des branches générales plus une branche par arme, qui n'améliore que cette arme ; il se réinitialise contre remboursement.

| Branche | Compétences (niveaux) | Effet |
| --- | --- | --- |
| Pilotage | Propulseurs (5) → Esquive (1) | Vitesse, esquive à Maj |
| Blaster | Calibre (3) → Double canon (1) | Dégâts, +1 projectile |
| Laser | Focalisation (3) → Rayon traversant (1) | Dégâts, +1 ennemi traversé |
| Lance-flammes | Carburant (3) → Napalm (1) | Dégâts, brûlure doublée |
| Roquettes | Ogives (3) → Charge lourde (1) | Dégâts, +40 % de rayon |
| Extraction | Foreuse (5) → Aimant (3) → Têtes de forage (1) | Butin, ramassage, ×2 aux roches |
| Survie | Blindage (6) → Capsule de secours (3) → Nanorobots (2) → Bouclier (1) | Coque, soute sauvée, réparation, bouclier |
| Exotique | Ralentisseur temporel (1) → Drone d'escorte (1) | Compétences actives |
| Hangar (à ajouter) | Emplacement d'arme, places d'inventaire, entrepôt | Capacités |

### Règles

- Les coûts montent vite (×1,6 à ×1,8 par niveau) ; les derniers niveaux demandent des ressources rares.
- Une branche d'arme peut s'acheter avant de posséder l'arme.
- **Réinitialisation** : le prototype rembourse 100 %. Pour la version finale, à décider entre gratuit et un coût en crédits.
- Objectif de durée : l'arbre complet en environ 100 runs (contre 4 runs dans le premier prototype).&#32;

## Économie, craft et inventaire

Les ressources ont trois usages en concurrence (vendre, fabriquer, améliorer), et l'objet n'est jamais perdu bêtement : il se vend, se recycle ou se range.

### Marché

- Chaque ressource a un prix de base ; vendre fait baisser le prix de 1,5 % par unité (plancher 40 % du prix de base).
- Après chaque run, les prix reviennent de 30 % vers leur base, avec une variation aléatoire de ±12 %.
- Les crédits servent aux améliorations de base et aux déblocages de planètes ; les paliers importants demandent des ressources rares.

### Craft

- Instantané, au vaisseau-mère, à partir de ressources et de crédits.
- Les recettes avancées demandent un **Noyau de gardien** : il faut battre un boss pour fabriquer.
- **Recyclage** : démonter un objet rend une partie de ses ressources (part à fixer, par exemple 50 %).

### Trois espaces de stockage

| Espace | Contenu | Capacité | Interface |
| --- | --- | --- | --- |
| Soute (pendant la run) | Ressources et objets ramassés | Selon le vaisseau | Jauge ;  surcharge jusqu'à 150 %, bouton Larguer |
| Entrepôt (vaisseau-mère) | Ressources, empilées | infinie | Liste simple par ressource |
| Inventaire d'équipement | Armes, armures, modules | Peu de places au départ, améliorable par l'arbre | Grille avec icônes, tri, filtres, glisser-déposer |

### Soute et surcharge

La soute ne bloque jamais net : au-delà de sa capacité, le vaisseau ralentit, ce qui transforme une soute pleine en décision de risque.

- Capacité par vaisseau, par exemple 100 unités pour l'Éclaireur et 300 pour le Cargo.
- Une ressource commune pèse 1 unité, une ressource rare 3, un Noyau 5 (à régler en test).
- Au-delà de 100 % : −1 % de vitesse par tranche de 2 % de surcharge.
- À 150 % : maximum atteint, plus aucun ramassage.
- Bouton **Larguer** : jette d'un coup la ressource commune la moins chère pour faire de la place.
- Compétences et modules (soute renforcée, compresseur) augmentent la capacité ou réduisent le ralentissement.

### Retour de run avec trop d'objets

Le surplus va sur un **quai de déchargement**. Il faut le vider avant la run suivante : équiper, vendre, recycler ou ranger. Aucun objet n'est détruit sans action du joueur.

## Progression et succès

La progression se gagne par la prise de risque : les crédits paient le confort, mais les paliers (planètes, armes, vaisseaux) exigent d'aller profond ou de battre des gardiens.

### Ce qui empêche le farming prudent

- Multiplicateur de butin +0,5 par secteur : le secteur 1 rapporte peu.
- Ressources rares seulement à partir du secteur 3, Noyaux seulement sur les gardiens.
- Planètes débloquées par un gardien vaincu, pas seulement par des crédits.
- Saturation du marché quand on revend toujours la même ressource.
- À étudier : un coût de lancement (carburant) par run.

### Rythme visé (à confirmer en test)

| Étape | Après environ |
| --- | --- |
| Premier gardien vaincu | 10 à 20 runs |
| Glacée débloquée, laser fabriqué | 20 à 30 runs |
| Gazeuse débloquée | 30 à 50 runs |
| Volcanique débloquée | 50 à 70 runs |
| Arbre complet | 70 à 100 runs |

### Succès Steam

Chaque vaisseau se débloque par un succès Steam (extension GodotSteam), ce qui donne une récompense concrète en jeu.

- Récolter 500 Fer → Foreuse
- Détruire 1 000 ennemis → Chasseur
- Rapporter une soute de 2 000 cr → Cargo
- Vaincre 3 gardiens → Cuirassé
- Autres succès sans récompense : atteindre le secteur 10, finir un secteur sans dégâts, découvrir toutes les ressources.

## Direction artistique et audio

Style cartoon à la Brotato en 2D avec relief : lisible même quand l'écran est chargé, et peu coûteux à produire.

### Règles visuelles

- **Contours noirs épais** sur tout ce qui est jouable.
- **Aplats** avec une seule ombre et un petit reflet blanc ; pas de dégradés complexes.
- **Une couleur dominante par planète** : ocre (Rocheuse), bleu (Glacée), violet (Gazeuse), rouge (Volcanique).
- **Relief** : ombres portées sous chaque élément, lumières 2D de Godot sur les tirs et les explosions, décor en parallaxe.
- **Lisibilité** : tirs ennemis rouges et ronds, butin en losanges qui tournent, dangers signalés avant d'arriver (lignes rouges, cercles d'impact).
- **Personnalité** : ennemis avec des yeux et des expressions (pirates à cache-œil, bestioles grognonnes).
- Interface : panneaux arrondis brun foncé à bord noir épais ; polices Lilita One (titres) et Nunito (texte).

### Sensations de jeu (« juice »)

Tremblement d'écran, petit arrêt sur image aux gros impacts, roches qui se fissurent puis éclatent en débris, chiffres de gain qui sautent, vaisseau qui s'écrase légèrement à l'esquive.

### Audio (à définir)

- Un son court et distinct par arme, par type d'impact et par ramassage.
- Une musique par planète, qui s'intensifie avec le niveau de menace.
- Un thème de gardien.

## Plan de production

On construit dans Godot dans cet ordre, en validant chaque jalon en jouant avant de passer au suivant ; la démo Steam arrive au jalon 5.

1. **Cœur de jeu** : vaisseau, deux modes de pilotage, blaster, roches, butin, 3 ennemis, menace, balise, une planète. Critère : aussi amusant que le prototype.
2. **Structure de run** : secteurs, carte des routes, station, coque, XP et montées de niveau, retour au vaisseau-mère, sauvegarde.
3. **Contenu de base** : 4 planètes, ressources rares, premier gardien, 4 armes, arbre de compétences avec réinitialisation.
4. **Vaisseau-mère complet** : emplacements d'équipement, craft, recyclage, entrepôt, inventaire en grille, quai de déchargement.
5. **Démo Steam** : direction artistique finale sur la Rocheuse, sons, menus, page Steam ouverte pour les listes de souhaits.
6. **Vaisseaux et succès** : 5 vaisseaux, succès Steam, gardiens uniques par planète.
7. **Accès anticipé** : équilibrage, traductions, options d'accessibilité.

### Questions ouvertes

- Réinitialisation de l'arbre : gratuite
- Part rendue par le recyclage 25 %
- Capacité de soute de chaque vaisseau, et ce qui se passe au-delà : surcharge progressive (décidé, voir Économie) ; capacités exactes à régler en test
- Butin d'équipement aléatoire pendant les runs, en plus du craft : non pas pour le moment
- Coût de lancement (carburant) par run : non
- Nombre maximum d'armes équipées, et emplacements ajoutés par l'arbre.

### Maquette graphique
Actuellement 2 pistes a réfléchir :
- maquette v1.png
- maquette v2.png