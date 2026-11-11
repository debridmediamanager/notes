# Alineando la limpieza de Plex con el estado de archivos de zurg {#aligning-the-plex-trash-sweep-with-zurgs-own-file-status}

## Propósito de este documento {#purpose-of-this-document}

El barrido de papelera de Plex decide ahora qué eliminar de una biblioteca de Plex usando **la ausencia del archivo más un temporizador por antigüedad**. zurg ya sabe algo mucho mejor —si el contenido detrás de ese archivo es reparable o está muerto de forma permanente— y no lo consulta.

Este documento es el plan para reemplazar el temporizador por ese conocimiento. Existe para revisarlo **antes** de escribir código, porque el cambio decide qué se borra de una biblioteca multimedia, y el comportamiento actual está mal en las dos direcciones: espera dos semanas para eliminar contenido que se sabe muerto desde el primer día, y borra contenido que zurg todavía está reparando activamente.

Registra lo que se verificó en el código y en una biblioteca en vivo, qué se propone y qué se deja deliberadamente como está. Todo lo que se afirma abajo como hecho se comprobó contra el sistema en funcionamiento el 2026-08-16, no se dedujo a partir de los nombres.

Alcance: `internal/plexsweep`, `internal/plexdb` y una nueva consulta de solo lectura en `internal/torrent`. Sin cambios en el comportamiento de reparación en sí.

---

## 1. Antecedentes: qué se lanzó y por qué hay que revisarlo {#1-background--what-shipped-and-why-it-needs-revisiting}

Cuatro commits trajeron el barrido:

| Commit | Qué |
|---|---|
| `4737b677` | Avisar cuando `autoEmptyTrash` de Plex está activado |
| `020042a3` | El barrido: detección, guardas, reparación y eliminación por elemento |
| `51cc9f69` | Interfaz de configuración del dashboard y documentación |
| `1a481a8f` | Contar las reparaciones contra el límite, no solo las eliminaciones |
| `c6f41621` | `plex_trash_sweep_min_age_days`, por defecto 14 |

El invariante principal del barrido no cambia y se mantiene: **nada que todavía tenga un archivo se elimina nunca.** Los elementos con un archivo activo se reparan o se dejan tal cual, con su icono de papelera. Las series y temporadas con episodios activos nunca se tocan. La eliminación es por elemento, nunca con el `emptyTrash` de toda la sección de Plex.

Lo único que se revisa es la regla de *cuándo se puede eliminar una entrada realmente ausente*.

### El temporizador es un sustituto de una pregunta que zurg puede responder directamente {#the-timer-is-a-proxy-for-a-question-zurg-can-answer-directly}

`plex_trash_sweep_min_age_days` espera 14 días antes de eliminar una entrada, porque considera que el icono rojo de la papelera es el único aviso que recibe el operador de que el contenido ha desaparecido, y purgar la entrada borra ese aviso.

La intención es correcta; el mecanismo es una suposición. Falla en ambos sentidos:

- Un torrent marcado como `infringing torrent` está **muerto desde el primer momento**. Mantener su entrada de Plex durante quince días no ayuda a nadie: esperar no lo va a devolver.
- Un torrent que todavía se está reintentando puede tardar **más de 14 días** en volver. El temporizador borra su entrada mientras zurg sigue trabajando en él. Este es el error más grave, porque destruye una entrada de la biblioteca de un contenido que luego sí vuelve.

---

## 2. Hechos verificados {#2-verified-facts}

### 2.1 El modelo de estados de zurg {#21-zurgs-state-model}

Existen tres estados de archivo y dos de torrent (contados en `internal/torrent`, sin contar los tests):

| Level | States |
|---|---|
| `File.State` | `ok_file`, `broken_file`, `deleted_file` |
| `Torrent.State` | `ok_torrent`, `broken_torrent` |

Ambos son máquinas de `pkg/fsm`. `FSMWithTime` guarda la marca de tiempo unix de cada transición y soporta `SinceWhen`, así que "cuánto tiempo lleva roto" ya se puede responder sin añadir nada.

**Un archivo roto condena a todo el torrent.**
`MarkFileBrokenAndEnqueueRepair` (`internal/torrent/hooks.go:215-234`):

```go
changed := file.State.Set("broken_file", torrent.State.GetMutex()) == nil
...
if err := torrent.State.Set("broken_torrent"); err == nil {
    t.repairLog.Infof("Torrent state changed: %s [? -> broken_torrent] (has broken file)", ...)
}
```

