# zurg Tags Documentation

Este documento descreve todas as tags possíveis que podem ser aplicadas automaticamente aos torrents no zurg.

## Tags de Resolução {#resolution-tags}

As tags de resolução são aplicadas com base nas dimensões do vídeo, com uma margem de tolerância de 5%: um stream entra em uma faixa quando tanto a largura quanto a altura são pelo menos 95% das dimensões listadas. Imagens embutidas (capas, miniaturas) são ignoradas. Só a tag de resolução mais alta que bater é aplicada.

| Tag | Descrição |
|-----|-----------|
| `zurg_8k` | Resolução >= 7680x4320 |
| `zurg_4k` | Resolução >= 3840x2160 |
| `zurg_1440p` | Resolução >= 2560x1440 |
| `zurg_1080p` | Resolução >= 1920x1080 |
| `zurg_720p` | Resolução >= 1280x720 |
| `zurg_480p` | Resolução >= 720x480 |

## Tags de Dynamic Range {#dynamic-range-tags}

| Tag | Description |
|-----|-------------|
| `zurg_hdr` | HDR content (detected by BT.2020 color space) |
| `zurg_dv` | Dolby Vision content |
| `zurg_sdr` | Standard Dynamic Range content (applied when neither HDR nor DV is detected) |

Quando os metadados de HDR e Dolby Vision estão presentes ao mesmo tempo, a tag de Dolby Vision tem prioridade e `zurg_hdr` não é aplicada.

## Tags de Bitrate de Vídeo {#video-bitrate-tags}

As tags de bitrate de vídeo são baseadas no maior bitrate de stream de vídeo encontrado em todos os arquivos analisados, ignorando imagens embutidas (capas de álbum, miniaturas). Só a faixa mais alta que bater é aplicada.

| Tag | Descrição |
|-----|-----------|
| `zurg_ultra_high_video_bitrate` | Bitrate de vídeo ≥ 100 Mbps |
| `zurg_high_video_bitrate` | Bitrate de vídeo ≥ 70 Mbps e < 100 Mbps |
| `zurg_moderate_video_bitrate` | Bitrate de vídeo ≥ 40 Mbps e < 70 Mbps |
| `zurg_low_video_bitrate` | Bitrate de vídeo ≥ 10 Mbps e < 40 Mbps |
| `zurg_very_low_video_bitrate` | Bitrate de vídeo ≥ 0 Mbps e < 10 Mbps |

## Tags de Bitrate de Áudio {#audio-bitrate-tags}

As tags de bitrate de áudio são baseadas no maior bitrate de áudio encontrado em todas as faixas de áudio. Só a faixa mais alta que bater é aplicada.

| Tag | Descrição |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | Bitrate de áudio ≥ 2000 kbps (ex.: DTS-HD MA, TrueHD, LPCM) |
| `zurg_high_audio_bitrate` | Bitrate de áudio ≥ 768 kbps e < 2000 kbps (ex.: DTS, AC3 de alto bitrate) |
| `zurg_moderate_audio_bitrate` | Bitrate de áudio ≥ 384 kbps e < 768 kbps (ex.: AC3 padrão, AAC 5.1) |
| `zurg_low_audio_bitrate` | Bitrate de áudio ≥ 128 kbps e < 384 kbps (ex.: AAC estéreo, MP3) |
| `zurg_very_low_audio_bitrate` | Bitrate de áudio ≥ 0 kbps e < 128 kbps (ex.: estéreo de baixa qualidade) |

## Tags de Duração {#duration-tags}

The duração das tags é baseada na maior duração encontrada entre todos os arquivos analisados, incluindo os arquivos só de áudio. Somente a faixa correspondente mais alta é aplicada.

| Tag | Descrição |
|-----|-------------|
| `zurg_80minsplus_duration` | Duração ≥ 80 minutos |
| `zurg_60to80mins_duration` | Duração ≥ 60 minutos e < 80 minutos |
| `zurg_40to60mins_duration` | Duração ≥ 40 minutos e < 60 minutos |
| `zurg_20to40mins_duration` | Duração ≥ 20 minutos e < 40 minutos |
| `zurg_0to20mins_duration` | Duração ≥ 0 minutos e < 20 minutos |

## Tags de Idioma {#language-tags}

