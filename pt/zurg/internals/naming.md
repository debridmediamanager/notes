# nomeação no zurg {#zurg-naming}

Quase todos os nomes que o zurg mostra são calculados, nunca armazenados. O nome da pasta de um lançamento, o nome de um arquivo dentro dela e o nome no disco do registro de cache são todos derivados do torrent a cada consulta. Nada grava esses nomes e depois os lê de volta, porque um nome armazenado é mais uma coisa para manter sincronizada com a biblioteca, e manter essa sincronia é exatamente o que um reparo ou uma nova resolução de NZB quebra.

A exceção é uma renomeação que o operador pediu. Essa fica armazenada no próprio lançamento e tem prioridade sobre todas as derivações abaixo. A Seção 9 traz as regras, e o guia de renomeação é a versão voltada ao usuário. Todo o resto desta página descreve o nome que um lançamento tem quando nenhuma renomeação está definida.

Isso tem uma consequência que vale declarar logo de início, porque é a fonte da maioria das surpresas para quem integra algo com o zurg: uma pasta pode mudar de nome sem que nada a tenha "renomeado". As entradas mudaram, então a saída mudou.

Este arquivo traz as regras, não os limites. Quando uma regra é definida por uma heurística, ele apenas indica a função que a define e para por aí. Essas heurísticas são ajustadas com base em lançamentos reais e mudam com o tempo, e copiá-las para cá só criaria mais uma coisa para manter sincronizada. As referências de código são relativas ao pacote.

## 1. O nome da pasta do release {#1-the-release-folder-name}

`internal/torrent/key.go`, GetKey / GetKey_Original

O nome da pasta dentro de `__all__/`, o nome do arquivo `.zurgtorrent`, a chave que toda consulta usa e o que o zurg chama de "access key" são todos a mesma string. Ela é definida nesta ordem, e vale a primeira condição que bater:

  | Condição                                       | Nome da pasta                |
  |------------------------------------------------|------------------------------|
  | `ignore_renames: false`, com Torrent.Rename definido | Torrent.Rename         |
  | `retain_rd_torrent_name: true`                 | Name, sem modificação        |
  | `retain_folder_name_extension: true` E         | Name, sem modificação        |
  |   Name contém OriginalName                     |                              |
  | caso contrário — as duas flags nos padrões     | OriginalName, tirando `.mp4` e depois `.mkv` |
  |                                                |   do final                   |

`retain_rd_torrent_name` é verificada primeiro e anula totalmente `retain_folder_name_extension`. A segunda se aplica apenas quando Name contém OriginalName como substring. Quando não contém, a remoção acontece de qualquer forma.

A remoção é `strings.TrimSuffix` executado duas vezes, ou seja, três regras em uma. Só `.mp4` e `.mkv` são removidos, então `.avi`, `.ts`, `.iso` e os demais continuam no nome da pasta. É sensível a maiúsculas e minúsculas, então `Movie.2019.MKV` mantém o `.MKV`. E as duas execuções são sequenciais, não alternativas, então `Movie.2019.mkv.mp4` vira `Movie.2019`. Um sufixo pode ser adicionado depois (seção 4). O resultado é um único componente de caminho, nunca dividido em `/`.

OBSOLETO. `retain_folder_name_extension` e `retain_rd_torrent_name` estão obsoletas e serão removidas. Por enquanto o comportamento não muda, mas definir qualquer uma das duas registra um aviso na inicialização. As duas usam Name como chave da biblioteca, e a conta reescreve Name por baixo do zurg (seção 2). Os padrões usam o que o próprio torrent declarou, e a conta não mexe nisso. Em uma instância que atende Sonarr ou Radarr, ou seja, que tem um bloco `sabnzbd:` ou `qbittorrent:`, os padrões são os únicos valores corretos, porque uma chave de acesso que muda depois de uma importação faz você perder o release. `ignore_renames` não está obsoleta.

