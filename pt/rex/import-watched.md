# Traga seu histórico de exibição para o rex {#bring-your-watch-history-to-rex}

rex começa sem histórico de exibição. Ele pode copiar os títulos assistidos, os pontos de continuação e as avaliações com estrelas de outro servidor Plex.
Títulos assistidos continuam marcados como assistidos. Títulos assistidos pela metade voltam para **Continue Watching**. Séries e temporadas contam os episódios de novo.

Execute uma vez a partir de qualquer computador de casa. Cada pessoa que usa o rex pode importar o próprio histórico.

## Antes de começar {#before-you-start}

| Você precisa de | Por quê |
|---|---|
| rex configurado, com sua biblioteca nele, como em [rex com seu próprio app](any-source.md), [rex com seus addons do Stremio](stremio.md) ou [rex com zurg](with-zurg.md) | O rex copia o histórico apenas para títulos que ele já tem. Se sua biblioteca ainda estiver sendo preenchida, rode a importação de novo depois: ela só adiciona o que é novo |
| rex nightly **2026.10.31 ou mais recente** | Atualize como em [seção Updating do rex](any-source.md#updating) |
| Seu servidor Plex antigo, em execução | O rex lê o histórico dele. Inicie de novo se você o desligou quando passou para o rex |
| Um computador na sua rede doméstica, com `curl` | A importação só roda a partir da sua rede doméstica. Windows 10 e 11, macOS e Linux têm todos o `curl` |

## 1. Copie o endereço do seu servidor antigo {#1-copy-your-old-servers-address}

1. Abra [app.plex.tv](https://app.plex.tv) no navegador e entre como **você mesmo**, com a conta cujo histórico você quer.
2. Escolha seu servidor antigo e abra qualquer filme nele.
3. Clique em **⋯** (More) e depois em **Get Info**.
4. Clique em **View XML** no canto inferior esquerdo da caixa **Media Info** que abrir. Uma nova aba se abre, cheia de texto.

   ![A caixa Media Info que o Get Info abre, com View XML no canto inferior esquerdo](../assets/rex/40-plex-get-info.webp)
5. Copie o **endereço completo** da barra de endereço dessa aba.

Ele fica parecido com isto, tudo em uma linha só, e termina com `X-Plex-Token=` seguido de um código:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

Esse código é o seu **Plex token** para esse servidor. Ele funciona como uma senha da sua conta Plex: nunca cole no Discord, em um post de suporte ou em uma captura de tela.

**Não aparece View XML no passo 4?** O Plex Web mostra essa opção só em servidores que são seus, então um servidor que alguém compartilhou com você não tem. Nesse caso, use as ferramentas de desenvolvedor do navegador no seu servidor antigo, como no [passo 2](#2-get-your-token-on-rex), e escolha uma requisição para o seu servidor antigo (o endereço dela tem `plex.direct`). Clique com o botão direito e copie o endereço: **Copy**, **Copy URL** no Chrome e no Edge, **Copy Value**, **Copy URL** no Firefox. Esse endereço é o que você precisa. Ele tem `X-Plex-Token=` e o código, junto com outras partes `X-Plex-`: cole tudo.

## 2. Pegue seu token no rex {#2-get-your-token-on-rex}

rex é compartilhado com você, então **Get Info** no rex não tem **View XML**: o Plex Web mostra isso só para o dono do servidor. Leia o token no seu navegador, do jeito que app.plex.tv envia para o rex:

1. No app.plex.tv, ainda logado como você, abra as ferramentas de desenvolvedor do navegador: **F12**, ou **⌥ ⌘ I** no Mac. No Safari, primeiro ative **Mostrar recursos para desenvolvedores web** em **Ajustes**, **Avançado**.
2. Abra a aba **Network** e digite `X-Plex-Token` na caixa de filtro dela.
3. Abra qualquer filme no servidor **rex**. A lista vai se encher de requisições.
4. Clique em uma cujo endereço seja o do rex: com rex-direct, ele tem `rex-direct.debridmediamanager.com`, ou é o endereço HTTPS que você configurou. Não uma para `plex.tv`.
5. Copie o valor de `X-Plex-Token`: Chrome e Edge mostram em **Payload**, Firefox em **Request**. Ou copie o endereço da requisição e pegue a parte depois de `X-Plex-Token=` até o próximo `&`.

É um código diferente do da etapa 1: cada servidor dá à sua conta um token próprio. O rex usa esse para saber de quem é o histórico.

## 3. Execute a importação {#3-run-the-import}

Execute isto num computador de casa, com os seus dois valores colados. `192.168.1.20` é o IP da LAN do rex, como nos guias de configuração: coloque o seu no lugar.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

No Windows, abra o **PowerShell** e digite `curl.exe` em vez de `curl`. Mantenha os dois pares de aspas duplas: o endereço do passo 1 contém caracteres `&`, que quebram o comando sem elas.

Leva alguns segundos, mais tempo para uma biblioteca grande: o rex lê cada filme e episódio do servidor antigo.

**O que você deve ver.** Uma linha assim:

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| Número | Significa |
|---|---|
| `watched` | Títulos que o rex marcou como assistidos, com o número de reproduções e a data do servidor antigo |
| `inProgress` | Títulos que você tinha começado a assistir: eles são retomados de onde você parou |
| `rated` | Títulos que receberam a sua avaliação em estrelas |
| `alreadyHere` | Títulos que você já tinha assistido ou começado no rex. O rex mantém o que tem e não altera nada ali |
| `notInRex` | Títulos que o servidor antigo tem no histórico, mas que o rex não tem, ou não como o mesmo título |

Abra o seu app do Plex de novo (ou recarregue app.plex.tv) para ver.

## Execute de novo quando quiser {#run-it-again-any-time}

Rodar de novo não muda nada do que você já tem, então rode sempre que mais da sua biblioteca tiver chegado. Uma segunda execução logo após a primeira mostra `"watched":0` e os anteriores em `alreadyHere`.

## O que não é copiado {#what-is-not-copied}

- Histórico de qualquer outra pessoa do seu servidor antigo. Cada pessoa roda a importação com os próprios dois tokens.
- A lista de histórico de reprodução, as playlists e as coleções do servidor.
- Avaliações com estrelas em séries e temporadas inteiras. Avaliações de filmes e episódios são copiadas.
- Títulos de uma biblioteca cujo agente no servidor antigo não é **Plex Movie** nem **Plex TV Series** (os agentes mais antigos, como Plex Movie (Legacy) e TheTVDB). O rex encontra um título pelo id que os agentes atuais do Plex dão a ele, e os mais antigos dão outro, então esses itens contam em `notInRex`.

## Se não funcionar {#if-it-does-not-work}

| O que você vê | O que fazer |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | O endereço colado para antes do token. Copie de novo, da barra de endereço ou das ferramentas do desenvolvedor, e cole tudo |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | Algo que não é o endereço foi colocado entre aspas depois de `-d` |
| `... refused the token: copy the address from View XML again` | O servidor antigo não aceitou o token. Faça o passo 1 de novo, com as ferramentas do desenvolvedor se o servidor for compartilhado com você |
| `could not reach https://...` | O rex não conseguiu se conectar ao seu servidor antigo. Ele precisa estar rodando, e **a máquina do rex** precisa alcançá-lo: o rex lê dele, não do seu computador |
| `run the import from your home network` | Você enviou o comando para o endereço externo do rex. Use o IP da LAN do rex, como no passo 3 |
| Uma página `Unauthorized` | O rex não aceitou o token do passo 2. Copie de novo, de uma requisição feita ao rex, não ao `plex.tv` |
| `notInRex` está muito mais alto do que você espera | A maior parte da sua biblioteca ainda não está no rex, ou sua biblioteca antiga usa um dos agentes mais antigos do Plex. Rode de novo quando sua biblioteca tiver chegado |

Ainda travado? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) explica o que incluir.
