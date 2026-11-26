# Planètes et difficultés

## Statut et objectif
**Socle validé / à préserver :** 8 planètes, 5 difficultés indépendantes, 3 branches, ressources visibles.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V4.md et ../CONTENT.md.

## Fonctionnement proposé
Définir profils et prérequis ; extraction réussie ouvre difficulté suivante.

## Exemple concret
Réussir rocheuse II ouvre rocheuse III, pas désertique III.

## Contrat technique proposé
- Responsabilités : `PlanetDefinition, DifficultyDefinition`.
- Données à modéliser : `planet_id, pools, hazards, unlocked_difficulty`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Pas de déblocage par mort ; modules environnementaux jamais obligatoires.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Frontières naturelles et densité de terrain propres à chaque planète. Surfaces libres indicatives : rocheuse 80 %, désertique 90 %, glaciaire 75 %, volcanique 70 %, cristalline 65 %, organique 75 %, radioactive 80 %, finale 70 %.