## 2. De onde vêm Name e OriginalName {#2-where-name-and-originalname-come-from}

  Real-Debrid   `internal/realdebrid/types.go`
                Name = `filename`, OriginalName = `original_filename`

  TorBox        `internal/torbox/types.go`, wireTorrent.originalName
                Name = `name`. OriginalName é o único diretório onde todos os arquivos
                ficam, quando existe exatamente um; arquivos na raiz da árvore usam
                `name` como fallback, exceto um arquivo único solto, cujo próprio nome é
                usado.

  AllDebrid     `internal/alldebrid/types.go`, originalName
                Mesma regra do TorBox, aplicada sobre a lista de arquivos achatada,
                com fallback para o `filename` do magnet.

  NZB           `internal/nzb/provider.go`
                Name e OriginalName são ambos releaseName, e o Hash do torrent
                é o id do release. Seção 3.

Como os backends de debrid derivam o OriginalName da pasta raiz do próprio torrent, duas contas com o mesmo conteúdo geram o mesmo nome de pasta.

O que os dois campos do Real-Debrid significam, medido em 2026-08-27 numa conta de teste com ~84k torrents, com 252 deles amostrados somente leitura via `GET /torrents/info`:
`original_filename` era sempre o nome que o torrent declarava — o nome do pack ou da pasta — em todos os casos, nunca o nome de um arquivo isolado. `filename` não é isso. Ele colapsa para o basename de um único arquivo, e faz isso exatamente quando um único arquivo de um torrent com vários arquivos está selecionado: 90 dos 112 torrents amostrados nesse formato, contra 0 dos 34 com vários, mas não todos, selecionados e 0 dos 24 com todos selecionados.

Num pack de 221 arquivos com um episódio selecionado, `original_filename`
retornava `Marvel Cinematic Universe MCU Collection 2008-2023 1080p jZQ` enquanto
`filename` retornava `Spider-Man.No.Way.Home.2021.1080p.BluRay.x264...-NOGRP.mkv`.
Então o padrão entrega o nome do pack, e `retain_rd_torrent_name: true` entrega o nome do arquivo individual — e é por isso que a flag está obsoleta: `filename` segue o estado da conta, e a chave de acesso não deve seguir.

## 3. Nomeação de releases NZB {#3-nzb-release-naming}

`internal/nzb/provider.go`, releaseName; `internal/nzb/parse.go`

O id da release, que também é o seu Hash, é `hex(sha1(lowercase(nzb filename)))`
— do nome do arquivo e não do conteúdo, então salvar de novo um NZB não deixa o torrent criado a partir dele órfão.
O nome da pasta é esse FILENAME sem a extensão, a menos que o nome fique parecendo um hash ou fique vazio depois da sanitização. Nesse caso, usa-se o nome que está nos metadados do `<head>` do próprio NZB.
O nome do arquivo tem prioridade porque é o nome que o indexador escreveu, que o downloader salvou e que a automação usa para procurar a release, enquanto os indexadores costumam reenviar com uma linha de assunto nos metadados.
`stemLooksJunk`, `looksLikeHash` e `sanitizeReleaseName` em `internal/nzb/parse.go` resolvem essas três questões; trate-as como caixas-pretas.

