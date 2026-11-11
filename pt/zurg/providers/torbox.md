# TorBox

`type: torbox`

[TorBox](https://torbox.app/subscription?referral=74ffa560-7381-4a18-adb1-cef97378c670) é a biblioteca mais barata para o zurg manter sincronizada e a mais fácil de ser limitada na leitura. A lista de torrents já traz todos os arquivos. Uma atualização da biblioteca custa uma única requisição, e não uma por torrent. O endpoint de resolução de links tem uma cota fixa, e não uma taxa. Por isso o zurg é cuidadoso com ele de propósito.

## Obtenha a chave de API {#get-the-api-key}

Entre na sua conta e abra [torbox.app/settings](https://torbox.app/settings). A chave de API está nessa página.

**Uma conta gratuita não funciona com o zurg.** O TorBox responde a todas as requisições da biblioteca feitas com uma chave gratuita usando `PLAN_RESTRICTED_FEATURE`, então o zurg não consegue ler o que a conta tem. Use um plano pago. Se um plano pago expirar, ele vira um plano gratuito da mesma forma.

## Configure {#configure-it}

```yaml
zurg: v1
providers:
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

Em uma instalação nova do container, deixe o setup gerar o arquivo.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox
```

Em uma instalação que já tem um `config.yml`, use **Add provider** no Dashboard em `http://localhost:9999/config/` ou edite o arquivo. Nos dois casos, reinicie depois.

```bash
docker compose restart zurg
```

!!!warning Uma chave do TorBox no environment do seu compose não faz nada sozinha
`TORBOX_TOKEN` é lido pelo `zurg setup` e não pelo daemon em execução. Só o `TOKEN` do Real-Debrid cria uma config na primeira inicialização. Passe a chave para um container de setup ou adicione a conta no Dashboard.
!!!

Para uma instalação automatizada, aponte o setup para um arquivo em vez de uma variável de ambiente.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

## Duas chaves que não se aplicam aqui {#two-keys-that-do-not-apply-here}

`download_tokens` é aceito, mas não faz o que deveria no Real-Debrid. Trocar para uma segunda chave não remapeia os IDs de torrent e de arquivo. No TorBox, esses IDs pertencem à conta que os listou. Uma segunda conta do TorBox precisa de sua própria entrada, com o seu próprio `name`.

```yaml
providers:
  - type: torbox
    name: tb-main
    token: FIRST_TORBOX_API_KEY
  - type: torbox
    name: tb-second
    token: SECOND_TORBOX_API_KEY
```

`strm_link_token` é aceito, mas não é usado. O TorBox gera uma URL de download a cada requisição. Não existe uma credencial de longa duração à qual um arquivo `.strm` possa ficar preso.

## Os slots ativos são o limite real {#active-slots-are-the-real-ceiling}

TorBox tem uma restrição bem característica: quantos torrents podem estar baixando ou fazendo seed ao mesmo tempo. A da Real-Debrid é a largura de banda. A da TorBox são os slots.

| Plano | Slots ativos |
|---|---|
| Free | 1, mas o zurg não pode usar uma chave free (veja acima) |
| Essential | 3 |
| Standard | 5 |
| Pro | 10 |

O zurg lê o plano a partir da conta e limita a adição de mais torrents com base nele. Uma conta cujo plano ele não consegue ler é tratada como se tivesse 3.

Dimensione tudo o mais que adiciona torrents usando esse mesmo orçamento. O Sonarr e o Radarr pegando downloads pelo endpoint do qBittorrent, uma varredura de reparo e uma watchlist disputam todos esses mesmos slots.

## Limites que vale conhecer {#limits-worth-knowing}

**A resolução de links é um orçamento de cerca de cem chamadas, e não uma taxa.**
Medido em 30/08/2026. Um 429 com `Retry-After: 300` chegou na chamada cumulativa 100 quando as chamadas foram feitas o mais rápido possível. Chegou na chamada 94 quando elas foram espaçadas em uma por segundo. O bloqueio vale para a conta inteira. Ele para o mount inteiro por cinco minutos, e não só a leitura que disparou o limite.

Disso decorrem duas coisas, e o zurg faz as duas sozinho.

- Ele nunca resolve um arquivo que ninguém pediu. Todos os outros backends ganham uma dianteira no próximo episódio. O TorBox não pode pagar por esse palpite, porque um media server analisando a biblioteca abre cada arquivo exatamente uma vez, e cada uma dessas aberturas é a frio.
- Ele resolve os volumes de um arquivo compactado em várias partes estritamente um de cada vez. Fazer em paralelo gastaria o teto várias vezes e compraria os volumes depois de um volume quebrado antes que alguém descobrisse que eles não eram necessários.

**60 adições não cacheadas por hora.** As adições cacheadas entram no orçamento por minuto.

**300 requisições por minuto, somando todos os endpoints, para uma chave.** O zurg se limita a 300 menos 60, para que as novas tentativas que o cliente HTTP faz por conta própria não empurrem uma rajada do orçamento acima do teto real.

**A 21ª conexão para um mesmo host de CDN recebe um 429.** Medido em 23/08/2026, abrindo uma conexão a cada 500ms e mantendo-a aberta. O limite é por host, e não por chave. Espalhar as leituras pela frota do TorBox evita o problema, e concentrá-las em um único nó não evita. O zurg enfileira a partir da 20ª conexão em vez de abrir uma nova. Assim, a recusa vira uma pequena espera local.

**O conteúdo é removido após a janela de retenção do plano.** Um torrent que sumiu é esperado, não quebrado. O reparo não mexe nele, a menos que você peça isso especificamente.

**Não há seleção de arquivos individuais.** Adicionar um torrent baixa tudo, e o reparo readiciona o lançamento inteiro.

O quadro completo, com as fontes, está em
[Limites do TorBox](torbox-limits.md).

## Escolhendo uma região de CDN {#choosing-a-cdn-region}

```yaml
tb_cdn_host_preference: "auto"
```

`auto` deixa a escolha do TorBox como está. `force_location_<region>` serve os downloads dessa região. Só dá para forçar regiões que estão anunciando um nó de entrega no momento, e o select do Dashboard lista exatamente essas. Não use `cdn_host_preference` aqui. Essa chave é só do Real-Debrid, e os valores dela são códigos de localização do Real-Debrid.

## Verifique se funcionou {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
ls /zurg_mnt/zurg/__all__/ | head
```

Com apenas uma conta, a pasta própria dela fica de fora da listagem da raiz do mount, então o mount mostra os mesmos arquivos em `__all__`.

## Quando dá errado {#when-it-goes-wrong}

**O log diz `Account <name> refused zurg` ou fica repetindo `TorBox rejected the API key`.**
O plano acabou e a chave agora está no plano gratuito. A partir do nightly 2026.10.11.2240,
o zurg carrega suas outras contas sem ela. O card da conta no dashboard
mostra `Refused: the account's plan does not include API access`. Os releases dela continuam
listados, mas não tocam, e nada é apagado nem movido para a lixeira por causa disso. O zurg
pergunta ao TorBox de novo a cada 10 minutos e retoma a conta assim que o plano for
pago. Nos nightlies mais antigos, a biblioteca inteira nunca terminava de carregar, então o conteúdo
das suas outras contas também parava de aparecer. Atualize o zurg ou renove o plano. Comentar
o provider `torbox` no `config.yml` e reiniciar o zurg também resolve.

**A reprodução para por cinco minutos seguidos.** A cota de requestdl acabou e o 429
vale para a conta toda. Algo está resolvendo mais links do que precisa.
Normalmente a causa é um servidor de mídia escaneando o mount inteiro de uma vez. Aponte-o para
um diretório só, em vez de todos.

**Os grabs deixam de ser aceitos.** Ou todos os slots ativos estão cheios, ou o limite
de adições por hora acabou. As duas coisas se resolvem sozinhas, e tentar de novo não ajuda em nada.

**Um release lista menos arquivos do que você esperava.** O `__torbox__` lista só o que o TorBox
realmente tem. Se outra conta tiver o release completo, o resto do mount continua servindo tudo.

**Um torrent sumiu.** Retenção. Veja acima. O zurg não o adiciona de novo sem você pedir,
porque redescobrir isso gasta a cota da conta à toa.
