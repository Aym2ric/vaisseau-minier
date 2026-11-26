# Vaisseau minier — Game Design Document V4

**Version de conception — 26 novembre 2026**  
**Plateforme cible : PC / Steam · Moteur : Godot 4**

Ce document consolide les décisions de conception. Les valeurs chiffrées proposées ne constituent pas un équilibrage définitif. Le catalogue de contenu reste à construire.

## 1. Vision

Roguelite d'action en vue de dessus mêlant combat, exploration, minage et extraction. Le joueur pilote un vaisseau, explore des planètes hostiles, développe son build pendant chaque expédition et rapporte des ressources pour améliorer définitivement ses possibilités.

**Pitch :** explore, mine, combats et extrais-toi avant que la menace ne devienne insurmontable.

Piliers : action continue, risque contre récompense, liberté de préparation, progression permanente gratifiante et exploration renouvelée. La particularité centrale est le minage à l'arrêt, qui expose le joueur aux ennemis.

## 2. Boucle de jeu

1. Depuis le vaisseau-mère, choisir un objectif de progression, une planète, une difficulté et un équipement.
2. Atterrir sur une carte procédurale et découvrir la mission.
3. Explorer, miner, combattre, récupérer le butin et améliorer temporairement le build.
4. Accomplir la mission pour autoriser l'extraction.
5. Choisir de prolonger l'expédition ou de s'extraire.
6. Consulter le bilan, sécuriser les ressources récupérées et acheter des compétences.
7. Préparer une nouvelle expédition.

Une expédition vise environ 30 à 35 minutes, sans limite de temps stricte. La menace croissante encourage naturellement le départ. Les secteurs successifs de la conception initiale sont abandonnés.

## 3. Carte et exploration

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
| Mur friable | Bloqué | Bloqué | Armes, minage, certains ennemis et boss |
| Gisement | Bloqué | Bloqué | Minage jusqu’à épuisement |
| Danger environnemental | Libre | Libre | Selon événement |

Le minage est plus efficace que les armes sur les murs friables. Les ennemis respectent les mêmes règles de déplacement ; pas d’exceptions de collision selon les armes. Les objectifs obligatoires doivent rester accessibles. Les dimensions et densités sont des paramètres à tester, pas des constantes validées.

## 4. Combat et minage

### Combat

Le système hybride de visée manuelle et automatique est déjà présent dans le prototype selon le développeur. Le joueur peut combattre tout en minant. Le détail des commandes et la question des munitions restent à formaliser.

### Minage

- Le minage démarre automatiquement lorsque le vaisseau est immobile et qu'un gisement est à portée.
- L'outil cible le gisement le plus proche, puis passe au suivant lorsqu'il est épuisé.
- Tout déplacement interrompt immédiatement le minage.
- Tout minerai est minable avec n'importe quel outil, même lentement. Aucun seuil de puissance obligatoire.
- Les gisements sont épuisables ; les événements peuvent en faire apparaître de nouveaux.
- Aucune limite de cargaison ni pénalité de déplacement liée au poids.

### Butin

Les minerais, l'expérience, les kits de réparation et les récompenses de boss apparaissent physiquement au sol. Ils sont récupérés automatiquement à proximité. Le rayon de ramassage est améliorable via Logistique, modules et bonus temporaires. Tout le butin persiste jusqu'à la fin de l'expédition. Le regroupement d'objets proches est prévu pour limiter le coût technique.

## 5. Missions et extraction

La mission est découverte après l'atterrissage. Elle provient de modèles conçus à l'avance avec paramètres variables. Sa complexité dépend de la planète et de la difficulté. Durée cible indicative : 3 à 8 minutes. Aucun quota de minerais.

Exemples : explorer des points d'intérêt, éliminer une cible, détruire des nids, récupérer des composants, activer ou défendre une installation, scanner des anomalies.

Une mission réussie autorise l'extraction, mais ne termine pas la run. Le joueur peut continuer à explorer librement.

### Extraction

Le joueur déclenche volontairement l'extraction depuis n'importe quel emplacement après réussite de la mission. Il doit rester immobile pendant X secondes (10 secondes proposées). Un déplacement ou dash annule le processus ; une nouvelle tentative repart de zéro. Tirer, miner et subir des dégâts n'interrompent pas le processus selon les règles proposées. La mort met fin à l'expédition. Une extraction réussie sécurise le butin ramassé. La durée pourrait être réduite via Navigation.

### Échec

La destruction du vaisseau entraîne la perte des ressources non sécurisées. Une compétence Logistique permet de conserver une proportion de chaque ressource ; sans compétence, aucune récupération. Plafond indicatif : 25 %, à équilibrer. Aucun coffre sécurisé.

## 6. Menace, ennemis et boss

La menace augmente uniquement avec le temps passé sur la carte, sans plafond prévu. Miner, combattre et accomplir la mission ne l'augmentent pas directement.

La difficulté se traduit par le nombre, la diversité et la puissance des ennemis, puis l'apparition d'élites et de boss à mesure que la menace monte. Les seuils et courbes restent à définir.

