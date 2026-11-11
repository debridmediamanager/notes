# Música com o rex {#music-with-rex}

rex pode manter uma biblioteca de música para Plexamp, Plex Web e Plex para Android. Um addon de música envia cada música e o seu lançamento no MusicBrainz. O Plex preenche os nomes, as capas, os detalhes dos artistas, os gêneros e artistas semelhantes.

O que você ganha:

- **Álbuns que o Plex conhece.** Um álbum enviado com o seu lançamento no MusicBrainz aparece como apareceria em qualquer servidor Plex, com a capa e os nomes das faixas do Plex. Um que o Plex não conhece mostra os nomes e as imagens que o addon envia.
- **Qualidade original.** As músicas tocam no formato original, como FLAC.
- **Letras e volume**, quando o addon envia: as letras aparecem junto com a música, e o rex passa o volume de cada música para os apps, como o Plex faz.
- **Suas próprias reproduções e playlists.** Reproduções, avaliações e playlists são mantidas por conta do Plex. O Plexamp também cria as suas playlists inteligentes no rex.

## Antes de começar {#before-you-start}

| Você precisa | Por quê |
|---|---|
| Um nightly do rex datado de 2026.11.02 ou mais recente | A música veio nessa build |
| rex configurado como em [rex with your own app](any-source.md) | É ali que a biblioteca de música aparece |
| Um addon de música | Qualquer programa que envie músicas pela feed API do rex. Para uma pasta de álbuns nos seus próprios discos, [Tutorial: a music addon](addon-music.md) é um exemplo completo em um único arquivo Python |
| [Converting video](any-source.md#converting-video-optional), opcional | O rex converte uma música somente para um app configurado com uma qualidade de música menor que a original |

## Passo 1. Instale o rex e adicione-o a uma conta do Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Siga [rex com seu próprio app](any-source.md):

1. [Passo 1. Instale o rex](any-source.md#step-1-install-rex), incluindo como descobrir o IP da LAN do rex. Esta página o escreve como `192.168.1.20`: coloque o seu no lugar.
2. [Passo 3. Adicione ao uma conta Plex](any-source.md#step-3-add-it-to-a-plex-account): registre o rex na conta nova e compartilhe com a sua.

## Passo 2. Aponte seu addon de música para o rex {#step-2-point-your-music-addon-at-rex}

O rex precisa de uma biblioteca de música para as músicas. Se o seu addon declarar uma, o rex cria ela quando o addon se registra. Se não declarar, adicione uma antes em um app do Plex logado com a conta nova: **Add Library**, **Music**, qualquer pasta. Uma música enviada antes de existir uma biblioteca de música é recusada.

Depois, dê ao seu addon o endereço do rex, `http://192.168.1.20:32400`, do jeito que as instruções dele dizem. Ele se registra no rex e envia os álbuns dele.

**O que você deve ver.** No log do rex:

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

A linha `SECTION create` só aparece se o addon declarar a biblioteca. A biblioteca de música aparece no rex, com cada álbum embaixo do seu artista. Uma música que o rex recusa aparece no log com o motivo, como `no music library holds <file>`.

## Passo 3. Compartilhe a biblioteca de música {#step-3-share-the-music-library}

A biblioteca de música é nova, então ainda não está no compartilhamento de ninguém. Logado com a conta nova, adicione-a ao compartilhamento da sua própria conta e ao de todos os outros em **Manage Library Access** ([Share rex](sharing.md)).

## Passo 4. Ouça {#step-4-listen}

- **Plexamp**: faça login com a sua própria conta do Plex e escolha a biblioteca de música do rex como sua biblioteca.
- **Plex Web e Plex para Android**: a biblioteca de música fica junto com as outras bibliotecas do rex.

**O que você deve ver.** Os álbuns com as capas e os nomes das faixas do Plex, e o artista com uma foto. Aperte play.

## O que ele não consegue fazer {#what-it-cannot-do}

- **Sem rádio, mixes ou estações.** O rádio, os mixes, as estações e as músicas sonoramente parecidas do Plexamp precisam de uma análise de cada música, e o rex não faz isso.
- **Sem pasta de música própria.** O rex não escaneia nada e não lê tags. Um addon precisa enviar cada música, junto com a release do MusicBrainz do álbum, para o Plex saber o nome dela.
- **Duas cópias de um álbum são dois álbuns**, como em qualquer servidor Plex: uma cópia em FLAC e uma em MP3 aparecem cada uma como um álbum separado.
- **Testado no Plexamp, no Plex Web e no Plex para Android.** Outros apps do Plex e os downloads offline do Plexamp não foram testados.

Para escrever um addon de música seu, comece por [Tutorial: um addon de música](addon-music.md); [Criando addons para o rex](addons.md#music) tem todos os campos.
