# Roadmap — du prototype à Steam

Ordre proposé, sans estimation calendaire faute d’audit du code et de disponibilité connue. Ne pas produire les 8 planètes avant validation de la boucle.

| Jalon | Livrables | Critère de sortie |
|---|---|---|
| 0 Audit | Inventaire scènes/scripts, tests du prototype, sauvegarde Git | État réel documenté et build reproductible |
| 1 Boucle verticale | Carte finie, brouillard, minage immobile, combat, pickups, mission, extraction | Une run complète jouable, victoire et mort cohérentes |
| 2 Progression | XP, 3 choix, une évolution, ressources, quatre arbres minimaux, hub | Plusieurs runs améliorent réellement le profil |
| 3 Rejouabilité | Menace, événements, élites, boss, difficultés, objectifs épinglés | Run de 30–35 min intéressante sans timer forcé |
| 4 Robustesse | Sauvegarde, reprise, historique, profiling, réglages | Pas de duplication de ressources ; tests de reprise et longues runs |
| 5 Alpha | Première planète complète, plusieurs builds, équilibrage | Retours de testeurs et corrections prioritaires |
| 6 Bêta | 3 planètes proposées, 3 difficultés, catalogue partiel, exports Windows | Installation externe simple, feedback et crash reports volontaires |
| 7 Production | 8 planètes, 57 ressources, équipements, 24 boss, 240 nœuds | Tous les déblocages accessibles ; contenu et progression testés |
| 8 Steam | Page boutique, trailer, captures, builds, succès, tests de distribution | Validation des exigences Steam en vigueur avant publication |

## Priorité immédiate
1. Auditer le prototype sans réécrire les systèmes qui fonctionnent.
2. Remplacer l’arène par une carte finie et assurer l’accessibilité des objectifs.
3. Implémenter mission et extraction volontaire partout.
4. Relier cargaison, bilan et portefeuille permanent.
5. Ajouter une branche minimale de chaque arbre et tester le retour en run.

## Definition of done
Chaque feature possède une spécification, un scénario nominal et des cas limites ; données configurables, tests de non-régression, intégration HUD et sauvegarde si pertinente. Une feature non testée n’est pas terminée.

## Risques
Charge de création de 24 boss et 48 évolutions ; explosion des combinaisons ; sauvegarde exacte de la simulation ; équilibre de 57 ressources ; performance des hordes. Réduire le contenu de bêta plutôt que sacrifier la boucle.
