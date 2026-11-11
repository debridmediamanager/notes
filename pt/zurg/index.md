# zurg

zurg coloca suas contas de debrid e sua biblioteca Usenet em uma única pasta virtual. Ele não armazena nenhum vídeo localmente. Nada é baixado até que um player peça. Um remux de 60 GB não ocupa 60 GB de espaço em disco local.

Quatro visões sobre a mesma biblioteca:

| Endpoint | Para |
|---|---|
| `/dav/` | WebDAV, o que o rclone monta |
| `/http/` | Navegador de diretórios em HTML |
| `/infuse/` | Variante do WebDAV com os detalhes do Infuse tratados |
| `/strm/` | URLs assinadas dentro de arquivos `.strm`, para players que querem uma URL em vez de um mount |

## Configuração {#setup}

Coloque o zurg para rodar na sua máquina.

- [Linux](setup/linux.md) — FUSE 3 e início automático com systemd
- [Docker](setup/docker.md) — um host Linux com um mount visível no host
- [macOS](setup/macos.md) — macFUSE e início automático com launchd
- [Windows](setup/windows.md) — WinFsp e uma tarefa de letra de unidade

## Provedores {#providers}

Aponte o zurg para uma conta. Cada página cobre a credencial e a entrada no `config.yml`. Os exemplos usam Docker. Uma instalação binária usa a mesma entrada no config. Veja [Configuração](setup/index.md) para os comandos.

| Página | O que é diferente nela |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | Seleção por arquivo, `__downloads__`, escolha do host de CDN, um token `.strm` separado |
| [TorBox](providers/torbox.md) | Uma requisição por atualização da biblioteca, e um teto de slots ativos em vez de um teto de banda |
| [AllDebrid](providers/alldebrid.md) | As listas de arquivos vêm de um endpoint próprio, então a primeira varredura é preenchida aos poucos |
| [Premiumize](providers/premiumize.md) | Transferências concluídas mais os arquivos da nuvem que ficaram para trás, com as pastas intactas |
| [Debrid-Link](providers/debridlink.md) | A listagem do seedbox traz todos os arquivos, e não há verificação de cache |
| [Offcloud](providers/offcloud.md) | Tamanhos verificados no servidor de entrega, caminhos de pastas a partir de metadados em cache |
| [Usenet](providers/usenet.md) | O tipo `nzb` como entrada de provedor. Sem token; em vez disso, um diretório de monitoramento |
| [Limites do TorBox](providers/torbox-limits.md) | Os números medidos por trás da limitação do TorBox, e como o zurg regula o ritmo em relação a eles |
| [Servidor de notícias do TorBox](providers/torbox-news-server.md) · [Servidor de notícias do ElfHosted](providers/elfhosted-news-server.md) | Como são as contas Usenet incluídas, no tráfego de rede |

[A página compartilhada](providers/index.md) tem as três formas de adicionar uma conta no Docker e as regras que o carregador de configuração aplica.

## Guias {#guides}

- [Usenet](guides/usenet.md) — o backend `nzb` de ponta a ponta: contas de news, NZBs, o mount, Plex
- [Sonarr & Radarr for Usenet](guides/sonarr-radarr.md) — os \*arrs buscam e o zurg responde como um SABnzbd, então as importações são só um rename, não um download
- [Sonarr & Radarr for torrents](guides/sonarr-radarr-torrents.md) — o mesmo, com o zurg respondendo como um qBittorrent; o Prowlarr também
- [zurg searches for Sonarr & Radarr](guides/sonarr-radarr-fetch.md). O Radarr e o Sonarr guardam a lista, e o zurg encontra e coloca o release. Não há indexers nem download client em nenhum dos dois.
- [`__magic__`](guides/magic.md) — o único diretório cujo layout fica guardado, e por isso é seu para organizar, com sua biblioteca arquivada por título para Kodi e Plex
- [Renaming](guides/renaming.md) — renomeie um release ou um arquivo em qualquer lugar da biblioteca. Um move é recusado, e a página explica o motivo
- [Plex](guides/plex.md) — o que o zurg faz com um token do Plex, e o que ele deliberadamente não faz
- [Jellyfin](guides/jellyfin.md) — o mesmo, para o Jellyfin
- [rex with zurg](../rex/with-zurg.md) — um servidor de mídia para os apps do Plex que não possui arquivo nenhum, preenchido pelo zurg a partir da sua conta de debrid. Mais em [rex](../rex/index.md)
- [The Stremio addon](guides/stremio.md) — o Stremio buscando nos seus próprios indexers, reproduzindo direto do backend de Usenet
- [Watchlist and Seerr](guides/acquisition.md) busca o que você pedir pelos seus próprios indexers
- [Plex watchlist](guides/plex-watchlist.md) é o lado do Plex nisso
- [DMM wanted list](guides/dmm-wanted.md) busca o que você marcar com Want no DMM, sem nada mais para configurar
- [Local libraries](guides/local-libraries.md) reproduz uma lista compartilhada de releases pela sua própria conta
- [Android and Google TV](guides/android.md) roda a biblioteca inteira em um celular ou em um TV box

## Migrando {#migrating}

Mova uma biblioteca existente para o zurg sem precisar baixar tudo de novo ou escanear novamente.

- [Vindo do AltMount](migrate/altmount.md)
- [Vindo do decypharr](migrate/decypharr.md)
- [Vindo do InfiniDysk](migrate/infinidysk.md)
- [Vindo do nzbdav](migrate/nzbdav.md)
- [Vindo do streamnzb](migrate/streamnzb.md)

## Referência {#reference}

- [Configuração](reference/config.md) — todas as opções do `config.yml`
- [Linha de comando](reference/cli.md) lista todos os comandos e flags que o binário aceita
- [Identidade de saída](reference/outbound-identity.md) explica o que o zurg informa sobre si mesmo aos serviços que ele chama
- [Servidor MCP](reference/mcp.md) permite que um agente de IA controle o zurg pelo Model Context Protocol
- [Tags](reference/tags.md) — o que é aplicado a um torrent, e por quê
- [Changelog](reference/changelog.md) — o que mudou e quando

## Internos {#internals}

Como o zurg é construído, o que foi medido nele e as notas de design por trás das partes mais complicadas.

- [Arquitetura](internals/architecture.md) — a estrutura geral e os invariantes que são fáceis de quebrar
- [Baseline de debrid](internals/debrid-baseline.md) — quanto o zurg custa e a velocidade percebida em RD, AD e TorBox
- [Ciclo de vida do torrent](internals/torrent-lifecycle.md) — o que cada conta realmente informa enquanto um download roda, medido ao vivo
- [Contrato do cliente SABnzbd](internals/sabnzbd-client-contract.md) — os formatos exatos que o Sonarr e o Radarr esperam
- [Varredura de lixo do Plex](internals/plex-trash-sweep.md) · [Regressão de timeout de stream](internals/stream-timeout-regression.md) · [Configuração de diretórios UI/UX](internals/uiux.md)
- [Testes E2E](internals/e2e-test.md) · [Notas da API do Real-Debrid](internals/realdebrid-behavior.md)
- [Contrato do cliente qBittorrent](internals/qbittorrent-client-contract.md) · [Caches persistentes](internals/persistent-caches.md)
- [Nomenclatura](internals/naming.md) · [Recusa de move do rclone](internals/rclone-move-refusal.md)

---

O zurg é distribuído para os patrocinadores: [GitHub Releases](https://github.com/debridmediamanager/zurg/releases)
· [Patrocínio](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
