# DMM

[Debrid Media Manager](https://debridmediamanager.com) te ayuda a encontrar películas y series y a mantenerlas en tu biblioteca de debrid.

La extensión de navegador DMM añade un botón a IMDb, Trakt y otros sitios de películas y series. [Botones DMM en Safari](safari.md) explica la configuración para Safari.

DMM también da servicio a los otros proyectos:

- **zurg** le pregunta a DMM qué película o episodio es cada archivo. Un patrocinador obtiene la clave API de DMM desde [gatekeeper](https://gatekeeper.debridmediamanager.com/). Sin ella, zurg depende de los nombres de archivo y coinciden menos títulos. [rex con zurg](../rex/with-zurg.md#why-dmm-places-the-files) explica la diferencia.
- **Sonarr Radarr y Prowlarr** pueden buscar en DMM como indexador de torrents Torznab o indexador de Usenet Newznab. Ambos necesitan un patrocinio activo y la clave API de DMM. Configúralos en las páginas [Torznab](https://debridmediamanager.com/torznab) y [Newznab](https://debridmediamanager.com/newznab).
- **Tu lista de deseados**: pulsa **Want** o sigue una lista de Trakt o MDBList. zurg descarga la lista y los nuevos episodios a medida que se emiten. Requiere patrocinio. Consulta [Lista de deseados de DMM](../zurg/guides/dmm-wanted.md).
- **Seerr, Overseerr y Jellyseerr** pueden usar DMM como si fueran Radarr y Sonarr. Las solicitudes entonces llegan a tu lista de deseados para que zurg las descargue. Requiere patrocinio. Consulta [Seerr a través de DMM](seerr.md).
- **rex-direct** le da a un rex reclamado su propia dirección y certificado. Consulta [rex-direct](../rex/any-source.md#rex-direct).

Todo lo que abre un patrocinio y dónde se configura cada cosa está en [Lo que te da un patrocinio](../guides/sponsorship.md).

¿Te atascas? Pregunta en el foro **dmm-support** de [Discord](https://discord.com/invite/7u4YjMThXP). [Pedir ayuda](../guides/remote-help.md) explica qué incluir.
