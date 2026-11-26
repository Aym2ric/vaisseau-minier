# Architecture, performance et tests

## Statut et objectif
**Socle validé / à préserver :** Godot 4 ; prototype non audité ; privilégier une tranche jouable.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Resources de définition, état runtime séparé, signaux métier, profiling et tests.

## Exemple concret
Regrouper pickups compatibles et réutiliser projectiles si profiling le justifie.

## Contrat technique proposé
- Responsabilités : `GameData, RunState, SaveGame`.
- Données à modéliser : `definitions, runtime_state, schema_version`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Mesurer frame time sur machine cible ; tester seed, sauvegarde, transactions et longue run.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Priorité : carte hybride, chunks, navigation partagée, recyclage hors caméra. Profiler avant de complexifier. Les noms de composants sont des propositions, pas un audit du projet.


## Précisions V5
Un seul pipeline de tir et de ciblage. Résoudre les dégâts par type de cible touchée ; supprimer le contrôleur de minage à l’arrêt si présent après audit. Tests de collision, bonus communs, dégâts distincts, destruction unique et reprise.
