# Documentation des tags zurg {#zurg-tags-documentation}

Ce document décrit toutes les balises qui peuvent être appliquées automatiquement aux torrents dans zurg.

## Tags de résolution {#resolution-tags}

Les tags de résolution sont appliqués selon les dimensions de la vidéo, avec une marge de tolérance de 5 %. Un flux correspond à un palier lorsque sa largeur et sa hauteur atteignent au moins 95 % des dimensions indiquées. Les images intégrées (jaquettes, miniatures) sont ignorées. Seul le tag de résolution correspondant le plus élevé est appliqué.

| Tag | Description |
|-----|-------------|
| `zurg_8k` | Résolution >= 7680x4320 |
| `zurg_4k` | Résolution >= 3840x2160 |
| `zurg_1440p` | Résolution >= 2560x1440 |
| `zurg_1080p` | Résolution >= 1920x1080 |
| `zurg_720p` | Résolution >= 1280x720 |
| `zurg_480p` | Résolution >= 720x480 |

## Tags de plage dynamique {#dynamic-range-tags}

| Tag | Description |
|-----|-------------|
| `zurg_hdr` | Contenu HDR (détecté par l'espace colorimétrique BT.2020) |
| `zurg_dv` | Contenu Dolby Vision |
| `zurg_sdr` | Contenu SDR (Standard Dynamic Range), appliqué quand ni HDR ni DV ne sont détectés |

Un seul de ces tags est appliqué selon les caractéristiques de dynamique de la vidéo :

Quand les métadonnées HDR et Dolby Vision sont toutes les deux présentes, le tag Dolby Vision est prioritaire et `zurg_hdr` n'est pas appliqué.

## Tags de débit vidéo {#video-bitrate-tags}

Les tags de débit vidéo sont basés sur le débit du flux vidéo le plus élevé trouvé dans l'ensemble des fichiers analysés, en ignorant les images intégrées (pochettes, miniatures). Seul le palier correspondant le plus élevé est appliqué.

| Tag | Description |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | Débit vidéo ≥ 100 Mbps |
| `zurg_high_video_bitrate` | Débit vidéo ≥ 70 Mbps et < 100 Mbps |
| `zurg_moderate_video_bitrate` | Débit vidéo ≥ 40 Mbps et < 70 Mbps |
| `zurg_low_video_bitrate` | Débit vidéo ≥ 10 Mbps et < 40 Mbps |
| `zurg_very_low_video_bitrate` | Débit vidéo ≥ 0 Mbps et < 10 Mbps |

## Tags de débit audio {#audio-bitrate-tags}

Les tags de débit audio se basent sur le débit audio le plus élevé trouvé parmi toutes les pistes audio. Seul le palier correspondant le plus élevé est appliqué.

| Tag | Description |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | Débit audio ≥ 2000 kbps (par ex. DTS-HD MA, TrueHD, LPCM) |
| `zurg_high_audio_bitrate` | Débit audio ≥ 768 kbps et < 2000 kbps (par ex. DTS, AC3 à haut débit) |
| `zurg_moderate_audio_bitrate` | Débit audio ≥ 384 kbps et < 768 kbps (par ex. AC3 standard, AAC 5.1) |
| `zurg_low_audio_bitrate` | Débit audio ≥ 128 kbps et < 384 kbps (par ex. AAC stéréo, MP3) |
| `zurg_very_low_audio_bitrate` | Débit audio ≥ 0 kbps et < 128 kbps (par ex. stéréo de faible qualité) |

## Tags de durée {#duration-tags}

Les tags de durée sont basés sur la durée la plus longue trouvée parmi tous les fichiers analysés, y compris les fichiers audio seuls. Seul le palier le plus élevé correspondant est appliqué.

| Tag | Description |
|-----|-------------|
| `zurg_80minsplus_duration` | Durée ≥ 80 minutes |
| `zurg_60to80mins_duration` | Durée ≥ 60 minutes et < 80 minutes |
| `zurg_40to60mins_duration` | Durée ≥ 40 minutes et < 60 minutes |
| `zurg_20to40mins_duration` | Durée ≥ 20 minutes et < 40 minutes |
| `zurg_0to20mins_duration` | Durée ≥ 0 minutes et < 20 minutes |

## Tags de langue {#language-tags}

Des étiquettes de langue sont appliquées pour chaque langue unique détectée dans les flux audio et sous-titres. La détection regroupe tous les fichiers analysés du torrent, donc un pack de saison porte l'union des langues de ses épisodes. Seuls les flux à l'intérieur des fichiers vidéo/audio analysés comptent : un `.srt` séparé à côté n'est jamais lu, et les flux sans langue déclarée prennent la valeur `und` par défaut.

### Tags de langue audio {#audio-language-tags}
Format : `zurg_aud_[language_code]`

Exemple :
- `zurg_aud_eng` - piste audio en anglais
- `zurg_aud_jpn` - piste audio en japonais

### Tags de langue des sous-titres {#subtitle-language-tags}
Format : `zurg_sub_[language_code]`

Exemple :
- `zurg_sub_eng` - sous-titres anglais
- `zurg_sub_spa` - sous-titres espagnols

## Utiliser les tags pour filtrer {#using-tags-for-filtering}

Les tags peuvent être utilisés dans le fichier de configuration pour filtrer les torrents dans des dossiers spécifiques. Il existe quatre filtres de tags basés sur des listes, plus deux conditions sur un seul tag :

### Types de filtres de tags {#tag-filter-types}

1. `tags_match_all` : Tous les tags indiqués doivent être présents
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any` : Au moins un des tags indiqués doit être présent
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all` : Renvoie true si aucun des tags du filtre n'est présent (l'inverse de "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any` : Renvoie true si au moins un des tags du filtre est absent (l'inverse de "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

Les noms des tags dans ces quatre filtres sont comparés sans tenir compte de la casse. Un torrent sans aucun tag échoue à `tags_match_all` et `tags_match_any`, et réussit `tags_missing_all` et `tags_missing_any` : c'est là que finissent les torrents jamais analysés.

Les quatre clés sont vérifiées dans l'ordre ci-dessus et la première présente décide de tout le bloc de filtres. Donc donnez à chaque filtre de tags sa propre entrée sous `and:`/`or:` au lieu d'en combiner plusieurs dans un même bloc.

### Conditions à tag unique {#single-tag-conditions}

`has_tag` et `not_has_tag` prennent un seul nom de tag au lieu d'une liste, et la correspondance est sensible à la casse. Contrairement aux quatre filtres ci-dessus, ils peuvent seulement rejeter un torrent, jamais en sélectionner un tout seul : un bloc de filtre qui ne contient que `has_tag` ne correspond à rien, donc ils doivent être placés avec une autre condition dans le même bloc.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Exemple de configuration de répertoire {#example-directory-configuration}

Voici un exemple d'utilisation des filtres de tags dans une configuration de répertoire :

```yaml
"quality movies":
  filters:
    - and:
      - tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
      - tags_match_any: ["zurg_high_video_bitrate", "zurg_ultra_high_video_bitrate"]  # Must have either high or ultra-high video bitrate
      - tags_match_any: ["zurg_high_audio_bitrate", "zurg_ultra_high_audio_bitrate"]  # Must have either high or ultra-high audio bitrate
      - tags_match_any: ["zurg_60to80mins_duration", "zurg_80minsplus_duration"]  # Must be at least 60 minutes long
      - tags_missing_all: ["zurg_sdr", "zurg_very_low_video_bitrate"]  # Must not have SDR or very low video bitrate
      - tags_missing_any: ["zurg_dv"]  # Must be missing Dolby Vision (prefer HDR10)
```

## Notes

- Les tags sont appliqués automatiquement selon l'analyse des médias, ce qui nécessite un binaire `ffprobe`. Sur les torrents nouvellement ajoutés, l'analyse ne se lance que si `auto_analyze_new_torrents` est activé. L'action d'analyse du tableau de bord et l'action d'informations média par torrent sur la page de gestion la déclenchent à la demande.
- Rien n'est tagué tant qu'au moins un fichier n'a pas été analysé. Un torrent non analysé ne porte ni `zurg_sdr`, ni palier de débit, ni palier de durée.
- Chaque tag `zurg_*` est effacé et recalculé à chaque analyse. Les tags sans ce préfixe (tags utilisateur, attributions de dossiers) sont conservés.
- Plusieurs tags de langue peuvent être présents en même temps.
- Un seul tag de résolution est appliqué (le plus élevé correspondant).
- Un seul tag de plage dynamique est appliqué.
- Un seul tag de palier de débit vidéo est appliqué (le plus élevé correspondant).
- Un seul tag de palier de débit audio est appliqué (le plus élevé correspondant).
- Un seul tag de palier de durée est appliqué (le plus élevé correspondant).
- Une marge de tolérance de 5 % est appliquée pour les vérifications de résolution.
- Les débits vidéo sont basés sur le flux au débit le plus élevé, et non sur la moyenne.
- Les débits audio sont basés sur le flux au débit le plus élevé, et non sur la moyenne.
- Un flux qui ne déclare pas de débit compte pour 0. Un fichier dont les flux n'ont aucune métadonnée de débit tombe donc dans le palier `very_low`.
- La durée est basée sur le fichier analysé le plus long du torrent (fichiers audio seuls inclus).
- Les filtres par tag peuvent être combinés avec d'autres filtres pour une organisation du contenu plus précise.
