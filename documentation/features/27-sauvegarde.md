# Sauvegarde et reprise

## Statut et objectif
**Socle validé / à préserver :** Sauvegarder et quitter, une run active, consommée à reprise ; crash non récupéré.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Écrire snapshot versionné atomiquement, restaurer puis consommer ; profil permanent séparé.

## Exemple concret
Reprise à 17:42 avec mêmes gisements, ennemis et événements.

## Contrat technique proposé
- Responsabilités : `SaveGame, SnapshotCodec`.
- Données à modéliser : `schema_version, profile, active_run, rng_states`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Tester fichier corrompu, version incompatible, crash pendant écriture ; préserver profil.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Snapshot : seed et version du générateur, identifiants des murs et PV, murs détruits, gisements épuisés ou ajoutés, positions et PV des ennemis recyclés, RNG. Aucun état de brouillard à conserver. Tester reprise après destruction et recyclage.


## Précisions V5
Versionner le schéma ; retirer le slot minier des nouveaux profils et sauvegardes, conserver arme, évolution, compteur et choix en attente. Migration des anciens déblocages et remboursements éventuels à décider ; ne pas supprimer silencieusement les ressources du profil.