El log dice *"has broken file"*, en singular. Que se rompa uno de diez o que se rompan los diez produce exactamente el mismo estado de torrent. Nada agrega los estados de los archivos.

**`Unfixable` agrega por cuentas, no por archivos.**
`markAsUnrepairable` (`internal/torrent/unplayable_unrepairable.go:44-71`):

```go
if cp != nil {
    cp.SetUnrepairableReasonIfEmpty(reason)      // one account's copy
    entryCondemned = t.repairableCopy(torrent) == nil
}
if entryCondemned {
    torrent.SetUnrepairableReasonIfEmpty(reason) // the entry
}
```

La entrada se condena cuando **no queda ninguna copia capaz de repararse**. Deliberadamente no "cada copia tiene un motivo": una copia que nunca podría repararse de todos modos (el backend de Usenet no tiene magnet adder) mantendría un release muerto elegible para reparación para siempre. `File` no tiene ningún campo de no reparable (`internal/torrent/file_types.go`).

Así que los tres niveles responden tres preguntas distintas, y **ninguno responde el alcance**:

| Nivel | Te dice | No te puede decir |
|---|---|---|
| `File.State` | si este archivo está bien / roto / borrado | si está muerto de forma permanente |
| `TorrentCopy.UnrepairableReason` | que la copia de esta cuenta está muerta | nada sobre las otras cuentas |
| `Torrent.UnrepairableReason` | que ninguna cuenta puede repararlo | cuánto del release está afectado |

### 2.2 Mediciones en vivo (una biblioteca de producción, 2026-08-16) {#22-live-measurements-a-production-library-2026-08-16}

Las cuotas de abajo son de los torrents rotos, que eran alrededor del **3% de la biblioteca**.

**Casi todos los rotos (98%) tienen un motivo `Unfixable`**:

| Reason | Parte de los rotos |
|---|---|
| stalled download | 38% |
| infringing torrent | 37% |
| repair failed | 15% |
| duplicate file IDs (pack torrent) | 4% |
| rar'ed by RD | 1% |
| repair failed, no seeders | 1% |
| the lone cached file is broken | menos del 1% |
| invalid file ids | menos del 1% |
| repair failed, download status: error | menos del 1% |
| provider cannot re-add torrents | menos del 1% |

**El resto (2%) está roto sin motivo**, pero aún se puede reparar.

**Pero `Unfixable` no significa muerto.** zurg ya clasifica estos motivos en
permanentes y recuperables (`internal/torrent/unrepairable_reasons.go:44-70`).
`permanentReasons` contiene ocho veredictos que ningún reintento puede cambiar: infringing,
unsupported, unavailable, invalid, too big, not allowed, no repairable files,
invalid file ids, más cualquier motivo que empiece con `repair failed, download status:`.
Todo lo demás, incluidos los dos grupos más grandes de arriba, está marcado explícitamente
como temporal: `stalled download`, `repair failed`, `duplicate file IDs`,
`rar'ed by RD`, `not cached`, `the lone cached file is broken`,
`full torrent repair failed`.

`repair failed, no seeders` era el noveno cuando se tomaron las cuotas de arriba, pero
las entradas que lo tienen aquí son la razón por la que ya no lo es: ningún backend con el que zurg
habla informa de seeders, así que nunca se midió ese veredicto; se dedujo de una reparación
que se quedó sin tiempo. Ahora es temporal y, además, no se puede registrar
(`verdictClaims`), así que esas entradas se retiran y se vuelven a intentar como cualquier otra.

Aplicando esa división a las cuotas de arriba:

| | Parte de los rotos |
|---|---|
| Irreparable de forma permanente | **39%** |
| Irreparable pero recuperable | **59%** |
| Roto, sin motivo todavía | 2% |

Un motivo no reconocido (`provider cannot re-add torrents`, una entrada aquí) no está en
ninguna de las dos listas, y `IsPermanentlyUnrepairable` devuelve false para él: la respuesta
conservadora, que es la que queremos.

Esto es lo más importante del diseño: **una regla basada en que "`Unfixable` está activo"
eliminaría entradas de Plex de dos veces y media más lanzamientos de los que realmente están muertos.**

Y, lo crucial, es dónde están esos torrents rotos respecto al mount:

