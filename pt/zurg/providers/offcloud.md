# Offcloud

`type: offcloud`

O Offcloud resolve os file handles pelo endpoint de explore da nuvem. Os tamanhos dos arquivos são verificados no servidor de entrega, e não são tomados como verdade a partir da listagem. Os metadados de torrent em cache fornecem os caminhos das pastas sempre que for possível fazer a correspondência sem ambiguidade.

## Obtenha a chave de API {#get-the-api-key}

Faça login e abra [offcloud.com/#/account](https://offcloud.com/#/account). A chave de API está nessa página.

## Configure {#configure-it}

```yaml
zurg: v1
providers:
  - type: offcloud
    token: YOUR_OFFCLOUD_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Em uma instalação nova do container, deixe o setup gravar isso para você.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider offcloud
```

Em uma instalação que já tem um `config.yml`, use **Add provider** no Dashboard em `http://localhost:9999/config/` ou edite o arquivo. Reinicie de qualquer jeito.

```bash
docker compose restart zurg
```

`OFFCLOUD_TOKEN` é lido pelo `zurg setup` e não pelo daemon em execução.

## Uma credencial por entrada {#one-credential-per-entry}

Os identificadores de arquivo do Offcloud pertencem à conta que os listou. Não existe uma segunda chave para trocar. `download_tokens` é recusado, e também é recusado um `strm_link_token` diferente de `token`. Uma segunda conta é uma segunda entrada, com o próprio `name`.

```yaml
providers:
  - type: offcloud
    name: oc-main
    token: FIRST_OFFCLOUD_API_KEY
  - type: offcloud
    name: oc-second
    token: SECOND_OFFCLOUD_API_KEY
```

## O que funciona aqui {#what-works-here}

Navegação da biblioteca, leituras por streaming, leituras redirecionadas, STRM e magnet, adições e uploads de `.torrent`, além da exclusão, funcionam todos. A conta ganha seu próprio diretório `__offcloud__`.

## Limites que vale conhecer {#limits-worth-knowing}

**8 requisições de API simultâneas.** Quatro volumes de um arquivo com várias partes são resolvidos ao mesmo tempo.

**O conteúdo expira.** Uma release que já saiu é algo esperado, não um erro. O repair a deixa de lado, a menos que você peça o contrário.

**A lista de torrents não traz detalhes dos arquivos.** Cada release exige a sua própria consulta na primeira vez.

**Uma listagem de arquivos ambígua é tratada como erro, não como um palpite.** Às vezes, os metadados de torrent em cache não podem ser associados a exatamente uma release. Nesses casos, o zurg informa o problema em vez de escolher caminhos de pasta que podem pertencer a outra coisa.

**Magnets malformados são recusados localmente.** Eles nunca chegam ao serviço. Um magnet ruim não custa nada.

O vocabulário de falhas do Offcloud é pobre. `NOAUTH` é o único código com que o zurg consegue fazer algo, e significa que a credencial foi rejeitada. Todo o resto chega como uma recusa sem motivo.

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/offcloud/test
ls /zurg_mnt/zurg/__all__/ | head
```

Com apenas uma conta, a pasta dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

## Quando dá errado {#when-it-goes-wrong}

**`NOAUTH` no log.** A chave foi revogada ou regenerada. Pegue uma nova em
[offcloud.com/#/account](https://offcloud.com/#/account) e atualize a entrada.

**`API refused request` sem mais nada.** A Offcloud não disse o motivo. Verifique
a conta no navegador antes de presumir que o problema é do zurg.

**Uma release não lista pastas.** Os metadados do torrent em cache não puderam
ser associados a exatamente uma release. Os arquivos continuam funcionando em
streaming. Só que ficam todos soltos, sem pasta.

**URLs geradas funcionam para quem tiver acesso a elas.** As URLs de entrega são
renovadas quando o cache expira ou quando uma leitura as invalida. A cota que
elas consomem é da própria conta. Mantenha essas URLs e o acesso aos `.strm`
em privado.
