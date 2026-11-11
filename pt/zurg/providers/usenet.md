# Usenet

`type: nzb`

Usenet é um tipo de provedor, não um serviço debrid. Não há token de API nem biblioteca remota. Você coloca arquivos `.nzb` em um diretório de monitoramento e o zurg transforma cada um deles em um release. Os artigos são baixados do seu servidor de notícias e decodificados no momento em que um player pede esses bytes.

Esta página trata apenas da entrada do provedor e dos detalhes do Docker. Todo o resto sobre como rodar Usenet no zurg está em [Usenet com zurg](../guides/usenet.md). Esse é o passo a passo completo, com contas de notícias e NZBs, o mount e o Plex. Leia essa página em segundo lugar.

## Configure {#configure-it}

Não existe `token`. Um bloco `nntp` com um host é o que torna a entrada válida.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

Defina `connections` com o que o seu plano realmente permite. O zurg lê nesse número
porque uma conexão carrega só uma fração da velocidade do plano. O streaming
usa todo o limite permitido em vez de buscar um artigo por vez. Passar do que
o plano permite faz as conexões serem recusadas.

Em uma instalação nova do container, o setup vai pedir tudo isso.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

Para uma instalação sem interação, a senha vem de um arquivo e todo o resto vem de flags.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

`--nntp-tls` vem como true por padrão, e `--nntp-port` vem como 563 com TLS ou 119
sem.

Em uma instalação que já tem um `config.yml`, use **Add provider** no Dashboard em `http://localhost:9999/config/` ou edite o arquivo. Reinicie de qualquer forma.

```bash
docker compose restart zurg
```

## Onde os NZBs ficam em um container {#where-the-nzbs-go-in-a-container}

The watch directory is `nzbs/` beside the config. That means `~/zurg/nzbs/` on
the host and `/config/nzbs/` inside the container. It is the same directory. Put
files in from the host.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

Com apenas uma conta, a sua própria pasta `__nzb__` fica de fora da listagem da raiz do mount, então procure em `__all__`. O diretório de monitoramento é verificado a cada 15 segundos, mais ou menos. Como ele fica dentro do bind `./:/config`, ele sobrevive a um `docker compose pull` e a uma recriação do container, assim como todo o resto.

## Regras específicas deste tipo {#rules-specific-to-this-type}

- **Só pode haver uma entrada `nzb` habilitada.** Duas escaneariam o mesmo diretório e duplicariam cada release. Mais servidores de notícias devem ficar em `nntp.servers` dessa única entrada. Assim eles servem a mesma biblioteca, em vez de uma segunda cópia dela. Uma entrada `nzb` ao lado de uma entrada [`torbox_nzb`](torbox-nzb.md) também é recusada pelo mesmo motivo.
- **`watchlist: true` é recusado.** Um servidor de notícias nunca recebe um torrent.
- **`add_torrents` é ignorado**, e na inicialização aparece um aviso sobre isso pelo mesmo motivo.
- **`download_tokens` e `strm_link_token` não fazem nada.** Não há credencial para rotacionar.
- **O diretório se chama `__nzb__`** porque o nome padrão é o tipo. Defina `name: usenet` na entrada se preferir navegar por `__usenet__`.

## Um segundo servidor de notícias vale mais do que parece {#a-second-news-server-is-worth-more-than-it-looks}

A retenção é por provedor. Um artigo que um servidor já perdeu muitas vezes ainda está em outro. Sem uma segunda conta, a única forma de recuperar um artigo perdido é com PAR2, e isso custa uma leitura de **toda a release**. Por isso, um segundo servidor faz a diferença entre baixar um artigo e reler tudo.

As contas extras vão dentro de `nntp.servers` desta entrada, e não em uma segunda entrada `nzb`. `priority`, `backup` e `backbone` decidem quem é consultado e em que ordem. As leituras seguem o limite combinado das contas que não estão marcadas como `backup`. A configuração de exemplo completa e o que cada chave faz estão em [Usenet com zurg](../guides/usenet.md#more-than-one-usenet-provider).

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

Com apenas uma conta, a pasta dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

A verificação aqui autentica no servidor de notícias usando no máximo uma conexão do pool existente. Não há uma API de conta para consultar.

## Quando dá errado {#when-it-goes-wrong}

Dois sintomas são do próprio provedor e não da biblioteca.

**As leituras travam e o zurg passa a baixar um artigo por vez.** O `pipeline_depth` está maior do que o servidor aguenta. O zurg reduz o valor sozinho e mostra um aviso. Defina-o como `1` explicitamente para um servidor que não consegue lidar com vários comandos em andamento.

**A taxa de transferência é ruim em um link de alta latência.** Deixe o `socket_receive_buffer_kb` sem definir. Um buffer fixo é um que o kernel para de ajustar. No Linux, isso mantém a janela de recebimento perto de 64 KiB e custa a maior parte da velocidade da conta.

Todo o resto tem uma linha na tabela de solução de problemas em [Usenet com zurg](../guides/usenet.md#troubleshooting). Conexões recusadas, streaming lento, um provedor que nunca é consultado e uma edição no Dashboard que apagou o `nntp.servers` estão todos lá.
