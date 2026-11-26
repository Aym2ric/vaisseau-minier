# Spécification fonctionnelle
## Règles V5 à préserver
Hub exclusivement sous forme de menus. Presets dès le départ. Loadout : un vaisseau, une arme (combat ET minage), une capacité active, 1 à 4 modules uniques selon Logistique. Pas de monnaie universelle ni de crafting. Progression permanente par les quatre arbres. Difficultés débloquées par extraction réussie à la précédente, indépendamment par planète. Mission révélée après atterrissage. Ressources et fréquences visibles avant départ. Une seule sauvegarde d'expédition active, consommée à la reprise.

## Interface proposée
Écran plein écran, navigation verticale persistante, stock résumé en haut, contenu central, panneau contextuel droit et action principale en bas. Style sci-fi industriel : fond bleu nuit, panneaux ardoise, accents cyan, orange pour action de départ, vert pour disponibilité, texte explicite en complément des couleurs. Typographie lisible. Référence 1600×900, mise en page responsive à partir de 1280×720 ; défilement plutôt que texte tronqué. Pas de déplacement physique ni de scène 3D obligatoire.

## Navigation
Carte des 8 planètes en branches : Rocheuse → Désertique → Volcanique ; Rocheuse → Glaciaire → Cristalline ; Rocheuse → Organique → Radioactive ; convergence Finale. Afficher verrouillage et prérequis réels, ne pas inventer les conditions de la Finale. Sélection planète puis difficulté 1–5. Panneau : description, dangers, ressources avec rareté et fréquence, meilleur résultat si disponible. Bouton départ actif seulement si planète/difficulté/loadout valides et aucune run à reprendre. Ne pas afficher la mission avant le départ.

## Hangar
Liste des presets, création, renommage, modification, duplication, suppression. Sélecteurs vaisseau, arme, capacité et modules. Afficher les slots verrouillés et leur condition. Afficher statistiques calculées par les règles existantes : coque, vitesse, dégâts combat, dégâts miniers, cadence, portée, rendement selon données disponibles. Prévisualiser les différences avant sélection. Équipement verrouillé consultable mais non équipable. Les évolutions d'armes (6 par arme) sont consultables, jamais équipées avant la run. Propositions UX : confirmation suppression, nom non vide, conserver un loadout valide si dernier preset supprimé.

## Recherche
Onglets Armement, Minage, Navigation, Logistique. Graphe de nœuds avec liens de prérequis, zoom et déplacement. Panneau sélection : rang actuel/max, effet actuel/suivant, coûts par ressource, stock, prérequis, provenance des ressources. Achat atomique, pas de solde négatif. Épingler/désépingler une compétence pour suivre les besoins dans le bilan. 30 évolutions dans Armement et 30 dans Minage (20 spécialisées et 10 hybrides chacun). Ne pas inventer les 240 nœuds si catalogue incomplet.

## Entrepôt
Liste des ressources permanentes, quantité, rareté, provenance, filtres et recherche. Sélection affiche les compétences qui consomment cette ressource et raccourci Recherche. Ne pas mélanger cargaison non sécurisée et stock permanent. Aucun bouton de vente/craft.

## Archives
Vue globale et filtres planète, difficulté, vaisseau, arme. Historique des expéditions, résultat, durée, mission, ressources sécurisées/perdues, build et records selon données disponibles. Détail en lecture seule. État vide explicite. Pas de statistiques fictives en production.

## Paramètres
Réutiliser les réglages existants (audio, affichage, commandes selon disponibilité). Ne pas introduire des options inopérantes. Retour au menu principal selon flux existant.

## Retour d'expédition
Afficher le bilan réel, puis retour hub ; rafraîchir stock, déblocages, objectifs épinglés et archives. Si une sauvegarde active existe, proposer Reprendre plutôt que lancer une nouvelle expédition ; abandon éventuel à faire confirmer et à implémenter seulement si cohérent avec le système existant.
