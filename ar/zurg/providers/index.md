# المزوّدون {#providers}

المزوّد هو حساب واحد يبني منه zurg مكتبتك. كل حساب هو مدخل واحد تحت `providers:` في `config.yml`. شغّل حسابًا واحدًا أو شغّل ستة.
الإصدار الموجود لدى أكثر من حساب منها يظهر مرة واحدة فقط، ويُقرأ من أي حساب يستطيع تقديمه في تلك اللحظة.

| الخدمة | `type` | الصفحة |
|---|---|---|
| Real-Debrid | `realdebrid` | [Real-Debrid](realdebrid.md) |
| TorBox | `torbox` | [TorBox](torbox.md) |
| AllDebrid | `alldebrid` | [AllDebrid](alldebrid.md) |
| Premiumize | `premiumize` | [Premiumize](premiumize.md) |
| Debrid-Link | `debridlink` | [Debrid-Link](debridlink.md) |
| Offcloud | `offcloud` | [Offcloud](offcloud.md) |
| Usenet | `nzb` | [Usenet](usenet.md) |
| TorBox hosted Usenet | `torbox_nzb` | [TorBox hosted Usenet](torbox-nzb.md) |

ثلاث صفحات تتعمق أكثر من الإعداد. تحتوي [حدود TorBox](torbox-limits.md) على الأرقام المقاسة وراء تقييد TorBox.
توضّح [صفحة خادم أخبار TorBox](torbox-news-server.md) و[صفحة خادم أخبار ElfHosted](elfhosted-news-server.md) ما هي حسابات Usenet المرفقة مع تلك الخطط فعليًا.
قيّم أيّها من هناك قبل أن تخصص له خانة مزوّد.

كل صفحة هنا تفترض التثبيت عبر الحاوية من [إعداد Docker](../setup/docker.md). `~/zurg` هو مجلد compose على المضيف. و`/config` هو المجلد نفسه كما يُرى من داخل الحاوية. يوجد `config.yml` واحد، وكلا الاسمين يصلان إليه.

في التثبيت الثنائي على Linux أو macOS أو Windows، تذكر صفحة [الإعداد](../setup/index.md) ما يحل محل `docker compose restart zurg` وسطر `setup`.
تُطبَّق الفحوصات بالطريقة نفسها. شغّلها من مجلد zurg. اقرأ `logs/zurg.log` بدلًا من `docker compose logs` (`Get-Content logs\zurg.log -Tail 100 -Wait` في PowerShell).
شغّل `./zurg doctor` (`.\zurg.exe doctor`) دون `--working-dir /config`.
اعرض نقطة التركيب الخاصة بك بدلًا من `/zurg_mnt/zurg`: `/mnt/zurg` أو `/Volumes/Zurg` أو `Z:\`، ما لم تكن قد غيّرت `mount_path`.
في Windows PowerShell 5.1 اكتب `curl.exe` وليس `curl`.

## ثلاث طرق لإضافة حساب {#three-ways-to-add-an-account}

أيُّهما تريد يعتمد على ما إذا كان الملف `config.yml` موجودًا أم لا.

### في التثبيت الجديد استخدم الإعداد {#on-a-fresh-install-use-setup}

`zurg setup` يسألك أي مزوّدين تريد ضبطهم، ولا يطلب منك إلا بيانات الدخول الخاصة بهم. يكتب الحسابات **فقط عندما لا يوجد `config.yml` بعد**.
شغّله مرة أخرى لاحقًا وسيحدّث التثبيت من دون أن يمسّ الحسابات الموجودة لديك.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

تقبل أداة الاختيار أرقامًا أو أسماءً، ويمكنك اختيار أكثر من واحد في المرة نفسها.

```
Choose one or more providers in priority order:
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
Providers (comma-separated numbers or names): 2,4
```

ما تكتبه لا يُحفظ في ملف compose ولا في سجل الأوامر (shell history). يُكتب الـ token مباشرةً في `config.yml`، ويُضبط الملف بحيث يقرؤه المالك فقط.

### في التثبيت الموجود استخدم لوحة التحكم {#on-an-existing-install-use-the-dashboard}

افتح `http://localhost:9999/config/` واضغط **Add provider** تحت Essentials.
اختر النوع. الصق الـ token. ثم احفظ. لوحة التحكم (Dashboard) تكتب الإدخال مرة أخرى في
نفس ملف `config.yml` الموجود بجانب ملف compose الخاص بك.

