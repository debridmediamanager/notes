# Trae tu historial de visualización a rex {#bring-your-watch-history-to-rex}

rex empieza sin historial de visualización. Puede copiar los títulos vistos, los puntos de reanudación y las calificaciones con estrellas desde otro servidor de Plex.
Los títulos vistos siguen marcados como vistos. Los títulos vistos a medias vuelven a **Continue Watching**. Las series y las temporadas vuelven a contar sus episodios.

Ejecútalo una vez desde cualquier computadora de casa. Cada persona que usa rex puede importar su propio historial.

## Antes de empezar {#before-you-start}

| Necesitas | Por qué |
|---|---|
| rex configurado, con tu biblioteca dentro, como en [rex con tu propia app](any-source.md), [rex con tus addons de Stremio](stremio.md) o [rex con zurg](with-zurg.md) | rex solo copia el historial a los títulos que ya tiene. Si tu biblioteca todavía se está llenando, ejecuta la importación más tarde: solo añade lo nuevo |
| rex nightly **2026.10.31 o más reciente** | Actualiza como en [la sección Updating de rex](any-source.md#updating) |
| Tu servidor Plex antiguo, en marcha | rex lee el historial desde él. Vuelve a arrancarlo si lo paraste cuando te pasaste a rex |
| Un ordenador en tu red doméstica, con `curl` | La importación solo funciona desde tu red doméstica. Windows 10 y 11, macOS y Linux traen todos `curl` |

## 1. Copia la dirección de tu servidor anterior {#1-copy-your-old-servers-address}

1. Abre [app.plex.tv](https://app.plex.tv) en un navegador e inicia sesión como **tú mismo**, con la cuenta cuyo historial quieres.
2. Elige tu servidor antiguo y abre cualquier película que tenga.
3. Haz clic en **⋯** (Más) y luego en **Get Info**.
4. Haz clic en **View XML**, abajo a la izquierda del cuadro **Media Info** que se abre. Se abre una pestaña nueva, llena de texto.

   ![The Media Info box that Get Info opens, with View XML at the bottom left](../assets/rex/40-plex-get-info.webp)
5. Copia la **dirección completa** de la barra de direcciones de esa pestaña.

Tiene este aspecto, todo en una sola línea, y termina en `X-Plex-Token=` seguido de un código:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

Ese código es tu **token de Plex** para ese servidor. Funciona como una contraseña de tu cuenta de Plex: nunca lo pegues en Discord, en una publicación de soporte ni en una captura de pantalla.

**¿No aparece View XML en el paso 4?** Plex Web solo lo muestra en un servidor que tú seas dueño, así que un servidor que alguien te ha compartido no lo tiene. Usa las herramientas de desarrollo del navegador en tu servidor antiguo, como en el [paso 2](#2-get-your-token-on-rex), y elige una petición a tu servidor antiguo (su dirección contiene `plex.direct`). Haz clic derecho sobre ella y copia su dirección: **Copy**, **Copy URL** en Chrome y Edge, **Copy Value**, **Copy URL** en Firefox. Esa es la dirección que necesitas. Contiene `X-Plex-Token=` y el código, entre otras partes `X-Plex-`: pega todo.

## 2. Obtén tu token en rex {#2-get-your-token-on-rex}

Como rex se comparte contigo, **Get Info** en rex no tiene **View XML**: Plex Web solo lo muestra al propietario del servidor. Lee el token desde tu navegador, tal como app.plex.tv lo envía a rex:

1. En app.plex.tv, con la sesión iniciada con tu cuenta, abre las herramientas de desarrollo del navegador: **F12**, o **⌥ ⌘ I** en un Mac. En Safari, primero activa **Show features for web developers** en **Settings**, **Advanced**.
2. Abre la pestaña **Network** y escribe `X-Plex-Token` en su cuadro de filtro.
3. Abre cualquier película del servidor **rex**. La lista se llena de solicitudes.
4. Haz clic en una cuya dirección sea la de rex: con rex-direct contiene `rex-direct.debridmediamanager.com`, o es la dirección HTTPS que configuraste tú mismo. No una de `plex.tv`.
5. Copia el valor de `X-Plex-Token`: Chrome y Edge lo muestran en **Payload**, Firefox en **Request**. O copia la dirección de la solicitud y toma la parte que va después de `X-Plex-Token=` hasta el siguiente `&`.

Es un código distinto del que aparece en el paso 1: cada servidor le da a tu cuenta el suyo propio. rex usa este para saber de quién es el historial.

## 3. Ejecuta la importación {#3-run-the-import}

Ejecútalo en un ordenador de casa, con tus dos valores pegados. `192.168.1.20` es la IP de rex en tu LAN, como en las guías de instalación: pon la tuya en su lugar.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

En Windows, abre **PowerShell** y escribe `curl.exe` en lugar de `curl`. Mantén los dos pares de comillas dobles: la dirección del paso 1 contiene caracteres `&`, que rompen el comando si no las tienes.

Tarda unos segundos, más si tu biblioteca es grande: rex lee cada película y cada episodio del servidor antiguo.

**Qué deberías ver.** Una línea como esta:

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| Número | Significa |
|---|---|
| `watched` | Títulos que rex marcó como vistos, con el número de reproducciones y la fecha del servidor antiguo |
| `inProgress` | Títulos que te quedaron a medias: se reanudan donde lo dejaste |
| `rated` | Títulos que recibieron su valoración con estrellas |
| `alreadyHere` | Títulos que ya habías visto o empezado en rex. rex conserva lo que tiene y no cambia nada ahí |
| `notInRex` | Títulos que el servidor antiguo tiene en su historial y que rex no tiene, o no como el mismo título |

Vuelve a abrir tu app de Plex (o recarga app.plex.tv) para verlo.

## Vuelve a ejecutarla cuando quieras {#run-it-again-any-time}

Volver a ejecutarlo no cambia nada de lo que ya tienes, así que ejecútalo cada vez que haya llegado más de tu biblioteca. Una segunda ejecución justo después de la primera muestra `"watched":0` y las anteriores bajo `alreadyHere`.

## Qué no se copia {#what-is-not-copied}

- El historial de cualquier otra persona de tu servidor antiguo. Cada una ejecuta la importación con sus propios dos tokens.
- El historial de reproducción, las listas de reproducción y las colecciones del servidor.
- Las calificaciones con estrellas de series y temporadas completas. Las calificaciones de películas y episodios sí se copian.
- Títulos de una biblioteca cuyo agente en el servidor antiguo no es **Plex Movie** ni **Plex TV Series** (los agentes antiguos, como Plex Movie (Legacy) y TheTVDB). rex encuentra un título por el id que le dan los agentes actuales de Plex, y los antiguos le asignan otro distinto, así que estos cuentan bajo `notInRex`.

## Si no funciona {#if-it-does-not-work}

| Lo que ves | Qué hacer |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | La dirección pegada se corta antes del token. Cópiala de nuevo, desde la barra de direcciones o las herramientas para desarrolladores, y pega todo |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | Algo distinto a la dirección se pegó entre las comillas después de `-d` |
| `... refused the token: copy the address from View XML again` | El servidor antiguo no aceptó el token. Repite el paso 1, con las herramientas para desarrolladores si el servidor está compartido contigo |
| `could not reach https://...` | rex no pudo conectarse a tu servidor antiguo. Tiene que estar en funcionamiento, y **la máquina de rex** tiene que poder alcanzarlo: rex lee de él, no de tu ordenador |
| `run the import from your home network` | Enviaste el comando a la dirección externa de rex. Usa la IP de LAN de rex, como en el paso 3 |
| Una página `Unauthorized` | rex no aceptó el token del paso 2. Cópialo de nuevo, desde una petición a rex, no a `plex.tv` |
| `notInRex` es mucho más alto de lo que esperas | La mayor parte de tu biblioteca todavía no está en rex, o tu biblioteca antigua usa uno de los agentes antiguos de Plex. Vuelve a ejecutarlo cuando tu biblioteca haya llegado |

¿Sigues atascado? Pregunta en el foro **rex-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Cómo pedir ayuda](../guides/remote-help.md) explica qué incluir.
