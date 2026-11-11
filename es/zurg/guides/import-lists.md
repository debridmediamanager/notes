# Seguir una lista en Sonarr y Radarr {#following-a-list-in-sonarr-and-radarr}

Sonarr y Radarr pueden seguir una lista de series o películas. Cada título de la lista se añade y se busca. Con zurg como cliente de descarga, cada descarga llega a tu cuenta de debrid e se importa en `__magic__` como cualquier otra. Así, una lista es una sección completa de la biblioteca que se llena sola. Una lista de terror te da una sección de terror, y los títulos nuevos aparecen a medida que la lista crece.

Esta página asume que los \*arrs ya descargan a través de zurg. Si todavía no lo hacen, empieza con [Sonarr y Radarr para torrents](sonarr-radarr-torrents.md).

## Usa MDBList y no IMDb {#use-mdblist-and-not-imdb}

Las dos apps todavía muestran un tipo de lista de IMDb, y ninguna funciona ya con una lista normal de IMDb.

- Radarr rechaza un ID de lista con la forma `ls12345678`. Solo acepta `top250`, `popular` o la watchlist de un usuario `ur12345678`.
- Sonarr acepta el ID y luego recibe una respuesta vacía de IMDb. El botón Test muestra `Imdb call resulted in an unexpected StatusCode [Accepted]`.

[MDBList](https://mdblist.com) es la forma de evitar los dos problemas. Publica cualquier lista como un feed JSON que ambas apps leen con su tipo Custom List. Las películas y las series están en listas separadas, así que añades una a cada app.

## 1. Elige una lista {#1-pick-a-list}

Las listas públicas no necesitan cuenta. Busca en MDBList el género que quieras y abre una lista. Dos listas de terror que funcionan a fecha de octubre de 2026:

| Lista | Contiene | URL del feed |
|---|---|---|
| Horror | películas | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | series | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

La URL del feed es la URL de la página de la lista con `/json` al final. Ábrela primero en un navegador. Deberías ver una página de texto que empieza con `[{"id":`.

Para crear tu propia lista, inicia sesión en MDBList y créala. Puede seguir filtros como un género y una puntuación mínima, o copiar una lista de IMDb que ya tengas. La URL del feed funciona igual.

## 2. Añádela a Radarr {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Campo | Valor |
|---|---|
| Name | lo que quieras, por ejemplo `Horror` |
| Enable | on |
| Enable Automatic Add | on |
| Search on Add | lee primero la advertencia de abajo |
| Monitor | Movie Only |
| Root Folder | tu carpeta de películas dentro de `__magic__`, por ejemplo `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` en macOS, `Z:\__magic__\movies` en Windows) |
| Quality Profile | el que uses |
| List URL | la URL del feed de películas |

Pulsa **Test** y luego **Save**.

## 3. Añádela a Sonarr {#3-add-it-to-sonarr}

**Settings → Import Lists → + → Custom List**

| Field | Value |
|---|---|
| Name | lo que quieras, por ejemplo `Horror Shows` |
| Enable Automatic Add | on |
| Monitor | All Episodes, o Pilot Episode para probar primero una serie |
| Root Folder | tu carpeta de series dentro de `__magic__`, por ejemplo `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` en macOS, `Z:\__magic__\tv` en Windows) |
| Quality Profile | el que uses |
| Series Type | Standard |
| Season Folder | on |
| Search for Missing Episodes | lee primero la advertencia de abajo |
| List URL | la URL del feed de series |

Pulsa **Test** y luego **Save**.

## Las listas grandes descargan todo de una vez {#big-lists-grab-everything-at-once}

A list with search on add switched on grabs every title the moment it syncs. The movie list above holds 400 titles and the show list holds 148 shows with every episode. That is a lot of grabs in one go. Your debrid account and your indexers will feel it, and an indexer with a rate limit will start refusing searches.

There are two gentler ways in.

- Leave search on add off. The titles get added and monitored and nothing is searched. Search the ones you want from the Movies or Series page.
- Start with a short list. Add the big one once the first batch has landed.

The apps also sync lists on their own schedule. **System → Tasks → Import List Sync** runs one now.

## Quitar una lista {#removing-a-list}

Borrar una lista detiene la llegada de títulos nuevos. Lo que ya se añadió se queda. En **Settings → Import Lists**, el **Clean Library Level** decide qué pasa con los títulos que salen de una lista. Déjalo en Disabled a menos que quieras que las apps eliminen cosas por ti.
