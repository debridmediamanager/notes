# Torrents

O Real-Debrid permite baixar um número ilimitado de arquivos torrent e links magnet, além de escolher quais arquivos dentro deles você quer baixar.

Se o arquivo torrent ou o link magnet já tiver sido baixado por outro usuário, ele é considerado "cached" e o Real-Debrid já te entrega o link em cache.

Se não, ele tenta baixar o link magnet a partir de trackers públicos ou de DHT/PEX.

Se for um arquivo torrent com informações de tracker, ele usa essas informações de tracker, o que é útil para trackers privados (infelizmente, muitos trackers privados bloqueiam os servidores de download do Real-Debrid).

Se o torrent não tiver mais seeders nem leechers e for impossível baixar todas as partes dele, vai dar erro.

Depois de baixado, você também recebe links em cache com a forma https://real-debrid.com/d/DOWNLOADCODE

DOWNLOADCODE é exatamente um ID único de 13 caracteres do arquivo específico (tudo depois do 13º caractere é ignorado).

# Selecionando arquivos {#selecting-files}

As mentioned, it is possible to select only the files you want to download from inside a torrent.
If a torrent contains files A, B and C and you select A and B, it will only download A and B.
The cached status of a torrent actually depends on this unique file selection.
Going back to the torrent containing files A, B and C, there are different cached statuses for A, or B, or B (single), A+B, B+C, A+C (pair), or A+B+C (all files).
Each unique selection downloads the torrent again from the trackers and returns a different cached link, even for the same file.

# Links em cache {#cached-links}

Links em cache não são links baixáveis. Na verdade, eles servem apenas como contêineres para os CÓDIGOS DE DOWNLOAD no Real-Debrid.
Você precisa "desrestringir" ou converter o link em um link real para download ou streaming do Real-Debrid, que expira após 7 dias.
Links em cache duram mais de 7 dias. Se um torrent tiver links em cache funcionando (ou seja, é possível desrestringi-los com sucesso), isso significa que ele ainda está em cache no Real-Debrid.
Não se sabe ao certo, mas é bem provável que o status de cache de um torrent possa ser estendido se mais usuários desrestringirem um link em cache.

Atenção: a única forma de verificar se um link em cache está funcionando é desrestringindo-o e checando o primeiro byte do link desrestringido usando o cabeçalho HTTP Range.
O zurg suporta dois tipos de verificação: HEAD (padrão, rápida) e baseada em Range (GET bytes=0-0, mais completa), através da opção de configuração use_range_verification.

# Compartilhamento de links em cache entre contas (medido em 2026-08-19) {#cached-link-sharing-across-accounts-measured-2026-08-19}

RD retorna IDs de link em dois tamanhos, 13 caracteres (~70%) e 16 caracteres (~30%), e esses 3 caracteres extras mudam QUEM pode desbloquear o link:
- Truncado nos primeiros 13 caracteres, um link /d/ pode ser desbloqueado de QUALQUER conta premium, não só da que o gerou. A biblioteca de torrents de quem chama continua intacta; o único efeito colateral é uma entrada no histórico de downloads de quem chama.
- Enviado com o ID completo de 16 caracteres, o mesmo link só pode ser desbloqueado pela conta que o gerou. Todas as outras contas recebem "unavailable_file", mesmo enquanto o torrent de origem estiver ativo, mesmo que quem chama tenha o mesmo infohash na própria biblioteca, e independentemente do parâmetro ip.
Por isso, sempre trunque para 13 caracteres antes de desbloquear um link armazenado. Testar com IDs não truncados "prova" falsamente que o compartilhamento de links é impossível.

Links em cache sobrevivem quando a conta que os gerou apaga o torrent, mas morrem com a idade. Em uma amostragem grande, links gerados 1-2 meses antes ainda desbloqueavam entre contas; links com mais de ~3 meses retornaram todos "hoster_unavailable". Além disso, a RD pode remover o próprio conteúdo do cache dela (um hash comprovadamente em cache um mês pode estar em downloading com 0 seeders no mês seguinte); nesse caso o link retorna "unavailable_file" para todos, inclusive para a conta que o gerou.

Como interpretar um erro de unrestrict em um link em cache armazenado:
- Link de 13 caracteres + hoster_unavailable -> o link envelheceu; adicionar o torrent de novo com a mesma seleção gera links novos (veja o reparo abaixo)
- Link de 13 caracteres + unavailable_file -> a RD removeu o conteúdo por completo; links novos exigem um download real de seeders
- Link de 16 caracteres + unavailable_file -> não diz nada sobre disponibilidade: você simplesmente não é a conta que gerou o link; trunque e tente de novo

Links desbloqueados (as URLs de host *.download) são vinculados ao IP pelo rastreamento do lado do servidor, não por recusa:
o CDN serve com satisfação um IP estrangeiro com um 206, mas a real-debrid registra os IPs de download, e o uso de links de uma mesma conta a partir de vários IPs gera um aviso de compartilhamento de conta. Passe o IP de quem baixa para unrestrict/link (o parâmetro ip) para que o link seja gerado para o IP que vai puxar os bytes.