| | Parte de los rotos | Lo que ve Plex |
|---|---|---|
| Rotos, **todavía en el mount** | alrededor de tres de cada cuatro | El archivo parece existir → nunca se marca como tombstone. No aparece el icono de papelera; falla solo al reproducirse |
| Rotos, **ya fuera del mount** | alrededor de uno de cada cuatro | Archivo desaparecido → marcado como tombstone → **estos son los candidatos del barrido** |

Esta es la medición clave. Significa que el barrido solo se encuentra con el segundo grupo,
y para ese grupo zurg normalmente ya tiene un veredicto.

Lado de Plex, mismo host: un montón de elementos enviados a la papelera, **ninguno** de ellos más allá de la
ventana de 14 días (la lápida más antigua es de 2026-08-11). Además, algunas carcasas vacías de series y
unas cuantas decenas de carcasas vacías de temporadas.

## 3. La brecha {#3-the-gap}

`broken_torrent` significa "al menos una cosa está mal". Esa granularidad es incorrecta para el barrido.

Concretamente: un pack de diez episodios donde el archivo de un episodio ha desaparecido para siempre, pero el torrent sigue siendo reparable en conjunto. Si le preguntas al torrent, responde "todavía reparable", así que el barrido mantendría la entrada de Plex de ese episodio muerto **para siempre**.

No existe ningún estado que signifique *"este lanzamiento entero está muerto"* como algo distinto de *"algo dentro de este lanzamiento está roto"*.

---

## 4. Diseño {#4-design}

### 4.1 No añadir un cuarto estado persistido {#41-do-not-add-a-fourth-persisted-state}

El primer movimiento obvio sería un nuevo estado de torrent, algo como `dead_torrent`. **Descartado.**

Cada sitio que cambia el estado de un torrent tendría que mantenerlo, y una bandera "todos los archivos rotos" desactualizada es peor que no tener ninguna, porque *autoriza eliminaciones*. La información ya existe en los estados de los archivos; simplemente no está agregada.

En lugar de eso, derívala:

```go
// AllFilesBroken reports whether nothing in this release still reads.
// Derived from the file states rather than stored, so it cannot go stale
// and needs no migration or new transitions.
func (t *Torrent) AllFilesBroken() bool
```

Es barato, siempre es coherente y se puede mostrar en el dashboard sin persistencia.

Definición que hay que cerrar durante la implementación: `deleted_file` debe contar como no leíble junto con `broken_file`, y un torrent con **cero** archivos debe devolver false en lugar de true por vacuidad. Una release vacía no es evidencia de que esté muerto.

### 4.2 Preguntar al archivo, recurrir al torrent {#42-ask-the-file-fall-back-to-the-torrent}

El sweep resuelve una ruta de Plex a un archivo de zurg y luego aplica:

| Veredicto de zurg | Sweep |
|---|---|
| el archivo es `ok_file` | **keep**: no está realmente perdido |
| `broken_file`, el torrent no tiene motivo de irreparable | **keep**: la reparación puede restaurarlo, por mucho que tarde |
| `broken_file`, hay motivo pero **no** es permanente | **keep**: zurg todavía lo considera recuperable |
| `broken_file`, el motivo es **permanentemente** irreparable | **remove**: ningún reintento puede cambiar este veredicto |
| zurg no tiene torrent para esta ruta | **usar la ventana de antigüedad** |

La prueba de permanencia es `IsPermanentlyUnrepairable(reason)`
(`internal/torrent/unrepairable_reasons.go:59`), usada exactamente igual que
`ForceRepairTorrent` la usa. Reutilizarla en lugar de volver a derivar una lista es
importante: un motivo añadido a `permanentReasons` más adelante debe cambiar el
comportamiento del sweep automáticamente, y un motivo no reconocido debe seguir siendo no permanente.

`AllFilesBroken()` **no** autoriza la eliminación por sí solo: un lanzamiento
completamente roto con un motivo recuperable sigue en proceso. Sirve para refinar
los informes y el panel, y para distinguir "se ha perdido un episodio de diez" de
"se ha perdido todo el pack" cuando una persona lee el registro.

La última fila es el motivo por el que `plex_trash_sweep_min_age_days` se mantiene. Cuando un torrent
desaparece por completo de la cuenta, su `.zurgtorrent` desaparece con él, y zurg ya no tiene nada que decir. El temporizador deja de ser la regla principal y pasa a ser la alternativa solo para el caso en que no existe nada mejor.

Esto también rebaja el ajuste en la interfaz, lo que resuelve la otra queja: su etiqueta ("Keep Broken Entries Visible") describe un efecto secundario y no la acción.

