# Os apps baixam do seu provedor {#apps-download-from-your-provider}

Normalmente o rex lê cada filme da sua fonte e o passa para o Plex. Se a fonte devolver um link de arquivo, como um link de download de debrid, o rex pode entregar esse link diretamente ao Plex. Assim, o Plex baixa o arquivo e a máquina do rex não carrega nenhuma mídia.

Isso funciona quando o Plex consegue reproduzir o arquivo diretamente (direct play). Qualquer coisa que o rex precise converter continua passando pelo rex ou é recusada, se você escolher essa opção.

Testado em 25/10/2026 com zurg no Real-Debrid, Plezy e Plex para Android em um Pixel 6, e Plex Web no Chrome.

## Antes de começar {#before-you-start}

**Mantenha o modo de proxy padrão para reprodução com debrid compartilhado.** Redirecionamentos não são um jeito seguro de compartilhar uma conta de debrid:

- **O Real-Debrid acompanha o IP público de cada downloader.** Usar uma mesma conta a partir de vários IPs gera um aviso de compartilhamento, mesmo quando a CDN entrega o arquivo normalmente. Mantenha todo uso dessa conta em um único IP público. Um app remoto baixando diretamente enquanto o rex, ou a fonte, consulta ou converte a partir do IP do servidor viola essa regra; uma reprodução bem-sucedida não prova que está seguro.
- **Os links de download do TorBox contêm a chave de API completa em `?token=`.** Redirecionar dá a cada cliente e a cada conta de usuário compartilhada acesso total, incluindo exclusão, e não apenas acesso àquele arquivo. Logs do player e o histórico do navegador podem guardar a chave. Não entregue esses links a clientes não confiáveis.

Continue só se esses riscos forem aceitáveis. Manter o modo de proxy padrão do rex significa que o rex segue os redirecionamentos da fonte por conta própria, em vez de entregar o link do provedor ao app.

