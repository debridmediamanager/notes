# رمز API الخاص بـ Real-Debrid: أين تجده وماذا تعني الأخطاء {#your-real-debrid-api-token-where-to-get-it-and-what-the-errors-mean}

هذا هو رمز API الخاص بك لـ Real-Debrid موجود على [real-debrid.com/apitoken](https://real-debrid.com/apitoken). سجّل الدخول إلى Real-Debrid، وافتح تلك الصفحة، وانسخ الرمز الموجود تحت **API Private Token**. ثم الصقه في DMM أو zurg. عندما يُظهر تطبيق الخطأ `bad_token`، فهذا يعني أن الرمز الموجود لديه خاطئ أو ناقص: انسخه مرة أخرى من تلك الصفحة.

## احصل على رمزك {#get-your-token}

1. سجّل الدخول على [real-debrid.com](https://real-debrid.com). إذا لم تكن مسجّل الدخول، فستظهر لك صفحة التوكن **403-Forbidden** فقط.
2. افتح [real-debrid.com/apitoken](https://real-debrid.com/apitoken).
3. انسخ الكود كاملاً تحت **API Private Token**. يتكوّن من 52 حرفاً كبيراً وأرقاماً.

![صفحة API Private Token الخاصة بـ Real-Debrid، والتوكن مموّه](../assets/real-debrid-api-token/01-apitoken.webp)

تعامل معه كما تتعامل مع كلمة المرور. لا تنتهي صلاحيته أبداً، ومن يملكه يستطيع استخدام حسابك بالكامل. وهذا تحذير Real-Debrid نفسه المكتوب في تلك الصفحة: **This token is not meant to be used into public apps, it is insecure !**

زر **Refresh** في تلك الصفحة يُنشئ لك توكناً جديداً. ينصحك Real-Debrid باستخدامه إذا شككت في أن شخصاً آخر حصل على توكنك. وبعد التحديث، ألصق التوكن الجديد في كل تطبيق كان يستخدم القديم.

## ضعه في DMM {#put-it-in-dmm}

1. على [debridmediamanager.com](https://debridmediamanager.com)، اضغط **Login with Real Debrid**.
2. تحت **or paste an API key**، الصق الرمز في **API Key** واضغط **Save API Key**. الزر **Get API Key from Real-Debrid** يفتح لك صفحة الرمز مباشرة.

![صفحة Connect Real-Debrid في DMM](../assets/real-debrid-api-token/02-dmm-paste-key.webp)

لا يحتاج DMM إلى الرمز أصلاً: الزر **Sign in with Real-Debrid** يعرض رمزاً توافق عليه على real-debrid.com/device. بذلك يحصل DMM على تسجيل دخول خاص به، ويتجدد تلقائياً. للمزيد، انظر [ما هو DMM وكيف أستخدمه؟](../dmm/index.md#sign-in)

## ضعه في zurg {#put-it-in-zurg}

في `config.yml`، تحت `providers`:

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
```

أو في لوحة تحكم zurg على `http://localhost:9999`: افتح **Config**، واضغط **Edit** في صف realdebrid تحت **Providers**، والصق التوكن في حقل **Token** واضغط **Save**. أعد تشغيل zurg في الحالتين. يوجد باقي التفاصيل في [Real-Debrid مع zurg](../zurg/providers/realdebrid.md)، بما فيها إعداد `TOKEN` في Docker.

للتحقق مما يراه zurg في التوكن:

```bash
curl -sS -X POST http://localhost:9999/api/providers/realdebrid/test
```

التوكن الذي يرفضه Real-Debrid يعطي الرسالة `account connection check failed; verify credentials and network`.

## تحقق من الرمز بنفسك {#check-a-token-yourself}

```bash
curl -H "Authorization: Bearer YOUR_RD_API_TOKEN" https://api.real-debrid.com/rest/1.0/user
```

على ويندوز، اكتب `curl.exe` بدلاً من `curl`. إذا كان الرمز صحيحاً فسيعرض حسابك: `username` و`"type": "premium"` وتاريخ `expiration`. أما إذا كان الرمز خاطئاً فسيعرض:

```json
{
	"error": "bad_token",
	"error_code": 8
}
```

## عندما تحدث مشكلة {#when-something-is-wrong}

أخطاء Real-Debrid تأتي مع اسم ورقم. يعرض zurg الاثنين، مثل `bad_token (status code: 401) (code: 8)`.

| ما تراه | ما معناه وما الذي تفعله |
|---|---|
| `bad_token`, code 8. In zurg: `Failed to get user information: api response error: bad_token (status code: 401) (code: 8) trying again in 30s` | Real-Debrid لا يعرف هذا الرمز. نُسخ بشكل خاطئ أو قُطع أو استُبدل. انسخه مرة أخرى من [real-debrid.com/apitoken](https://real-debrid.com/apitoken)، كاملاً دون أي شيء قبله أو بعده، ثم أعد تشغيل zurg. |
| zurg: `Account realdebrid refused zurg (credential rejected)` | نفس حالة `bad_token`. حساباتك الأخرى تستمر في العمل، ويسأل zurg Real-Debrid مرة أخرى كل 10 دقائق. |
| DMM: **Real-Debrid rejected that API key.** | نفس حالة `bad_token`. انسخه مرة أخرى، أو اضغط **Sign in with Real-Debrid** بدلاً من ذلك. |
| `permission_denied`, code 9. In zurg: `RD Permission denied (code=9)` | رفض Real-Debrid الحساب وليس الرمز. تذكر وثائقه حساباً مقفلاً، وفي بعض الطلبات حساباً غير مميز. سجّل الدخول على real-debrid.com وتحقق من الحساب وأيام **Premium**. إذا بدا كل شيء سليماً، اضغط **Refresh** في صفحة الرمز والصق الرمز الجديد، كما تقول رسالة zurg. |
| `ip_not_allowed`, code 22. In zurg: `RD refused link generation from this IP (code=22, ip_not_allowed)` | ليست المشكلة في الرمز. Real-Debrid لا ينشئ روابط تحميل لعناوين IP الخاصة بالخوادم وخوادم VPS. شغّله من اتصال منزلي، أو اشترِ Remote Traffic من Real-Debrid. |
| `service_unavailable`, code 25 | Real-Debrid نفسه يعاني من مشكلة. لا شيء تغيّره من جهتك. راجع [هل Real-Debrid متوقف أم أنا فقط؟](https://debridmediamanager.com/is-real-debrid-down-or-just-me) وجرّب لاحقاً. |
| **403-Forbidden** on real-debrid.com/apitoken | لست مسجّل الدخول إلى Real-Debrid. سجّل الدخول وافتح الصفحة مرة أخرى. |

كل الرموز مدرجة في [وثائق API الخاصة بـ Real-Debrid](https://api.real-debrid.com/)، في الأسفل.

## أسئلة {#questions}

### أين أجد رمز API الخاص بـ Real-Debrid؟ {#where-do-i-find-my-real-debrid-api-token}

[real-debrid.com/apitoken](https://real-debrid.com/apitoken)، بعد تسجيل الدخول. انسخ الرمز الموجود تحت **API Private Token**.

### رمزي يعمل في تطبيق آخر لكن zurg يقول إنه غير صالح. لماذا؟ {#my-token-works-in-another-app-but-zurg-says-its-invalid-why}

هذا الحساب عنده توكن API واحد. كثير من التطبيقات ما تستخدمه أصلاً، وبدلاً منه تسجّل الدخول برمز، مثل زر **Sign in with Real-Debrid** في DMM. لذلك إذا كان تطبيق آخر يعمل، فهذا لا يعني أن zurg عنده التوكن الصحيح. انسخ التوكن من صفحة التوكنات مرة ثانية وضعه في zurg، بدون أي مسافات أو أحرف قبله أو بعده، ثم أعد تشغيل zurg.

### هل ينتهي صلاحية الرمز؟ {#does-the-token-expire}

لا، لرمز الـAPI لا يوجد تاريخ انتهاء. أما تسجيل الدخول عبر تطبيق فهو مختلف: إذ يمنح ذلك التطبيق بيانات اعتماد خاصة به، وتتجدد هذه البيانات تلقائياً.

### هل من الآمن إعطاء رمزي لإضافة أو موقع ويب؟ {#is-it-safe-to-give-my-token-to-an-addon-or-website}

أعطِها فقط للتطبيقات التي تثق بها. فالرمز المميز يفتح حسابك بالكامل، وتقول Real-Debrid إنه غير مخصص للتطبيقات العامة. وإذا كان التطبيق يتيح تسجيل الدخول برمز، فاستخدم ذلك بدلاً من ذلك.
