# Boss

## Statut et objectif
**Socle validé / à préserver :** 24 boss, 3 par planète, une ressource exclusive chacun.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V4.md et ../CONTENT.md.

## Fonctionnement proposé
Machine à états de phases ; télégraphes ; récompense physique unique.

## Exemple concret
Boss volcanique alterne charge et éruption ; lâche son cœur.

## Contrat technique proposé
- Responsabilités : `BossController`.
- Données à modéliser : `boss_id, phase, hp, timers, reward_dropped`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Boss facultatif hors mission ; récompense unique ; reprise au milieu d’une phase.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Les boss peuvent détruire les murs friables, jamais les frontières ou murs permanents. Pas de recyclage des boss selon la règle proposée.
