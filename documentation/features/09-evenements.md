# Événements planétaires

## Statut et objectif
**Socle validé / à préserver :** Fenêtres garanties, type lieu instant aléatoires, annonce HUD, temporaire ou permanent.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Planifier fenêtres, annoncer, déclencher, terminer effets temporaires, conserver gisements.

## Exemple concret
Météorite annoncée 30 s avant impact ; minerai reste après événement.

## Contrat technique proposé
- Responsabilités : `EventDirector`.
- Données à modéliser : `event_id, scheduled_at, warning_at, position, phase`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Aucune fenêtre sautée par reprise ; emplacement accessible ; pas de double déclenchement.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Seuls les événements ajoutent de nouveaux gisements ; ils ne réinitialisent pas les dépôts épuisés. Valider chaque nouvelle position et conserver son identifiant.
