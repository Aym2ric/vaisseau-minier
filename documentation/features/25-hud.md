# HUD et ergonomie

## Statut et objectif
**Socle validé / à préserver :** Annonce événements, mission, menace, informations de run.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Afficher coque, bouclier si présent, XP, mission, chrono, extraction (sans minimap pour le moment).

## Exemple concret
Alerte météorite avec délai et direction ; extraction disponible distincte.

## Contrat technique proposé
- Responsabilités : `HUDPresenter`.
- Données à modéliser : `run_snapshot, warnings, objective_progress`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Lisibilité en combat, résolution, contraste, pas de dépendance exclusive aux couleurs.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Aucun brouillard de guerre, aucune minimap pour le moment. Indications de mission et scanner hors écran à concevoir.


## Précisions V5
Afficher la cible et le compteur d’évolution de l’arme ; aucun indicateur d’outil ou d’immobilité minière. L’immobilité d’extraction demeure.
