# Premiumize

`type: premiumize`

يعرض Premiumize التحويلات المكتملة **وكذلك** ملفات السحابة التي تبقى بعد مسح قائمة التحويلات. تحتفظ المجلدات المتداخلة بمساراتها. ستظهر مكتبتك المنظمة على Premiumize في الـ mount بالترتيب نفسه الذي تركتها عليه.

## الحصول على مفتاح API {#get-the-api-key}

سجّل الدخول وافتح [premiumize.me/account](https://www.premiumize.me/account). مفتاح الـ API موجود في تلك الصفحة.

## إعداده {#configure-it}

```yaml
zurg: v1
providers:
  - type: premiumize
    token: YOUR_PREMIUMIZE_API_KEY
mount_path: "/zurg_mnt/zurg"
```

في تثبيت حاوية جديد، دع أمر الإعداد يكتب الملف.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider premiumize
```

إذا كان لديك تثبيت يحتوي على `config.yml` بالفعل، استخدم **Add provider** في Dashboard على `http://localhost:9999/config/` أو عدّل الملف مباشرةً. أعد التشغيل في الحالتين.

```bash
docker compose restart zurg
```

يقرأ `zurg setup` المتغير `PREMIUMIZE_TOKEN`، وليس الخدمة الخلفية التي تعمل. لا يفعل شيئًا إذا بقي في كتلة `environment:` الخاصة بـ compose وحده.

## بيانات اعتماد واحدة لكل إدخال {#one-credential-per-entry}

معرّفات ملفات Premiumize تنتمي إلى الحساب الذي أضافها. لا يوجد مفتاح ثانٍ تقوم بتدويره. يُرفض `download_tokens` بشكل قاطع، وكذلك `strm_link_token` إذا كانت قيمته تختلف عن `token`. الحساب الثاني في Premiumize يُضاف كإدخال منفصل له `name` خاص به.

```yaml
providers:
  - type: premiumize
    name: pm-main
    token: FIRST_PREMIUMIZE_API_KEY
  - type: premiumize
    name: pm-second
    token: SECOND_PREMIUMIZE_API_KEY
```

المُحمِّل يذكر ذلك صراحةً بدلاً من أن يتجاهل المفاتيح بصمت. يرفض الإعدادات ويسمّي الإدخال المعني.

## ما الذي يعمل هنا {#what-works-here}

تعمل كل هذه الأمور: تصفح المكتبة، والقراءة المتدفقة، والقراءة عبر إعادة التوجيه، وملفات STRM، وإضافة الروابط المغناطيسية، ورفع ملفات `.torrent`، والحذف. ويحصل الحساب على مجلد `__premiumize__` خاص به، مثل بقية الحسابات.

## يتم تخزين الـ hashes على القرص {#hashes-are-remembered-on-disk}

تُكتب الـ hashes التي يوفّرها zurg إلى الملف `data/premiumize/<account>/sources.json` داخل الـ `/config` bind. تبقى المطابقة بين الحسابات سليمة بعد إعادة التشغيل، وكذلك بعد مسح قائمة النقل المكتملة.

المحتوى السحابي الذي استوردته بطرق أخرى ليس له hash مسجّل. ما زال يمكن بثه. لا يمكن إصلاحه باستخدام الـ hash، ولا يمكن مطابقته مع حساب آخر باستخدام الـ hash.

!!!warning حذف النقل يحذف ملفاته
حذف نقل Premiumize عبر zurg يحذف أيضاً الملفات التي يملكها ذلك النقل. هذا هو السلوك الأصلي لـ Premiumize، وليس شيئاً يضيفه zurg فوقه.
!!!

## حدود تستحق الانتباه {#limits-worth-knowing}

**Cloud-Speicher und Fair-Use-Grenzen sind die eigenen Limits des Kontos.** zurg hebt sie nicht an
und umgeht sie auch nicht.

**8 gleichzeitige API-Anfragen.** Vier Teile eines Multi-Volume-Archivs werden
gleichzeitig aufgelöst.

**Inhalte laufen ab.** Ein Release, das nicht mehr da ist, ist ein erwartetes Ergebnis und kein
Fehler. Repair lässt es in Ruhe, außer du bittest ausdrücklich darum.

**Die Torrent-Liste enthält keine Dateidetails.** Jedes Release kostet beim ersten Mal
eine eigene Abfrage.

zurg ordnet die Fehlercodes des Dienstes dem zu, was als Nächstes passieren sollte.

| Code von Premiumize | Was zurg macht |
|---|---|
| `authentication_failed` | Meldet einen ungültigen Zugangsschlüssel. Korrigiere den Key. |
| `rate_limit_reached` | Pausiert das Konto für eine Minute. |
| `account_limit_reached` oder `service_limit_reached` | Meldet ein aufgebrauchtes Kontingent. |
| `service_down` | Behandelt das Konto als vorübergehend nicht verfügbar. |
| `not_found` | Behandelt den Torrent als nicht mehr vorhanden. |

## تحقّق من أنه يعمل {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/premiumize/test
ls /zurg_mnt/zurg/__all__/ | head
```

مع حساب واحد فقط، يتم استبعاد مجلده الخاص من قائمة الجذر في الـ mount،
لذلك يُظهر الـ mount نفس الملفات تحت `__all__`.

## عندما تسوء الأمور {#when-it-goes-wrong}

**كل شيء يفشل برسالة خطأ بخصوص بيانات الاعتماد.** أعد إنشاء المفتاح من [premiumize.me/account](https://www.premiumize.me/account) ثم حدّث الإدخال.
انتبه إلى أن Premiumize يرد بالرد نفسه إذا كان المفتاح مفقودًا وإذا كان المفتاح خاطئًا. الرسالة لا تخبرك أيّ الحالتين حدثت.

**ملف يعمل في البث لكن لا يمكن إصلاحه.** ليس له hash مسجّل. هذا يعني أنه دخل الحساب بطريقة أخرى غير zurg. راجع ما سبق.

**القراءات تتوقف لدقيقة في كل مرة.** وصل الحساب إلى حد المعدل، فأوقفه zurg عمدًا. سيستأنف العمل من تلقاء نفسه.

**الروابط المُنشأة تعمل لأي شخص يملكها.** روابط التسليم والوصول عبر `.strm` تستحق أن تبقى خاصة. الحصة التي تُستهلك منها هي حصة الحساب نفسه.
