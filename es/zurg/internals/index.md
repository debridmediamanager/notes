# Internos {#internals}

Cómo está hecho zurg. Con qué se midió. Las notas de diseño detrás de las partes más complicadas. Escrito para alguien que está a punto de cambiar el código. Nada de lo que aparece aquí hace falta para ejecutar zurg.

## La forma general {#the-shape-of-it}

| Página | Qué contiene |
|---|---|
| [Architecture](architecture.md) | La forma general del conjunto y los invariantes que son fáciles de romper. Empieza aquí. |
| [Naming](naming.md) | Cómo un release y sus archivos terminan con los nombres que muestra el mount. |
| [Persistent caches](persistent-caches.md) | Qué se guarda en disco entre reinicios y cuánto cuesta. |
| [Directory config UI/UX](uiux.md) | La evaluación de diseño detrás del editor de directorios. |

## Qué se midió {#what-was-measured}

| Página | Qué contiene |
|---|---|
| [Debrid baseline](debrid-baseline.md) | Lo que cuesta zurg y qué tan rápido se siente con Real-Debrid, AllDebrid y TorBox. |
| [Torrent lifecycle](torrent-lifecycle.md) | Lo que informa cada cuenta mientras corre una descarga, capturado en vivo. |
| [Real-Debrid API notes](realdebrid-behavior.md) | Semántica de los enlaces, selección de archivos y lo que realmente significa cached. |

## Contratos que zurg tiene que cumplir {#contracts-zurg-has-to-satisfy}

| Página | Qué contiene |
|---|---|
| [Contrato del cliente SABnzbd](sabnzbd-client-contract.md) | Las formas exactas que Sonarr y Radarr esperan de un SABnzbd. |
| [Contrato del cliente qBittorrent](qbittorrent-client-contract.md) | Lo mismo para un qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | La superficie de la API de Plex en bruto que usa zurg. 1.2 MB. |

## Cosas que salieron mal {#things-that-went-wrong}

| Página | Qué contiene |
|---|---|
| [Plex trash sweep](plex-trash-sweep.md) | Alinear la limpieza con la propia visión de zurg sobre qué está roto. |
| [Stream timeout regression](stream-timeout-regression.md) | Un stream proxificado que dejó de aguantar lecturas largas. |
| [rclone move refusal](rclone-move-refusal.md) | Importaciones vacías tras un backend que rechazó un MOVE, y el parche. |

## Pruebas {#testing}

- [Pruebas E2E](e2e-test.md) explica qué cubre la suite de extremo a extremo y cuánto cuesta ejecutarla.

Qué hace cada servicio y cuáles son sus límites está en [Proveedores](../providers/index.md) y no aquí.
