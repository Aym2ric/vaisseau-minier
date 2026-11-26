# Statistiques et équilibrage

## Statut et objectif
**Socle validé / à préserver :** Progression forte ; ×5 dégâts/minage, ×3 rendement indicatifs ; 80–120 h cible.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Mesurer durée, taux extraction, rendement/minute, coûts et puissance par difficulté.

## Exemple concret
Gisement de 20 s devient 4 s à puissance ×5.

## Contrat technique proposé
- Responsabilités : `StatResolver, BalanceConfig`.
- Données à modéliser : `base, additive, multiplicative, caps`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Pas de scaling joueur ; éviter cadence nulle, valeurs non finies, économie bloquée.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.


## Précisions V5
Mesurer DPS offensif et minier séparément avec la cadence commune ; rendement distinct. Les 60 évolutions doivent offrir des choix utiles sans rendre une orientation systématiquement dominante.
