# Evaluación de UI/UX de la configuración de directorios {#directory-configuration-uiux-assessment}

## Alcance y estado actual {#scope-and-current-state}
- Página: `Directory Configuration` en `http://localhost:9999/directories/`.
- UI actual: una sola tabla plana que lista los directorios bajo encabezados como "MEDIA" y "RECENT", con columnas para el nombre del directorio, el orden numérico y los enlaces de acción ("Edit", "Delete").
- Comportamiento: editar y eliminar disparan acciones simples; no hay agrupación más allá de los encabezados, ni un flujo dedicado de creación o edición para todas las opciones de YAML.

## Principales lagunas de UX {#key-ux-gaps}
- **Arquitectura de la información**
  - Los grupos están visualmente aplanados; los usuarios no pueden centrarse en un solo grupo a la vez.
  - El orden depende de números manuales (`group_order`), lo cual es poco intuitivo y propenso a errores.
  - No hay barra de búsqueda/filtro para localizar rápidamente los directorios.
  - No hay acciones en lote (eliminar/mover) ni elementos de selección.
- **Experiencia de creación/edición**
  - Los flujos de edición y creación no muestran el esquema YAML completo (ajustes generales, filtros de tamaño/archivo/etiqueta/tiempo).
  - No hay una disposición estructurada; los campos no están agrupados, lo que genera sobrecarga cognitiva a medida que crecen las opciones.
  - Falta un constructor de reglas AND/OR anidadas que refleje la lógica de filtros anidados del YAML.
  - Los campos relacionados con etiquetas (`tags_match_all`, `tags_match_any`) son difíciles de descubrir y no ofrecen ayuda para seleccionarlos.
  - No hay vista previa en vivo de los torrents que coinciden con la configuración de filtros actual.
- **Orientación y validación**
  - Faltan tooltips/iconos de información por campo y enlaces a documentación más detallada (por ejemplo, `tags.md`).
  - No hay advertencia proactiva cuando un directorio no producirá ningún torrent o le faltan filtros obligatorios.
  - Los campos de expresiones regulares y otros patrones no ofrecen validación en tiempo real.
  - Las eliminaciones se realizan sin confirmación ni opción de deshacer.
- **Accesibilidad y adaptabilidad**
  - No se ha verificado el contraste ni la legibilidad según WCAG; las acciones solo con iconos pueden carecer de etiquetas.
  - No hay arrastrar y soltar; no existe una ruta de reordenación accesible por teclado.
  - La disposición en móvil no está optimizada (la tabla no se adapta a tarjetas apiladas y los formularios pueden no desplazarse bien).
  - Las acciones dependen de enlaces solo de texto; faltan iconos y objetivos claros.
- **Rendimiento y pulido de la interacción**
  - La búsqueda/filtro (una vez añadido) necesitará debounce y paginación/virtualización para listas grandes.
  - El arrastrar y soltar (una vez añadido) necesitará persistencia y una alternativa elegante cuando la persistencia falle.

## Cambios de UI/UX recomendados {#recommended-uiux-changes}
- **Presentación de grupos**
  - Muestra cada `group` de primer nivel (por ejemplo, media/recent/example) como una tarjeta o sección desplegable con su propia lista.
  - Ofrece acciones rápidas por grupo (contraer/expandir, selección masiva).
- **Orden**
  - Reemplaza la columna de orden numérico por asas de arrastre para reordenar dentro del grupo; muestra el orden calculado en un tooltip o en una insignia en línea.
  - Ofrece controles de reordenación con teclado (botones para subir/bajar) como alternativa de accesibilidad y para móviles.
- **Búsqueda y acciones masivas**
  - Añade una barra de búsqueda/filtrado encima de la lista; aplica debounce a la entrada.
  - Añade casillas para borrar o mover en masa; incluye una opción de "select all in group".
- **Superficie de añadir/editar**
  - Usa un modal o un panel lateral con un diseño por secciones: General, Size Filters, File Filters, Tag Filters, Time Filters y Advanced.
  - Añade subsecciones desplegables para reducir la sobrecarga; mantén el estado de expansión durante la sesión.
