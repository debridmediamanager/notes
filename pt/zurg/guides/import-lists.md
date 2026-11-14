# Seguindo uma lista no Sonarr e no Radarr {#following-a-list-in-sonarr-and-radarr}

Sonarr e Radarr podem seguir uma lista de séries ou filmes. Cada título dela é adicionado e pesquisado. Com o zurg como cliente de download, cada download cai na sua conta de debrid e é importado para `__magic__` como qualquer outro. Assim, uma lista é uma seção inteira da biblioteca que se preenche sozinha. Uma lista de terror te dá uma seção de terror, e os títulos novos aparecem conforme a lista cresce.

Esta página assume que os \*arrs já baixam pelo zurg. Se ainda não baixam, comece por [Sonarr e Radarr para torrents](sonarr-radarr-torrents.md).

## Use o MDBList e não o IMDb {#use-mdblist-and-not-imdb}

Os dois apps ainda mostram um tipo de lista do IMDb, e nenhum deles funciona mais com uma lista normal do IMDb.

- O Radarr recusa um ID de lista no formato `ls12345678`. Ele só aceita `top250`, `popular` ou a watchlist de um usuário, `ur12345678`.
- O Sonarr aceita o ID, mas depois recebe uma resposta vazia do IMDb. O botão Test mostra `Imdb call resulted in an unexpected StatusCode [Accepted]`.

O [MDBList](https://mdblist.com) é a saída para os dois casos. Ele publica qualquer lista como um feed JSON, que os dois apps leem com o tipo de lista Custom List. Filmes e séries ficam em listas separadas, então você adiciona uma em cada app.

## 1. Escolha uma lista {#1-pick-a-list}

Listas públicas não precisam de conta. Pesquise no MDBList pelo gênero que você quer e abra uma lista. Duas listas de terror que funcionam em outubro de 2026:

| List | Holds | Feed URL |
|---|---|---|
| Horror | movies | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | shows | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

A URL do feed é a URL da página da lista com `/json` no final. Abra-a primeiro em um navegador. Você deve ver uma página de texto que começa com `[{"id":`.

Para criar a sua própria lista, faça login no MDBList e crie uma. Ela pode seguir filtros como gênero e nota mínima, ou pode copiar uma lista do IMDb que você já tenha. A URL do feed funciona da mesma forma.

## 2. Adicione ela no Radarr {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | qualquer nome, por exemplo `Horror` |
| Enable | ativado |
| Enable Automatic Add | ativado |
| Search on Add | leia o aviso abaixo antes |
| Monitor | Movie Only |
| Root Folder | sua pasta de filmes dentro de `__magic__`, por exemplo `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` no macOS, `Z:\__magic__\movies` no Windows) |
| Quality Profile | o que você usa |
| List URL | a URL do feed de filmes |

Clique em **Test** e depois em **Save**.

## 3. Adicione ela no Sonarr {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Field | Value |
|---|---|
| Name | qualquer nome, por exemplo `Horror Shows` |
| Enable Automatic Add | ativado |
| Monitor | All Episodes, ou Pilot Episode para testar uma série primeiro |
| Root Folder | sua pasta de séries dentro de `__magic__`, por exemplo `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` no macOS, `Z:\__magic__\tv` no Windows) |
| Quality Profile | o que você usa |
| Series Type | Standard |
| Season Folder | ativado |
| Search for Missing Episodes | leia o aviso abaixo antes |
| List URL | a URL do feed da série |

Clique em **Test** e depois em **Save**.

## Listas grandes baixam tudo de uma vez {#big-lists-grab-everything-at-once}

A lista com busca ao adicionar ativada pesquisa e baixa cada título assim que ela sincroniza. A lista de filmes acima tem 400 títulos e a lista de séries tem 148 séries com todos os episódios. São muitos downloads de uma vez. A sua conta de debrid e os seus indexadores vão sentir isso, e um indexador com limite de requisições vai começar a recusar buscas.

Há duas formas mais suaves de começar.

- Deixe a busca ao adicionar desativada. Os títulos são adicionados e monitorados, mas nada é pesquisado. Pesquise os que você quiser pelas páginas Movies ou Series.
- Comece com uma lista curta. Adicione a lista grande depois que o primeiro lote tiver chegado.

Os apps também sincronizam as listas no próprio cronograma. **System → Tasks → Import List Sync** executa uma sincronização agora.

## Removendo uma lista {#removing-a-list}

Excluir uma lista impede que novos títulos entrem por ela. O que ela já adicionou continua lá. Em **Settings → Import Lists**, o **Clean Library Level** define o que acontece com os títulos que saem de uma lista. Deixe em Disabled, a menos que você queira que os apps removam coisas por conta própria.
