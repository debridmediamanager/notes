# أحضر سجل المشاهدة الخاص بك إلى rex {#bring-your-watch-history-to-rex}

rex يبدأ بدون أي سجل مشاهدة. يمكنه نسخ العناوين التي شوهدت، ونقاط الاستئناف، وتقييمات النجوم من خادم Plex آخر.
تبقى العناوين التي شوهدت بالكامل مُشاهَدة. العناوين التي شوهدت جزئيًا تعود إلى **Continue Watching**. تُعاد حساب حلقات المسلسلات والمواسم.

شغّله مرة واحدة من أي حاسوب في المنزل. يمكن لكل من يستخدم rex أن يستورد سجل مشاهدته الخاص.

## قبل أن تبدأ {#before-you-start}

| تحتاج إلى | السبب |
|---|---|
| إعداد rex مع مكتبتك، كما في [rex مع تطبيقك الخاص](any-source.md) أو [rex مع إضافات Stremio الخاصة بك](stremio.md) أو [rex مع zurg](with-zurg.md) | rex ينسخ السجل فقط إلى العناوين الموجودة لديه بالفعل. إذا كانت مكتبتك لا تزال تمتلئ، أعد تشغيل الاستيراد لاحقاً: فهو يضيف فقط ما هو جديد |
| إصدار rex الليلي **2026.10.31 أو أحدث** | قم بالتحديث كما في قسم [تحديث rex](any-source.md#updating) |
| خادم Plex القديم الخاص بك، قيد التشغيل | يقرأ rex السجل منه. أعد تشغيله إذا أوقفته عند انتقالك إلى rex |
| جهاز كمبيوتر على شبكتك المنزلية، مع `curl` | يعمل الاستيراد فقط من شبكتك المنزلية. تتوفر الأداة `curl` على Windows 10 و11 وmacOS وLinux جميعها |

## 1. انسخ عنوان الخادم القديم الخاص بك {#1-copy-your-old-servers-address}

1. افتح [app.plex.tv](https://app.plex.tv) في المتصفح وسجّل الدخول بحسابك **أنت**، الحساب الذي تريد سجلّه.
2. اختر السيرفر القديم الخاص بك وافتح أي فيلم عليه.
3. اضغط على **⋯** (More)، ثم **Get Info**.
4. اضغط على **View XML** في الزاوية السفلية اليسرى من مربع **Media Info** الذي يفتح. ستفتح علامة تبويب جديدة مليئة بالنصوص.

   ![مربع Media Info الذي يفتحه Get Info، مع View XML في الزاوية السفلية اليسرى](../assets/rex/40-plex-get-info.webp)
5. انسخ **العنوان كاملاً** من شريط العناوين في علامة التبويب تلك.

يبدو هكذا، كله في سطر واحد، وينتهي بـ `X-Plex-Token=` متبوعاً برمز:

```
https://192-168-1-5.0123456789abcdef.plex.direct:32400/library/metadata/1234?checkFiles=1&includeAllConcerts=1&X-Plex-Token=AbCdEfGh1234567890xy
```

هذا الرمز هو **Plex token** الخاص بك لذلك السيرفر. يعمل ككلمة مرور لحساب Plex الخاص بك، فلا تلصقه أبداً في Discord أو في منشور دعم أو في لقطة شاشة.

**لا يوجد View XML في الخطوة 4؟** تعرضه Plex Web فقط على سيرفر تملكه، لذلك السيرفر الذي شاركه معك شخص آخر لن يحتويه. استخدم أدوات المطوّر في المتصفح على سيرفرك القديم بدلاً من ذلك، كما في [الخطوة 2](#2-get-your-token-on-rex)، واختر طلباً إلى سيرفرك القديم (عنوانه يحتوي على `plex.direct`). انقر عليه بالزر الأيمن وانسخ عنوانه: **Copy**، ثم **Copy URL** في Chrome وEdge، أو **Copy Value**، ثم **Copy URL** في Firefox. هذا العنوان هو المطلوب. يحتوي على `X-Plex-Token=` والرمز بين أجزاء `X-Plex-` أخرى، فالصق كل شيء.

## 2. احصل على الرمز الخاص بك على rex {#2-get-your-token-on-rex}

بما أن rex مُشارَك معك، فإن **Get Info** على rex لا يحتوي على **View XML**، إذ يعرضه Plex Web لمالك الخادم فقط. اقرأ الرمز من متصفحك بدلاً من ذلك، كما يرسله app.plex.tv إلى rex:

1. في app.plex.tv، وأنت ما زلت مسجلاً الدخول بحسابك، افتح أدوات المطورين في المتصفح: **F12**، أو **⌥ ⌘ I** على جهاز Mac. في Safari، فعّل أولاً **Show features for web developers** من **Settings** ثم **Advanced**.
2. افتح تبويب **Network** واكتب `X-Plex-Token` في مربع التصفية الخاص به.
3. افتح أي فيلم على خادم **rex**. ستمتلئ القائمة بالطلبات.
4. انقر على طلب عنوانه يخص rex: إذا كنت تستخدم rex-direct فسيحتوي العنوان على `rex-direct.debridmediamanager.com`، أو يكون عنوان HTTPS الذي أعددته بنفسك. ولا تختر طلباً يذهب إلى `plex.tv`.
5. انسخ قيمة `X-Plex-Token`: يعرضها Chrome وEdge تحت **Payload**، ويعرضها Firefox تحت **Request**. أو انسخ عنوان الطلب، وخذ الجزء الذي يأتي بعد `X-Plex-Token=` حتى أول `&`.

هذا الرمز غير الرمز الذي في الخطوة 1: فكل خادم يمنح حسابك رمزاً خاصاً به. يستخدم rex هذا الرمز ليعرف صاحب السجل.

## 3. شغّل الاستيراد {#3-run-the-import}

على كمبيوتر في المنزل، شغّل هذا الأمر بعد لصق القيمتين الخاصتين بك. `192.168.1.20` هو عنوان IP الخاص بـ rex على الشبكة المحلية، كما في أدلة الإعداد: ضع عنوانك مكانه.

```bash
curl -d "ADDRESS-FROM-STEP-1" "http://192.168.1.20:32400/rex/import-watched?X-Plex-Token=TOKEN-FROM-STEP-2"
```

على Windows، افتح **PowerShell** واكتب `curl.exe` بدلاً من `curl`. احتفظ بزوجي علامات الاقتباس المزدوجة: العنوان من الخطوة 1 يحتوي على أحرف `&`، وستعطّل هذه الأحرف الأمر إذا لم تكن موجودة.

يستغرق الأمر بضع ثوانٍ، وأطول مع المكتبة الكبيرة: يقرأ rex كل فيلم وكل حلقة على الخادم القديم.

**ما الذي يجب أن تراه.** سطر واحد مثل هذا:

```json
{"watched":412,"inProgress":7,"rated":38,"alreadyHere":0,"notInRex":55}
```

| الرقم | المعنى |
|---|---|
| `watched` | العناوين التي وضعها rex كمُشاهَدة، مع عدد مرات التشغيل وتاريخه على الخادم القديم |
| `inProgress` | العناوين التي كنت قد شاهدت جزءاً منها: ستستأنف من حيث توقفت |
| `rated` | العناوين التي حصلت على تقييمها بالنجوم |
| `alreadyHere` | العناوين التي شاهدتها أو بدأت مشاهدتها بالفعل على rex. يحتفظ rex بما لديه ولا يغيّر شيئاً هناك |
| `notInRex` | العناوين التي لدى الخادم القديم سجل مشاهدة لها ولا يملكها rex، أو لا يملكها كنفس العنوان |

افتح تطبيق Plex مرة أخرى (أو أعد تحميل app.plex.tv) لترى النتيجة.

## أعد تشغيله في أي وقت {#run-it-again-any-time}

شغّله مرة أخرى لا يغيّر أي شيء موجود لديك، لذا شغّله كلما وصل المزيد من مكتبتك. التشغيل الثاني مباشرة بعد الأول يعرض `"watched":0` والعناصر السابقة تحت `alreadyHere`.

## ما الذي لا يتم نسخه {#what-is-not-copied}

- Historial de cualquier otra persona de tu servidor anterior. Cada una ejecuta la importación con sus propios dos tokens.
- La lista de historial de reproducción, las listas de reproducción y las colecciones del servidor.
- Las calificaciones con estrellas de series y temporadas completas. Las calificaciones de películas y episodios sí se copian.
- Títulos de una biblioteca cuyo agente en el servidor anterior no es **Plex Movie** ni **Plex TV Series** (los agentes antiguos, como Plex Movie (Legacy) y TheTVDB). rex encuentra un título por el id que le dan los agentes actuales de Plex, y los antiguos le asignan otro, así que estos cuentan bajo `notInRex`.

## إذا لم يعمل {#if-it-does-not-work}

| What you see | What to do |
|---|---|
| `that address has no X-Plex-Token: copy it whole from the tab View XML opens` | العنوان الملصوق يتوقف قبل الرمز المميز. انسخه مرة أخرى من شريط العنوان أو من أدوات المطور، والصقه كاملاً |
| `send the address View XML opens on your old Plex server, starting http:// or https://` | شيء غير العنوان دخل بين علامتي الاقتباس بعد `-d` |
| `... refused the token: copy the address from View XML again` | خادم Plex القديم لم يقبل الرمز المميز. أعد تنفيذ الخطوة 1، واستخدم أدوات المطور إذا كان الخادم مشتركاً معك |
| `could not reach https://...` | تعذر على rex الاتصال بخادم Plex القديم. يجب أن يكون الخادم قيد التشغيل، و**جهاز rex** يجب أن يصل إليه، لأن rex يقرأ منه، وليس جهازك |
| `run the import from your home network` | أرسلت الأمر إلى العنوان الخارجي لـ rex. استخدم عنوان LAN IP الخاص بـ rex، كما في الخطوة 3 |
| صفحة `Unauthorized` | رفض rex الرمز المميز من الخطوة 2. انسخه مرة أخرى من طلب موجّه إلى rex، وليس من `plex.tv` |
| `notInRex` أعلى بكثير مما تتوقع | معظم مكتبتك ليس في rex بعد، أو أن مكتبتك القديمة تستخدم أحد الـ agents القديمة في Plex. شغّل الأمر مرة أخرى بعد وصول مكتبتك |

ما زلت عالقاً؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP). صفحة [طلب المساعدة](../guides/remote-help.md) توضح ما يجب تضمينه.
