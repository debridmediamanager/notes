# Importações vazias após um movimento recusado {#empty-imports-after-a-refused-move}

Reproduzido com rclone 1.72.0, um union local-first, VFS com cache completo e o `File.Move(source, destination)` do .NET 6 usado pelo Sonarr 4.0.19.2979.

Quando o backend recusa um MOVE, o `vfs.File.rename` do rclone deixa o diretório e o nome do arquivo apontando para o destino tentado. Aí o .NET recorre a uma cópia. Ao criar o destino, é criada uma entrada de cache VFS vazia. Ao abrir a origem, chega-se a essa mesma entrada, então a cópia lê EOF e informa sucesso. A reprodução esperava 4096 bytes e recebeu zero. Mudar a recusa do WebDAV de 409 para 422 não mudou o resultado.

O patch em `scripts/patches/rclone-v1.72.0-rename.patch` restaura o diretório e o nome originais quando o rename imediato falha. Ele inclui um teste de regressão upstream do VFS. O teste de montagem exercita todo o caminho WebDAV, union, FUSE e .NET com um arquivo falso e sem credenciais de provedor. O veredito de dano é injetado enquanto os bytes do fixture continuam legíveis: o .NET pode copiar esses bytes com sucesso, mas não pode transformá-los em um arquivo vazio.

Monte um novo binário ao lado do instalado:

```sh
./scripts/build-rclone-move-fix.sh /absolute/path/to/rclone-fixed
RCLONE_TEST_BIN=/absolute/path/to/rclone-fixed ./integration/magic_move_refusal.sh
```

O build fixa o commit upstream `38ab3dd5b1df946aecf5bd085c671c86f46f68eb` (1.72.0). Ele roda os testes de rename do VFS antes de compilar. O teste de montagem exige FUSE no Linux e Docker, ou um `DOTNET_MOVE_PROBE_BIN` autocontido compilado a partir de `integration/dotnet-move-probe`. Ele falha de propósito contra o binário sem patch. `make integration-test` inclui essa verificação. Aponte `RCLONE_TEST_BIN` e `RCLONE_BIN` para o binário corrigido ao rodar a suíte.

A instalação exige reiniciar a montagem usando as proteções normais de media server do seu deployment. Guarde o binário anterior para rollback. Arquivos vazios que já existem na origem local de um union sobrevivem a um restart da montagem. Preserve e remova apenas os artefatos de importação vazios confirmados ali. Reiniciar limpa os nós VFS obsoletos, mas não repara artigos Usenet ausentes.

Esta correção não suprime o fallback de cópia do .NET nem torna legível conteúdo danificado. A verificação de disponibilidade do zurg antes da conclusão no SABnzbd e o MOVE recusado continuam sendo proteções separadas. A amostragem de disponibilidade não é uma verificação de arquivo completo. Veja `sabnzbd-client-contract.md`.

O patch fixado também traz a correção de alias de arquivo usada pelo union embutido. Com `action_policy: all`, local e WebDAV podem receber uma mesma operação de arquivo. Uma operação Move ou Remove local bem-sucedida, pareada com um 404 do WebDAV, só é aceita depois que uma nova consulta provar que a origem do upstream que falhou sumiu. Operações em que todos falharam, uma origem que ainda existe, um diretório pai de destino ausente e outros erros de I/O ou permissão continuam sendo falhas. O binário resultante informa `v1.72.0-zurg-rename-sidecar-fix`, para que seja distinguível do build original somente com VFS.