## 4. Os três sufixos de nome {#4-the-three-name-suffixes}

  ` {xxxxxx}`   Em uma pasta de release, quando dois releases DIFERENTES têm o mesmo nome:
                seis caracteres hexadecimais do próprio infohash daquele release. Dentro do
                grupo, o release ADICIONADO MAIS RECENTEMENTE mantém o nome puro e
                todos os outros recebem a tag. Isso é decidido uma vez a cada atualização, por uma passagem
                que enxerga a biblioteca inteira, e fica salvo como KeySuffixed, então
                GetKey continua sendo uma função pura do torrent
                (`internal/torrent/key.go`, disambiguateNames). Um torrent do RD e um NZB do
                mesmo release são dois releases diferentes aqui, já que o hash de um NZB é um sha1 do nome do arquivo.

  ` (tag).ext`  Em um ARQUIVO cujo nome base se repete dentro de um mesmo release, já que o zurg
                achata a árvore de um torrent em um único diretório. A tag é o
                diretório que já diferencia os arquivos em conflito (o componente de caminho
                mais raso que é distinto dentro do grupo), senão seis caracteres hexadecimais do sha1 do
                caminho do arquivo. Qual profundidade se qualifica, e o que um componente pode levar
                para um nome de arquivo, são `dupeTags` e `sanitizeTag` em
                `internal/torrent/dupenames.go`; trate ambos como opacos. O
                grupo são todos os arquivos da listagem, selecionados ou não, então um
                arquivo que deixa de ser selecionado continua resolvendo para a chave sob a qual foi registrado. `__magic__` é a
                única exceção: ele mostra a árvore real do release sem tags, porque as pastas
                diferenciam os arquivos ali — seção 8.

  `_xxxxxxxx`   Em um nome de arquivo NO DISCO cuja entrada tinha qualquer caractere não ASCII:
                oito caracteres hexadecimais do sha256 dessa entrada. Seção 6. Nunca
                aparece na montagem.

## 5. Nomes de arquivos dentro de um release {#5-file-names-inside-a-release}

`internal/torrent/manager.go`. VisibleName(key, file) é a única autoridade para o nome que a montagem mostra e para o nome que uma busca precisa bater. Ele usa um File.Rename quando existe um e `ignore_renames` está como false; caso contrário, usa a chave de SelectedFiles, que já traz a tag da seção 4. GetFilename retorna `filepath.Base(file.Path)`, então descarta essa tag. Tanto a exibição quanto a busca precisam passar pelo VisibleName, senão uma requisição para um nome com tag não encontra nada, enquanto N arquivos compartilham o mesmo nome puro.

## 6. Nomes de arquivos no disco {#6-on-disk-filenames}

`internal/torrent/utils.go`, sanitizeFilename — opaco, e se aplica SOMENTE aos arquivos que o zurg grava no host (`data/<name>.zurgtorrent` e a árvore de STRM), nunca ao que o mount serve. É bem mais agressiva do que qualquer coisa acima: uma release cuja pasta no mount é `Три богатыря` tem um arquivo de cache cujo nome é uma sequência de underscores mais o sufixo `_xxxxxxxx`, que o mantém distinto do próximo título em cirílico. É um namespace diferente, e não deve bater com o outro.

## 7. Conteúdo de arquivos compactados {#7-archive-interiors}

A release servido a partir de um RAR, ZIP ou 7z lista o conteúdo do arquivo, e não os seus volumes. Duas regras mudam como esses itens são chamados.

`stripRedundantRoot` (`internal/universal/rar_streamer.go`) remove os diretórios de nível superior que envolvem o arquivo inteiro. `payloadRenames` (`internal/universal/deobfuscate.go`) apresenta um único payload ofuscado com o nome do RELEASE, movendo todas as entradas que compartilham o mesmo nome base com ele. O que conta como ofuscado é `looksObfuscated`, no mesmo arquivo, que é a porta do zurg para o teste do SABnzbd: opaco, junto com as proteções ao redor dele. Nada é reescrito no disco, e `archiveName` também resolve a grafia original do próprio arquivo.

## 8. Nomes de diretórios {#8-directory-names}

`internal/torrent/manager.go`, `internal/torrent/provider_directories.go`

