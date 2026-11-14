# Internos {#internals}

Como o zurg é construído. Como ele foi medido. As notas de design por trás das partes mais complicadas. Escrito para quem está prestes a mexer no código. Nada disso é necessário para rodar o zurg.

## A forma disso {#the-shape-of-it}

| Página | O que contém |
|---|---|
| [Arquitetura](architecture.md) | A forma do conjunto e os invariantes que são fáceis de quebrar. Comece por aqui. |
| [Nomenclatura](naming.md) | Como uma release e seus arquivos acabam com os nomes que o mount mostra. |
| [Caches persistentes](persistent-caches.md) | O que fica guardado em disco entre reinícios e o que isso custa. |
| [Config de diretórios UI/UX](uiux.md) | A avaliação de design por trás do editor de diretórios. |

## O que foi medido {#what-was-measured}

| Página | O que contém |
|---|---|
| [Baseline de debrid](debrid-baseline.md) | Quanto o zurg custa e a velocidade dele com Real-Debrid, AllDebrid e TorBox. |
| [Ciclo de vida do torrent](torrent-lifecycle.md) | O que cada conta realmente informa durante um download, capturado ao vivo. |
| [Notas da API do Real-Debrid](realdebrid-behavior.md) | Semântica dos links, seleção de arquivos e o que "cached" realmente significa. |

## Contratos que o zurg precisa cumprir {#contracts-zurg-has-to-satisfy}

| Página | O que contém |
|---|---|
| [Contrato do cliente SABnzbd](sabnzbd-client-contract.md) | As formas exatas que o Sonarr e o Radarr esperam de um SABnzbd. |
| [Contrato do cliente qBittorrent](qbittorrent-client-contract.md) | O mesmo para um qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | A superfície bruta da API do Plex que o zurg usa no código. 1.2 MB. |

## Coisas que deram errado {#things-that-went-wrong}

| Página | O que contém |
|---|---|
| [Limpeza de lixo do Plex](plex-trash-sweep.md) | Alinhar a limpeza do Plex com a visão do próprio zurg sobre o que está quebrado. |
| [Regressão de timeout no stream](stream-timeout-regression.md) | Um stream em proxy que deixou de aguentar leituras longas. |
| [recusa do rclone move](rclone-move-refusal.md) | Importações vazias depois que um backend recusou um MOVE, e o patch. |

## Testes {#testing}

- [Testes E2E](e2e-test.md) explica o que a suíte end to end testa e quanto custa rodá-la.

O que cada serviço faz e quais são os limites dele fica em [Provedores](../providers/index.md), e não aqui.
