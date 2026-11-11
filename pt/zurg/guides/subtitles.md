# Legendas com o Bazarr {#subtitles-with-bazarr}

Bazarr encontra legendas para o que o Sonarr e o Radarr importam e salva cada uma delas ao lado do seu vídeo. Com o zurg, o vídeo fica em `__magic__`, e a legenda também. Bibliotecas do Plex e do Jellyfin apontadas para `__magic__` leem a legenda como qualquer legenda em disco, e o rex também a mostra, como **English (SRT External)** no menu de legendas.

Isso precisa do zurg e do rex da nightly de 2026-10-24 ou mais recente.

Tudo abaixo foi testado em 2026-10-23 com o Radarr `6.3.0.10514`, a imagem atual `lscr.io/linuxserver/bazarr`, o zurg e o rex desse dia, e uma conta do Real-Debrid.

## Antes de começar {#before-you-start}

Radarr (ou Sonarr) já importa pelo zurg, com a pasta raiz dentro de `__magic__`, por exemplo `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` no macOS, `Z:\__magic__\movies` no Windows). Se ainda não estiver assim, siga primeiro [Sonarr & Radarr for torrents](sonarr-radarr-torrents.md) ou [for Usenet](sonarr-radarr.md).

## 1. Execute o Bazarr {#1-run-bazarr}

Em um host Linux, dê ao Bazarr o mesmo volume que o Radarr, para que os dois vejam o filme no mesmo caminho e não precise de mapeamento de caminhos:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

O bind é a pasta **acima** do mount do zurg (`/mnt`, que contém `/mnt/zurg`), não o próprio mount. Um container que faz bind direto no mount mantém um mount morto depois que o zurg reinicia, e toda leitura responde `Socket not connected`. [O passo do Docker no guia de torrents](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) explica o motivo. `PUID` e `PGID` precisam do mesmo cuidado que no Whisparr: [veja lá](whisparr.md#2-run-whisparr).

No macOS e no Windows este arquivo compose não se aplica, pelo motivo que o [passo 8 do guia do Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker) explica. Rode o Bazarr a partir do código-fonte (`python bazarr.py`) na mesma máquina que o Radarr e o zurg, com o mesmo usuário do zurg, seguindo as páginas do próprio Bazarr para [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) e [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). No Windows, pule o instalador do Bazarr: ele configura o Bazarr como um serviço do Windows, e um serviço não enxerga o drive `Z:` do zurg ([por quê](sonarr-radarr.md#before-you-start)). Inicie o `bazarr.py` a partir da sua própria sessão logada. Assim ele enxerga cada filme no caminho que o Radarr informa, e não precisa de mapeamento de caminhos. Só a imagem Docker acima foi testada.

Abra `http://<your server>:6767`.

## 2. Conecte ao Radarr e ao Sonarr {#2-connect-it-to-radarr-and-sonarr}

**Settings → Radarr**: ative a opção e informe o endereço, a porta e a API key do Radarr (em **Settings → General** do Radarr). De dentro de um container, use o IP da LAN do host, e não `localhost`. Clique em **Test** e depois em **Save**. O Sonarr funciona da mesma forma em **Settings → Sonarr**.

## 3. Idiomas {#3-languages}

**Settings → Languages**: adicione os idiomas que você quer, crie um perfil de idioma com eles e defina-o como perfil padrão para filmes e para séries. Depois disso, o Bazarr passa a buscar legendas para tudo o que o Radarr e o Sonarr já têm.

## 4. Provedores {#4-providers}

**Settings → Providers**: adicione os sites de legendas que o Bazarr pesquisa. Alguns precisam de conta e outros não. Duas coisas que encontramos durante os testes:

- O **subf2m** precisa de um User-Agent nas configurações do provedor. Sem ele, o Bazarr pausa o provedor por 12 horas na primeira pesquisa.
- O Bazarr pausa um provedor que falha por um tempo, e se todos os provedores estiverem pausados, uma pesquisa não encontra nada. **System → Providers** mostra a lista deles e permite resetá-los.

## 5. Legendas embutidas {#5-embedded-subtitles}

Muitos lançamentos já trazem uma faixa em inglês dentro do próprio arquivo de vídeo. O Bazarr entende que o inglês já está ali e não baixa nada. Se você quiser um arquivo de legenda mesmo assim, desative **Use Embedded Subtitles** em **Settings → Subtitles**.

## 6. Teste um {#6-check-one}

Na página **Movies** do Bazarr você vê o que cada filme está faltando. Pesquise um filme por ali, e a legenda vai parar ao lado do vídeo (no Windows, procure na mesma pasta em `Z:\__magic__\movies` no Explorador de Arquivos):

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

A legenda é um arquivo real no disco do zurg, em `data/local/__magic__/` (veja [Sidecars](magic.md#sidecars-nfo-posters-subtitles)). O vídeo continua sendo transmitido da sua conta.

## No rex {#in-rex}

O zurg envia para o rex todas as legendas que ficam ao lado de um vídeo em `__magic__`, não importa para onde o Radarr ou o Sonarr moveram esse vídeo. O zurg procura legendas novas, alteradas e removidas uma vez por minuto, então uma legenda que o Bazarr salvar aparece no rex em cerca de um minuto, e uma que você apagar some na mesma velocidade. Não é preciso configurar nada além de `rex_url` no config do zurg, que [o guia do rex](../../rex/with-zurg.md) já manda você definir.

O nome do arquivo diz qual é a legenda, do mesmo jeito que o Plex lê os nomes de legenda:

| Nome do arquivo termina em | o rex mostra |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`, `.en.sdh.srt`, `.en.cc.srt` | English SDH (SRT External) |

`.srt`, `.ass`, `.ssa`, `.smi` e `.txt` são lidos. O idioma pode ser um código de duas ou três letras (`en`, `eng`, `de`, `ger`). O nome antes dele precisa ser o nome do próprio vídeo, como o Bazarr escreve.

Só as legendas em `__magic__` chegam ao rex. Uma salva ao lado de um arquivo em outra pasta do zurg, como `/mnt/zurg/movies`, não é enviada.

O rex também consegue buscar legendas sozinho: **Search Subtitles** em qualquer app do Plex, sem nenhum Bazarr. Veja [legendas do rex](../../rex/with-zurg.md#subtitles).
