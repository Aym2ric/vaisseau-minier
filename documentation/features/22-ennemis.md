# Ennemis et élites

## Statut et objectif
**Socle validé / à préserver :** 10 archétypes, 16 exclusifs, 8 modificateurs.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Composer comportement, profil planète et modificateurs compatibles.

## Exemple concret
Sprinter blindé ; éviter combinaison illisible de trop nombreux effets.

## Contrat technique proposé
- Responsabilités : `EnemyDefinition, EliteModifier`.
- Données à modéliser : `enemy_id, hp, behavior, modifiers`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Télégraphes lisibles, collisions, spawn hors obstacle, budget performance.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Tous les ennemis respectent les mêmes collisions de déplacement. Certains ennemis spécialisés et boss détruisent les murs friables. Recyclage des standards et élites éloignés selon 08-menace.md ; gardiens, cibles de mission et boss exclus selon la proposition.
