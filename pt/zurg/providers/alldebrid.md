# AllDebrid

`type: alldebrid`

[AllDebrid](https://alldebrid.com/?uid=1kk5i&lang=en) é o outro backend que rotaciona credenciais. Então `download_tokens`
e um token separado para `.strm` significam algo aqui. As listas de arquivos dele vêm
de um endpoint próprio, e não da lista de magnets. Isso muda o que é a primeira varredura de uma biblioteca grande.

## Obtenha a chave de API {#get-the-api-key}

Faça login e abra [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i).
Gere uma chave e copie.

## Configure {#configure-it}

```yaml
zurg: v1
providers:
  - type: alldebrid
    token: YOUR_ALLDEBRID_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Em uma instalação nova do container, deixe o setup gravar isso para você.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider alldebrid
```

Em uma instalação que já tem um `config.yml`, use **Add provider** no Dashboard em `http://localhost:9999/config/` ou edite o arquivo. Reinicie de qualquer jeito.

```bash
docker compose restart zurg
```

`ALLDEBRID_TOKEN` é lido pelo `zurg setup` e não pelo daemon que está rodando. Colocá-lo no bloco `environment:` do seu compose e iniciar o container não faz nada por si só.

## Chaves extras que este backend usa {#extra-keys-this-backend-uses}

```yaml
providers:
  - type: alldebrid
    token: PRIMARY_AD_API_KEY
    strm_link_token: AD_KEY_FOR_STRM
    download_tokens:
      - SECOND_AD_API_KEY
```

`download_tokens` são chaves de backup do mesmo serviço. Elas assumem quando a franquia de banda da chave ativa acaba. Elas usam o catálogo desta entrada e as bibliotecas delas nunca são importadas.

`strm_link_token` resolve as leituras que chegam em `/strm/`, assim um player que abre um `.strm` não gasta a chave que o seu mount ao vivo usa para transmitir. Quando não está definido, ele usa `token` no lugar.

## A primeira varredura preenche aos poucos {#the-first-scan-fills-in-gradually}

AllDebrid v4.1 moved os detalhes dos arquivos da lista de magnets para um endpoint separado. Listar seus magnets não diz ao zurg o que há dentro deles. Cada release precisa de uma consulta.

A boa notícia é que essa consulta é feita **uma única vez para sempre**, e não uma vez a cada reinício. A árvore de arquivos de um magnet é imutável assim que ele fica Ready. Por isso, o cache de informações em disco do zurg é permanente para ele. Um batcher na frente do endpoint cuida da varredura inicial. O que você vê numa primeira execução é uma biblioteca grande aparecendo aos poucos, e depois isso nunca mais acontece.

## Limites que vale conhecer {#limits-worth-knowing}

**Sem limite publicado para magnets ativos.** O zurg não inventa um. O reparo nunca espera por espaço que nunca foi escasso.

**600 requisições por minuto para uma chave.** Esse é o limite documentado. O zurg controla o ritmo em 600 menos 100, para que as novas tentativas que o próprio cliente HTTP faz não empurrem uma rajada acima do teto real. Na prática, a concorrência é a restrição que realmente limita, e ela é limitada a 12 para espelhar as 12 requisições por segundo documentadas.

**A 33ª conexão a um mesmo servidor de entrega recebe um 429.** Medido em 2026-08-23 abrindo uma conexão a cada 500ms e mantendo-a aberta. O AllDebrid gera um novo nome de host de entrega a cada desbloqueio. Por isso, isso só se aplica quando várias leituras acabam compartilhando o mesmo host. O zurg coloca na fila além de 32, em vez de discar.

**Não há seleção por arquivo.** Adicionar um magnet baixa tudo, e o reparo readiciona o lançamento inteiro.

**O conteúdo some sozinho.** Magnets são removidos de uma conta com o tempo, e um link pode ser derrubado pelo host. Um lançamento que desapareceu é um resultado esperado, não corrupção. O reparo o deixa em paz, a menos que você peça o contrário.

**Os links guardados não apodrecem.** Os links bloqueados registrados para um arquivo são gerados de novo a partir do estado atual do magnet. O próprio status do magnet já informa se os dados estão lá. O zurg não gasta um desbloqueio por torrent em cada varredura fria só para descobrir o que o status já dizia de graça.

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/alldebrid/test
ls /zurg_mnt/zurg/__all__/ | head
```

Com apenas uma conta, a pasta própria dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

## Quando dá errado {#when-it-goes-wrong}

**`AllDebrid rejected the API key` no log.** A chave foi revogada ou gerada de novo. Pegue uma nova em [alldebrid.com/apikeys](https://alldebrid.com/apikeys?uid=1kk5i) e atualize a entrada.

**A biblioteca fria aparece devagar.** É esperado. Veja a seção acima. É uma consulta por release e ela não se repete.

**Um release toca em outro ponto do mount, mas dá 404 em `__alldebrid__`.** A verificação de problema é feita por conta, e esse diretório fixa as leituras nesta conta. Outra conta deve ter uma cópia boa.
