# Vaisseau minier — projet Godot

Jalon 1 du plan de production : **le cœur de jeu**. Un vaisseau qui se déplace librement, vise et tire, sur la planète Rocheuse, avec des roches à miner, du butin à ramasser, trois ennemis, une menace qui monte et une balise d'extraction. Les secteurs s'enchaînent : rentrer avec la soute, ou continuer plus loin.

## Ouvrir le projet

1. Installe **Godot 4** (version standard, pas besoin de .NET), idéalement 4.7 ou plus récent.
2. Dans le gestionnaire de projets : **Importer**, puis choisis le fichier `project.godot` de ce dossier.
3. Lance avec **F5**.

> Ce code n'a pas encore été exécuté dans Godot : sa syntaxe a été vérifiée avec un analyseur GDScript, mais pas son fonctionnement. Si Godot signale une erreur à l'ouverture, copie le message, il sera rapide à corriger.

## Contrôles

| Action | Clavier-souris | Manette |
| --- | --- | --- |
| Se déplacer | ZQSD (AZERTY) / WASD (QWERTY) / flèches | Stick gauche |
| Viser | Souris | Stick droit |
| Tirer | Clic gauche ou Espace | Gâchette droite |
| Esquive (si la compétence est acquise) | Maj | A / Croix |
| Pause | Échap | Start |

Les touches suivent la **position physique** du clavier : ZQSD fonctionne directement sur un clavier AZERTY.
Le mode de pilotage « inertie » et le tir automatique se règlent dans `SaveGame.data["options"]` (menu d'options au jalon 2).

## Structure

```
autoload/                 Singletons chargés au démarrage
  game_data.gd            Toutes les valeurs de jeu (CONFIG, planètes, ressources, roches, ennemis, armes)
  save_game.gd            Sauvegarde JSON persistante (user://save.json)
  run_state.gd            État de la run : secteur, coque, soute, quota, menace ; fin de run
  input_setup.gd          Actions d'entrée (clavier physique + manette)
scenes/
  main.tscn / main.gd     Point d'entrée : enchaîne les secteurs, panneaux de choix, pause
  sector/sector.gd        Un secteur : roches, ennemis, vagues, événements, balise d'extraction
  ship/ship.gd            Vaisseau du joueur (CharacterBody2D) : pilotage libre ou inertie, esquive
  weapons/weapon.gd       Classe de base des armes
  weapons/blaster.gd      Blaster (les autres armes hériteront de Weapon)
  weapons/bullet.gd       Projectile du joueur
  enemies/enemy.gd        Classe de base des ennemis (Area2D)
  enemies/mite.gd         Essaim
  enemies/gunner.gd       Artilleur pirate
  enemies/rammer.gd       Kamikaze
  enemies/enemy_bullet.gd Tir ennemi
  world/rock.gd           Roche destructible (StaticBody2D, sert de couvert)
  world/pickup.gd         Butin à ramasser (attiré par l'aimant)
  ui/hud.gd               Interface : barre d'état, quota, annonces, panneaux
scripts/
  draw_utils.gd           Dessin cartoon (aplats + contour noir épais)
  float_text.gd           Chiffres de gain
  burst.gd                Effets d'impact
```

**Couches de collision** : 1 joueur, 2 roches, 3 ennemis, 4 murs.

**Graphismes provisoires** : tout est dessiné par code (`_draw`) dans le style de la maquette. Quand les sprites définitifs arriveront, chaque élément pourra devenir une scène `.tscn` avec un `Sprite2D`, sans toucher à la logique.

## Réglages

Tous les chiffres du rythme sont dans `autoload/game_data.gd`, bloc `CONFIG` (vitesse, menace, quotas, multiplicateur, extraction…), avec les mêmes valeurs que le prototype validé.

## Prochaines étapes (jalon 2 : structure de run)

- Vaisseau-mère (hub) : choix de la planète, marché, arbre de compétences, journal.
- Carte des routes entre les secteurs (types de secteurs, station marchande).
- Expérience et montées de niveau (1 amélioration parmi 3) : les valeurs d'XP sont déjà dans `GameData.ROCKS` et `GameData.ENEMIES`.
- Soute avec surcharge progressive.
- Puis jalon 3 : 4 planètes, ressources rares, gardien, laser / lance-flammes / roquettes.
# vaisseau-minier


cd /mnt/c/Users/Aym2ric/Desktop/vaisseau-minier-godot/vaisseau-minier
