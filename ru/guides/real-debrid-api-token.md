# Ваш API-токен Real-Debrid: где его взять и что означают ошибки {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

Ваш API-токен Real-Debrid находится на странице [real-debrid.com/apitoken](https://real-debrid.com/apitoken). Войдите в Real-Debrid, откройте эту страницу и скопируйте код под заголовком **API Private Token**. Вставьте его в DMM или zurg. Если приложение показывает `bad_token`, значит токен, который у него есть, неверный или неполный: скопируйте его заново с этой страницы.

## Получите токен {#get-your-token}

1. Войдите на [real-debrid.com](https://real-debrid.com). Если вы не вошли, страница токена покажет только **403-Forbidden**.
2. Откройте [real-debrid.com/apitoken](https://real-debrid.com/apitoken).
3. Скопируйте весь код под **API Private Token**. Это 52 заглавные буквы и цифры.

![Страница API Private Token в Real-Debrid, токен размыт](../assets/real-debrid-api-token/01-apitoken.webp)

Относитесь к нему как к паролю. Срок его действия не истекает, а любой, у кого он есть, может пользоваться всем вашим аккаунтом. Предупреждение от самого Real-Debrid на этой странице: **This token is not meant to be used into public apps, it is insecure !**

Кнопка **Refresh** на этой странице выдаёт новый токен. Real-Debrid советует так сделать, если вам кажется, что кто-то узнал ваш. После обновления вставьте новый токен во все приложения, которые использовали старый.

## Вставьте его в DMM {#put-it-in-dmm}

1. На [debridmediamanager.com](https://debridmediamanager.com) нажмите **Login with Real Debrid**.
2. Под **or paste an API key** вставьте токен в поле **API Key** и нажмите **Save API Key**. **Get API Key from Real-Debrid** откроет для вас страницу с токеном.

![Страница Connect Real-Debrid в DMM](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

DMM вообще не требует токена: **Sign in with Real-Debrid** показывает код, который нужно подтвердить на real-debrid.com/device. Так DMM получает собственный вход, который продлевается сам. Подробнее в [Что такое DMM и как им пользоваться?](../dmm/index.md#sign-in)

## Вставьте его в zurg {#put-it-in-zurg}

В `config.yml`, в разделе `providers`:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

Или в Dashboard zurg по адресу `http://localhost:9999`: откройте **Config**, нажмите **Edit** в строке realdebrid под **Providers**, вставьте токен в поле **Token** и нажмите **Save**. В любом случае перезапустите zurg. [Real-Debrid с zurg](../zurg/providers/realdebrid.md) содержит остальное, включая настройку `TOKEN` для Docker.

Чтобы проверить, что zurg об этом думает:

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

Токен, который Real-Debrid не принимает, выдаёт ответ `account connection check failed; verify credentials and network`.

## Проверьте токен самостоятельно {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

В Windows введите `curl.exe` вместо `curl`. Если токен рабочий, в ответе будут ваш аккаунт: `username`, `"type": "premium"` и дата `expiration`. Если токен неверный, выведется:

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## Если что-то не работает {#when-something-is-wrong}

Ошибки Real-Debrid приходят с названием и номером. zurg показывает оба, например `bad_token (status code: 401) (code: 8)`.

| Что вы видите | Что это значит и что делать |
|---|---|
| `bad_token`, code 8. В zurg: `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | Real-Debrid не узнаёт этот токен. Его скопировали неправильно, обрезали или заменили. Скопируйте его заново с [real-debrid.com/apitoken](https://real-debrid.com/apitoken), целиком, без лишних символов до или после, и перезапустите zurg. |
| zurg: `Account realdebrid refused zurg (credential rejected)` | То же, что и `bad_token`. Ваши другие аккаунты продолжат работать, а zurg будет спрашивать Real-Debrid снова каждые 10 минут. |
| DMM: **Real-Debrid rejected that API key.** | То же, что и `bad_token`. Скопируйте токен заново или вместо этого нажмите **Sign in with Real-Debrid**. |
| `permission_denied`, code 9. В zurg: `RD Permission denied (code=9)` | Real-Debrid отказал в доступе самому аккаунту, а не токену. В документации указаны заблокированный аккаунт и, для некоторых запросов, аккаунт без премиума. Войдите на real-debrid.com и проверьте аккаунт и количество дней **Premium**. Если всё в порядке, нажмите **Refresh** на странице токена и вставьте новый токен, как написано в сообщении zurg. |
| `ip_not_allowed`, code 22. В zurg: `RD refused link generation from this IP (code=22, ip_not_allowed)` | Дело не в токене. Real-Debrid не создаёт ссылки для скачивания с адресов серверов и VPS. Запускайте zurg из домашней сети или купите Remote Traffic у Real-Debrid. |
| `service_unavailable`, code 25 | Сбой на стороне самого Real-Debrid. Ничего менять у себя не нужно. Проверьте [Is Real-Debrid down or just me?](https://debridmediamanager.com/is-real-debrid-down-or-just-me) (Real-Debrid сейчас недоступен или проблема только у меня?) и попробуйте позже. |
| **403-Forbidden** на real-debrid.com/apitoken | Вы не вошли в Real-Debrid. Войдите в аккаунт и откройте страницу снова. |

Все коды перечислены внизу [документации API Real-Debrid](https://api.real-debrid.com/).

## Вопросы {#questions}

### Где найти мой API-токен Real-Debrid? {#where-do-i-find-my-real-debrid-api-token}

На [real-debrid.com/apitoken](https://real-debrid.com/apitoken), будучи залогиненным. Скопируйте код в разделе **API Private Token**.

### Мой токен работает в другом приложении, но zurg пишет, что он недействителен. Почему? {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

Ваш аккаунт имеет один API-токен. Многие приложения его вообще не используют: вместо этого они входят по коду, как **Sign in with Real-Debrid** в DMM. Поэтому то, что другое приложение работает, не значит, что в zurg правильный токен. Скопируйте его заново со страницы токенов в zurg, без лишних пробелов и символов до или после, и перезапустите zurg.

### Токен истекает? {#does-the-token-expire}

Нет, у API-токена нет срока действия. А вход через приложение работает по-другому: приложение получает собственные учётные данные, которые обновляются сами.

### Безопасно ли давать свой токен дополнению или сайту? {#is-it-safe-to-give-my-token-to-an-addon-or-website}

Только тем, кому вы доверяете. Токен открывает доступ ко всему вашему аккаунту, а Real-Debrid говорит, что он не предназначен для публичных приложений. Если приложение предлагает вход по коду, используйте его.