Population initiale de groupes, nids et gardiens, complétée par des apparitions dynamiques hors écran autour du joueur. Les ennemis standards et élites éloignés sont recyclés hors écran près du joueur, sans soin, XP, butin ni création d’une nouvelle entité. Les gardiens, cibles de mission et boss sont exclus du recyclage selon la règle proposée. Voir features/08-menace.md et features/22-ennemis.md.

Les boss peuvent également apparaître lors d'événements planétaires, indépendamment de la menace. Ils sont facultatifs, sauf lorsqu'ils constituent l'objectif de mission.

Les ennemis standards et élites fournissent de l'expérience et des récompenses temporaires. Les boss fournissent également des ressources permanentes exclusives. Les modalités exactes des récompenses et kits de réparation restent à préciser.

## 7. Événements planétaires

Des fenêtres temporelles garantissent des événements, dont la nature, la localisation et le moment exact sont aléatoires. Le HUD annonce les événements à l'avance. La rareté potentielle des ressources augmente avec le temps.

Familles envisagées : géologique (séisme, météorite), biologique (boss, invasion), environnementale (tempête, éruption), technologique (bonus temporaire). Les ressources permanentes proviennent du minage et des boss. Les récompenses de missions et épaves restent à préciser ; proposition : XP, bonus temporaires ou révélation de gisements, sans troisième filière permanente.

Fenêtres indicatives : 3–6, 7–10, 12–15, 17–20 et 22–25 minutes. La fréquence après 25 minutes et les probabilités restent à équilibrer. Les événements permettent de renouveler les gisements sans rendre la carte infinie.

## 8. Planètes et difficultés

Chaque planète possède des ressources communes avec des fréquences différentes, des ressources exclusives, ses propres ennemis, événements et dangers environnementaux. Des modules peuvent contrer ces dangers, sans jamais être obligatoires pour accéder à une planète.

Les planètes se débloquent via les ressources dépensées dans l'arbre Navigation. La progression est ramifiée, non linéaire. Le joueur choisit les branches selon ses besoins.

Toutes les ressources disponibles et leurs fréquences sont visibles avant le départ. Depuis une compétence, le joueur peut identifier les planètes fournissant ses ressources nécessaires.

Chaque planète dispose de difficultés sélectionnables, débloquées indépendamment : une extraction réussie ouvre la suivante sur cette planète. Les difficultés modifient la progression de la menace, les ennemis, le rendement, les probabilités de ressources rares et les apparitions d'élites et boss. Cinq difficultés par planète ; noms et multiplicateurs à définir.

## 9. Équipements et préparation

Chaque vaisseau possède un emplacement d'arme, un outil de minage, une capacité active et des emplacements de modules. Les équipements débloqués sont interchangeables entre vaisseaux. La capacité active n'est pas liée au vaisseau ; le dash est disponible initialement.

En V1, les vaisseaux se distinguent uniquement par leurs statistiques de base, sans passif exclusif. Le joueur commence avec un emplacement de module et en débloque d'autres via Logistique (maximum de quatre validé). Un module ne peut être équipé qu'une seule fois.

Familles de modules envisagées : ramassage, défense, scanner, automatisation, énergie, protection environnementale. Le bouclier n'est pas présent par défaut : il nécessite un module ou une compétence.

Les presets sont disponibles dès le début : création, nommage, modification, duplication et suppression de configurations.

## 10. Progression temporaire

Une expérience commune est gagnée par le minage, le combat et la réussite des missions. Chaque montée de niveau propose trois améliorations aléatoires compatibles avec l'équipement et le build. Les améliorations sont perdues à la fin de l'expédition.

Les améliorations statistiques classiques sont cumulables sans limite de rang ; celles qui modifient les mécaniques possèdent des plafonds individuels. Les limites techniques et statistiques effectives restent à définir.

Les armes et outils de minage possèdent des améliorations spécifiques et des évolutions. Après suffisamment d'améliorations liées à un équipement, le joueur choisit directement une évolution préalablement débloquée dans les arbres, sans combinaison aléatoire imposée. Les modules équipés alimentent également le tirage, mais n'évoluent pas en V1.

Les arbres peuvent enrichir le catalogue des améliorations temporaires. Les raretés, le rythme de niveaux (environ 40 niveaux en 30 minutes proposés), les seuils d'évolution et les éventuelles relances, exclusions ou réservations de choix restent à formaliser.

## 11. Progression permanente et économie

Toute la progression permanente passe par quatre arbres ramifiés, avec prérequis et coûts en ressources. Aucun point de compétence, niveau global obligatoire, système de fabrication, monnaie universelle ou niveau permanent propre aux équipements. Un équipement débloqué est immédiatement utilisable.

| Arbre | Rôle principal |
|---|---|
| Armement | Armes, dégâts, cadence, projectiles, évolutions offensives |
| Minage | Outils, puissance, portée, rendement, évolutions de minage |
| Navigation | Planètes, vaisseaux, mobilité, exploration, extraction |
| Logistique | Modules, emplacements, défense, ramassage, récupération après décès |