Embutidos e reservados:

    __all__          todos os releases
    __unplayable__   releases sem nada reproduzível
    __dump__         torrents despejados
    __downloads__    a visualização de downloads
    __magic__        a camada gravável, o único diretório cuja estrutura é
                     armazenada em vez de calculada. O próprio `__all__` espelha
                     a biblioteca: cada release que o `__all__` contém, como a
                     árvore de diretórios descrita pelos valores `File.Path` dos
                     arquivos, e não achatada (`internal/magic/tree.go`). Tudo
                     ao lado desse espelho é o que o usuário armazenou. O espelho
                     é calculado, então nada pode ser gravado nele;
                     `MirrorDirectory` em `internal/magic/resolve.go` dá esse
                     nome a ele
    int__all__       índice interno de hashes

`__downloads__` e `__magic__` não são filtros, então são adicionados à listagem
da raiz manualmente, e `__magic__` só aparece quando o magic está habilitado.
Qualquer nome que comece com `int__` é ignorado na listagem da raiz.

Para cada conta existe mais um, `"__" + account name + "__"` — `__realdebrid__`,
`__torbox__`, `__nzb__` — montado a partir do bloco providers. Ele também decide
para onde vão as leituras: um arquivo aberto em `__torbox__` é servido pelo
TorBox mesmo quando outra conta tem o mesmo release e venceria pela ordem da
configuração. Uma conta cujo nome colidiria com um reservado não recebe nenhum,
e o zurg emite um aviso. Todo o resto na raiz é uma chave do bloco
`directories:`, sem alteração.

## 9. Renomeações feitas pelo usuário {#9-user-renames}

`internal/torrent/rename.go`, `internal/torrent/rename_bulk.go`

Um renomeio é só uma visualização, não uma mudança em nada da conta no debrid. Ele é guardado como Torrent.Rename ou File.Rename e tem prioridade sobre todas as derivações acima, até que `ignore_renames: true` faça o zurg ignorá-lo por completo.

Um renomeio de torrent só é aceito se o nome, depois de tirar os espaços das pontas, não estiver vazio, não tiver `/` nem `\`, for igual ao próprio `filepath.Clean` (o que também rejeita `.` e `..`) e não colidir com uma chave de acesso já existente que pertença a outro hash. Ao aplicar, as chaves dos mapas de diretórios são refeitas, o `.zurgtorrent` é gravado com o novo nome e o antigo é APAGADO. Se ele ficar para trás, na próxima reinicialização os dois são carregados e o renomeio volta ao nome original sem aviso.

O season fix (`/torrents/season-fix/plan` e `/apply`) é um renomeio de arquivos em massa guiado pela própria correspondência de episódios do Plex. O plan é somente leitura e informa, para cada arquivo, o motivo do pulo. O apply recebe uma lista explícita de hashes, e não uma flag de aplicar em tudo. O dashboard usa ambos a partir de `/season-fix/`, que também é onde as regras de mapeamento e os motivos de pulo são explicados para o operador.

## 10. Consequências para quem integra com o zurg {#10-consequences-for-anything-integrating-with-zurg}

If you are building a path from the torrent's name — a symlink farm, a remote
path mapping, a script — these are the ways it goes wrong:

  a. The extension. Only `.mkv` and `.mp4` come off, case sensitively. Any other
     container keeps its extension in the folder name.

  b. The rename. `Torrent.Rename` wins over the derived name, and RD's own
     renaming of a torrent changes `Name` under you.

  c. The hash suffix. Two different releases sharing a name means one of them is
     ` {a1b2c3}`, and which one moves as content is added.

  d. The duplicate-file tag. A file whose basename repeats inside a release is
     served as `name (tag).ext`, where the tag is a directory component or a
     path hash. `filepath.Base(file.Path)` does not reproduce it.

  e. The archive rename. An obfuscated payload inside an archive is presented
     under the release name, not its own.

  f. NZB names come from the `.nzb` FILENAME, not from anything inside it, unless
     the filename is a hash. Name the file, name the folder.

  g. Sanitised on-disk filenames are a different namespace from mount names, and
     for non-ASCII releases they deliberately do not match.

The robust way to resolve a release is by hash, then ask zurg what it is called.
Reconstructing the name is guessing, and every rule above is a way for the guess
to be wrong.
