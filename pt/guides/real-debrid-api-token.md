# Seu token de API do Real-Debrid: onde pegar e o que significam os erros {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

Seu token de API do Real-Debrid está em [real-debrid.com/apitoken](https://real-debrid.com/apitoken). Entre no Real-Debrid, abra essa página e copie o código em **API Private Token**. Cole no DMM ou no zurg. Quando um app mostrar `bad_token`, o token que ele tem está errado ou incompleto: copie de novo essa página.

## Pegue seu token {#get-your-token}

1. Faça login em [real-debrid.com](https://real-debrid.com). Se estiver deslogado, a página do token mostra só **403-Forbidden**.
2. Abra [real-debrid.com/apitoken](https://real-debrid.com/apitoken).
3. Copie o código inteiro em **API Private Token**. São 52 letras maiúsculas e números.

![Página API Private Token da Real-Debrid, token borrado](../assets/real-debrid-api-token/01-apitoken.webp)

Trate ele como uma senha. Ele não expira, e quem tiver ele pode usar sua conta inteira. Aviso da própria Real-Debrid nessa página: **This token is not meant to be used into public apps, it is insecure !**

**Refresh** nessa página gera um novo token. A Real-Debrid sugere isso se você achar que outra pessoa tem o seu. Depois de um refresh, cole o novo token em todos os apps que usavam o antigo.

## Coloque no DMM {#put-it-in-dmm}

1. No [debridmediamanager.com](https://debridmediamanager.com), pressione **Login with Real Debrid**.
2. Em **or paste an API key**, cole o token em **API Key** e pressione **Save API Key**. **Get API Key from Real-Debrid** abre a página do token para você.

![Página Connect Real-Debrid do DMM](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

O DMM não precisa do token: **Sign in with Real-Debrid** mostra um código que você aprova em real-debrid.com/device. Assim o DMM tem o próprio login, que se renova sozinho. Mais detalhes em [O que é o DMM e como eu uso?](../dmm/index.md#sign-in)

## Coloque no zurg {#put-it-in-zurg}

Em `config.yml`, em `providers`:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

Ou no Dashboard do zurg em `http://localhost:9999`: abra **Config**, clique em **Edit** na linha realdebrid em **Providers**, cole o token em **Token** e clique em **Save**. Reinicie o zurg de qualquer jeito. [Real-Debrid com zurg](../zurg/providers/realdebrid.md) tem o resto, incluindo a configuração `TOKEN` do Docker.

Para ver o que o zurg acha disso:

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

Um token recusado pelo Real-Debrid retorna `account connection check failed; verify credentials and network`.

## Teste um token você mesmo {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

No Windows, digite `curl.exe` em vez de `curl`. Um token válido mostra sua conta: `username`, `"type": "premium"` e a data de `expiration`. Um token errado mostra:

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## Quando algo está errado {#when-something-is-wrong}

Os erros do Real-Debrid vêm com um nome e um número. O zurg mostra os dois, como `bad_token (status code: 401) (code: 8)`.

| O que você vê | O que significa e o que fazer |
|---|---|
| `bad_token`, código 8. No zurg: `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | O Real-Debrid não reconhece esse token. Ele foi copiado errado, cortado ou substituído. Copie de novo em [real-debrid.com/apitoken](https://real-debrid.com/apitoken), o token inteiro, sem nada antes ou depois, e reinicie o zurg. |
| zurg: `Account realdebrid refused zurg (credential rejected)` | Igual ao `bad_token`. Suas outras contas continuam funcionando, e o zurg pergunta ao Real-Debrid de novo a cada 10 minutos. |
| DMM: **Real-Debrid rejected that API key.** | Igual ao `bad_token`. Copie de novo, ou clique em **Sign in with Real-Debrid** no lugar. |
| `permission_denied`, código 9. No zurg: `RD Permission denied (code=9)` | O Real-Debrid recusou a conta, não o token. A documentação dele cita conta bloqueada e, em algumas requisições, conta sem premium. Entre no real-debrid.com e confira a conta e os dias de **Premium**. Se tudo estiver certo, clique em **Refresh** na página do token e cole o novo token, como diz a mensagem do zurg. |
| `ip_not_allowed`, código 22. No zurg: `RD refused link generation from this IP (code=22, ip_not_allowed)` | Não é o token. O Real-Debrid não gera links de download para endereços de servidor e VPS. Rode o zurg a partir de uma conexão residencial, ou compre Remote Traffic no Real-Debrid. |
| `service_unavailable`, código 25 | O próprio Real-Debrid está com problemas. Nada para mudar do seu lado. Veja [Is Real-Debrid down or just me?](https://debridmediamanager.com/is-real-debrid-down-or-just-me) e tente mais tarde. |
| **403-Forbidden** em real-debrid.com/apitoken | Você não está conectado ao Real-Debrid. Entre na conta e abra a página de novo. |

Todos os códigos estão listados nas [documentações da API do Real-Debrid](https://api.real-debrid.com/), no final da página.

## Perguntas {#questions}

### Onde encontro meu token de API do Real-Debrid? {#where-do-i-find-my-real-debrid-api-token}

No site [real-debrid.com/apitoken](https://real-debrid.com/apitoken), já logado. Copie o código em **API Private Token**.

### Meu token funciona em outro app, mas o zurg diz que ele é inválido. Por quê? {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

Sua conta tem um único token de API. Muitos apps não usam ele: eles entram com um código, como o **Sign in with Real-Debrid** do DMM. Então, se o outro app está funcionando, não quer dizer que o zurg tem o token certo. Copie o token de novo na página de tokens e cole no zurg, sem nada antes ou depois dele, e reinicie o zurg.

### O token expira? {#does-the-token-expire}

Não, o token de API não tem data de validade. Já o login feito por meio de um app é diferente: ele dá ao app as próprias credenciais, que se renovam sozinhas.

### É seguro dar meu token para um addon ou site? {#is-it-safe-to-give-my-token-to-an-addon-or-website}

Só para apps em que você confia. O token dá acesso à sua conta inteira, e o Real-Debrid diz que ele não foi feito para apps públicos. Quando um app oferecer login com código, use esse método.
