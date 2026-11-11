# Busque o que você quiser no DMM {#fetch-what-you-want-from-dmm}

Clique em **Want** em um filme ou série no [Debrid Media Manager](https://debridmediamanager.com), e o seu zurg baixa o conteúdo. Não precisa configurar Sonarr nem Radarr, e também não tem nada para montar.
As séries continuam recebendo os novos episódios conforme forem sendo exibidos.

Isso é para patrocinadores: o zurg lê a sua lista usando a sua chave de API do DMM.

## O que você precisa {#what-you-need}

- Um nightly do zurg de 2026-10-25 ou posterior.
- Sua chave de API do DMM no `config.yml` do zurg. É a chave que o [gatekeeper](https://gatekeeper.debridmediamanager.com/) mostra para você depois que você se torna patrocinador:

  ```yaml
  dmm_api_key: YOUR_DMM_API_KEY
  ```

- Algo para o zurg buscar: uma conta de debrid que aceite torrents, um provedor `nzb` ou
  `torbox_nzb` para Usenet, ou os dois.

É só isso para configurar. O zurg lê sua lista uma vez por minuto desde o momento em que é iniciado.

## Adicionando títulos {#adding-titles}

1. Cole a mesma chave na página de [Settings](https://debridmediamanager.com/settings) do DMM.
2. Abra um filme e clique em **Want**. Na página de uma temporada de uma série, **Want S2** adiciona essa temporada e **Want all seasons** adiciona a série inteira, incluindo as novas temporadas.
3. Sua lista fica em [debridmediamanager.com/wanted](https://debridmediamanager.com/wanted). Ela mostra quando seu zurg leu a lista pela última vez e quando buscou cada filme. Listas longas são exibidas com 120 títulos por página.

Pedidos feitos no Seerr, Overseerr ou Jellyseerr também podem cair nessa mesma lista: veja [Seerr through DMM](../../dmm/seerr.md).

## Seguindo uma lista {#following-a-list}

Cole a página de uma lista do Trakt ou do MDBList na sua [lista de desejados](https://debridmediamanager.com/wanted)
e clique em **Follow**. Todo filme e série nela entra como desejado, e o DMM lê a lista de novo a cada seis horas, então o que for adicionado depois também entra como desejado. Páginas aceitas:

- `https://trakt.tv/users/<user>/lists/<list>` e `https://trakt.tv/lists/<id>`
- `https://trakt.tv/users/<user>/watchlist`, se esse perfil do Trakt for público
- `https://mdblist.com/lists/<user>/<list>`

Nas próprias páginas do Trakt no DMM, sua watchlist e cada uma das suas listas têm um botão **Follow with Want** que faz a mesma coisa.

Uma watchlist do IMDb, Letterboxd, Rotten Tomatoes ou Plex: no mdblist.com, crie uma [lista externa](https://docs.mdblist.com/docs/external_lists) a partir da URL dela e siga essa lista. O MDBList mantém ela sincronizada com a origem.

O que seguir uma lista faz:

- Uma série entra inteira, incluindo as temporadas novas.
- Só entram os títulos que são novos na lista desde a última leitura. Um título que você tirar da sua lista de desejados continua fora, e um título que sair da lista continua desejado. **Unfollow** mantém o que a lista adicionou.
- A página mostra cada lista com quantos títulos ela tem, quantos ela já adicionou e quando foi lida pela última vez. **Read again** lê a lista agora. Títulos sem id do IMDb ficam de fora, e a contagem mostra quantos são.
- Sua lista comporta 10.000 títulos a buscar: todas as séries, e cada filme que o zurg ainda não buscou ou que está esperando para ser atualizado. Filmes que o zurg já buscou não contam. Um título que não cabe é adicionado em uma leitura posterior, quando houver espaço.

## Migrando do Radarr ou Sonarr {#moving-from-radarr-or-sonarr}

1. No Radarr ou Sonarr, abra **System → Backup**, clique em **Backup Now** e baixe o
   zip. Os backups agendados na pasta `Backups` também funcionam.
2. Na sua [lista de desejados](https://debridmediamanager.com/wanted), clique em **Import a Radarr or
   Sonarr backup** e escolha o zip. Depois faça o mesmo com o backup do outro app.

O que é importado:

- Do Radarr, todo filme monitorado sem arquivo que já atingiu sua disponibilidade mínima.
  Filmes sem id do IMDb ficam de fora; a página mostra quantos são.
- Do Sonarr, toda série monitorada com episódios já exibidos que estão faltando, só com essas temporadas.
- Títulos que já estão na sua lista continuam como estão.

Só o banco de dados dentro do zip é enviado. O resto do backup, incluindo a API key do app,
fica no seu computador.

Duas coisas não são importadas:

- **Perfis de qualidade.** O zurg escolhe os releases pelas suas próprias
  [configurações de aquisição](acquisition.md#configuration). O Radarr normalmente recusa cópias de câmera e
  telesync; para bloqueá-las, adicione-as em
  [`exclude_words`](acquisition.md#excluding-releases-by-name):

  ```yaml
  acquisition:
    exclude_words: [CAM, CAMRip, HDCAM, TS, HDTS, TELESYNC, TC, HDTC, TELECINE]
  ```

- **Números de temporada do Sonarr, quando forem diferentes.** Sua lista numera as temporadas como o TMDB faz.
  O Sonarr segue o TheTVDB, que divide alguns animes de longa duração em mais temporadas, então uma
  temporada do Sonarr que o TMDB não tem não é buscada. Confira essas séries na página delas no DMM
  e clique em **Want** nas temporadas que estiverem faltando.

## O que o zurg busca {#what-zurg-fetches}

- **Um filme** uma vez. Depois ele sai da lista que o zurg lê. Um filme baixado abaixo da resolução que `quality` busca (2160p para `best`) continua na lista: o zurg baixa uma cópia melhor quando ela sai e remove a que baixou antes. Uma cópia que você mesmo adicionou é mantida. `upgrades: false` em `acquisition:` no config do zurg desliga isso. `/wanted` mostra o que o zurg pegou e a resolução que ainda está esperando, exceto com a lista de resoluções abaixo.
- **Um filme em 1080p e em 4K**, se você quiser os dois, por exemplo para que uma TV 1080p reproduza um arquivo sem que o arquivo 4K precise ser transcodificado. Precisa da nightly de 2026-10-31 ou posterior. Liste as resoluções no config do zurg:

  ```yaml
  acquisition:
    quality: [1080p, 4k]
  ```

  Assim o zurg mantém uma cópia de cada filme em cada uma delas. Cada cópia pega o melhor release igual ou abaixo da própria resolução e é atualizada sozinha, então a cópia 1080p nunca vira uma 2160p. Enquanto nenhum release melhor que 1080p estiver disponível, as duas geralmente pegam o mesmo release e você fica com um arquivo só. `720p` também pode ser listado. Séries ainda recebem uma cópia só, escolhida como se você tivesse escrito apenas a resolução mais alta. Filmes que o zurg baixou antes de você adicionar a lista são baixados de novo em cada resolução; o zurg nunca remove a cópia antiga, então apague você mesmo se não quiser mais. As regras completas estão em [uma cópia em cada uma de várias resoluções](acquisition.md#a-copy-at-each-of-several-resolutions).
- **Uma série**: todo episódio já exibido das temporadas que você escolheu, como pacote de temporada quando um pacote cobre a temporada inteira e como episódios avulsos onde ela ainda está no ar. Continua verificando novos episódios até você remover a série. Especiais não são baixados.

Os releases vêm da Usenet como NZBs e de torrents que sua conta debrid já tem em cache; torrents não cacheados nunca são adicionados. Se você não configurou nenhum indexador, o zurg pesquisa no próprio DMM. Qualidade, limites de tamanho, palavras a evitar e os idiomas de áudio e legenda que um release precisa ter são as [configurações de aquisição](acquisition.md#configuration) do zurg, iguais para todas as fontes.

## Assistindo no Kodi ou Plex {#watching-it-in-kodi-or-plex}

Com `__magic__` ativado, o zurg organiza o que ele busca pelo título, em `__magic__/__movies__` e `__magic__/__shows__`, com nomes no formato que o Kodi e o Plex reconhecem. Aponte uma biblioteca de Filmes e uma de Séries para essas duas pastas, ou, com `magic.anime`, uma biblioteca de Anime em `__magic__/__anime__` também: veja [`__movies__` and `__shows__`](magic.md#__movies__-and-__shows__-sorted-by-title).

```yaml
magic:
  enabled: true
```

## Dois zurgs em uma mesma chave {#two-zurgs-on-one-key}

Cada zurg lê a mesma lista, então dois deles buscam cada título duas vezes. Deixe a lista ativada em um e desative nos outros:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

## Quando para {#when-it-stops}

Se sua assinatura expirar ou você redefinir sua chave, o zurg registra que o DMM recusou a chave e pede de novo a cada hora. O que ele já baixou continua na sua biblioteca.

Mais detalhes: [DMM wanted list](acquisition.md#dmm-wanted-list) na referência de aquisição.
