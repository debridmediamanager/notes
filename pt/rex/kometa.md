# Kometa com rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) cria coleções, coloca selos nos pôsteres (4K, HDR, notas) e preenche notas e gêneros em um servidor Plex. O rex responde ao Kometa da mesma forma que um servidor Plex, então a mesma configuração funciona nas suas bibliotecas do rex.

Tudo abaixo foi testado em 2026-10-23 com o Kometa 2.5.3 (a imagem Docker `kometateam/kometa`) e um rex com filmes e uma série.

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| rex configurado e adicionado a uma conta do Plex, como em [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account) | O Kometa edita a biblioteca, e só a conta em que o rex está registrado pode fazer isso. Um rex sem conta não serve a ninguém |
| rex nightly **2026.10.24 ou mais recente** | Atualize como em [rex's Updating section](any-source.md#updating) |
| Docker em qualquer máquina que consiga acessar o rex | O Kometa roda como um container. A própria documentação do Kometa traz [outras formas de instalar](https://kometa.wiki/en/latest/kometa/install/overview/) |
| Uma chave de API gratuita do TMDb | O Kometa precisa de uma para si mesmo, mesmo que o rex não precise. Crie em **Settings → API** no themoviedb.org, como descreve a [página de primeiros passos do TMDb](https://developer.themoviedb.org/docs/getting-started) |

## 1. Pegue o token do rex {#1-get-rexs-token}

Kometa faz login no rex com um token do Plex. Use o token que o rex recebeu quando você o registrou. Na máquina do rex:

+++ Linux e macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

Com o [rex no Docker](any-source.md#run-rex-in-docker), o arquivo só pode ser lido pelo root: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**O que você deve ver.** Uma linha, `"token": "..."`. Copie o que fica entre o segundo par de aspas. Trate como uma senha: ele dá acesso ao servidor inteiro. Se você registrar o rex de novo, ele muda e o Kometa precisa do novo.

**Não é o token da sua própria conta.** Em [Compartilhe com a sua própria conta](any-source.md#share-it-with-your-own-account), a sua conta recebeu o rex como um compartilhamento. Um compartilhamento pode assistir, mas não editar. Então, com esse token, o Kometa para com `Plex Token is read only` ou, se o compartilhamento permitir downloads, falha na primeira alteração.

## 2. Escreva a configuração do Kometa {#2-write-kometas-config}

Crie uma pasta para o Kometa, por exemplo `~/kometa/config` (`$HOME\kometa\config` no Windows), e coloque isto dentro do `config.yml`:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` é o IP da LAN do rex e a porta, o endereço de [Install rex](any-source.md#step-1-install-rex). Não use `127.0.0.1` nem `localhost`: dentro do container do Kometa, esses endereços apontam para o próprio container.
- Os nomes em `libraries:` precisam ser exatamente iguais às bibliotecas do rex: **Movies** e **TV Shows**, além de quaisquer outras que você tenha adicionado ou renomeado. Deixe de fora uma biblioteca que você não quer que o Kometa mexa.

Isto é só um começo. A documentação do Kometa lista [todas as coleções e overlays padrão](https://kometa.wiki/en/latest/defaults/guide/), e os seus próprios arquivos de coleção também funcionam.

## 3. Rode uma vez {#3-run-it-once}

+++ Linux e macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` faz o Kometa executar uma passada agora e encerrar. Sem ele, o Kometa continua rodando e espera pela agenda diária.

**O que você deve ver.** Na saída do Kometa, para cada biblioteca:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

Em um app do Plex, a biblioteca de filmes tem uma aba **Collections** com as coleções de gênero, e os pôsteres exibem os selos. Sua conta e todas as outras com quem você compartilhou o rex veem as mesmas coleções e selos. A primeira execução em uma biblioteca grande demora um pouco: o Kometa lê cada título e redesenha cada pôster que recebe selo.

## Se não funcionar {#if-it-does-not-work}

| Kometa diz | O que significa |
|---|---|
| `Plex Token is read only. Please get a new token` | O rex ainda não foi adicionado a uma conta Plex, ou o token é da sua própria conta e não o do passo 1 |
| Kometa conecta, mas toda alteração falha | O token é da sua própria conta. Use o do passo 1 |
| `url_poster failed to update poster` | A máquina do rex não consegue acessar o site onde a imagem está |
| `Plex URL is probably invalid` ou um timeout | A `url` não chega ao rex a partir de onde o Kometa roda. Abra `http://192.168.1.20:32400/identity` nessa máquina: ela deve mostrar o `machineIdentifier` do rex |
| `Plex Error: Plex Library '...' not found. Options: [...]` | Um nome em `libraries:` não bate com o nome da biblioteca. Copie um dos nomes da lista que ele mostra |

Ainda travado? Pergunte no fórum **rex-support** do [Discord](https://discord.com/invite/7u4YjMThXP). [Getting help](../guides/remote-help.md) explica o que incluir.

## O que o Kometa consegue e não consegue ver {#what-kometa-can-and-cannot-see}

O Kometa faz a correspondência dos títulos pelos ids do TMDb, TVDb e IMDb que o rex mostra para eles. Um título que a fonte não identificou, que ainda mostra o nome do arquivo e não tem pôster, não tem esses ids. Por isso o Kometa o deixa de fora de tudo que é montado a partir deles. Antes, use Fix Match em um app do Plex para corrigir esse título.

Testado com o rex: coleções por busca de título, por id do TMDb e coleções inteligentes; as coleções padrão de gênero com seus pôsteres; os overlays de resolução e de avaliações; e as atualizações de nota da crítica e de gênero vindas do TMDb. Ainda não testado: playlists, bibliotecas de música e as outras operações do Kometa. Se alguma falhar, o log do próprio Kometa mostra qual requisição falhou, e vale reportar isso no Discord.
