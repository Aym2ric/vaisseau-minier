# Modules

## Statut et objectif
**Socle validé / à préserver :** 16 modules, 1 à 4 slots, pas de doublon ni évolution.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Valider équipement débloqué et slots ; injecter bonus et pool temporaire.

## Exemple concret
Aimant et drone collecteur améliorent la collecte sans doubler un pickup.

## Contrat technique proposé
- Responsabilités : `ModuleDefinition, LoadoutValidator`.
- Données à modéliser : `module_ids, slot_count`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Refuser doublon et dépassement ; retirer bonus au changement de build.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Scanner : détection de ressources et points d’intérêt hors écran, sans brouillard ni minimap. Signal directionnel proposé.


## Précisions V5
L’optimiseur minier agit sur les dégâts miniers ou le rendement de l’arme ; les accélérateurs de cadence agissent sur les deux usages. Effets exacts à définir.
