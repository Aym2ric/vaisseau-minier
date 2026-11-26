# Bilan, objectifs et statistiques

## Statut et objectif
**Socle validé / à préserver :** Historique détaillé, records, compétences épinglées.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Finaliser rapport, agréger dimensions, comparer ressources manquantes.

## Exemple concret
Avant run manque 80 fer ; après extraction de 50, manque 30.

## Contrat technique proposé
- Responsabilités : `RunReportService`.
- Données à modéliser : `run_id, result, duration, loot, build, stats`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Échec et extraction distincts ; rapport immuable ; aucune double agrégation.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.


## Précisions V5
Historique et statistiques par arme, évolution, vaisseau, planète et difficulté ; distinguer dégâts offensifs, dégâts miniers et ressources récoltées. Aucun filtre par outil.
