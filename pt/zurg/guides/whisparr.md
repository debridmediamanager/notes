# Whisparr

Whisparr é o Radarr para filmes e cenas adultas. Ele usa o zurg como cliente qBittorrent. Os downloads vão para a sua conta de debrid. Importar só renomeia um caminho dentro de `__magic__`; nada é baixado nem copiado.

Tudo abaixo foi testado em 2026-10-23 com Whisparr `3.6.5.1886` (a imagem `ghcr.io/hotio/whisparr:v3`), Prowlarr, zurg compilado do `main` daquele dia e uma conta Real-Debrid. Um filme de 17 GB foi pedido, importado e reproduzido a partir do mount.

## Antes de começar {#before-you-start}

Configure o zurg para o Radarr primeiro, seguindo [Sonarr e Radarr para torrents](sonarr-radarr-torrents.md): uma conta que aceita torrents, `__magic__` ativado e o endpoint do qBittorrent ativado. O Whisparr reaproveita tudo isso.

## 1. Categoria do Whisparr no zurg {#1-whisparrs-category-in-zurg}

Whisparr envia seus downloads sob a categoria `whisparr`. O botão **Test** no passo 3 cria essa categoria no zurg, então não precisa adicionar nada. Para listá-la no `config.yml` mesmo assim, adicione-a junto das que já existem:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. Executar o Whisparr {#2-run-whisparr}

No Linux, dê ao Whisparr o mesmo volume do Radarr: a pasta **acima** do mount do zurg, com `rslave` ([por quê](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` e `PGID` são o usuário do Linux com que o Whisparr roda. A imagem Docker do próprio zurg deixa qualquer usuário ler o mount. Um zurg instalado como binário comum só faz isso se rodar como root ou com `user_allow_other` ativado ([configuração no Linux](../setup/linux.md#1-install-fuse-3)). Caso contrário, defina `PUID` e `PGID` com o usuário que roda o zurg (`id -u` e `id -g` mostram esses valores), ou o Whisparr vai ver o mount vazio.

No macOS e no Windows este arquivo compose não se aplica, pelo motivo explicado no [passo 8 do guia de Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). Instale o Whisparr como um app normal, com os cuidados listados em [Antes de começar](sonarr-radarr.md#before-you-start) nesse guia: o mesmo usuário do zurg no macOS, e o app de bandeja e não o serviço do Windows no Windows. Só a imagem Docker acima foi testada.

Abra `http://<your server>:6969`.

## 3. Adicionar o zurg como cliente de download {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**, preenchido exatamente como no Radarr ([os campos](sonarr-radarr-torrents.md#what-to-put-in-each-field)), exceto que **Category** é `whisparr`. Deixe **Remove Completed** ativado. **Test** e depois **Save**.

## 4. Adicionar a pasta raiz {#4-add-the-root-folder}

Crie a pasta no mount e depois adicione-a em **Settings → Media Management → Root Folders**:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

Ela fica ao lado de `__magic__/movies`, não dentro dela. O Whisparr organiza cada filme por estúdio, em `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. Indexadores {#5-indexers}

DMM não tem uma categoria adulta no indexador, então o Whisparr precisa de outros indexadores. No Prowlarr, os indexadores públicos **Knaben** e **The Pirate Bay** funcionaram bem. O **XXXClub** fica atrás do Cloudflare, e o Prowlarr não consegue adicioná-lo sem um solver do Cloudflare.

Depois, conecte o Prowlarr ao Whisparr em **Settings → Apps → + → Whisparr** no Prowlarr, com o endereço do Whisparr e a API key (em **Settings → General** do Whisparr). O Prowlarr adiciona os indexadores no próprio Whisparr.

O zurg só aceita releases que a sua conta já tem em cache (`cached_only`, ativado por padrão). Quando ele recusa um, o Whisparr pega o próximo resultado.

## 6. Baixar um {#6-grab-one}

Adicione um filme no Whisparr com **Start search for missing movie** marcado. Quando funcionar, o histórico do Whisparr mostra **Grabbed** e depois **Imported** em poucos segundos, e o filme aparece na montagem:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

No macOS, o caminho começa com `/Volumes/Zurg`. No Windows, procure `Z:\__magic__\whisparr\movies` no Explorador de Arquivos. Nada aparece na pasta `data/local` do zurg. O arquivo é transmitido da sua conta.

## Assistindo {#watching-it}

Aponte uma biblioteca do Plex ou do Jellyfin para `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` no macOS, `Z:\__magic__\whisparr` no Windows) para manter esses filmes em uma biblioteca própria.

No rex, eles aparecem na biblioteca em que as pastas do zurg os colocam, como qualquer outro lançamento, o que na maioria das configurações é a biblioteca de filmes.