# Reparando links em cache quebrados {#repairing-broken-cached-links}

Às vezes, um link em cache ou até mesmo o link desbloqueado de um arquivo dentro de um torrent deixa de funcionar
Isso pode acontecer por causa de um erro na API de desbloqueio ou porque o link desbloqueado retorna uma resposta de erro HTTP
Para resolver, precisamos baixar o torrent de novo e gerar links em cache novos ou frescos
Você pode tentar baixar o torrent de novo com exatamente a mesma seleção de arquivos e ver se ele gera links em cache novos ou frescos
Se isso não funcionar, significa que você precisa fazer uma seleção de arquivos diferente nesse torrent
Por exemplo, se só um arquivo está quebrado em um torrent com vários arquivos, selecione apenas esse arquivo quebrado
Se ainda retornar um link em cache quebrado, tente adicionar outro arquivo à seleção
Você repete isso até conseguir um link em cache novo e funcionando

# Comportamento de RAR {#rar-behavior}

Real-Debrid tem o comportamento de guardar torrents em arquivos RAR (sem compressão) se você selecionar um tipo de arquivo não suportado que não pode ser transmitido em streaming.
Tipos de arquivo de vídeo confirmados: .avi .flv .m2ts .m4v .mkv .mov .mp4 .mpg .mpeg .ts .webm .wmv
Tipos de arquivo de áudio confirmados: .mp3 .flac .m4a
Quando esses tipos de arquivo são selecionados, o Real-Debrid gera links individuais para cada arquivo, e eles podem ser transmitidos em streaming.
Se você selecionar qualquer outra coisa, é garantido que o Real-Debrid vai guardar tudo em um arquivo RAR.
Se você selecionar um vídeo .mkv e uma legenda .sub, ele vai ser colocado em RAR.
O mesmo acontece se você selecionar só o pôster .jpg: ele também vai ser colocado em RAR.

Um torrent, mesmo com vários arquivos, se for colocado em RAR, vai retornar apenas um único link em cache (que aponta para o arquivo RAR).
Se você selecionar apenas arquivos de vídeo/áudio confirmados, ele não será colocado em RAR e você receberá um link em cache para cada arquivo selecionado.

# Apagar uma linha da lista de downloads revoga a URL que ela gerou {#deleting-a-downloads-list-row-revokes-the-url-it-minted}

Medido em 2026-08-22 na conta de teste, uma unrestrict por caso.

Um unrestrict cria uma linha em /downloads e uma URL em um host numerado, por exemplo
https://124-4.download.real-debrid.com/d/<13-char code>/<filename>. O código
não é restrito a um host: antes de a linha ser deletada, o mesmo código responde 200 em
44-4, 125-4 e no próprio 124-4. O segmento final com o nome do arquivo é opcional
em todos os casos; o zurg o remove e as duas formas respondem igual.

DELETE /downloads/delete/<id> revoga esse código, e o que sobrevive depende de
quais hosts já serviram o arquivo:

  - Linha deletada com a URL nunca buscada: todos os hosts respondem 404 com
    X-Error: invalid_download_code. Continua 404 depois de 30s — não se estabiliza.
  - Linha deletada depois de uma busca pelo 44-4: o 44-4 continua respondendo 200,
    enquanto o host que gerou o código, 124-4, e um 125-4 que não foi usado, respondem
    ambos 404 invalid_download_code.

Ou seja, uma busca ativa o código no host que a serviu, e é a linha que
mantém os outros hosts servindo. Isso é o oposto da premissa em que a limpeza da
lista de downloads foi escrita, e importa porque o zurg escolhe o host de download
a cada requisição (ensureReachableDownloadServer reescreve para um dos N hosts mais
rápidos): o host que recebeu o HEAD de verificação não é o host que a
próxima requisição escolhe. Por isso, uma resolução que fica no cache de links depois
que a linha é deletada responde 404 invalid_download_code em quase todas as
requisições seguintes, o que parece um link quebrado e marca uma release saudável como
com problema.

Refazer o unrestrict do mesmo link depois de um delete acaba criando um novo id em um
novo host, e aí funciona normalmente. Os ids não são reutilizados.

Mas não de imediato, e a primeira medição aqui disse "não afetado" porque foi feita
minutos depois. Medido de novo em 2026-08-23 na conta de teste: depois de
DELETE /downloads/delete/<id>, unrestrict/link continuou retornando o *mesmo id morto*
por 75 segundos, e só gerou um novo em t+81s.

Duas coisas decorrem disso, e ambas estão no código. O downloadsCleanupMinAge mantém
uma linha por dois minutos antes de aposentá-la, então uma instância irmã que resolva o
mesmo link nessa janela recebe um código ativo. E o caminho de serviço, com a cadeia de
re-unrestrict (quatro tentativas em cerca de seis segundos), cabe inteiramente dentro
da janela, então esgotá-la não diz nada sobre o arquivo: quando todas as resoluções voltam
como a URL que acabou de responder 404, o zurg recusa a leitura com um Retry-After
em vez de marcar a release como com problema.
