# Premiumize

`type: premiumize`

O Premiumize monta as transferências concluídas **e** os arquivos na nuvem que continuam lá depois que a lista de transferências é limpa. Pastas aninhadas mantêm seus caminhos. Uma biblioteca que você organizou no Premiumize chega no mount do jeito que você deixou.

## Obtenha a chave de API {#get-the-api-key}

Faça login e abra [premiumize.me/account](https://www.premiumize.me/account). A API key fica nessa página.

## Configure {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Em uma instalação nova do container, deixe o setup gravar isso.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

Em uma instalação que já tem um `config.yml`, use **Add provider** no Dashboard em `http://localhost:9999/config/` ou edite o arquivo. Reinicie de qualquer forma.

```bash
docker compose restart zurg
```

`PREMIUMIZE_TOKEN` é lido pelo `zurg setup` e não pelo daemon em execução. Ele não faz nada se ficar sozinho em um bloco `environment:` do compose.

## Uma credencial por entrada {#one-credential-per-entry}

Os IDs de arquivo do Premiumize pertencem à conta que os listou. Não existe uma segunda chave para trocar. `download_tokens` é recusado de cara, e também um `strm_link_token` diferente de `token`. Uma segunda conta do Premiumize é uma segunda entrada, com o próprio `name`.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

O loader é explícito sobre isso em vez de ignorar as chaves em silêncio. Ele recusa a configuração e indica a entrada.

## O que funciona aqui {#what-works-here}

Navegação da biblioteca, leituras em streaming, leituras redirecionadas, STRM, adição via magnet, uploads de `.torrent` e exclusão funcionam. A conta ganha o seu próprio diretório `__premiumize__`, como todas as outras.

## Hashes são lembrados no disco {#hashes-are-remembered-on-disk}

Os hashes fornecidos pelo zurg são gravados em
`data/premiumize/<account>/sources.json` dentro do bind `/config`. A correspondência entre contas sobrevive a um reinício e também a limpar a lista de transferências concluídas.

O conteúdo da nuvem que você importou por outros meios não tem hash registrado. Ele continua sendo transmitido. Não pode ser reparado por hash e não pode ser associado a outra conta por hash.

!!!warning Excluir uma transferência exclui os arquivos dela
Excluir uma transferência do Premiumize pelo zurg também exclui os arquivos que pertencem a essa transferência. Esse é o comportamento do próprio Premiumize e não algo que o zurg adiciona por cima.
!!!

## Limites que vale conhecer {#limits-worth-knowing}

**Los límites de almacenamiento en la nube y de uso justo son los de la cuenta.** zurg no los sube ni los esquiva.

Ah, wait, this is supposed to be Brazilian Portuguese. Let me restart the translation properly.

**Os limites de armazenamento em nuvem e de uso justo são os da própria conta.** O zurg não os aumenta nem contorna.

**8 requisições simultâneas à API.** Quatro volumes de um arquivo com várias partes são resolvidos ao mesmo tempo.

**O conteúdo expira.** Um lançamento que sumiu é um resultado esperado, não um erro. O reparo não mexe nele, a menos que você peça.

**A lista de torrents não traz detalhes dos arquivos.** Cada lançamento precisa de uma consulta própria na primeira vez.

O zurg converte os códigos de erro do serviço naquilo que deve fazer em seguida.

| Código do Premiumize | O que o zurg faz |
|---|---|
| `authentication_failed` | Informa que a credencial está errada. Corrija a chave. |
| `rate_limit_reached` | Pausa a conta por um minuto. |
| `account_limit_reached` or `service_limit_reached` | Informa que a cota foi esgotada. |
| `service_down` | Trata a conta como temporariamente indisponível. |
| `not_found` | Trata o torrent como removido. |

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

Com apenas uma conta, a pasta própria dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

## Quando dá errado {#when-it-goes-wrong}

**Tudo falha com uma credencial inválida.** Gere a chave novamente em [premiumize.me/account](https://www.premiumize.me/account) e atualize a entrada.
Observe que o Premiumize responde da mesma forma quando a chave está ausente e quando está errada. A
mensagem não consegue indicar qual dos dois casos aconteceu.

**Um release faz streaming, mas não é reparado.** Ele não tem um hash registrado. Isso significa que
ele entrou na conta por uma rota diferente do zurg. Veja acima.

**As leituras pausam por um minuto de cada vez.** O limite de taxa foi atingido e o zurg
pausou a conta de propósito. Ela volta a funcionar sozinha.

**As URLs geradas funcionam para qualquer pessoa que as tenha.** URLs de entrega e acesso via `.strm`
valem a pena manter em privado. A cota que elas consomem é da própria conta.
