# Roadmap — du prototype à Steam

Ordre proposé, sans estimation calendaire. Ne pas produire les 8 planètes avant validation de la boucle.

| Jalon | Livrables | Statut |
|---|---|---|
| 0 Audit | Inventaire scènes/scripts, tests du prototype, sauvegarde Git | ✅ Terminé |
| 1 Boucle verticale | Carte finie hybride, arme unique, minage en mouvement, ciblage commun, pickups, mission, extraction | ✅ Terminé |
| 2 Progression | XP, 3 choix, une évolution, ressources, quatre arbres minimaux, hub | ✅ Terminé |
| 3 Rejouabilité | Menace, événements, élites, boss, difficultés, objectifs épinglés | ✅ Terminé |
| 4 Robustesse | Sauvegarde mid-run, reprise, historique, stats, profiling, réglages | ✅ Terminé |
| 5 Alpha | Première planète complète, plusieurs builds, ressources complètes | ✅ Terminé |
| 6 Bêta | 3 planètes, 3 difficultés, tank/sniper, prérequis compétences | ✅ Terminé |
| 7 Production | 8 planètes, 57 ressources, boss planétaire, extraction révisée | ✅ Terminé |
| UI | Refonte hub : layout 3 colonnes, 6 sections, carte planètes, hub.tscn | ✅ Terminé |
| 8 Contenu | Minage par arme (V5), 6 vaisseaux, 60 évolutions, 240 nœuds permanents | 🔲 À faire |
| 9 Polish | Équilibrage, événements planétaires, élites visuels, sons, shaders | 🔲 À faire |
| 10 Steam | Page boutique, trailer, captures, succès, builds distribution | 🔲 À faire |

---

## Jalon 8 — Contenu (prochain)

### Priorité haute

#### Minage par arme (rupture V5)
- Chaque arme a `combat_damage` et `mining_damage` distincts
- Un impact sur gisement applique `mining_damage` (même si l'arme visait un ennemi)
- Auto-visée : cible valide la plus proche sans distinction ennemi/gisement
- Bullets → endommagent ore/gold avec `mining_damage`
- Supprimer le minage auto à l'arrêt
- Voir `features/04-minage.md`

#### 6 vaisseaux
- Polyvalent (implémenté), Mobile, Mineur, Offensif, Résistant, Collecteur
- Voir `features/12-vaisseaux.md`

#### 60 évolutions d'arme
- 6 évolutions par arme : 2 offensives + 2 minières + 2 hybrides
- Voir `features/14-evolutions.md`

#### 240 nœuds permanents
- 4 arbres × 60 nœuds : Armement, Minage, Navigation, Logistique
- Planètes débloquées via arbre Navigation (branches ramifiées)
- Voir `features/18-armement.md` à `features/21-logistique.md`

### Priorité moyenne
- Système d'événements planétaires en run (`features/09-evenements.md`)
- Élites avec modificateurs visuels
- Module slots (1–4 selon compétence Logistique)

---

## Definition of done
Chaque feature possède une spécification, un scénario nominal et des cas limites ; données configurables, tests de non-régression, intégration HUD et sauvegarde si pertinente. Une feature non testée n'est pas terminée.

## Risques
Charge de création des 60 évolutions et 240 nœuds ; explosion des combinaisons ; équilibre des 57 ressources ; performance des hordes. Réduire le contenu si nécessaire plutôt que sacrifier la boucle.
