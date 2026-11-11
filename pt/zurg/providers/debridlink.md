# Debrid-Link

`type: debridlink`

A listagem de seedbox da [Debrid-Link](https://debrid-link.com/id/diG1t) traz todos os arquivos. Uma atualização da biblioteca custa uma única
varredura paginada, em vez de uma consulta por release. É a opção mais barata entre os três
backends de nuvem para manter em sincronia.

## Obtenha a chave de API {#get-the-api-key}

Entre e abra [debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). Gere uma chave e copie ela.

## Configure {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Em uma instalação nova do container, deixe o setup gravar isso.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

Em uma instalação que já tem um `config.yml`, use **Add provider** no Dashboard em `http://localhost:9999/config/` ou edite o arquivo. Reinicie de qualquer jeito.

```bash
docker compose restart zurg
```

`DEBRIDLINK_TOKEN` é lido pelo `zurg setup` e não pelo daemon em execução.

## Uma credencial por entrada {#one-credential-per-entry}

O Debrid-Link resolve cada arquivo por um ID que pertence à conta de listagem.
Não existe uma segunda chave para trocar. `download_tokens` é recusado, e o mesmo vale para um `strm_link_token` diferente de `token`. Uma segunda conta é uma segunda entrada, com o próprio `name`.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## O que funciona aqui {#what-works-here}

Navegação na biblioteca, leituras por streaming, leituras redirecionadas, STRM, adição por magnet e uploads de `.torrent` e exclusão funcionam. A conta ganha o seu próprio diretório `__debridlink__`.

## Limites que vale conhecer {#limits-worth-knowing}

**20 slots ativos.** Esse é o teto que o zurg usa para não deixar adicionar mais.

**8 requisições de API simultâneas.** Quatro volumes de um arquivo com várias partes são resolvidos ao mesmo tempo.

**O conteúdo expira.** Um release que sumiu é o esperado, não um erro.

**Não há verificação de cache.** O Debrid-Link desativou esse endpoint e o zurg não o usa. Um add somente-com-cache só consegue confirmar um hit pela própria resposta do add. Perguntar se algo está em cache antes de adicionar é algo que esse backend não consegue responder.

O zurg associa os códigos de erro do serviço ao que ele deve fazer em seguida.

| Código do Debrid-Link | O que o zurg faz |
|---|---|
| `badToken` ou `badSign` | Informa uma credencial inválida. Corrija a chave. |
| `floodDetected` | Pausa a conta por uma hora. |
| `maxTorrent` `maxData` `maxLink` e suas variantes `Host` | Informa que a cota diária de adds ou de tráfego acabou. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | Trata a conta como temporariamente indisponível. |
| `badId` | Trata o torrent como removido. |

!!!warning Uma recusa por flood custa uma hora
`floodDetected` deixa a conta parada por uma hora inteira, e não por um minuto. Isso é proposital. Tentar de novo logo após uma recusa por flood é o que gera a próxima. Espace o que estava sobrecarregando o serviço antes de reiniciar o zurg.
!!!

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

Com apenas uma conta, a pasta própria dela fica fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

## Quando dá errado {#when-it-goes-wrong}

**Nada acontece por uma hora.** Uma recusa de enxurrada. Veja o aviso acima.

**Os grabs são recusados, mas as leituras continuam funcionando.** A cota diária de adição ou de tráfego foi esgotada. Ela é reiniciada no cronograma do próprio serviço.

**As adições dão certo e depois ficam paradas.** Sem um endpoint de cache, não há como saber de antemão se um hash já estava disponível. Uma adição não cacheada é baixada como qualquer outra.