### 4.3 Búsqueda ruta → torrent → archivo {#43-path--torrent--file-lookup}

El mapeo de Plex que ya existe va en el sentido *contrario*: `buildPlexDirIndex`
(`internal/plex/matcher.go:539`) indexa los componentes de ruta de Plex y los busca por
clave del torrent. El barrido necesita lo inverso, construido con la misma idea:

1. Construye `map[strings.ToLower(GetKey(torrent))] *Torrent` a partir de
   `DirectoryMap.Get(INT_ALL)`.
2. Para una ruta de Plex, divídela en componentes con la misma normalización que
   `splitPathComponents` (`matcher.go:525`) y busca cada uno. El directorio de la
   release es el componente que coincide.
3. Dentro de ese torrent, compara el resto de la ruta con `File.Path`
   (`internal/debrid/types.go:133`) para llegar al archivo concreto.

Esto tiene que pasar por `TorrentManager` y no por comparar cadenas con
`data/*.zurgtorrent`, por tres motivos: los nombres desambiguados (`Some.Release {a1b2c3}`),
las copias de varias cuentas y los renombrados solo se resuelven bien a través de `GetKey`.

**Que una búsqueda falle no es motivo para borrar nada.** Si no se puede resolver, se
considera que zurg no tiene nada que decir y se usa el respaldo de la ventana de antigüedad.

### 4.4 Lo que no cambia {#44-what-does-not-change}

- El invariante: nada con un archivo activo se elimina.
- Las series y temporadas con descendientes activos nunca se tocan.
- Por elemento, `DELETE`, nunca `emptyTrash`.
- Protecciones: rclone gestionado y en ejecución, el montaje lee, Plex no está escaneando.
- Snapshot antes de cualquier cambio; los límites se aplican a las reparaciones *y* a las eliminaciones.

Las nuevas reglas solo hacen que la limpieza sea **más** conservadora o **más** precisa;
nunca autorizan una eliminación que el código actual rechazaría.

---

## 5. Plan de implementación {#5-implementation-plan}

| # | Paso | Archivos |
|---|---|---|
| 0 | Confirma que la división permanente/recuperable es el filtro correcto haciendo un conteo en modo simulación contra una biblioteca real antes de que algo borre | — |
| 1 | `AllFilesBroken()` + pruebas unitarias (release vacío, mixto, todo roto, todo borrado) | `internal/torrent/` |
| 2 | Búsqueda de estado de solo lectura: ruta → torrent → archivo, devolviendo un valor de veredicto pequeño | archivo nuevo en `internal/torrent/` o `internal/plexsweep/` |
| 3 | Define el tipo de veredicto (`StatusOK`, `StatusRecoverable`, `StatusPermanentlyDead`, `StatusUnknown`) para que el barrido nunca maneje los detalles internos de zurg directamente | `internal/plexsweep` |
| 4 | Conecta la búsqueda a `Sweeper` detrás de una interfaz, igual que ya están `Mount`/`Library`/`Trash` | `internal/plexsweep/sweep.go` |
| 5 | Aplica la tabla de decisiones; mantén la ventana de antigüedad como fallback de `StatusUnknown` | `internal/plexsweep/sweep.go` |
| 6 | Inyecta el `TorrentManager` en el punto de llamada | `internal/app.go` |
| 7 | Pruebas: una por cada fila de la tabla de decisiones, más una prueba de fallo de búsqueda que demuestre que lo no resoluble nunca elimina | `internal/plexsweep/sweep_test.go` |
| 8 | Docs: `docs/config.md`, `config.example.yml`, `docs/CHANGELOG.md`, y reformula la etiqueta del panel | docs + plantillas |

Nota sobre el orden: los pasos 1–3 son adiciones puras sin cambio de comportamiento y pueden entrar
en un solo commit; el paso 5 es el único que cambia lo que se borra.

## 6. Riesgos y preguntas abiertas {#6-risks-and-open-questions}

1. **Orden de conexión.** Confirmado: `startPlexTrashSweep` se llama en
   `internal/app.go:268`, y `TorrentManager` se construye en `internal/app.go:285`, es decir, después. La llamada debe moverse después de ese punto, o usar un setter. Hay que comprobar que nada más depende de la posición actual.
