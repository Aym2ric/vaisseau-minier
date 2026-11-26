# Minage par l’arme équipée

## Règles validées
- Aucun équipement ou mode de minage séparé. Tirer sur les gisements, à l’arrêt ou en mouvement.
- Toute arme peut miner tout minerai ; dégâts miniers propres à l’arme, distincts des dégâts offensifs.
- Cadence, portée, projectiles et zone d’effet partagés avec le combat.
- Les gisements bloquent les tirs et déplacements jusqu’à destruction. À destruction, libérer le butin physique et supprimer la collision ; pas de repousse naturelle. Les événements peuvent créer de nouveaux gisements.
- Rendement minier indépendant ; aucune limite de cargaison.

## Contrat technique proposé
`WeaponDefinition` porte `combat_damage`, `mining_damage`, `mining_yield` et les caractéristiques communes. `DepositState` porte ID, PV restants et contenu. Le résolveur d’impact choisit les dégâts selon la cible touchée. La destruction est atomique et ne produit le butin qu’une fois, même si plusieurs projectiles arrivent simultanément. Sauvegarder les PV et gisements détruits.

## Exemples proposés
Canon automatique : impacts réguliers ; missiles : zone minière ; laser : dégâts continus. Un projectile destiné à un ennemi mais intercepté par un gisement inflige des dégâts miniers. Les valeurs, arrondis de rendement et effets de zone restent à équilibrer.

## Tests
1. Miner en mouvement et à l’arrêt avec la même arme.
2. Vérifier qu’un bonus offensif seul ne change pas les dégâts miniers et inversement.
3. Vérifier qu’un bonus de cadence bénéficie aux deux activités.
4. Détruire un gisement avec plusieurs impacts simultanés : un seul butin, collision supprimée.
5. Sauvegarder puis reprendre un gisement partiellement détruit ; vérifier l’absence de duplication.
6. Vérifier que chaque arme peut épuiser chaque minerai.