تغييرات الـ providers تحتاج إلى إعادة تشغيل حتى تسري. لوحة التحكم تخبرك بذلك،
وإعادة التشغيل تتم بأمر واحد.

```bash
docker compose restart zurg
```

### أو عدّل ملف config.yml يدويًا {#or-edit-configyml-by-hand}

الملف هو `~/zurg/config.yml` على الجهاز المضيف. أضِف المدخل ثم أعِد التشغيل.

```yaml
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN
  - type: torbox
    token: YOUR_TORBOX_API_KEY
mount_path: "/zurg_mnt/zurg"
```

`mount_path` هو `/zurg_mnt/zurg` داخل الحاوية، ويجب أن يربط ملف compose المسار
`/zurg_mnt:/zurg_mnt:rshared` حتى يصل التركيب (mount) إلى الجهاز المضيف. هذه هي صفحة [إعداد Docker](../setup/docker.md)، وهي الجزء الوحيد في تثبيت الحاوية الذي يختلف عن التثبيت بالملف التنفيذي.

## التثبيت بدون مراقبة {#unattended-installs}

كل مزوّد له علامة ملف توكن ومتغير بيئة. كرّر `--provider` لكل حساب تريد إضافته.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider torbox \
  --torbox-token-file /config/secrets/torbox
```

| `type` | العلم | متغير البيئة |
|---|---|---|
| `realdebrid` | `--realdebrid-token-file` | `REALDEBRID_TOKEN` أو `TOKEN` أو `RD_TOKEN` |
| `torbox` | `--torbox-token-file` | `TORBOX_TOKEN` |
| `alldebrid` | `--alldebrid-token-file` | `ALLDEBRID_TOKEN` |
| `premiumize` | `--premiumize-token-file` | `PREMIUMIZE_TOKEN` |
| `debridlink` | `--debridlink-token-file` | `DEBRIDLINK_TOKEN` |
| `offcloud` | `--offcloud-token-file` | `OFFCLOUD_TOKEN` |
| `nzb` | `--nntp-password-file` مع `--nntp-host` و`--nntp-username` | `NNTP_HOST` وما شابه |
| `torbox_nzb` | `--torbox-token-file` | `TORBOX_TOKEN` |

لا يُستنتج `torbox_nzb` أبداً من `TORBOX_TOKEN` أو `--torbox-token-file` وحدهما؛ مرّر `--provider torbox_nzb`.

مع `--non-interactive` ومن دون `--provider` نهائياً، يأخذ الإعداد أي من هذه المتغيرات التي تكون مضبوطة.

!!!warning لا يُهيَّأ من الحاوية العاملة إلا Real-Debrid
خدمة zurg نفسها تقرأ `TOKEN` و`RD_TOKEN` و`MOUNT_PATH` في التشغيل الذي ينشئ `config.yml`. وهذه هي القائمة كاملة. أما `TORBOX_TOKEN` وغيره فيقرؤه `zurg setup`. إضافة أحدها إلى قسم `environment:` في ملف compose وتشغيل الحاوية لا يفعل شيئاً وحده. شغّل الإعداد أو أضف الحساب من Dashboard.
!!!

## ما يقبله كل إدخال {#what-every-entry-accepts}

| المفتاح | وظيفته |
|---|---|
| `type` | مطلوب. واحد من الأنواع الثمانية أعلاه. |
| `name` | القيمة الافتراضية هي `type`. يفرّق بين حسابين على الخدمة نفسها. |
| `token` | مفتاح API. لا يُستخدم مع `nzb`. |
| `disabled` | يوقف الحساب مؤقتاً دون حذف بيانات الاعتماد. |
| `watchlist` | يحدد الحساب الذي تُجرَّب عليه الإضافات الجديدة للتورنت أولاً. |
| `add_torrents` | إذا ضبطته على `false` يبقى الحساب يخدم الطلبات، لكنه لا يحصل على أي شيء جديد أبداً. |
| `warm_connections` | عدد الاتصالات المفتوحة لكل مضيف، حتى لا تحتاج كل قراءة إلى فتح اتصال جديد. |

الأوصاف الكاملة وكل التفاصيل الأخرى موجودة في [المرجع الكامل للإعدادات](../reference/config.md#accounts).

## القواعد التي يفرضها المحمّل {#rules-the-loader-enforces}

- يجب أن تكون الأسماء فريدة. إذا كان لديك حسابان على Real-Debrid، فاستخدم `name: rd-main` و`name: rd-backup`، وإلا سيفشل التحميل.
- الاسم `e` محجوز لتوجيه روابط `.strm`. اختر اسمًا آخر.
- يُسمح بمدخل واحد فقط يضبط `watchlist: true`.
- لا يُقبل `watchlist: true` مع `add_torrents: false` في المدخل نفسه.
- لا يُدعم إلا مدخل `nzb` أو `torbox_nzb` واحد مفعّل. أي خوادم أخبار إضافية تُضاف تحت `nntp.servers` في مدخل `nzb`.
- إذا كانت جميع المداخل معطّلة، فسيفشل التحميل.
- ترفض Premiumize وDebrid-Link وOffcloud القيمة `download_tokens` وأي `strm_link_token` يختلف عن `token`. معرّفات الملفات لديها تخص حسابًا واحدًا، لذا إذا أردت حسابًا ثانيًا فيجب أن يكون مدخلًا ثانيًا.

## تحقّق من أنه يعمل {#check-it-worked}

ابدأ بالسجل وبالتشخيص.

```bash
docker compose logs -f --tail=100 zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