- **Constructor de reglas**
  - Ofrece un constructor visual de AND/OR que refleje la estructura del YAML: grupos anidados, píldoras de condición y selectores de propiedad/operador/valor (por ejemplo, has_episodes, regex con matches/does not match).
  - Permite cambiar entre AND/OR en cada nodo y muestra una vista previa de la expresión resultante.
- **Selector de etiquetas**
  - Multiselección con autocompletado alimentado por las etiquetas disponibles; muestra descripciones, tooltips y contadores cuando estén disponibles.
  - Distingue claramente `tags_match_all` de `tags_match_any`.
- **Vista previa**
  - Añade "Preview matching torrents" para traer resultados de ejemplo con el estado actual de los filtros; muestra estados de carga con skeleton y manejo de errores.
- **Ayuda**
  - Tooltips o iconos de información para cada campo; enlaza a la documentación detallada cuando haga falta (por ejemplo, [tags.md](../reference/tags.md)).
  - Muestra pistas contextuales (por ejemplo, "Only show largest file" explica los efectos secundarios del comportamiento).
- **Validación y seguridad**
  - Bloquea los guardados cuando falten filtros obligatorios o la validación falle; muestra errores en línea.
  - Validación de regex en tiempo real (en el cliente) más una confirmación del servidor al enviar, para evitar diferencias entre ambos.
  - Avisa cuando la configuración no coincida con ningún torrent (según la vista previa o heurísticas).
  - Muestra un diálogo de confirmación para los borrados; ofrece un deshacer breve en un snackbar cuando sea posible (borrado suave si está soportado).
- **Accesibilidad y diseño responsive**
  - Verifica el contraste de la paleta elegida; asegura estados de foco y etiquetas ARIA para los controles.
  - Asegura que los desplegables, las asas de arrastre y las acciones sean accesibles con teclado.
  - En móviles, muestra los grupos como tarjetas apiladas; asegura que los modales y paneles sean desplazables, con encabezados fijos para las acciones.
  - Acompaña los iconos de acciones clave con etiquetas; asegura que los objetivos solo con icono tengan nombres accesibles.
- **Pulido visual**
  - Usa iconografía consistente para editar/borrar/reordenar; añade separadores sutiles y chips para indicar el contexto o el estado del grupo.
  - Considera codificar los grupos por color para escanearlos rápido (con contraste accesible).

## Dependencias y supuestos por confirmar {#dependencies-and-assumptions-to-confirm}
- API support for: persisting group order, bulk operations, nested AND/OR serialization, tag metadata source, and preview query endpoint.
- Soporte de API para: guardar el orden de los grupos, operaciones en lote, serialización de AND/OR anidados, fuente de metadatos de etiquetas y endpoint de vista previa de consultas.
- Behavior of deletes: soft vs hard delete, undo window, and audit needs.
- Comportamiento de los borrados: borrado suave frente a borrado definitivo, ventana para deshacer y necesidades de auditoría.
- Ownership/permissions model (if multi-user) for displaying last-edited metadata and preventing conflicts.
- Modelo de propiedad y permisos (si hay varios usuarios) para mostrar los metadatos de última edición y evitar conflictos.
- Performance constraints for preview/search; paging or virtualization strategy for large datasets.
- Limitaciones de rendimiento para la vista previa y la búsqueda; estrategia de paginación o virtualización para conjuntos de datos grandes.

## Prioridades de implementación {#implementation-priorities}
1) Reestructurar la lista en tarjetas o secciones desplegables agrupadas; añadir una barra de búsqueda y filtro y diálogos de confirmación.
2) Introducir un modal o panel lateral por secciones para añadir y editar, con tooltips y validación básica; añadir selección múltiple de etiquetas.
3) Añadir arrastrar y soltar, y reordenar con el teclado con persistencia; implementar un creador de reglas Y/O.
4) Añadir una vista previa de los torrents que coinciden, con peticiones con debounce y manejo de errores.
5) Terminar la accesibilidad (rutas de teclado, ARIA) y un diseño responsive de tarjetas apiladas para móvil.
