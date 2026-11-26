# Combat et ciblage

## Statut et objectif
**Socle validé / à préserver :** Visée hybride déjà annoncée implémentée ; arme unique pour combat et minage.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Séparer ciblage, cadence, projectile, dégâts et collisions.

## Exemple concret
Un tir manuel vise le curseur ; il peut toucher un ennemi ou un gisement.

## Contrat technique proposé
- Responsabilités : `WeaponController, DamageResolver`.
- Données à modéliser : `aim_mode, cooldown, projectile_state`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Pas de double tir lors du changement de mode ; vérifier collisions et cadence.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Les projectiles alliés et ennemis sont bloqués par tous les obstacles solides, sans exception selon l’arme. Les armes endommagent les murs friables, pas les gisements.


## Précisions V5
Ciblage automatique : cible valide la plus proche à portée, sans préférence ennemi/gisement. Visée manuelle prioritaire. Un impact sur un gisement applique les dégâts miniers même si le tir visait un ennemi. Les obstacles bloquent les tirs ; pas de traversée des murs. Tester les deux types de cible, le changement de cible et les obstacles. Le départage à distance égale et la gestion de ligne de vue restent à définir.
