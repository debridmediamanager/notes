# Kometa con rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) crea colecciones, pone insignias en los pósters (4K, HDR, valoraciones) y completa las valoraciones y los géneros en un servidor de Plex. rex responde a Kometa igual que lo haría un servidor de Plex, así que la misma configuración funciona en tus bibliotecas de rex.

Todo lo que aparece a continuación se probó el 2026-10-23 con Kometa 2.5.3 (la imagen de Docker `kometateam/kometa`) y con un rex reclamado que tiene películas y una serie.

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| rex configurado y añadido a una cuenta de Plex, como en [Añadirlo a una cuenta de Plex](any-source.md#step-3-add-it-to-a-plex-account) | Kometa edita la biblioteca, y solo la cuenta en la que está registrado rex puede hacerlo. Un rex sin reclamar no le sirve a nadie |
| rex nightly **2026.10.24 o más reciente** | Actualiza como se explica en [la sección Updating de rex](any-source.md#updating) |
| Docker en cualquier máquina que pueda acceder a rex | Kometa se ejecuta como un contenedor. Los propios documentos de Kometa explican [otras formas de instalarlo](https://kometa.wiki/en/latest/kometa/install/overview/) |
| Una clave de API de TMDb gratuita | Kometa la necesita para sí mismo, aunque rex no. Créala en **Settings → API** en themoviedb.org, como describe [la página de primeros pasos de TMDb](https://developer.themoviedb.org/docs/getting-started) |

## 1. Obtén el token de rex {#1-get-rexs-token}

Kometa inicia sesión en rex con un token de Plex. Usa el token que rex te dio al registrarlo. En la máquina de rex:

+++ Linux y macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

Con [rex en Docker](any-source.md#run-rex-in-docker) el archivo es solo para root: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**Qué deberías ver.** Una línea, `"token": "..."`. Copia lo que está entre el segundo par de comillas. Trátalo como una contraseña: abre todo el servidor. Si alguna vez vuelves a registrar rex, el token cambia y Kometa necesitará el nuevo.

**No el token de tu propia cuenta.** En [Compártelo con tu propia cuenta](any-source.md#share-it-with-your-own-account) tu cuenta recibió rex como un recurso compartido. Un recurso compartido puede ver, pero no editar, así que con su token Kometa se detiene con `Plex Token is read only` o, si el recurso permite descargas, falla en su primer cambio.

## 2. Escribe la configuración de Kometa {#2-write-kometas-config}

Crea una carpeta para Kometa, por ejemplo `~/kometa/config` (`$HOME\kometa\config` en Windows), y pon esto en `config.yml` dentro de ella:

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

- `url` es la IP de LAN y el puerto de rex, la dirección de [Instalar rex](any-source.md#step-1-install-rex). No uses `127.0.0.1` ni `localhost`: dentro del contenedor de Kometa, esas direcciones apuntan al propio contenedor.
- Los nombres bajo `libraries:` deben coincidir exactamente con las bibliotecas de rex: **Movies** y **TV Shows**, además de cualquiera que hayas añadido o renombrado. Omite la biblioteca que no quieras que Kometa toque.

Es un comienzo sencillo. La documentación de Kometa lista [todas las colecciones y overlays predeterminados](https://kometa.wiki/en/latest/defaults/guide/), y tus propios archivos de colección también funcionan.

## 3. Ejecútalo una vez {#3-run-it-once}

+++ Linux and macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` hace que Kometa haga una pasada ahora y se cierre. Sin él, Kometa se queda en ejecución y espera a su programación diaria.

**Qué deberías ver.** En la salida de Kometa, para cada biblioteca:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

En una app de Plex, la biblioteca de películas tiene una pestaña **Collections** con las colecciones por género, y los pósteres llevan sus insignias. Tu propia cuenta y todos los demás con los que compartiste rex ven las mismas colecciones e insignias. La primera ejecución en una biblioteca grande tarda un poco: Kometa lee cada título y vuelve a dibujar cada póster al que le pone insignia.

## Si no funciona {#if-it-does-not-work}

| Lo que dice Kometa | Qué significa |
|---|---|
| `Plex Token is read only. Please get a new token` | rex todavía no está añadido a una cuenta de Plex, o el token es el de tu propia cuenta y no el del paso 1 |
| Kometa se conecta, pero luego todos los cambios fallan | El token es el de tu propia cuenta. Usa el del paso 1 |
| `url_poster failed to update poster` | La máquina de rex no puede acceder al sitio donde está la imagen |
| `Plex URL is probably invalid` o un timeout | `url` no llega a rex desde donde se ejecuta Kometa. Abre `http://192.168.1.20:32400/identity` desde esa máquina: debería mostrar el `machineIdentifier` de rex |
| `Plex Error: Plex Library '...' not found. Options: [...]` | Un nombre bajo `libraries:` no coincide. Copia uno de la lista que muestra |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Pedir ayuda](../guides/remote-help.md) explica qué incluir.

## Lo que Kometa puede y no puede ver {#what-kometa-can-and-cannot-see}

Kometa busca títulos por los ids de TMDb, TVDb e IMDb que rex muestra para ellos. Un título que su fuente no identificó, que todavía muestra el nombre de su archivo y no tiene póster, no tiene ninguno de esos ids, así que Kometa lo deja fuera de todo lo que se construya con ellos. Arréglalo primero con Fix Match en una app de Plex.

Probado con rex: colecciones por búsqueda de título, por id de TMDb y colecciones inteligentes; las colecciones predeterminadas de género con sus pósteres; los overlays de resolución y de valoraciones; y las actualizaciones de valoraciones de crítica y de géneros desde TMDb. Todavía no probado: listas de reproducción, bibliotecas de música y las demás operaciones de Kometa. Si alguna falla, el log de Kometa indica la petición que falló, y vale la pena reportarlo en Discord.