التحذير `WARN service zurg is not installed` متوقع في Docker لأن Compose هو المسؤول عن التشغيل التلقائي. التحذيرات لا تجعل doctor يفشل. الذي يفشله هو `FAIL`.

ثم افحص الحساب نفسه من Dashboard أو من الـshell.

```bash
curl -fsS -X POST http://localhost:9999/api/providers/torbox/test
```

يعني `{"success":true}` أن بيانات الاعتماد نجحت في المصادقة. الاسم الموجود في المسار هو `name` الخاص بالحساب، وقيمته الافتراضية هي `type`. أضف `-u user:pass` إذا كنت قد حددت `username` في `config.yml`. وإن لم تفعل ذلك، فإن Dashboard وواجهته البرمجية (API) تكونان مفتوحتين على المنفذ الذي نشرته.

وأخيرًا، ألقِ نظرة على المكتبة الموجودة على نقطة التركيب (mount).

```bash
ls /zurg_mnt/zurg/__all__/
```

يحصل كل حساب مُعدّ على مجلد `__<name>__` خاص به. يحتوي هذا المجلد على كل ما يحتويه الحساب، ويثبّت القراءة على ذلك الحساب. المسار `__torbox__/Some.Release/` يبث من TorBox فقط ولا يبث من أي مكان آخر. لا يظهر مجلد الحساب المنفرد في قائمة الجذر الخاصة بنقطة التركيب، لأن `__all__` هو المكتبة نفسها. أما مسارات HTTP المباشرة وWebDAV، مثل `/http/__torbox__/`، فما زالت تستجيب. أما عبر نقطة التركيب فلم يعد هذا المسار يُحلّ أيضًا؛ فوجّه أي مكتبة أو سكربت كان يستخدم `__<name>__` إلى `__all__`.

تستغرق المكتبة الكبيرة بعض الوقت في التحميل الأول. وحتى ينتهي التحميل، يرد `/dav/movies/` برمز 503 وقد لا تعرض نقطة التركيب أي شيء.

## تشغيل عدة حسابات {#running-several-accounts}

يهمّ الترتيب في موضع واحد فقط. ترتيب قائمة `providers:` هو الترتيب الذي تُجرَّب به الحسابات التي تقبل الإضافات. يُجرَّب الحساب الذي يحمل `watchlist: true` أولاً أينما كان موضعه. أما عند عرض المحتوى وقراءته فلا يكون للترتيب أي أفضلية.

هناك أمران يستحق معرفتهما قبل أن توجّه خادم الوسائط إلى النتيجة.

- يظهر الإصدار نفسه في مجلداتك المصفّاة **وأيضاً** داخل كل مجلد `__<name>__` يحتويه. وجّه Plex أو Jellyfin إلى جزء واحد من نقطة التركيب بدلاً من كلها، وإلا فسيفحص المحتوى نفسه عدة مرات.
- لا يوجد تبديل تلقائي صامت داخل مجلد `__<name>__`. الملف المعطوب في حساب واحد يُرجع 404 هناك، ويُشغَّل من مجلد حساب آخر. أما بقية نقطة التركيب فتقدّمه بشكل طبيعي.
