# Tu token de la API de Real-Debrid: dónde conseguirlo y qué significan los errores {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

Tu token de API de Real-Debrid está en [real-debrid.com/apitoken](https://real-debrid.com/apitoken). Inicia sesión en Real-Debrid, abre esa página y copia el código que aparece debajo de **API Private Token**. Pégalo en DMM o en zurg. Si una app muestra `bad_token`, el token que tiene es incorrecto o está incompleto: cópialo de nuevo desde esa página.

## Consigue tu token {#get-your-token}

1. Inicia sesión en [real-debrid.com](https://real-debrid.com). Si no has iniciado sesión, la página del token solo muestra **403-Forbidden**.
2. Abre [real-debrid.com/apitoken](https://real-debrid.com/apitoken).
3. Copia todo el código que aparece bajo **API Private Token**. Son 52 letras mayúsculas y dígitos.

![Página API Private Token de Real-Debrid, token difuminado](../assets/real-debrid-api-token/01-apitoken.webp)

Trátalo como si fuera una contraseña. No caduca, y cualquiera que lo tenga puede usar toda tu cuenta. La advertencia de Real-Debrid en esa página: **Este token no está pensado para usarse en apps públicas, es inseguro !**

**Refresh** en esa página genera un token nuevo. Real-Debrid lo sugiere si crees que alguien más tiene el tuyo. Después de regenerarlo, pega el token nuevo en todas las apps que usaban el anterior.

## Ponlo en DMM {#put-it-in-dmm}

1. En [debridmediamanager.com](https://debridmediamanager.com), pulsa **Login with Real Debrid**.
2. Debajo de **or paste an API key**, pega el token en **API Key** y pulsa **Save API Key**. **Get API Key from Real-Debrid** abre la página del token por ti.

![Página Connect Real-Debrid de DMM](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

DMM no necesita el token para nada: **Sign in with Real-Debrid** muestra un código que apruebas en real-debrid.com/device. Así DMM tiene su propio inicio de sesión, que se renueva solo. Más información en [¿Qué es DMM y cómo lo uso?](../dmm/index.md#sign-in)

## Ponlo en zurg {#put-it-in-zurg}

En `config.yml`, bajo `providers`:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

O en el Dashboard de zurg en `http://localhost:9999`: abre **Config**, pulsa **Edit** en la fila de realdebrid bajo **Providers**, pega el token en **Token** y pulsa **Save**. Reinicia zurg de cualquiera de las dos formas. [Real-Debrid con zurg](../zurg/providers/realdebrid.md) tiene el resto, incluido el ajuste `TOKEN` de Docker.

Para comprobar qué opina zurg al respecto:

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

Un token que Real-Debrid rechaza responde `account connection check failed; verify credentials and network`.

## Comprueba un token tú mismo {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

En Windows escribe `curl.exe` en lugar de `curl`. Un token que funciona muestra tu cuenta: `username`, `"type": "premium"` y la fecha de `expiration`. Uno incorrecto muestra:

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## Cuando algo va mal {#when-something-is-wrong}

Los errores de Real-Debrid llegan con un nombre y un número. zurg muestra los dos, como `bad_token (status code: 401) (code: 8)`.

| Lo que ves | Qué significa y qué hacer |
|---|---|
| `bad_token`, código 8. En zurg: `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | Real-Debrid no reconoce ese token. Se copió mal, se cortó o se reemplazó. Cópialo otra vez desde [real-debrid.com/apitoken](https://real-debrid.com/apitoken), completo y sin nada antes ni después, y reinicia zurg. |
| zurg: `Account realdebrid refused zurg (credential rejected)` | Lo mismo que `bad_token`. Tus otras cuentas siguen funcionando y zurg vuelve a preguntarle a Real-Debrid cada 10 minutos. |
| DMM: **Real-Debrid rejected that API key.** | Lo mismo que `bad_token`. Cópiala otra vez o pulsa **Sign in with Real-Debrid** en su lugar. |
| `permission_denied`, código 9. En zurg: `RD Permission denied (code=9)` | Real-Debrid rechazó la cuenta, no el token. Su documentación menciona una cuenta bloqueada y, en algunas peticiones, una cuenta sin premium. Inicia sesión en real-debrid.com y revisa la cuenta y sus días de **Premium**. Si todo parece correcto, pulsa **Refresh** en la página del token y pega el nuevo token, tal como indica el mensaje de zurg. |
| `ip_not_allowed`, código 22. En zurg: `RD refused link generation from this IP (code=22, ip_not_allowed)` | No es el token. Real-Debrid no genera enlaces de descarga para direcciones de servidores y VPS. Ejecútalo desde una conexión doméstica o compra Remote Traffic a Real-Debrid. |
| `service_unavailable`, código 25 | Real-Debrid tiene problemas por su cuenta. No hay nada que cambiar de tu lado. Consulta [Is Real-Debrid down or just me?](https://debridmediamanager.com/is-real-debrid-down-or-just-me) e inténtalo más tarde. |
| **403-Forbidden** en real-debrid.com/apitoken | No has iniciado sesión en Real-Debrid. Inicia sesión y vuelve a abrir la página. |

Todos los códigos aparecen en [la documentación de la API de Real-Debrid](https://api.real-debrid.com/), al final de la página.

## Preguntas {#questions}

### ¿Dónde encuentro mi token de la API de Real-Debrid? {#where-do-i-find-my-real-debrid-api-token}

En [real-debrid.com/apitoken](https://real-debrid.com/apitoken), con la sesión iniciada. Copia el código en **API Private Token**.

### Mi token funciona en otra app, pero zurg dice que no es válido. ¿Por qué? {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

Tu cuenta tiene un solo token de API. Muchas apps no lo usan: en su lugar inician sesión con un código, como el botón **Sign in with Real-Debrid** de DMM. Así que si la otra app funciona, eso no significa que zurg tenga el token correcto. Copia el token otra vez desde la página de tokens y pégalo en zurg, sin nada antes ni después, y reinicia zurg.

### ¿El token caduca? {#does-the-token-expire}

No, el token de API no tiene fecha de caducidad. Iniciar sesión a través de una app es distinto: le da a esa app sus propias credenciales, que se renuevan solas.

### ¿Es seguro dar mi token a un addon o a una web? {#is-it-safe-to-give-my-token-to-an-addon-or-website}

Solo a las que confíes. El token abre toda tu cuenta, y Real-Debrid dice que no está pensado para apps públicas. Si una app ofrece iniciar sesión con un código, usa eso en su lugar.
