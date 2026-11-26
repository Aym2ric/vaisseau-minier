# Armes et évolutions

## Statut et objectif
**Socle validé / à préserver :** 10 armes, 3 évolutions chacune, une arme équipée.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V4.md et ../CONTENT.md.

## Fonctionnement proposé
Débloquer évolution dans arbre ; compter améliorations pertinentes ; proposer choix direct.

## Exemple concret
Canon automatique → Gatling après seuil proposé de 5 améliorations.

## Contrat technique proposé
- Responsabilités : `WeaponDefinition, EvolutionDefinition`.
- Données à modéliser : `weapon_id, evolution_id, upgrade_count`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Aucune évolution verrouillée proposée ; pas de combinaison aléatoire obligatoire.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.
