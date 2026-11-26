# Menace et spawn

## Statut et objectif
**Socle validé / à préserver :** Menace liée uniquement au temps ; pas de scaling selon puissance du joueur.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Évaluer courbe de difficulté, budget de spawn et pool compatible avec planète.

## Exemple concret
À temps égal deux joueurs de puissances différentes rencontrent la même courbe.

## Contrat technique proposé
- Responsabilités : `ThreatDirector, SpawnDirector`.
- Données à modéliser : `elapsed, threat, spawn_budget, rng_state`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Pause et sauvegarde ne font pas avancer le temps ; limiter surcharge sans modifier silencieusement la difficulté.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Population et recyclage — V4

Population initiale autour des points d’intérêt et nids, plus spawn dynamique hors caméra selon la menace (temps uniquement). Le recyclage ne consomme pas le budget de création et ne modifie pas la menace.

Algorithme proposé : à intervalles espacés, sélectionner les ennemis mobiles trop éloignés et hors caméra ; rechercher un point hors du rectangle caméra agrandi d’une marge, dans une couronne proche du joueur. Vérifier frontière, collisions, place libre et chemin praticable. Si aucun point valide après un nombre borné d’essais, reporter le recyclage. Déplacer la même entité, conserver PV, type, modificateurs et état de combat pertinent ; recalculer son chemin. Aucun soin, XP, butin, kill ou nouvel identifiant. Exclure gardiens, cibles de mission et boss (exceptions proposées). Ne jamais recycler une entité morte.

Paramètres de test : marge caméra 200 px, seuil de recyclage 2500 px, contrôle toutes les 0,5 s par lots ; adapter au zoom, format d’écran et vitesse. Seuil supérieur à la distance de réapparition pour éviter les boucles. Cap d’ennemis actifs configurable, indépendant du recyclage.

Tests : zoom et redimensionnement ; joueur au bord ou dans un passage ; ennemi blessé ; élite ; cible de mission ; aucune position valide ; déplacements rapides ; absence de duplication de butin ; run longue avec population bornée.
