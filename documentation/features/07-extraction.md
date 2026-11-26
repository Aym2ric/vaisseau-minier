# Extraction et échec

## Statut et objectif
**Implémenté et validé.** Extraction volontaire partout après mission ; mort perd le butin sauf récupération Logistique.

## Fonctionnement actuel (implémenté dans `scenes/sector/sector.gd`)

### Démarrage
- Disponible uniquement une fois la mission accomplie (`RunState.mission_complete`)
- Déclenché par TAB (`action "extract"`)
- **Pas besoin d'être immobile** pour démarrer

### Déroulement
- Canalisation de 10 secondes (configurable via `GameData.CONFIG["extract_time"]`)
- Réduite par la compétence `extract_boost` : `× maxf(0.3, 1.0 - 0.15 × rang)`
- Anneau de progression affiché autour du vaisseau (arc vert)
- Message "Extraction en cours… (TAB pour annuler)"

### Annulation
- **TAB à nouveau** → annulation manuelle
- **Dégâts reçus** → annulation automatique ("Extraction interrompue par les dégâts !")
- **Dash** → annulation automatique
- Compteur remis à zéro ; nouvelle tentative possible immédiatement

### Finalisation
- Signal `cleared` émis → `main.gd` termine la run et affiche le bilan
- Bilan distingue succès (tout le cargo sécurisé) d'un échec (cargo partiel)

### Échec (mort)
- `RunState.damage()` → hull ≤ 0 → signal `run_failed`
- Cargo perdu sauf portion sauvegardée par compétence `insure` (+12 % par rang, max 3 rangs = 36 %)

## Paramètres configurables
| Paramètre | Clé | Valeur actuelle |
|---|---|---|
| Durée de base | `CONFIG["extract_time"]` | 10 s |
| Réduction max | compétence `extract_boost` | −45 % (3 rangs) |
| Récupération mort | compétence `insure` | +36 % max |

## Cas limites validés
- Double pression TAB (démarrage + annulation) : corrigé par `elif _extracting`
- Dégâts pendant extraction : annule via `_on_ship_damaged()`
- Extraction après reprise de sauvegarde : fonctionne (état `_extracting` = false par défaut)
