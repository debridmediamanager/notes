# Real-Debrid

`type: realdebrid`

zurg começou como um servidor do [Real-Debrid](http://real-debrid.com/?id=20476302) e ainda é o que melhor conhece. É o único
backend com seleção de arquivos por arquivo, uma lista separada `__downloads__`, seleção de host de CDN
e um token dedicado para `.strm`.

## Obtenha o token de API {#get-the-api-token}

Entre na sua conta e abra [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354).
O token é uma string hexadecimal longa. Copie tudo.

!!!warning Desative primeiro o tráfego remoto automático
Na sua [página de conta](http://real-debrid.com/?id=20476410), confirme que **Use my
Remote Traffic automatically when needed** está desmarcado. Se essa opção ficar ligada, ela gasta sua cota de tráfego remoto em streaming comum sem avisar você.
!!!

## Configure {#configure-it}

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
mount_path: "/zurg_mnt/zurg"
```

Em uma instalação nova do container, deixe o setup gerar isso para você.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider realdebrid
```

Em uma instalação que já tem um `config.yml`, use o Dashboard em
`http://localhost:9999/config/` ou edite o arquivo. Depois, reinicie.

```bash
docker compose restart zurg
```

### O único provedor que um container pode usar a partir do ambiente {#the-one-provider-a-container-can-seed-from-the-environment}

O Real-Debrid é a única conta para a qual o daemon em execução cria uma configuração sozinho. `TOKEN` ou `RD_TOKEN` no bloco `environment:` do seu compose são usados para preencher o `config.yml` na execução que cria o arquivo. `MOUNT_PATH` preenche o mount.

```yaml
    environment:
      - TOKEN=YOUR_RD_API_TOKEN
      - MOUNT_PATH=/zurg_mnt/zurg
```

As duas são lidas **só** nessa primeira execução. Depois que o arquivo existe, ele passa a ser a única fonte de verdade. Uma variável antiga nunca consegue desfazer, sem você perceber, um caminho de mount que você definiu no Dashboard. Na inicialização, aparece um aviso quando um `MOUNT_PATH` está sendo ignorado por esse motivo.

## Chaves extras que este backend usa {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: realdebrid
    token: PRIMARY_RD_TOKEN
    strm_link_token: RD_TOKEN_FOR_STRM
    download_tokens:
      - SECOND_RD_TOKEN
      - THIRD_RD_TOKEN
```

`download_tokens` são tokens de API de backup no mesmo serviço. Eles assumem quando
a franquia de banda do token ativo acaba. Eles usam o catálogo desta entrada
e as bibliotecas de torrents deles nunca são importadas.

`strm_link_token` resolve as leituras que chegam em `/strm/`, para que um player que abre
um arquivo `.strm` não gaste o token que o seu mount ao vivo está usando para transmitir. Se não estiver definido, ele usa `token` como fallback.

Os dois valem a pena ter aqui porque o Real-Debrid é um dos dois backends que
rotacionam credenciais.

## O que o Real-Debrid faz que os outros não fazem {#what-real-debrid-does-that-the-others-do-not}

- **Seleção por arquivo.** Adicionar um lançamento pode baixar só parte dele. Assim, `force_select_playable_files` tem o que processar, e o reparo pode se limitar aos arquivos quebrados em vez de adicionar o lançamento inteiro de novo.
- **Uma segunda lista chamada downloads.** `__downloads__` na raiz do mount é a lista de links sem restrição, que só o Real-Debrid tem. Limpá-la em massa precisa de um cookie de sessão da web. Por isso, o botão do Dashboard é o único caminho. Uma instalação sem conta no Real-Debrid recebe essa informação em vez de um falso sucesso.
- **Seleção de host CDN.** `rd_cdn_host_preference` escolhe entre a opção do próprio Real-Debrid, os espelhos da Cloudflare e um país específico. Veja [CDN and host selection](../reference/config.md#cdn--host-selection).
- **Reparo.** Um link do Real-Debrid registrado para um arquivo pode parar de funcionar enquanto o torrent ainda aparece como saudável. Essa é a razão de o zurg ter um subsistema de reparo, e ele é o único backend que precisa disso.

## Limites que vale conhecer {#limits-worth-knowing}

**Duas adições na mesma conta precisam de 20 segundos entre elas.** Medido contra a API ao vivo em 17/08/2026. Seis nomes de release limpos adicionados com dez segundos de intervalo foram recusados seis vezes em seis. Os mesmos seis, com vinte segundos de intervalo, foram aceitos seis vezes em seis. O zurg ajusta suas próprias adições para respeitar esse intervalo mínimo.

**Uma adição recusada parece exatamente um nome de arquivo bloqueado.** O Real-Debrid responde aos dois casos com `451 infringing_file`. O limitador também tem memória. Depois de acionado, continua recusando por minutos mesmo sem movimento. Em uma varredura de reparo em produção, passaram-se quatro horas sem nenhuma adição porque três adições caíram a menos de treze segundos uma da outra no início.

**Alguns releases são recusados só pelo nome.** Desde 14/10/2026, são onze strings. WEB-DL, WEB.x264 e WEB.H264 só contam quando aparecem exatamente assim, então web-dl, Web-Dl e o WEB.h264 da scene passam. WEBRip, BDRip, HDRip, DVDRip, HDTV.x264, HDTV.XviD, BluRay.x264 e p.BluRay.DTS contam em qualquer capitalização. Esse último precisa de um p logo antes, como em 1080p.BluRay.DTS. Um release 2002.BluRay.DTS passa sem problemas. Só o separador exato conta. WEB.DL, WEB-x264 e BluRay-x264 passam sem problemas. Um release com um desses nomes é recusado na primeira requisição, sempre, independentemente do conteúdo por trás. Um arquivo dentro de um release cujo próprio nome combina é aceito, mas não vai transmitir. O zurg conhece os padrões e recusa esses downloads localmente, em vez de gastar um slot de adição e duas tentativas de sessenta segundos em uma falha certa.

**Uma segunda cópia de um conteúdo que a conta já tem nunca é baixada.** O Real-Debrid aceita a adição e não busca nada para ela. A instância fica em 0 por cento com 0 seeders para sempre.

**A lista de torrents não traz detalhes dos arquivos.** Cada torrent precisa de sua própria chamada de info. Por isso o zurg mantém um cache de info em disco. Uma varredura fria de uma biblioteca grande é o caso caro, e o cache é o que impede que ela se repita.

Três chaves controlam o ritmo da API, e os padrões servem para uma conta comum.

```yaml
api_rate_limit_per_minute: 250
torrents_rate_limit_per_minute: 75
fetch_torrents_page_size: 5000
```

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/realdebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Com apenas uma conta, a pasta dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

## Quando dá errado {#when-it-goes-wrong}

**`RD Permission denied` no log.** A chave foi revogada ou trocada. Pegue uma nova em [real-debrid.com/apitoken](http://real-debrid.com/?id=20476302) e atualize a entrada no Dashboard ou no `config.yml`.

**Toda busca volta com 451.** Ou o nome do lançamento é um que o Real-Debrid recusa de cara, ou os arquivos foram adicionados em intervalos muito curtos e o throttle ainda está segurando. Isso se resolve com calma, não com novas tentativas.

**A montagem não lista nada na primeira inicialização.** Uma biblioteca grande demora um pouco para carregar. `/dav/movies/` responde 503 até terminar.

**Os links passam na verificação e depois não servem nada.** Ative `use_range_verification` para que o zurg verifique com um GET de um byte usando range, em vez de um `HEAD`. Algumas redes e alguns servidores do Real-Debrid respondem a um `HEAD` de forma incorreta.
