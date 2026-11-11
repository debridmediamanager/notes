# Música con rex {#music-with-rex}

rex puede guardar una biblioteca de música para Plexamp, Plex Web y Plex para Android. Un addon de música envía cada canción y su release de MusicBrainz. Plex rellena los nombres, las portadas, los detalles del artista, los géneros y los artistas similares.

Esto es lo que obtienes:

- **Álbumes que Plex conoce.** Un álbum enviado con su release de MusicBrainz se ve igual que en cualquier servidor de Plex, con la portada y los nombres de las pistas de Plex. Uno que Plex no conoce muestra los nombres y las imágenes que envía el addon.
- **Calidad original.** Las canciones se reproducen en su formato original, como FLAC.
- **Letras y loudness**, cuando el addon las envía: las letras se muestran junto con la canción, y rex pasa la loudness de cada canción a las apps, igual que hace Plex.
- **Tus reproducciones y listas.** Las reproducciones, valoraciones y listas se guardan por cuenta de Plex. Plexamp también crea sus listas inteligentes en rex.

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| Un nightly de rex con fecha 2026.11.02 o posterior | La música llegó en esa versión |
| rex configurado como en [rex con tu propia app](any-source.md) | Ahí es donde aparece la biblioteca de música |
| Un addon de música | Cualquier programa que envíe canciones a través de la API de feed de rex. Para una carpeta de álbumes en tus propios discos, [Tutorial: un addon de música](addon-music.md) es un ejemplo completo en un solo archivo de Python |
| [Convertir video](any-source.md#converting-video-optional), opcional | rex convierte una canción solo para una app configurada con una calidad de música inferior a la original |

## Paso 1. Instala rex y añádelo a una cuenta de Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

Sigue [rex con tu propia app](any-source.md):

1. [Paso 1. Instala rex](any-source.md#step-1-install-rex), incluida la búsqueda de la IP de rex en tu LAN. Esta página la escribe como `192.168.1.20`: pon la tuya en su lugar.
2. [Paso 3. Añádelo a una cuenta de Plex](any-source.md#step-3-add-it-to-a-plex-account): registra rex en la cuenta nueva y compártelo con la tuya.

## Paso 2. Apunta tu addon de música a rex {#step-2-point-your-music-addon-at-rex}

rex necesita una biblioteca de música para las canciones. Si tu addon la declara, rex la crea cuando el addon se registra. Si no la declara, añade una primero en una app de Plex con la cuenta nueva: **Add Library**, **Music**, cualquier carpeta. Una canción enviada antes de que exista una biblioteca de música se rechaza.

Luego dale a tu addon la dirección de rex, `http://192.168.1.20:32400`, como indiquen sus propias instrucciones. Se registra en rex y le envía sus álbumes.

**Qué deberías ver.** En el log de rex:

```
INFO    SOURCES PUT /rex/sources/<addon> -> 200
INFO    SECTION create Music (artist) for <addon>'s music
INFO    FEED <addon> upsert: ...
```

La línea `SECTION create` solo aparece si el addon declara la biblioteca. La biblioteca de música aparece en rex, con cada álbum bajo su artista. Una canción que rex rechaza aparece en el log con el motivo, por ejemplo `no music library holds <file>`.

## Paso 3. Comparte la biblioteca de música {#step-3-share-the-music-library}

La biblioteca de música es nueva, así que todavía no está en el compartido de nadie. Con la cuenta nueva iniciada, añádela al compartido de tu propia cuenta y al de todos los demás en **Manage Library Access** ([Share rex](sharing.md)).

## Paso 4. Escucha {#step-4-listen}

- **Plexamp**: inicia sesión con tu propia cuenta de Plex y elige la biblioteca de música de rex como tu biblioteca.
- **Plex Web y Plex para Android**: la biblioteca de música está junto con las otras bibliotecas de rex.

**Qué deberías ver.** Los álbumes con las portadas y los nombres de las pistas de Plex, y el artista con una foto. Pulsa reproducir.

## Lo que no puede hacer {#what-it-cannot-do}

- **Sin radio, mezclas ni estaciones.** La radio, las mezclas, las estaciones y las canciones sonoramente similares de Plexamp necesitan un análisis de cada canción, y rex no lo hace.
- **Sin carpeta de música propia.** rex no escanea nada ni lee etiquetas. Un addon tiene que enviar cada canción, junto con la versión de MusicBrainz del álbum para que Plex le ponga nombre.
- **Dos copias de un álbum son dos álbumes**, como en cualquier servidor de Plex: una copia en FLAC y una copia en MP3 aparecen cada una como su propio álbum.
- **Probado en Plexamp, Plex Web y Plex para Android.** Otras apps de Plex, y las descargas sin conexión de Plexamp, no se han probado.

Para escribir tu propio addon de música, empieza por [Tutorial: un addon de música](addon-music.md); [Building rex addons](addons.md#music) tiene todos los campos.
