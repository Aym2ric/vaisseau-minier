# Arbre Armement

## Statut et objectif
**Socle validé / à préserver :** 60 nœuds cibles ; armes, évolutions, statistiques.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Prérequis en graphe acyclique ; achat atomique par ressources.

## Exemple concret
Fer → dégâts → canon lourd → évolution.

## Contrat technique proposé
- Responsabilités : `SkillTreeService`.
- Données à modéliser : `node_id, prerequisites, rank, costs, effects`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Pas de cycle ni ressource inaccessible ; tous nœuds complétables.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.


## Précisions V5
Budget proposé : 9 armes non initiales + 20 évolutions offensives + 10 hybrides = 39 nœuds ; 21 restants pour statistiques, mécaniques et capacités à répartir. Aucun prérequis Minage.
