# Votre jeton d'API Real-Debrid : où le trouver et ce que signifient les erreurs {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

Votre jeton d'API Real-Debrid se trouve sur [real-debrid.com/apitoken](https://real-debrid.com/apitoken). Connectez-vous à Real-Debrid, ouvrez cette page et copiez le code sous **API Private Token**. Collez-le dans DMM ou zurg. Lorsqu'une application affiche `bad_token`, cela signifie que le jeton qu'elle a est incorrect ou incomplet : copiez-le à nouveau depuis cette page.

## Récupérer votre jeton {#get-your-token}

1. Connectez-vous sur [real-debrid.com](https://real-debrid.com). Si vous n'êtes pas connecté, la page du token n'affiche que **403-Forbidden**.
2. Ouvrez [real-debrid.com/apitoken](https://real-debrid.com/apitoken).
3. Copiez tout le code sous **API Private Token**. Il fait 52 lettres majuscules et chiffres.

![Page API Private Token de Real-Debrid, token flouté](../assets/real-debrid-api-token/01-apitoken.webp)

Traitez-le comme un mot de passe. Il n'expire pas, et quiconque le possède peut utiliser tout votre compte. L'avertissement de Real-Debrid lui-même, sur cette page : **This token is not meant to be used into public apps, it is insecure !**

**Refresh** sur cette page génère un nouveau token. Real-Debrid le suggère si vous pensez que quelqu'un d'autre possède le vôtre. Après un refresh, collez le nouveau token dans chaque application qui utilisait l'ancien.

## Le mettre dans DMM {#put-it-in-dmm}

1. Sur [debridmediamanager.com](https://debridmediamanager.com), appuyez sur **Login with Real Debrid**.
2. Sous **or paste an API key**, collez le jeton dans **API Key** puis appuyez sur **Save API Key**. **Get API Key from Real-Debrid** ouvre directement la page du jeton.

![Page Connect Real-Debrid de DMM](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

DMM n'a pas besoin du jeton du tout : **Sign in with Real-Debrid** affiche un code que vous validez sur real-debrid.com/device. DMM dispose ainsi de sa propre connexion, qui se renouvelle toute seule. Pour en savoir plus, voir [What is DMM and how do I use it?](../dmm/index.md#sign-in)

## Le mettre dans zurg {#put-it-in-zurg}

Dans `config.yml`, sous `providers` :

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

Ou dans le Dashboard de zurg sur `http://localhost:9999` : ouvre **Config**, appuie sur **Edit** de la ligne realdebrid sous **Providers**, colle le token dans **Token** et appuie sur **Save**. Redémarre zurg dans tous les cas. [Real-Debrid avec zurg](../zurg/providers/realdebrid.md) explique le reste, y compris le réglage `TOKEN` de Docker.

Pour vérifier ce que zurg en pense :

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

Un token refusé par Real-Debrid renvoie `account connection check failed; verify credentials and network`.

## Vérifier un jeton vous-même {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

Sous Windows, tapez `curl.exe` au lieu de `curl`. Un token valide affiche votre compte : `username`, `"type": "premium"` et la date `expiration`. Un token incorrect affiche :

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## Quand quelque chose ne va pas {#when-something-is-wrong}

Les erreurs de Real-Debrid arrivent avec un nom et un numéro. zurg affiche les deux, comme `bad_token (status code: 401) (code: 8)`.

| Ce que vous voyez | Ce que ça veut dire et quoi faire |
|---|---|
| `bad_token`, code 8. Dans zurg : `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | Real-Debrid ne connaît pas ce token. Il a été mal copié, coupé ou remplacé. Recopiez-le depuis [real-debrid.com/apitoken](https://real-debrid.com/apitoken), en entier et sans rien avant ni après, puis redémarrez zurg. |
| zurg : `Account realdebrid refused zurg (credential rejected)` | Même chose que `bad_token`. Vos autres comptes continuent de fonctionner, et zurg redemande à Real-Debrid toutes les 10 minutes. |
| DMM : **Real-Debrid rejected that API key.** | Même chose que `bad_token`. Recopiez la clé, ou appuyez plutôt sur **Sign in with Real-Debrid**. |
| `permission_denied`, code 9. Dans zurg : `RD Permission denied (code=9)` | Real-Debrid a refusé le compte, pas le token. Sa doc cite un compte bloqué, et pour certaines requêtes un compte sans premium. Connectez-vous sur real-debrid.com et vérifiez le compte ainsi que ses jours **Premium**. Si tout semble correct, appuyez sur **Refresh** sur la page du token et collez le nouveau token, comme l'indique le message de zurg. |
| `ip_not_allowed`, code 22. Dans zurg : `RD refused link generation from this IP (code=22, ip_not_allowed)` | Ce n'est pas le token. Real-Debrid ne génère pas de liens de téléchargement pour les adresses de serveurs et de VPS. Lancez-le depuis une connexion domestique, ou achetez du Remote Traffic auprès de Real-Debrid. |
| `service_unavailable`, code 25 | Real-Debrid rencontre lui-même un problème. Rien à changer de votre côté. Consultez [Is Real-Debrid down or just me?](https://debridmediamanager.com/is-real-debrid-down-or-just-me) (Real-Debrid est-il en panne ou seulement moi ?) et réessayez plus tard. |
| **403-Forbidden** sur real-debrid.com/apitoken | Vous n'êtes pas connecté à Real-Debrid. Connectez-vous, puis rouvrez la page. |

Chaque code est listé dans [la documentation API de Real-Debrid](https://api.real-debrid.com/), tout en bas.

## Questions

### Où trouver mon jeton d'API Real-Debrid ? {#where-do-i-find-my-real-debrid-api-token}

Sur [real-debrid.com/apitoken](https://real-debrid.com/apitoken), en étant connecté. Copiez le code sous **API Private Token**.

### Mon jeton fonctionne dans une autre application mais zurg dit qu'il est invalide. Pourquoi ? {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

Votre compte a un seul jeton API. Beaucoup d'applications ne l'utilisent pas du tout : elles se connectent avec un code à la place, comme **Sign in with Real-Debrid** dans DMM. Donc si une autre application fonctionne, cela ne veut pas dire que zurg a le bon jeton. Recopiez-le depuis la page des jetons dans zurg, sans rien avant ni après, puis redémarrez zurg.

### Le jeton expire-t-il ? {#does-the-token-expire}

Non, le jeton d'API n'a pas de date de fin. Une connexion via une application est différente : elle donne à cette application ses propres identifiants, qui se renouvellent automatiquement.

### Est-ce sûr de donner mon jeton à un addon ou à un site web ? {#is-it-safe-to-give-my-token-to-an-addon-or-website}

Uniquement à celles en qui vous avez confiance. Le jeton ouvre l'accès à tout votre compte, et Real-Debrid indique qu'il n'est pas destiné aux applications publiques. Si une application propose une connexion avec un code, utilisez plutôt celle-ci.
