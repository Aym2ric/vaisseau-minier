# Carte procédurale et terrain — V4

### Décisions validées
- Très grande carte finie, procédurale, hybride : grandes plaines, formations rocheuses, passages et raccourcis. Densité propre à chaque planète.
- Aucun brouillard de guerre ni mémorisation des zones explorées. Minimap reportée. Le terrain est visible dans le champ de la caméra.
- Frontières naturelles propres à chaque planète, indestructibles.
- Points d’intérêt découverts naturellement ou détectés par scanner et compétences, y compris hors écran.
- Gisements isolés, concentrations régionales, filons cachés derrière des murs friables, gisements de points d’intérêt et événements. Aucun renouvellement naturel ; seuls les événements ajoutent des gisements.
- Vaisseau à basse altitude sans mécanique d’altitude. Décors plats franchissables ; obstacles volumineux bloquants ; fissures signalant les murs friables ; cristaux signalant les gisements.

| Terrain | Déplacement | Projectile | Destruction |
|---|---|---|---|
| Décor | Libre | Libre | Non nécessaire |
| Mur permanent / frontière | Bloqué | Bloqué | Non |
| Mur friable | Bloqué | Bloqué | Arme équipée, certains ennemis et boss |
| Gisement | Bloqué | Bloqué | Minage jusqu’à épuisement |
| Danger environnemental | Libre | Libre | Selon événement |

Les armes détruisent les murs friables ; leur efficacité reste à équilibrer. Les ennemis respectent les mêmes règles de déplacement ; pas d’exceptions de collision selon les armes. Les objectifs obligatoires doivent rester accessibles. Les dimensions et densités sont des paramètres à tester, pas des constantes validées.

## Génération proposée

1. Initialiser une seed de carte indépendante du RNG de combat.
2. Construire la frontière naturelle et réserver une zone de départ ouverte.
3. Distribuer des régions ouvertes et des amas rocheux via bruit spatial ou formes polygonales. Réserver de larges passages et des espaces de combat.
4. Placer les points d’intérêt à partir de modèles avec empreintes et marges de sécurité : nid, épave, installation, cratère, filon caché.
5. Distribuer les gisements isolés et les concentrations selon les poids de la planète ; ne pas créer de chevauchements bloquants.
6. Placer les objectifs obligatoires dans des zones accessibles, puis les groupes initiaux d’ennemis.
7. Vérifier la connectivité avec une grille tenant compte du rayon du vaisseau. Les objectifs obligatoires doivent être accessibles sans destruction ; les filons facultatifs peuvent nécessiter un raccourci miné. Réparer les passages ou régénérer avec un nombre borné de tentatives.

### Paramètres de départ (propositions)

| Paramètre | Valeur de test |
|---|---|
| Dimensions | 12 000 × 12 000 px |
| Vaisseau | 48 px |
| Vitesse | 250 px/s |
| Surface libre rocheuse | 80 % |
| Murs permanents | 12 % |
| Murs friables | 8 % |
| Chunk | 1024 × 1024 px |

La traversée directe théorique dure 48 s sans obstacle. Ajuster la taille et la densité après des runs réelles ; la grande carte ne doit pas être vide. Les proportions excluent ici les gisements supplémentaires : mesurer la surface libre finale.

## Architecture Godot proposée

- `MapGenerator` produit les données de terrain ; `PlanetDefinition` porte les paramètres ; `ChunkManager` matérialise les chunks utiles ; `TerrainState` conserve les modifications.
- TileMapLayer pour le sol et les décors ; collisions statiques pour obstacles ; entités destructibles avec identifiant stable, PV et empreinte.
- Chunks : générer d’abord les données globales et la connectivité ; instancier progressivement les visuels et collisions autour du joueur. Précharger une marge suffisante pour éviter les collisions manquantes à grande vitesse. Ne jamais régénérer un chunk modifié depuis sa seed seule.
- Navigation : commencer par une grille grossière partagée et des contournements locaux, sans recalcul complet par ennemi à chaque frame. Mettre à jour la zone touchée lors d’une destruction.
- Destruction : appliquer les dégâts, retirer collision et visuel bloquant une seule fois à zéro PV, mettre à jour navigation et état sauvegardé. Pas de récompense de minerai pour un mur friable ordinaire sauf décision ultérieure.
- Gisement : état distinct des murs ; les tirs sont arrêtés et infligent des dégâts miniers. Les murs friables sont destructibles par les tirs ; leur ciblage automatique reste à décider.
- Scanner : signal directionnel hors écran proposé, sans minimap ni voile. Les missions doivent rester réalisables sans scanner.

## Exemples

- Un filon rare est derrière une paroi fissurée : le joueur s’arrête pour miner la paroi, ouvre un passage, exploite le filon puis repart.
- Un boss détruit un mur friable pendant la poursuite ; les deux camps peuvent emprunter le nouveau passage. La frontière reste intacte.
- Une région épuisée reste vide après un aller-retour ; une météorite peut créer un nouveau dépôt distinct.

## Critères d’acceptation et tests

- Tester au moins 100 seeds en automatisation (objectif proposé) : départ libre, objectifs accessibles, frontières fermées, absence de chevauchements invalides.
- Vérifier tirs alliés et ennemis contre chaque catégorie de terrain ; aucun passage de projectile par un mur intact.
- Détruire un mur simultanément avec deux sources : une seule transition, aucune collision résiduelle.
- Quitter puis revenir dans un chunk : murs détruits et gisements épuisés restent absents.
- Sauvegarder/reprendre : mêmes positions, PV, gisements, événements et terrain modifié.
- Tester le déplacement rapide aux limites des chunks et de la carte ; aucun passage hors carte.
- Tester une run de 35 minutes avec hordes, destruction et butin ; profiler temps CPU/physique et mémoire. Aucun objectif FPS garanti avant mesure.
