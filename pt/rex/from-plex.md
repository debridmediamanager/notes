# Mudar do Plex para o rex {#move-from-plex-to-rex}

Você usa o Plex Media Server e quer testar o rex. Os seus apps do Plex continuam os mesmos. Mudam apenas a fonte da biblioteca e o endereço do servidor.

## O que muda {#what-changes}

| | Plex Media Server | rex |
|---|---|---|
| De onde vem a biblioteca | O Plex escaneia pastas em um disco ou em um mount | Uma fonte (seu próprio app, rex-stremio ou zurg) diz ao rex o que ela tem. O rex nunca escaneia uma pasta e não precisa de mount |
| O que cada arquivo é | O Plex identifica pelo nome do arquivo | A fonte descobre e informa ao rex. O rex nunca lê um nome de arquivo |
| Uma identificação errada | Fix Match no servidor | **Fix Match** em um app do Plex, logado com a conta que é dona do rex. O rex guarda a sua escolha, e uma fonte pode desfazê-la e mantê-la, como faz o zurg ([por que os títulos são colocados como estão](with-zurg.md#why-dmm-places-the-files)) |
| A conta do servidor | Geralmente a sua | Uma conta nova do Plex criada para o rex, compartilhada com a sua |
| Música, Live TV e fotos | De pastas e de um sintonizador | Somente de uma fonte que as envie, como um addon ([Building rex addons](addons.md#music)) ou os quadrinhos do zurg. O Plex Web mostra fotos; o Plex para Android não |
| Gravar TV | Sim | Não |

## Escolha um caminho {#pick-a-way}

| | Ao lado do Plex | No lugar do Plex |
|---|---|---|
| O que você ganha | rex ao lado do seu Plex. Seus apps listam os dois servidores | rex sozinho, na porta usual do Plex |
| Ideal para | Testar o rex, ou manter o Plex para fotos ou músicas em um disco, ou para gravar TV | Mudar de vez |
| Na mesma máquina do Plex | rex roda na porta `32500`, e seus apps o encontram pela conta Plex com a qual ele é compartilhado | O Plex é parado, o rex assume a porta `32400` e os apps em casa o encontram sozinhos |

Comece ao lado do Plex, mesmo que você pretenda substituí-lo: copiar o seu histórico de exibição precisa que o seu servidor Plex antigo esteja rodando. Faça os passos 1 a 3, use o rex por um tempo e faça o passo 4 quando estiver pronto.

## Passo 1. Configure o rex ao lado do Plex {#step-1-set-up-rex-beside-plex}

Configure o rex com a fonte que vai alimentá-lo, como em [rex com seu próprio app](any-source.md), [rex com seus addons do Stremio](stremio.md) ou [rex com o zurg](with-zurg.md), até assistir algo. Já usa o zurg com o Plex? Pule a instalação e atualize-o como manda o passo 1 de rex com o zurg: o zurg alimenta o rex a partir da versão noturna **2026.10.27**.

- **O Plex roda na mesma máquina?** Coloque o rex na porta `32500`, como diz [Instalar o rex](any-source.md#step-1-install-rex) para esse caso, e informe essa porta também na sua fonte. Assim, seus apps vão listar dois servidores com o nome da máquina: o rex é o que é compartilhado com você, com o nome da conta nova ao lado. [Instalar o rex](any-source.md#step-1-install-rex) explica como renomeá-lo.
- **Registre o rex em uma conta nova do Plex,** não na conta em que está o seu servidor Plex, como explica [Adicione-o a uma conta do Plex](any-source.md#step-3-add-it-to-a-plex-account).
- **Longe de casa com o rex-direct?** A porta 32400 do seu roteador já vai para o Plex. Encaminhe também a porta `32500` para a máquina do rex ou, [por IPv6](any-source.md#rex-direct-over-ipv6), libere a `32500` para ela.

Usando o zurg? Enquanto os dois estiverem rodando, o zurg alimenta os dois. Deixe tudo o que o zurg tem para o Plex como está (`plex_server_url`, `plex_token`, seu mount do rclone e qualquer script de scan): o Plex continua funcionando como antes, e `rex_url` acrescenta o rex.

## Passo 2. Traga seu histórico de exibição {#step-2-bring-your-watch-history}

Quando sua biblioteca estiver no rex, [Traga seu histórico de exibição](import-watched.md) copia o que você assistiu, onde você parou e suas avaliações com estrelas do seu servidor Plex. Faça isso enquanto o Plex ainda estiver rodando. Cada pessoa com quem você compartilha executa isso para o próprio histórico.

## Passo 3. Convide as pessoas de novo {#step-3-invite-your-people-again}

Seus amigos e familiares foram convidados para o seu servidor Plex, não para o rex. O rex é um servidor novo, na conta nova, então convide-os por lá e eles aceitam como em qualquer compartilhamento: [Compartilhe o rex com família e amigos](sharing.md).

## Passo 4. Desativar o Plex (opcional) {#step-4-retire-plex-optional}

Só para substituir o Plex. Ignore isto se quiser manter os dois.

**Pare o Plex de vez.** No Linux, rode `sudo systemctl disable --now plexmediaserver`. No Docker, pare o contêiner dele e tire-o do seu arquivo compose. No Windows e no macOS, feche o Plex Media Server e tire-o dos apps que iniciam quando você faz login.

**Mude o rex para a porta 32400** se ele estava na `32500`, ao lado do Plex, na mesma máquina:

1. Tire `--port 32500` do comando de início do rex (ou da linha `command:` no Docker) e reinicie o rex, como mostra [Instalar o rex](any-source.md#step-1-install-rex) para o seu sistema. No Windows, libere a 32400 e as duas portas de descoberta no firewall, como esse passo indica.
2. Informe ao seu source o novo endereço do rex, `http://192.168.1.20:32400` (o IP da LAN do rex), e reinicie-o: o `rex_url` do zurg, ou o **rex's address** na página de configurações do rex-stremio.
3. Troque `32500` por `32400` em qualquer outro lugar onde você informou o endereço do rex, como no Kometa.
4. Com o rex-direct, aponte o redirecionamento de porta 32400 do seu roteador para a máquina do rex e remova o de `32500`. Via IPv6, troque a regra do firewall de `32500` para `32400` e reinicie o rex, para que ele anuncie o IPv6 na nova porta.

O rex passa a responder na porta 32400, e os apps Plex dentro de casa encontram ele sozinhos na sua rede.

**Usa o zurg? Ajuste as configurações de Plex dele.** O config do zurg pode ainda apontar para o Plex que você parou:

| No `config.yml` do zurg | O que fazer |
|---|---|
| `plex_server_url` e `plex_token` | Apague os dois, ou clique em **Remove** ao lado do Plex no painel do zurg (página de configuração, **Media Server Integration**). Usa a [watchlist do Plex](../zurg/guides/plex-watchlist.md) do zurg? Apague só o `plex_server_url`: a watchlist é lida do plex.tv com o `plex_token` e não precisa de servidor Plex. Você também pode apontá-los para o rex: clique em **Re-Auth** ali, faça login com a conta nova e escolha o rex. O zurg 2026.10.27 e versões mais novas veem que o servidor é o rex e não enviam scans, correspondência do Plex, correção de temporadas nem verificações de configurações do Plex. Nesse caso o token é o da conta nova, então uma watchlist do Plex seguiria essa conta |
| `on_library_update` rodando um scan do Plex, como o `plex_update.sh` | Apague. O rex fica sabendo de cada mudança direto pelo zurg |
| `plex_database_path`, `plex_scan_check_url` e `plex_scan_check_token` | Apague. Eles se referem ao Plex que você parou |
| Seu mount do rclone (`rclone_enabled: true`, ou um rclone que você roda por conta própria) | Mantenha se o Sonarr, o Radarr, o Bazarr ou outro app lê arquivos ali. Se o Plex era o único leitor, você pode desligar: o rex lê cada arquivo direto do zurg |

Reinicie o zurg depois de editar o config.

## O que vem junto e o que não vem {#what-comes-along-and-what-does-not}

| Vem junto | Como |
|---|---|
| Seus filmes e séries | Sua fonte os envia para o rex. Com o zurg, eles vêm da mesma conta de debrid que o Plex lê |
| O que você assistiu, onde parou e suas notas de filmes e episódios | [Traga seu histórico de exibição](import-watched.md), cada pessoa na sua própria conta |

| Não vem junto | Por quê |
|---|---|
| Correções que você fez no Plex | O rex não usa as correspondências do Plex. Sua fonte diz o que é cada arquivo; corrija o que ela errar com **Fix Match** no rex |
| Coleções | Não são copiadas. [Kometa com o rex](kometa.md) as recria a partir da sua configuração do Kometa |
| Pôsteres e artes que você escolheu | Ficam só no servidor antigo |
| Playlists e a lista de histórico de reprodução do servidor | Ficam só no servidor antigo |
| Acesso dos seus amigos | Eles foram convidados para o servidor antigo. Convide-os para o rex ([passo 3](#step-3-invite-your-people-again)) |
| Músicas e fotos em um disco, TV ao vivo de um sintonizador e gravações | O rex não tem sintonizador e não grava nada; músicas, fotos e canais ao vivo vêm apenas de uma fonte que os envie. Mantenha o Plex junto com o rex para eles |
| Arquivos em um disco local | O rex não escaneia pastas. Um app precisa servir esses arquivos e avisar o rex sobre eles: [rex com seu próprio app](any-source.md) |