| Você precisa de | Por quê |
|---|---|
| rex configurado como em [rex com seu próprio app](any-source.md), [rex com seus addons do Stremio](stremio.md) ou [rex com zurg](with-zurg.md), e um filme que reproduza | Esta página muda o comando de inicialização do rex e, em algumas fontes, uma das configurações da fonte |
| rex nightly **2026.10.26 ou mais recente** | Versões mais antigas não têm essa configuração. Atualize como em [seção de atualização do rex](any-source.md#updating) |
| Uma fonte que consiga responder com um link | O rex só consegue repassar um link que a fonte lhe dá. O [Passo 1](#step-1-let-your-source-hand-out-links) diz quais fontes fazem isso |

## Escolha o quão rigoroso {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| Um app reproduz o arquivo como ele é | O app baixa do seu provedor | O app baixa do seu provedor |
| Um app precisa que o arquivo seja convertido (qualidade menor, áudio que ele não consegue tocar, legendas embutidas) | O rex converte, lendo o arquivo da sua fonte como antes | Recusado: o app mostra um erro |
| Arquivos que sua fonte envia por conta própria, não como link (os arquivos Usenet do zurg, por exemplo) | Reproduz pelo rex como antes | Recusado |
| Plex Web | Reproduz, pelo rex | Todo arquivo do Real-Debrid é recusado (veja abaixo) |

Escolha `redirect` se você quer que tudo continue reproduzindo e economizar o que puder. Escolha `redirect-only` se a máquina do rex nunca pode carregar um filme, por exemplo uma VPS pequena com limite de dados.

Seja qual for a sua escolha, todo app e toda pessoa com quem você compartilha o rex recebe o link que a sua fonte deu ao rex para o que ela reproduz, e o serviço por trás desse link, o seu serviço de debrid por exemplo, vê cada um deles baixando o arquivo.

## Passo 1. Deixe sua fonte entregar os links {#step-1-let-your-source-hand-out-links}

**O que faz.** Sua fonte responde a cada leitura com um link para o arquivo em outro lugar (um redirecionamento HTTP), em vez do próprio arquivo.

**Por que importa.** O rex só consegue repassar um link que sua fonte lhe entrega. Uma fonte que envia o próprio arquivo continua fazendo o arquivo passar pelo rex.

| Fonte | O que fazer |
|---|---|
| [rex-stremio](stremio.md) | Nada: ela responde com o link que um addon de stream forneceu. Um link que precisa de headers próprios, e uma playlist ao vivo, ele ainda envia por conta própria |
| [zurg](with-zurg.md) | Ative `disable_stream_proxy`, abaixo. O zurg não tem link para um arquivo Usenet, então ele sempre envia esses por conta própria |
| [Seu próprio app](any-source.md) | Responda o `GET` do arquivo com um `302` ou `307` apontando para o link |

### zurg

The setting is zurg's, so anything else that reads zurg (rclone, a Plex or Jellyfin server on zurg's mount) gets the links too; zurg's [config reference](../zurg/reference/config.md) has the details.

+++ Linux and macOS
Veja se a configuração já está no config do zurg:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

Se ela imprimir uma linha, altere-a para `disable_stream_proxy: true` com `nano ~/zurg/config.yml`. Se não imprimir nada, adicione:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
Abra o config do zurg com `notepad $HOME\zurg\config.yml`. Se houver uma linha `disable_stream_proxy:`, altere-a para `disable_stream_proxy: true`; se não houver, adicione essa linha no final. Salve e reinicie o zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
Na pasta do zurg:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

Se ela imprimir uma linha, altere-a com `sudo nano config.yml`. Se não imprimir:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**O que você deve ver.** O zurg inicia de novo normalmente. Os filmes ainda tocam pelo rex neste ponto: o rex segue os links por conta própria até o passo 2.

## Passo 2. Deixe o rex repassar os links {#step-2-let-rex-pass-the-links-on}

**O que faz.** O rex entrega ao app o link que sua fonte deu a ele, em vez de baixar o filme para ele.

Coloque `--part-mode redirect` (ou `--part-mode redirect-only`) no fim do comando de início do rex, depois reinicie o rex e abra o log dele. [Instale o rex](any-source.md#step-1-install-rex) mostra onde fica o comando de início no seu sistema e como reiniciar o rex e ver o log. No Linux, a linha `ExecStart` em `~/.config/systemd/user/rex.service` deve ficar assim, sem mais nada:

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

Mantenha o que já estiver na linha, como `--port 32500` ou `--announce-url ...`.

**O que você deve ver.** A linha de início termina em `parts=redirect`:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

Com `redirect-only`, ela termina em `parts=redirect-only`, e algumas linhas acima o rex diz `transcoder off: --part-mode redirect-only`.

## Passo 3. Reproduza algo {#step-3-play-something}

Deixe o log do rex aberto e reproduza um filme no Plezy ou no Plex para Android.

**O que você deve ver.** Para cada leitura que o app faz, aparece uma linha com o nome do servidor do seu provedor:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

Isso é o rex enviando o app para o servidor do link, no caso o do Real-Debrid. Se aparecer uma linha terminando em `-> 206 len=...`, significa que o rex enviou o próprio filme: veja [Se não funcionar](#if-it-does-not-work).

## O que cada app faz {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | Baixa do seu provedor | Baixa do seu provedor |
| Plex para Android, Qualidade original | Baixa do seu provedor, quando o rex permite reproduzir o arquivo como ele é | O mesmo |
| Plex para Android, uma qualidade inferior, ou áudio que ele não consegue reproduzir | O rex converte | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | Reproduz através do rex | "Playback Error: This server is not powerful enough to convert video." |

O Plex Web não consegue usar os links do Real-Debrid de jeito nenhum: o Real-Debrid marca os arquivos como downloads, não como vídeo, e o navegador se recusa a reproduzi-los. No modo `redirect`, o Plex Web muda discretamente para uma conversão pelo rex em menos de um segundo, então continua funcionando; no modo `redirect-only` não existe para onde voltar.

## No Docker {#in-docker}

Se você seguiu [rex no Docker](any-source.md#run-rex-in-docker), o passo 2 é uma linha `command:` embaixo de `rex:` no `compose.yml` do rex, ao lado de `image:`:

```yaml
    command: --part-mode redirect
```

Já tem `command: --port 32500`? Troque para `command: --port 32500 --part-mode redirect`. Depois rode `docker compose up -d` na pasta do rex, e `docker compose logs -f rex` mostra a mesma linha `parts=redirect`.

## Se não funcionar {#if-it-does-not-work}

| Você vê | O que significa |
|---|---|
| rex sai com `invalid choice` para `--part-mode` | O rex é anterior a 2026.10.26. Atualize-o como em [seção Updating do rex](any-source.md#updating) |
| O log do rex diz `-> 206 len=...` para toda leitura | A fonte ainda envia o próprio arquivo. Com o zurg: `disable_stream_proxy: true` está faltando na configuração do zurg, ou o zurg não foi reiniciado após o passo 1 |
| `-> 206 len=...` só para alguns títulos | A fonte envia esses você mesmo: arquivos Usenet do zurg, ou links do rex-stremio que ele precisa repassar |
| `-> 403: the source answered with the bytes, not a link` | O `redirect-only` recusando um arquivo que a fonte enviou diretamente, pelos mesmos motivos acima |
| Nenhuma linha `PART` enquanto um filme toca | O app está tocando uma conversão, não o arquivo original. Defina a qualidade dele como Original |

Ainda travado? Pergunte no fórum **rex-support** no [Discord](https://discord.com/invite/7u4YjMThXP). [Pedindo ajuda](../guides/remote-help.md) explica o que incluir.

## Voltando {#going-back}

Remova `--part-mode ...` do comando de inicialização do rex (ou da linha `command:` no Docker) e reinicie o rex. Sua fonte pode continuar entregando links: com a configuração do rex removida, o próprio rex os segue. No caso do zurg, defina `disable_stream_proxy` de volta para `false` e reinicie o zurg para que ele volte a repassar os arquivos por conta própria, tanto para o rclone quanto para qualquer outro que os esteja lendo.
