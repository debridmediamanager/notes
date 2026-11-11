# Renomeando releases e arquivos {#renaming-releases-and-files}

zurg's mount is writable in exactly one way: você pode **renomear** a pasta de um release ou um arquivo dentro dela, em qualquer lugar da biblioteca. Essa opção já vem ativada por padrão. Nada é copiado, nada é baixado, e a conta de debrid não é tocada — o novo nome é guardado ao lado do release e tem prioridade sobre o nome que o zurg calcularia de outra forma.

O que você não pode fazer é **mover** nada. Renomear e mudar de lugar parecem a mesma ação em um gerenciador de arquivos, mas o zurg as trata como opostas, por um motivo que [a última seção](#why-a-move-is-refused-when-a-rename-is-not) explica.

Para um *layout* guardado, e não um *nome* guardado — pastas que você organiza, um \*arr importando por movimentação — veja [`__magic__`](magic.md). Esta página trata apenas do nome.

## Renomeando pelo mount {#renaming-through-the-mount}

Uma renomeação no mount é um `MOVE` do WebDAV cujo destino difere da origem apenas no último segmento do caminho. O rclone transforma uma renomeação no mount (um `rename(2)` do FUSE, ou o equivalente no WinFsp, no Windows) exatamente nisso. Assim, `mv` ou `Rename-Item` no mount, renomear no Finder, no Explorer ou em outro gerenciador de arquivos, e um cliente WebDAV chegam todos ao mesmo handler.

+++ Linux e macOS

```bash
mv "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show.S01E01.mkv" \
   "/mnt/zurg/shows/Show.S01.1080p.WEB-DL/Show - s01e01.mkv"
```

No macOS o mount é `/Volumes/Zurg`, a menos que você tenha mudado o `mount_path`.

+++ Windows

```powershell
Rename-Item -LiteralPath "Z:\shows\Show.S01.1080p.WEB-DL\Show.S01E01.mkv" -NewName "Show - s01e01.mkv"
```

+++

Os dois níveis funcionam:

| Renomear | Armazenado como |
|---|---|
| Uma pasta de release | `Torrent.Rename` |
| Um arquivo dentro de um release | `File.Rename` |

Os endpoints `/dav/` e `/infuse/` aceitam `MOVE`. O `/http/` não: ele é um navegador somente leitura e responde `405` fora de `__magic__`.

### O que um nome precisa satisfazer {#what-a-name-has-to-satisfy}

A um novo nome é aceito quando, depois de remover os espaços do começo e do fim, ele não está vazio, não contém `/` nem `\`, é igual ao seu próprio `filepath.Clean` (o que também rejeita `.` e `..`) e, no caso de uma pasta de release, não colide com a chave de acesso de um hash *diferente*. O nome de um arquivo precisa ser único dentro da sua própria release.

| Resultado | Status |
|---|---|
| Renomeado | `201` |
| Nome vazio, separador no nome ou destino que nomeia só um diretório | `400` |
| O nome já está em uso | `412` |
| Origem não encontrada | `404` |
| Dentro de um arquivo compactado, ou recusado (veja abaixo) | `403` |

Renomear um arquivo *dentro de um arquivo compactado* não é possível. O conteúdo interno do arquivo é gerado a partir do próprio arquivo, então não há onde gravar um nome. O zurg recusa com um `403` que diz que arquivos dentro de um arquivo compactado não podem ser renomeados.

## Renomeando pelo dashboard e pela API {#renaming-from-the-dashboard-and-the-api}

As mesmas duas renomeações são endpoints `POST`, e cada uma tem um reset correspondente que apaga o nome armazenado e devolve o release ao nome calculado:

```
POST /manage/{torrentHash}/rename
POST /manage/{torrentHash}/clear-rename
POST /manage/{torrentHash}/files/{fileid}/rename
POST /manage/{torrentHash}/files/{fileid}/clear-rename
```

Não existe um equivalente a `clear-rename` pelo mount. Renomear de volta para o nome original armazena esse nome; isso não remove a substituição.

### A correção de temporada {#the-season-fix}

`GET /torrents/season-fix/plan` e `POST /torrents/season-fix/apply` são uma renomeação de arquivos em massa baseada na própria correspondência de episódios do Plex, para lançamentos cujos arquivos estão numerados de um jeito que nada consegue interpretar. O plano é somente leitura e mostra, para cada arquivo, o motivo do pulo. O apply recebe uma lista explícita de hashes em vez de uma flag de aplicar tudo, então você confirma exatamente o que revisou.

## O que sobrevive a um rename {#what-a-rename-survives}

O nome salvo fica no release e é serializado dentro do `.zurgtorrent`, então ele sobrevive a:

- **Uma atualização da biblioteca**, inclusive uma que recria as entradas de arquivo do release a partir da listagem do provedor.
- **Um reinício.**
- **Um reparo**, que adiciona o release de novo pelo hash, com um id novo.
- **O provedor renomear o torrent por baixo dos panos**, o que o Real-Debrid faz.

Ele também viaja: um `.zurgtorrent` exportado leva os renames junto, então uma [biblioteca local](local-libraries.md) chega com o nome que você deu.

Uma coisa que ele não sobrevive é `ignore_renames: true`, que é justamente a função dessa chave. O zurg ignora todos os nomes salvos, mostra o nome calculado e recusa novos renames pelo mount. Os renames não são apagados, só ignorados, então desligar a opção de novo faz eles voltarem.

## O que um rename muda ao redor {#what-a-rename-changes-around-it}

Um rename é uma visualização, mas várias coisas são construídas a partir dessa visualização, e todas são atualizadas junto com ela:

- **O mount.** O cache de diretórios do rclone é invalidado para o caminho antigo e para o novo, então a mudança aparece sem precisar esperar o cache expirar.
- **Arquivos `.strm`**, se `save_strm_files` estiver ativado. Os antigos são apagados e gerados de novo com o novo nome.
- **Plex e Jellyfin** são solicitados a verificar o lançamento novamente.
- **O registro de cache no disco.** O `.zurgtorrent` é gravado com o novo nome e o arquivo antigo é apagado. Essa exclusão é importante: se o arquivo antigo ficar para trás, um reinício carrega os dois, a colisão de hash resolve de volta para a outra cópia e o rename volta atrás sem aviso. Esse foi um bug real, visto em 17/08/2026.
- **Os endpoints do SABnzbd e do qBittorrent**, que recalculam a pasta informada ao Sonarr e ao Radarr a cada consulta. Assim, um rename durante uma importação muda o caminho do qual eles são instruídos a importar, em vez de deixá-los perdidos.

## Três armadilhas {#three-traps}

**Um rename pode mudar a pasta do release na próxima atualização.** A divisão em diretórios é decidida rodando os filtros de `directories:` sobre o nome do release, e esses filtros veem o nome *renomeado*. O rename em si não reavalia os filtros de propósito — ele mantém o release nos diretórios em que já estava —, mas a próxima atualização reavalia. Então, se um filtro depende de algo no nome e o seu novo nome não tem mais isso, o release vai para outro diretório depois, sem nada no momento do rename que indique isso. Renomeie com cuidado quando houver filtros baseados em nomes.

**Mudar a extensão muda o que o arquivo é.** Nada impede `episode.mkv` virar `episode.txt`; só os separadores são rejeitados. Mas a visibilidade é avaliada pelo nome que o cliente vê, então o arquivo renomeado pode sair de `only_show_the_biggest_file`, da lógica de arquivos reproduzíveis e da varredura do seu servidor de mídia.

**Uma URL `.strm` que já foi entregue a outra coisa quebra.** O token assinado codifica a chave de acesso e o nome do arquivo, então uma URL capturada antes do rename não resolve mais nada depois e responde `404`. A árvore `.strm` do próprio zurg é reescrita, mas qualquer coisa que tenha copiado uma URL dela não é.

## Desligando {#turning-it-off}

| Key | Default | Effect |
|---|---|---|
| `dav_allow_rename` | `true` | `false` recusa um `MOVE` no mount com `403`, citando a chave no corpo |
| `ignore_renames` | `false` | `true` ignora todos os renames salvos, serve os nomes calculados e recusa novos renames pelo mount com `403` |
| `mount_read_only` | `false` | `true` inicia o rclone com `--read-only`, então o kernel recusa a escrita antes que o zurg a veja |

`dav_allow_rename` vale para o mount. Ele não controla os endpoints do dashboard,
e também não controla escritas em `__magic__`, que não chegam a nenhuma conta de debrid.
O mirror é a única exceção, e não por causa desta chave: `__magic__/__all__`
e as pastas de release diretamente dentro dele são o layout próprio da biblioteca, então
uma escrita em qualquer uma delas é recusada, independentemente do valor desta chave. Dentro
de uma pasta de release, tudo volta ao normal.
`mount_read_only` sobrepõe tudo, no kernel, e também é a única forma de bloquear um `DELETE` no mount — veja [config.md](../reference/config.md) para entender por que isso importa mais do que o rename.

## Por que um move é recusado quando um rename não é {#why-a-move-is-refused-when-a-rename-is-not}

| Tentativa | Status |
|---|---|
| Mover uma pasta de release para outro diretório | `403` |
| Mover um arquivo para outro release | `403` |
| Mover um arquivo para uma subpasta do próprio release | `400` |
| Renomear ou mover um diretório de nível superior | `405` |
| Mover qualquer coisa para fora de `__magic__` | `403` |
| Escrever em `__magic__/__all__`, ou em um nome diretamente dentro dele | `403` |

A regra por trás de tudo isso é a mesma em cada caso: **um renomeio tem onde ser guardado, e um movimento não.**

O nome de um release é uma única string no próprio release, então escrever um nome novo é uma atribuição de campo que toda consulta seguinte lê de volta. Já um diretório de nível superior não é uma pasta de verdade: é um filtro salvo, e os membros dele são recalculados a partir da configuração `directories:` a cada atualização. Mover um release "para dentro" de `movies` não gravaria nada, porque nada lê uma resposta guardada para essa pergunta; na próxima atualização, os membros seriam recalculados a partir dos filtros e o movimento seria desfeito. Recusar é a resposta honesta. O mesmo vale para uma subpasta dentro de um release, cujo formato vem da própria lista de arquivos da conta.

`__magic__` existe porque um layout guardado é realmente útil, e ele resolve o problema de armazenamento em vez de fingir que ele não existe: um movimento dentro dele grava uma linha em uma tabela pequena indexada pelo hash do conteúdo, e é por isso que ele sobrevive a um reparo que readiciona o release com um novo id. Essa tabela é restrita a um único namespace de propósito.

Há um segundo motivo para não ampliar a superfície de recusas sem cuidado. [rclone-move-refusal.md](../internals/rclone-move-refusal.md) documenta o que um `MOVE` recusado faz com um cliente que não esperava por ele: no rclone 1.72.0, a entrada do VFS fica apontando para o destino tentado, e um cliente que recorre a copiar-e-apagar lê EOF e informa sucesso, produzindo um arquivo de zero bytes que ele acredita ter gravado. Cada recusa acima é uma recusa que algo precisa sobreviver.
