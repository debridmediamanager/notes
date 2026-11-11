# Botones de DMM en Safari {#dmm-buttons-in-safari}

El complemento de DMM para el navegador añade un botón **DMM🔎** en los sitios de películas y series. Al pulsarlo, abre el título en DMM. Junto a los enlaces magnet añade un botón **DMM🧲** que agrega el torrent a tu biblioteca de DMM.

En Chrome y Firefox, instala la [extensión de Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) o el [complemento de Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). Safari usa el mismo código como [userscript de Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) con un gestor de userscripts.

Elige uno de estos gestores:

| Gestor | Precio | Funciona en | Actualiza el script |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | Gratis | Mac, iPhone, iPad | Cuando pulsas **Update** en su ventana emergente |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | 2,99 $ | Mac, iPhone, iPad | Por sí solo |

## Con Userscripts {#with-userscripts}

1. Instala [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) desde la App Store y ábrela una vez.
2. Activa la extensión:
   - **Mac:** Safari > **Settings** > **Extensions**, marca **Userscripts**.
   - **iPhone y iPad:** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts**, activa **Allow Extension**.
3. Deja que se ejecute en todos los sitios. Los enlaces magnet pueden estar en cualquier sitio, así que el script tiene que funcionar en todas partes.
   - **Mac:** en el mismo panel **Extensions**, haz clic en **Edit Websites…** y pon **When visiting other websites** en **Allow**.
   - **iPhone y iPad:** en la misma pantalla de **Userscripts**, pon **All Websites** en **Allow**.
4. En Safari, abre el [archivo del userscript de DMM](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). Se muestra como texto plano.
5. Abre el popup de Userscripts: su botón de la barra de herramientas en Mac, o el botón **aA** de la barra de direcciones en iPhone. Toca el aviso de instalación que muestra y confirma.

Para actualizar más adelante, abre el popup de Userscripts y toca **Update** cuando aparezca el script de DMM.

## Con Tampermonkey {#with-tampermonkey}

1. Instala [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) desde la App Store.
2. Actívalo y déjalo funcionar en todas las webs, igual que en los pasos 2 y 3 de arriba, pero usando **Tampermonkey** en lugar de **Userscripts**.
3. En Safari, abre la [página del script en Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) y haz clic en **Install this script**.
4. Tampermonkey abre su página de instalación. Haz clic en **Install**.

Tampermonkey busca una nueva versión una vez al día.

## Comprueba que funciona {#check-it-works}

Abre [Dune: Part Two en Letterboxd](https://letterboxd.com/film/dune-part-two/). Aparece un botón verde azulado **DMM🔎** junto al título, y al pulsarlo se abre la película en DMM.

¿No ves el botón? Revisa estas cosas:

- El popup del gestor de extensiones lista **Debrid Media Manager** y su interruptor está activado.
- Safari deja que el gestor se ejecute en ese sitio. Cuando lo pregunte, elige **Always Allow on Every Website**.
- La página ya terminó de cargar. Sitios como TMDB, Wikipedia y AniList muestran el botón un momento después de que cargue la página.
