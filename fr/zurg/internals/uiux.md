# Évaluation UI/UX de la configuration des répertoires {#directory-configuration-uiux-assessment}

## Périmètre et état actuel {#scope-and-current-state}
- Page : `Directory Configuration` à l'adresse `http://localhost:9999/directories/`.
- Interface actuelle : un seul tableau plat qui liste les répertoires sous des titres comme "MEDIA" et "RECENT", avec des colonnes pour le nom du répertoire, l'ordre numérique et des liens d'action ("Edit", "Delete").
- Comportement : l'édition et la suppression déclenchent de simples actions. Il n'y a pas de regroupement au-delà des titres, et pas de flux dédié à la création ou à l'édition des options YAML complètes.

## Principaux problèmes d'UX {#key-ux-gaps}
- **Architecture de l'information**
  - Les groupes sont visuellement aplatis ; les utilisateurs ne peuvent pas se concentrer sur un seul groupe à la fois.
  - L'ordre repose sur des numéros saisis à la main (`group_order`), ce qui est peu intuitif et source d'erreurs.
  - Pas de barre de recherche ou de filtre pour retrouver rapidement un répertoire.
  - Pas d'actions en masse (supprimer/déplacer) ni de moyens de sélection.
- **Expérience de création et de modification**
  - Les flux d'ajout et de modification n'exposent pas tout le schéma YAML (paramètres généraux, filtres de taille, de fichier, de tags et de temps).
  - Pas de mise en page structurée ; les champs ne sont pas regroupés, ce qui surcharge l'utilisateur à mesure que les options se multiplient.
  - Pas de constructeur de règles ET/OU imbriquées pour reproduire la logique de filtres imbriquée du YAML.
  - Les champs liés aux tags (`tags_match_all`, `tags_match_any`) sont difficiles à découvrir et n'offrent pas d'aide à la sélection.
  - Pas d'aperçu en direct des torrents correspondant aux filtres actuels.
- **Aide et validation**
  - Pas d'infobulles ni d'icônes d'information pour chaque champ, ni de liens vers la documentation détaillée (par exemple `tags.md`).
  - Aucun avertissement proactif quand un répertoire ne donnerait aucun torrent ou qu'il manque des filtres obligatoires.
  - Les expressions régulières et autres champs de motifs n'ont pas de validation en temps réel.
  - Les suppressions se font sans confirmation ni possibilité d'annulation.
- **Accessibilité et adaptation aux écrans**
  - Le contraste et la lisibilité ne sont pas vérifiés selon les critères WCAG ; les actions réduites à une icône n'ont peut-être pas de libellé.
  - Pas de glisser-déposer ; aucun moyen accessible au clavier pour réordonner.
  - La mise en page mobile n'est pas optimisée (le tableau ne s'adapte pas en cartes empilées, et les formulaires défilent mal).
  - Les actions reposent sur des liens textuels seuls ; il manque des icônes et des zones de clic claires.
- **Performance et finitions d'interaction**
  - La recherche et le filtre (une fois ajoutés) nécessiteront un debounce ainsi qu'une pagination ou une virtualisation pour les longues listes.
  - Le glisser-déposer (une fois ajouté) devra être persisté, avec une solution de repli propre si la sauvegarde échoue.

## Changements UI/UX recommandés {#recommended-uiux-changes}
- **Présentation des groupes**
  - Afficher chaque `group` de premier niveau (par ex. media/recent/example) sous forme de carte ou de section repliable, avec sa propre liste.
  - Proposer des actions rapides par groupe (replier/déplier, sélection en masse).
- **Ordre**
  - Remplacer la colonne de numéros d'ordre par des poignées de glisser-déposer pour réordonner dans un groupe ; afficher l'ordre calculé dans une infobulle ou un badge en ligne.
  - Proposer des contrôles de réordonnancement utilisables au clavier (boutons monter/descendre), comme solution d'accessibilité et de repli pour le mobile.
- **Recherche et actions en masse**
  - Ajouter une barre de recherche/filtre au-dessus de la liste ; temporiser (debounce) la saisie.
  - Ajouter des cases à cocher pour supprimer ou déplacer en masse ; inclure un raccourci « sélectionner tout le groupe ».