Les arbres combinent bonus statistiques à plusieurs rangs et déblocages uniques. Tous sont intégralement complétables, sans spécialisation irréversible. Les coûts augmentent avec la progression. Les ressources communes servent à plusieurs arbres ; les ressources rares, exclusives et de boss répondent à des besoins spécifiques.

Pas de statistique globale de chance : des bonus de probabilité ciblés peuvent améliorer certains tirages ou récompenses. Le rendement minéral peut être augmenté directement.

## 12. Statistiques et défense

Référentiel envisagé : dégâts, cadence, portée, vitesse des projectiles, critique, perforation, nombre de projectiles ; puissance, portée et rendement de minage ; vitesse, accélération, rayon de découverte, durée d'extraction ; intégrité, armure, régénération, bouclier et recharge, rayon de ramassage, récupération après décès ; gain d'expérience et recharge de capacité active.

Le bouclier est optionnel. L'intégrité ne se régénère pas naturellement selon la proposition initiale ; des compétences ou modules peuvent permettre la régénération. Les sources exactes de soin et les formules de cumul restent à valider.

## 13. Vaisseau-mère et interfaces

Le hub est une interface de menus, sans déplacement physique en V1. Organisation proposée : Navigation (planètes et difficultés), Hangar (équipements et presets), Recherche (arbres), Entrepôt (ressources), Archives (statistiques et historique), Paramètres.

Le joueur peut épingler plusieurs compétences à débloquer. Le bilan affiche les ressources acquises et manquantes pour ces objectifs.

Le bilan de fin de run présente le résultat, la durée, la mission, la menace, le niveau temporaire, les éliminations, le minage, l'exploration, le butin sécurisé ou perdu et le build final. Des statistiques cumulées et records personnels sont conservés, avec détails par planète, difficulté et équipement. L'historique conserve les bilans et builds ; sa limite éventuelle reste à définir.

## 14. Sauvegarde

Une seule sauvegarde d'expédition active, créée par « Sauvegarder et quitter ». La reprise restaure l'état exact : carte, murs détruits, gisements, butin, ennemis, mission, événements, temps, menace, vaisseau, cargaison et build temporaire. La sauvegarde est consommée à la reprise pour éviter les rechargements répétés. Pas de récupération automatique après crash en V1 ; la progression permanente déjà acquise doit être préservée.

## 15. Histoire et complétion

Une planète finale représente la conclusion de l'histoire. Sa mission et son extraction réussie marquent la fin narrative, sans empêcher de continuer à jouer. Les conditions exactes de déblocage restent à définir.

La complétion à 100 % relève des succès Steam : arbres complétés, équipements et planètes débloqués, difficultés réussies, boss et autres défis. La liste définitive reste à concevoir. Les découvertes narratives facultatives, journaux et vestiges ne sont pas prioritaires en V1.

## 16. Suite de la conception

1. Catalogue des ressources et raretés.
2. Planètes, biomes et distribution des ressources.
3. Vaisseaux et statistiques de base.
4. Armes, outils de minage et évolutions.
5. Capacités actives et modules.
6. Ennemis, élites et boss.
7. Missions et événements.
8. Contenu et coûts des quatre arbres.
9. Courbes de menace, expérience, difficulté et économie.
10. Interfaces, sauvegarde, performances et intégration Steam.

## 17. Points ouverts et périmètre

Les quantités de contenu ci-dessous sont validées ; les noms, comportements détaillés et coûts restent des propositions. Les valeurs de durée, coûts, probabilités, plafonds, dégâts et rendements doivent être testées. Les règles détaillées de soin, de tirage, de cumul statistique et de récompenses restent à préciser. Le document décrit la cible de conception, pas l'état d'implémentation complet du prototype. Aucun audit du code Godot n'a été réalisé.

## 18. Décisions complémentaires validées

- 8 planètes : rocheuse, désertique → volcanique, glaciaire → cristalline, organique → radioactive, puis finale. Trois branches depuis la rocheuse.
- 5 difficultés par planète ; 40 couples planète/difficulté.
- 57 ressources : 17 partagées, 16 exclusives planétaires (2 par planète), 24 exclusives de boss. 5 raretés.
- 6 vaisseaux : polyvalent, mobile, mineur, offensif, résistant, collecteur.
- 10 armes et 30 évolutions ; 6 outils et 18 évolutions ; 8 capacités actives sans évolution ; 16 modules sans évolution, 1 à 4 emplacements.
- 10 archétypes ennemis partagés, 2 exclusifs par planète, 8 modificateurs élite, 3 boss par planète.
- Missions principales potentiellement multi-objectifs et missions secondaires facultatives. Événements temporaires ou permanents.
- 60 nœuds par arbre, 240 au total ; environ 10 rangs par nœud statistique ; objectif 80–120 h de complétion.
- Progression permanente prononcée, sans adaptation automatique des ennemis au joueur. Hypothèses : dégâts et vitesse de minage ×5, rendement ×3 à progression maximale.
- Les catalogues de dix missions et dix événements sont des propositions, non des quotas définitifs.

Voir CONTENT.md pour le catalogue de travail et ROADMAP.md pour les jalons. Les spécifications par fonctionnalité complètent ce document. En cas de conflit, une décision validée prime sur une proposition.
