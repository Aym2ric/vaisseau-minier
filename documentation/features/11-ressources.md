# Ressources et économie

## Statut et objectif
**Socle validé / à préserver :** 57 ressources, 5 raretés, pas de monnaie universelle ni crafting.

Les composants, champs et algorithmes ci-dessous sont des propositions techniques, pas des noms de classes existantes vérifiés. Voir ../GDD_V5.md et ../CONTENT.md.

## Fonctionnement proposé
Définir IDs stables, sources, rareté, coûts ; afficher provenance et fréquence.

## Exemple concret
Une compétence coûte fer, titane et cœur de boss.

## Contrat technique proposé
- Responsabilités : `ResourceDefinition, Wallet`.
- Données à modéliser : `resource_id, rarity, sources, balance`.
- Séparer les définitions statiques (Resources Godot) de l’état mutable de la run.
- Utiliser des identifiants stables, valider les références au chargement et sérialiser les données plutôt que les références de Node.
- Émettre un signal métier après changement effectif ; l’interface observe l’état sans en être propriétaire.

## Critères d’acceptation et cas limites
Chaque ressource requise doit être accessible avant son achat ; pas de quantité négative.

## Scénarios de test
1. Initialiser une partie ou un profil minimal avec des données déterministes ; exécuter le scénario nominal décrit ci-dessus.
2. Répéter avec les conditions limites décrites ; vérifier que l’état et les quantités restent cohérents.
3. Vérifier l’intégration avec sauvegarde/reprise lorsque la fonctionnalité appartient à la run, ou avec persistance du profil sinon.
4. Vérifier l’affichage et les retours utilisateur, puis effectuer un test en expédition réelle.

## Paramètres et arbitrages
Les valeurs d’exemple ne sont pas des constantes définitives. Exposer les paramètres pertinents dans les données ; mesurer avant de figer. Ne pas ajouter de mécanique hors GDD sans validation.

## Mise à jour V4
Distribution hybride : dépôts isolés, concentrations régionales, filons cachés, points d’intérêt et événements. Aucun renouvellement naturel.
