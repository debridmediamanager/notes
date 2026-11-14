# DMM

[Debrid Media Manager](https://debridmediamanager.com) te ayuda a encontrar películas y series y a mantenerlas en tu biblioteca de debrid.

Para verlo en Stremio, añade el propio addon de DMM, DMM Cast. [DMM en Stremio](stremio.md) explica cómo.

La extensión de navegador de DMM añade un botón a IMDb, Trakt y otros sitios de películas y series. [Botones de DMM en Safari](safari.md) explica la configuración para Safari.

DMM también sirve a los otros proyectos:

- **zurg** le pregunta a DMM qué película o episodio es cada archivo. Un patrocinador obtiene la clave API de DMM desde [gatekeeper](https://gatekeeper.debridmediamanager.com/). Sin ella, zurg depende de los nombres de los archivos y coinciden menos títulos. [rex con zurg](../rex/with-zurg.md#why-dmm-places-the-files) explica la diferencia.
- **Sonarr Radarr y Prowlarr** pueden buscar en DMM como indexador de torrents Torznab o indexador Usenet Newznab. Ambos requieren un patrocinio activo y la clave API de DMM. Configúralos en las páginas [Torznab](https://debridmediamanager.com/torznab) y [Newznab](https://debridmediamanager.com/newznab).
- **Tu lista de deseados**: pulsa **Want** o sigue una lista de Trakt o MDBList. zurg obtiene la lista y los nuevos episodios cuando se emiten. Requiere patrocinio. Consulta [Lista de deseados de DMM](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr y Jellyseerr** pueden usar DMM como si fueran Radarr y Sonarr. Las solicitudes entonces llegan a tu lista de deseados para que zurg las obtenga. Requiere patrocinio. Consulta [Seerr a través de DMM](seerr.md).
- **rex-direct** da a un rex reclamado su propia dirección y certificado. Consulta [rex-direct](../rex/any-source.md#rex-direct).

Todo lo que abre un patrocinio y dónde se configura cada cosa está en [Lo que te da un patrocinio](../guides/sponsorship.md).

¿Te atascas? Pregunta en el foro **dmm-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Pedir ayuda](../guides/remote-help.md) explica qué incluir.