Tags de idioma são aplicadas para cada idioma único detectado nos streams de áudio e legenda. A detecção agrega todos os arquivos analisados do torrent, então um pacote de temporada traz a união dos idiomas dos seus episódios. Só contam os streams dentro dos arquivos de vídeo/áudio analisados — um `.srt` avulso ao lado deles nunca é lido — e streams sem idioma declarado assumem `und`.

### Tags de Idioma de Áudio {#audio-language-tags}
Formato: `zurg_aud_[language_code]`

Exemplo:
- `zurg_aud_eng` - faixa de áudio em inglês
- `zurg_aud_jpn` - faixa de áudio em japonês

### Tags de Idioma de Legenda {#subtitle-language-tags}
Formato: `zurg_sub_[language_code]`

Exemplo:
- `zurg_sub_eng` - legendas em inglês
- `zurg_sub_spa` - legendas em espanhol

## Usando Tags para Filtrar {#using-tags-for-filtering}

Tags podem ser usados no arquivo de configuração para filtrar torrents em diretórios específicos. Há quatro filtros de tag baseados em lista, além de duas condições de tag única:

### Tipos de Filtro de Tag {#tag-filter-types}

1. `tags_match_all`: Todas as tags especificadas devem estar presentes
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: Pelo menos uma das tags especificadas deve estar presente
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: Retorna true se nenhuma das tags do filtro estiver presente (o oposto de "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: Retorna true se pelo menos uma das tags do filtro estiver faltando (o oposto de "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

Os nomes das tags nesses quatro filtros são comparados sem diferenciar maiúsculas de minúsculas. Um torrent sem nenhuma tag falha em `tags_match_all` e `tags_match_any`, e passa em `tags_missing_all` e `tags_missing_any`, que é para onde vão os torrents que nunca foram analisados.

As quatro chaves são verificadas na ordem acima, e a primeira que estiver presente decide o bloco de filtro inteiro. Por isso, coloque cada filtro de tag em sua própria entrada sob `and:`/`or:` em vez de combinar vários em um único bloco.

### Condições de Tag Única {#single-tag-conditions}

`has_tag` e `not_has_tag` recebem um único nome de tag em vez de uma lista, e comparam com diferenciação de maiúsculas e minúsculas. Diferente dos quatro filtros acima, eles só podem rejeitar um torrent, nunca selecionar um sozinhos: um bloco de filtro que tenha apenas `has_tag` não corresponde a nada, então eles precisam ficar junto de outra condição no mesmo bloco.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Exemplo de Configuração de Diretório {#example-directory-configuration}

Aqui está um exemplo de como usar filtros de tag em uma configuração de diretório:

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

## Notas {#notes}

- As tags são aplicadas automaticamente com base na análise de mídia, que precisa de um binário `ffprobe` e roda em torrents recém-adicionados somente quando `auto_analyze_new_torrents` está ativado; a ação analyze do painel e a ação de informações de mídia por torrent na página manage disparam a análise sob demanda
- Nada é marcado até que pelo menos um arquivo tenha sido analisado — um torrent não analisado não tem `zurg_sdr`, nenhuma faixa de bitrate e nenhuma faixa de duração
- Toda tag `zurg_*` é removida e recalculada a cada execução da análise; tags sem esse prefixo (tags do usuário, atribuições de diretório) são mantidas
- Várias tags de idioma podem estar presentes ao mesmo tempo
- Só uma tag de resolução é aplicada (a mais alta que corresponder)
- Só uma tag de faixa dinâmica é aplicada
- Só uma tag de faixa de bitrate de vídeo é aplicada (a mais alta que corresponder)
- Só uma tag de faixa de bitrate de áudio é aplicada (a mais alta que corresponder)
- Só uma tag de faixa de duração é aplicada (a mais alta que corresponder)
- Um fator de tolerância de 5% é aplicado nas verificações de resolução
- Os bitrates de vídeo são baseados no stream de maior bitrate (não na média)
- Os bitrates de áudio são baseados no stream de maior bitrate (não na média)
- Um stream que não informa bitrate conta como 0, então um arquivo cujos streams não têm metadados de bitrate cai na faixa `very_low`
- A duração é baseada no arquivo analisado mais longo do torrent (incluindo arquivos somente de áudio)
- Os filtros de tag podem ser combinados com outros filtros para uma organização de conteúdo mais precisa