2. **Ambigüedad en la búsqueda.** Dos torrents cuyas claves coinciden con el mismo componente de ruta. Resolución: si más de un candidato coincide, tratarlo como `StatusUnknown` en lugar de elegir uno.
3. **`only_show_the_biggest_file`.** El directorio de películas oculta archivos, así que una ruta de Plex puede nombrar un archivo que no es el que zurg serviría. La búsqueda no debe asumir que el nombre de archivo de Plex aparece tal cual en `File.Path`.
4. **Coste.** Construir el índice de claves en cada barrido es O(biblioteca). Con unos pocos miles de torrents es trivial, y el barrido se ejecuta a diario. Construirlo por barrido, no por elemento.
5. ~~**¿Se borra alguna vez `Unfixable`?**~~ **Resuelto: sí.** `refresh.go:851-857` lo borra cuando un torrent se verifica limpio y vuelve a `ok_torrent` ("all links intact, no broken files"), y `repair.go:165-181` lo borra (la entrada y cada copia) cuando se fuerza una reparación. Así que una release recuperada no arrastra una condena obsoleta, y el diseño no necesita protegerse contra eso.
6. **Los torrents rotos pero presentes.** Quedan fuera del alcance de este documento: Plex nunca los marca como eliminados, así que el barrido nunca los ve. Conviene señalar que son invisibles tanto para Plex como para esta función hasta que la reproducción falla.

## 7. Cómo se implementó (2026-08-16) {#7-how-it-was-implemented-2026-08-16}

Quedó como `feat: decide plex trash sweep removals from zurg's repair verdicts`.
Cuando la implementación resolvió una pregunta que este documento dejaba abierta, o se apartó de §4, aquí va la decisión y su motivo:

- **La búsqueda compara exactamente el directorio padre de la ruta** con `DirectoryMap[INT_ALL]`, en lugar de revisar cada componente de la ruta (§4.3). El montaje guarda cada release de forma plana: `<library dir>/<key>/<visible name>`. Plex registró la ruta desde el montaje, que sirve la clave tal cual. Si no hay coincidencia exacta, la respuesta es unknown, y la ambigüedad por colisión de claves (riesgo 2) desaparece: las claves exactas no pueden colisionar.
- **Cambió la fila 1 de la tabla de decisiones.** Un `ok_file` que aun así no está en el montaje es un archivo que ocultan los filtros, no uno que «realmente no existe». Conservarlo para siempre dejaría un icono de papelera permanente después de cambiar un filtro. Ahora se usa la ventana de antigüedad en su lugar.
- **`deleted_file` cuenta igual que `broken_file`** en todas las reglas, no solo en `AllFilesBroken()`. Las filas de la tabla dicen «no `ok_file`».
- **Los elementos con varias versiones se juzgan como una unidad** (la tabla era por archivo, pero la unidad del barrido es un elemento de Plex con partes): una sola parte recuperable mantiene todo el elemento; el elemento solo está muerto cuando lo están todas las partes; cualquier otra mezcla pasa a la ventana de antigüedad.
- **Un nombre de archivo que corresponde a un torrent pero no a un archivo** (renombrado, listado de un archivo comprimido, `only_show_the_biggest_file` — riesgo 3) solo está muerto cuando el motivo de la entrada es permanente **y** `AllFilesBroken()`; es recuperable cuando el torrent está roto sin un veredicto permanente; en otro caso, unknown. Un nombre sin coincidencia nunca se condena por asociación mientras algún archivo siga legible.
- **Conexión (riesgo 1):** `startPlexTrashSweep` se movió debajo de la construcción del manager en `internal/app.go`; nada dependía de su posición anterior. Los veredictos llegan al barrido a través de `plexsweep.Verdicts`, implementado por `TorrentManager.FileStatusForMountPath`. Antes de que el primer refresh llene `INT_ALL`, cada búsqueda responde unknown y el barrido se comporta exactamente igual que la versión basada en la ventana de antigüedad.

## 8. Explícitamente fuera de alcance {#8-explicitly-out-of-scope}

- **Carpetas vacías de series y temporadas.** El barrido solo elimina los episodios finales, así que una serie completamente muerta deja una carcasa (algunas series y unas pocas decenas de temporadas en la biblioteca medida). Es un problema aparte y requiere cuidado con el orden: eliminar los episodios, volver a comprobar el padre y eliminarlo solo cuando no le quede ningún hijo.
- Cualquier cambio en el comportamiento de reparación, en la cola de reparación o en el momento en que zurg marca algo como irreparable.
- `autoEmptyTrash` de Plex, que ya está cubierto por la advertencia de `4737b677`.
- El backlog existente de la biblioteca medida, que se deja a propósito para una decisión manual.
