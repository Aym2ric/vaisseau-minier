# Évolutions et spécialisations des armes

## Règles validées
10 armes × 6 évolutions = 60. Pour chaque arme : deux offensives et une hybride dans Armement ; deux minières et une hybride dans Minage. Aucun prérequis croisé entre arbres. Déblocage permanent par ressources ; choix temporaire pendant la run après un nombre suffisant d’améliorations de l’arme. Une seule évolution, irréversible jusqu’à la fin de la run. Les améliorations temporaires continuent ensuite.

## Exemple proposé
Canon automatique : Gatling et Canon lourd (offensives), Excavateur et Extracteur (minières), Canon multiple et Fragmentation (hybrides). Les effets exacts restent à concevoir ; une évolution offensive doit privilégier les dégâts offensifs plutôt qu’une cadence commune si l’on souhaite éviter un bonus minier involontaire.

## Contrat technique proposé
`EvolutionDefinition`: ID, arme, orientation, arbre, prérequis, effets. État runtime : compteur d’améliorations de l’arme, seuil, choix en attente, ID d’évolution active. Compter les améliorations effectivement choisies, pas celles simplement proposées. Exclure les évolutions verrouillées. Si aucune n’est disponible, conserver le build sans évolution (proposition). Seuil et traitement des choix en attente à équilibrer.

## Tests
- Vérifier six évolutions uniques par arme et répartition 30/30 entre arbres.
- Atteindre le seuil avec des améliorations d’arme ; vérifier que les bonus de module seuls ne le déclenchent pas.
- Vérifier qu’une évolution verrouillée ne peut pas être choisie.
- Après sélection, empêcher une seconde évolution et permettre les améliorations ordinaires.
- Sauvegarder et reprendre avec compteur, choix et évolution identiques.
