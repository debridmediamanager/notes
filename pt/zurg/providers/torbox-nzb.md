# Usenet hospedado no TorBox {#torbox-hosted-usenet}

`type: torbox_nzb`

Com um plano TorBox Pro, o TorBox faz a parte do Usenet para você. O zurg envia os arquivos `.nzb` que estão no diretório de watch para a sua conta TorBox. O TorBox baixa cada release, repara e entrega como qualquer outro download do TorBox. O zurg lista o que o TorBox baixou no mount, junto com todo o resto. Você não precisa de conta em servidor de notícias, e nenhum artigo do Usenet é decodificado na sua máquina.

Isto não é o [servidor de notícias do TorBox](torbox-news-server.md). Esse é um login para o backend `nzb`, que lê os artigos por conta própria e está descrito em [Usenet](usenet.md). Também não é uma entrada `torbox`. Essa lista os seus torrents, e a página [TorBox](torbox.md) explica como ela funciona.

## O que você precisa {#what-you-need}

- **Um plano TorBox Pro.** Planos inferiores não aceitam NZBs.
- **Sua chave de API do TorBox** em [torbox.app/settings](https://torbox.app/settings).
  É a mesma chave que uma entrada `torbox` usa.
- **Um zurg nightly atual.** Os nightlies precisam de uma patrocinação ativa.
- **Um host comum.** O zurg+rex no Android, um servidor Plex no seu celular, não tem backend `torbox_nzb`. Em um dispositivo Android, reproduza NZBs hospedados no TorBox pelo TorBox Cast do DMM ou pelo addon do Kodi.

## Configure {#configure-it}

The entry takes a `token`; there is no `nntp` block. `watchlist` cannot be set on it, because an NZB account cannot add torrents.

```yaml
providers:
  - type: torbox_nzb
    token: YOUR_TORBOX_API_KEY
```

On a fresh container install save your key in `~/zurg/secrets/torbox` first, then let setup read it.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox_nzb \
  --torbox-token-file /config/secrets/torbox
```

On an install that already has a `config.yml` you can also use **Add provider** in the Dashboard at `http://localhost:9999/config/` and pick `torbox_nzb`. Restart zurg either way.

```bash
docker compose restart zurg
```

## Como os NZBs entram {#how-nzbs-get-in}

Tudo que chega a uma entrada `nzb` chega a esta da mesma forma; a ação TorBox do DMM é o único caminho que ignora o zurg.

- **O diretório de monitoramento.** Coloque um arquivo na pasta `nzbs/` ao lado da configuração (`~/zurg/nzbs/` no host, `/config/nzbs/` no container). O zurg o envia para o TorBox.
- **Sonarr e Radarr** pelo endpoint compatível com SABnzbd do zurg. Veja [Sonarr e Radarr para Usenet](../guides/sonarr-radarr.md).
- **Aquisição.** Indexadores Newznab, DMM Wanted e listas de acompanhamento enviam conteúdo para ela. Veja [Aquisição](../guides/acquisition.md).
- **A ação TorBox do DMM** em um resultado Usenet envia o NZB diretamente para o TorBox. A release também aparece no zurg, mas o zurg não guarda o NZB dela, então o botão de reparo não consegue baixá-lo de novo depois que o TorBox o descarta.

Um post que o TorBox não consegue baixar é reportado ao Sonarr ou Radarr como um download com falha. O cliente coloca a release na lista de bloqueio e faz uma nova busca.

## O que é diferente de `nzb` {#what-differs-from-nzb}

- **Sem conta de notícias.** Não há limite de conexões para configurar nem retenção de provedores para considerar. O próprio spool do TorBox decide de quais posts é possível baixar.
- **Nenhum artigo é decodificado aqui.** O TorBox baixa a release inteira. Download de artigos, reparo com PAR2, cache de artigos e verificações de artigos não se aplicam; o cache de disco dos arquivos decodificados continua valendo. Um grab é considerado concluído quando o TorBox o baixou.
- **Cache de 30 dias.** Uma release que outra pessoa já baixou no TorBox fica pronta na hora. O TorBox remove uma release 30 dias depois de tê-la guardado em cache. O botão de reparo no painel baixa a release de novo, enviando o NZB mais uma vez, então mantenha os arquivos em `nzbs/`. O zurg nunca reenvia por conta própria, porque o TorBox considera downloads automáticos repetidos como abuso.
- **Um slot por NZB em andamento.** Um post que o TorBox ainda está baixando ocupa um dos slots ativos do seu plano. Uma entrada `torbox` na mesma chave usa os mesmos slots para os seus torrents.
- **60 posts por hora.** O TorBox aceita essa quantidade de NZBs novos por hora, por chave. Um backlog grande, como uma pasta `nzbs/` cheia na primeira inicialização, leva horas para ser processado.

## Uma conta NZB por instância {#one-nzb-account-per-instance}

Uma instância aceita uma entrada `nzb` ou uma entrada `torbox_nzb`, nunca as duas. Com as duas, cada uma listaria todos os arquivos em `nzbs/`. Para usar as duas, dê à outra um instância própria com seu próprio diretório de trabalho. Com `dmm_api_key` nas duas, [desligue a fonte `dmm-wanted` em uma delas](../guides/dmm-wanted.md#two-zurgs-on-one-key), senão cada título da Wanted será buscado duas vezes. Qualquer uma das duas pode ficar ao lado das suas contas de debrid.

O addon Stremio do zurg envia a escolha dele para a conta NZB que a instância tiver. Com `torbox_nzb`, um release que a TorBox já tem começa dentro do tempo de espera do addon, desde que nenhum outro post NZB esteja na fila. Um release não cacheado precisa terminar na TorBox primeiro, o que demora mais do que o player espera.

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox_nzb/test
ls /zurg_mnt/zurg/__all__/
curl -s http://localhost:9999/http/__torbox_nzb__/ | head
```

Com apenas uma conta, a pasta dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`. O nome do diretório segue o nome da entrada, que por padrão é o tipo dela.
