# Minage

## Statut et objectif
**Socle validé / à préserver :** Immobile uniquement, tous minerais accessibles à tous outils, cible la plus proche.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V4.md et ../CONTENT.md.

## Fonctionnement proposé
Détecter immobilité, sélectionner cible valide, appliquer puissance, épuiser puis changer de cible.

## Exemple concret
Un minerai rare résiste 20 s avec outil de base ; déplacement annule immédiatement le rayon.

## Contrat technique proposé
- Responsabilités : `MiningController, Deposit`.
- Données à modéliser : `deposit_id, remaining_hp, resource_id, yield`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Aucun dégât minier en mouvement ; gérer égalité de distance, cible détruite et multi-faisceau.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Les murs friables peuvent être minés à l’arrêt ; le minage est plus efficace que les armes. Les gisements épuisés disparaissent avec leur collision et ne repoussent jamais.