- **Ajout/Modification**
  - Utiliser une fenêtre modale ou un panneau latéral avec une mise en page en sections : General, Size Filters, File Filters, Tag Filters, Time Filters et Advanced.
  - Ajouter des sous-sections repliables pour réduire la surcharge ; mémoriser l'état d'ouverture pendant la session.
- **Éditeur de règles**
  - Proposer un éditeur visuel ET/OU qui reprend la structure YAML : groupes imbriqués, pastilles de conditions, sélecteurs propriété/opérateur/valeur (par ex. has_episodes, regex avec matches/does not match).
  - Permettre de basculer entre ET et OU à chaque nœud ; afficher un aperçu de l'expression obtenue.
- **Sélecteur de tags**
  - Sélection multiple avec autocomplétion alimentée par les tags disponibles ; afficher les descriptions et infobulles des tags, ainsi que leur nombre si disponible.
  - Différencier clairement `tags_match_all` et `tags_match_any`.
- **Aperçu**
  - Ajouter « Preview matching torrents » pour récupérer des résultats d'exemple selon l'état actuel des filtres ; afficher des états de chargement (squelettes) et gérer les erreurs.
- **Aide**
  - Ajouter des infobulles ou des icônes d'information pour chaque champ ; renvoyer vers la documentation détaillée si besoin (par ex. [tags.md](../reference/tags.md)).
  - Afficher des indications contextuelles (par ex. « Only show largest file ») qui expliquent les effets de bord d'un réglage.
- **Validation et sécurité**
  - Bloquer l'enregistrement si des filtres requis sont vides ou si la validation échoue ; afficher les erreurs en ligne.
  - Valider les regex en temps réel côté client, puis demander une confirmation côté serveur à l'envoi pour éviter les écarts.
  - Avertir si la configuration ne correspondrait à aucun torrent (d'après l'aperçu ou des heuristiques).
  - Afficher une boîte de confirmation pour les suppressions ; proposer un court « annuler » (snackbar) si possible (suppression réversible si elle est prise en charge).
- **Accessibilité et design adaptatif**
  - Vérifier le contraste de la palette choisie ; s'assurer que les contrôles ont des états de focus visibles et des libellés ARIA.
  - S'assurer que les sections repliables, les poignées de glisser-déposer et les actions sont accessibles au clavier.
  - Sur mobile, afficher les groupes sous forme de cartes empilées ; s'assurer que les fenêtres modales et les panneaux sont défilants, avec des en-têtes fixes pour les actions.
  - Associer les icônes à des libellés pour les actions clés ; s'assurer que les cibles qui n'ont que des icônes ont un nom accessible.
- **Finitions visuelles**
  - Utiliser une iconographie cohérente pour modifier, supprimer et réordonner ; ajouter des séparateurs discrets et des puces pour indiquer le contexte ou l'état d'un groupe.
  - Envisager un code couleur par groupe pour un repérage rapide (avec un contraste accessible).

## Dépendances et hypothèses à confirmer {#dependencies-and-assumptions-to-confirm}
- Support API pour : conserver l'ordre des groupes, opérations en masse, sérialisation ET/OU imbriquée, source de métadonnées des tags, et endpoint de prévisualisation des requêtes.
- Comportement des suppressions : suppression douce ou définitive, délai d'annulation, et besoins d'audit.
- Modèle de propriété et de permissions (si multi-utilisateur) pour afficher les métadonnées de dernière modification et éviter les conflits.
- Contraintes de performance pour la prévisualisation et la recherche ; stratégie de pagination ou de virtualisation pour les grands jeux de données.

## Priorités d'implémentation {#implementation-priorities}
1) Restructurer la liste en cartes ou sections repliables ; ajouter une barre de recherche et de filtre ainsi que des boîtes de dialogue de confirmation.
2) Introduire une fenêtre modale ou un panneau latéral pour ajouter et modifier, organisé en sections, avec des infobulles et une validation de base ; ajouter une sélection multiple de tags.
3) Ajouter le glisser-déposer et la réorganisation au clavier, avec sauvegarde ; implémenter un générateur de règles ET/OU.
4) Ajouter un aperçu des torrents correspondants, avec des requêtes temporisées (debounce) et une gestion des erreurs.
5) Finaliser l'accessibilité (parcours au clavier, ARIA) et une mise en page responsive en cartes empilées pour mobile.
