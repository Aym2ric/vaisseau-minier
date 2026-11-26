# Missions

## Statut et objectif
**Socle validé / à préserver :** Mission découverte après arrivée, multi-objectifs possibles, secondaires facultatives, aucun quota minéral.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V4.md et ../CONTENT.md.

## Fonctionnement proposé
Instancier modèle compatible, valider objectifs, écouter événements de progression, débloquer extraction.

## Exemple concret
Détruire deux nids puis activer une balise ; secondaire facultative : tuer une élite.

## Contrat technique proposé
- Responsabilités : `MissionController`.
- Données à modéliser : `template_id, objectives, progress, status`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Une secondaire échouée ne bloque jamais extraction ; objectifs accessibles et comptage idempotent.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.
