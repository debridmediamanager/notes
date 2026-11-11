# rex مع إضافات Stremio الخاصة بك {#rex-with-your-stremio-addons}

[rex-stremio](https://github.com/debridmediamanager/rex-stremio) يحوّل قوائم إضافات Stremio إلى مكتبات rex. بعدها تُشغَّل الأفلام والمسلسلات والقنوات المباشرة في تطبيقات Plex. لا يتم تنزيل أي شيء. عندما يضغط أحدهم على تشغيل، يطلب rex-stremio رابطاً من إضافة البث، ثم يشغّله rex.

لا تحتاج هذه الأداة إلى رعاية DMM. rex وrex-stremio مجانيان. أحضر إضافات البث التي تعيد الروابط، وغالباً ما تعمل عبر حساب debrid الخاص بك.

ما ستحصل عليه:

- **المكتبات.** تُضاف الأفلام إلى **Stremio Films**، والمسلسلات إلى **Stremio Shows**، وقنوات إضافة التلفزيون المباشر إلى مكتبة اسمها **Live TV**، ما لم تسمِّ مكتبة القائمة بنفسك. هذه المكتبة قائمة من القنوات، وهي لا تظهر في دليل Live TV الخاص بتطبيقات Plex.
- **المجموعات.** أعطِ عدة قوائم أفلام المكتبة نفسها وفعّل **Catalogs as collections**: مكتبة واحدة، ومجموعة لكل قائمة، والفيلم الذي تذكره عدة قوائم يظهر مرة واحدة فقط.
- **Plex يعرض ما يعرفه.** تُرسل الأفلام والحلقات إلى rex بمعرّفات IMDb الخاصة بها، لذلك بمجرد أن يُضاف rex إلى حساب Plex، تعرض التطبيقات العناوين والملصقات والملخصات المعتادة. أما العناوين التي تعرفها الإضافة وحدها، والقنوات المباشرة، فتحتفظ بأسماء الإضافة وصورها.

## قبل أن تبدأ {#before-you-start}

| تحتاج إلى | السبب |
|---|---|
| جهاز يعمل باستمرار، بنظام Linux أو macOS، لتشغيل rex وrex-stremio معاً | rex-stremio برنامج Python واحد، ويعمل بجانب rex. الخدمة أدناه مخصصة لـ Linux، و[Docker](#in-docker) يعمل أيضاً |
| Python 3.9 أو أحدث، و`git` و`ffprobe` | rex-stremio يفحص مسار كل عنوان مرة واحدة باستخدام ffprobe، لأن rex يحتاج إلى معرفة محتوى الملف قبل أن يتمكن من تشغيله. مع مفتاح API خاص بـ DMM، فإن تدفق debrid لتورنت يحتفظ به DMM أصلاً يحمل فحص probe، فيتخطى هذا الفحص. أما غير ذلك فيُفحص |
| إضافات Stremio التي تعطي روابط، لا تورنتات | rex يشغّل الملفات. اضبط خدمة debrid الخاصة بك في الإضافة لكي تعطيك روابط |
| حساب Plex جديد، مخصص لـ rex فقط | كما في إعداد rex: يُربط rex بهذا الحساب، ويُشارَك مع حسابك الخاص |

## الخطوة 1. تثبيت rex وإضافته إلى حساب Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

اتبع [rex مع تطبيقك الخاص](any-source.md):

1. [الخطوة 1. ثبّت rex](any-source.md#step-1-install-rex)، بما في ذلك معرفة عنوان IP الخاص بـ rex على الشبكة المحلية (LAN). استخدم هذا العنوان في كل أمر.
2. [الخطوة 3. أضفه إلى حساب Plex](any-source.md#step-3-add-it-to-a-plex-account): سجّل rex على الحساب الجديد وشاركه مع حسابك.

تجاوز الخطوتين 2 و4 هنا، لأن rex-stremio هو تطبيقك.

القنوات المباشرة، والإضافات التي تكون بثوثها عبارة عن قوائم تشغيل `.m3u8`، لا تعمل إلا عبر تحويل الفيديو في rex. لذلك، أعدّ أيضًا [تحويل الفيديو](any-source.md#converting-video-optional) على الجهاز الذي يعمل عليه rex. أما الأفلام والحلقات المقدمة كملفات (`.mkv`، `.mp4`) فلا تحتاج إلى أي شيء إضافي.

## الخطوة 2. تثبيت rex-stremio {#step-2-install-rex-stremio}

**ما الذي يفعله؟** يُنزّل rex-stremio إلى `~/rex-stremio` على جهاز rex ويشغّله كخدمة.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
mkdir -p ~/.config/systemd/user
cp ~/rex-stremio/rex-stremio.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-stremio
journalctl --user -u rex-stremio -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-stremio
cd ~/rex-stremio && python3 rex_stremio.py
```

يبقى يعمل ما دامت نافذة Terminal تلك مفتوحة.
+++

**ما الذي يجب أن تراه؟** سطر يشبه:

```
... INFO relay and settings on http://127.0.0.1:9982/, 0 catalog(s), rex at http://127.0.0.1:32400
```

صفحة إعدادات rex-stremio والعنوان الذي يقرأ منه rex الفيديوهات كلاهما على `127.0.0.1:9982`، لذلك لا يصل إليهما إلا هذا الجهاز.

## الخطوة 3. أضف إضافاتك {#step-3-add-your-addons}

افتح `http://127.0.0.1:9982/` في متصفح على جهاز rex. لا توجد شاشة؟ من حاسوبك شغّل `ssh -L 9982:127.0.0.1:9982 you@<rex's LAN IP>` ثم افتح العنوان نفسه while SSH يبقى مفتوحًا.

1. ضمن **Addons**، الصق رابط manifest الخاص بالإضافة كما تفعل في Stremio، ثم اضغط **Add**. كرر ذلك لـ:
   - **Catalogs**، مثل Cinemeta: `https://v3-cinemeta.strem.io/manifest.json`.
   - **Streams**: إضافة تجد الإصدارات وتشغّلها عبر خدمة debrid الخاصة بك. افتح صفحة الإعدادات الخاصة بها، واختر خدمة debrid، والصق مفتاح API الخاص بك، وانسخ رابط manifest الذي تنشئه. إذا كانت تقدم نتائج مخزّنة مؤقتًا فقط، فاختر ذلك. الرابط يحتوي على مفتاح debrid الخاص بك، فاحتفظ به لنفسك.

   ![قسم Addons في rex-stremio مع Cinemeta و Public Domain Movies مضافين](../assets/rex/90-stremio-addons.webp)

2. ضمن **Catalogs**، فعّل الكتالوجات التي تريدها. سمِّ المكتبة التي سيذهب إليها كل كتالوج، واضبط **How many** للأفلام أو الحلقات أو القنوات التي تريد جلبها. إذا أردت مكتبة واحدة بمجموعة لكل كتالوج، فاجعل الكتالوجات في المكتبة نفسها وفعّل **Catalogs as collections**.
3. ضمن **Streams**، اضبط **Highest resolution** و **Largest file** اللذين تريد تشغيلهما، أو اتركهما على any.
4. ضمن **rex**، اضبط العنوان على `http://<rex's LAN IP>:32400`.
5. إذا كنت تدعم DMM، فالصق مفتاح DMM API الخاص بك ضمن **DMM** ([gatekeeper](https://gatekeeper.debridmediamanager.com/) يعرضه مرة واحدة بعد أن تصبح داعمًا). أي بث debrid لتورنت يحمل DMM فحصًا مسبقًا له يتخطى فحصه. أما غيره فيُفحص، وما يفحصه rex-stremio من ملفات التورنت (وليس بث HTTP عاديًا أو قائمة HLS أبدًا) يُعاد إلى DMM ليستفيد منه الداعم التالي (`share_probes: false` في `config.json` يوقف ذلك). اضغط **Save and sync**.

![أقسام Catalogs و Streams و rex و DMM في rex-stremio، مع زر Save and sync](../assets/rex/91-stremio-catalogs-rex.webp)

**ما يجب أن تراه.** في سجل rex، كما في [الخطوة 4 من rex مع تطبيقك الخاص](any-source.md#step-4-connect-your-app):

```
INFO    SOURCES PUT /rex/sources/stremio -> 200
INFO    FEED stremio upsert: ...
```

تظهر العناوين في rex مع فحص كل عنوان، لا عند انتهاء الكتالوج كله، ويفحص rex-stremio عدة عناوين في وقت واحد. تتم المزامنة مرة أخرى كل ست ساعات، وبعد كل حفظ.

## الخطوة 4. شارك المكتبات الجديدة وشاهد {#step-4-share-the-new-libraries-and-watch}

لأن المكتبات التي ينشئها rex-stremio جديدة، فحسابك لا يراها بعد. شاركها مع حسابك كما في [الخطوة 3](any-source.md#share-it-with-your-own-account)، وسجّل الدخول بالحساب الجديد، وشاركها أيضًا مع أي شخص آخر تشارك معه rex.

بعد ذلك، افتح تطبيق Plex بحسابك واضغط تشغيل على أي شيء. يطلب rex-stremio من إضافات البث الخاصة بك رابطًا في تلك اللحظة، ويشغّل rex الرابط. لمشاهدة المحتوى خارج المنزل أو في app.plex.tv، امنح rex عنوانًا خاصًا به: [استخدمه خارج منزلك](any-source.md#use-it-outside-your-home-optional).

## في Docker {#in-docker}

rex-stremio's [README](https://github.com/debridmediamanager/rex-stremio#set-up) has the Docker commands. In a container, rex reads the videos from the container's address on your network rather than `127.0.0.1`, which the README shows how to set.

## التحديث {#updating}

```bash
cd ~/rex-stremio && git pull && systemctl --user restart rex-stremio
```

على macOS، أوقفه بـ Ctrl+C، ثم شغّل `git pull` داخل `~/rex-stremio` وأعد تشغيله.

## ما الذي لا يستطيع فعله {#what-it-cannot-do}

- **تُرقَّم الحلقات كما يرقّمها Cinemeta.** في عدد قليل من المسلسلات يختلف ذلك عن ترقيم TMDB الذي يتبعه rex، لذلك قد تقع الحلقة في المكان الخطأ.
- **العدد يحسب الحلقات** في فهرس المسلسلات، وليس المسلسلات نفسها.
- **تشغيل خيار Catalogs as collections أو إيقافه** يرسل العناوين إلى rex من جديد كأنها عناوين جديدة، لذا قد لا تنتقل ما شاهدته عليها. قرر قبل أن تبدأ المشاهدة.
- **تُدرج فقط فهارس الأفلام والمسلسلات والقنوات**، ولا تُدرج أي فهرس يحتاج إلى بحث أو اختيار نوع أولاً.
- **لا يمكن إيقاف القنوات المباشرة مؤقتاً بعيداً إلى الخلف، ولا استئنافها لاحقاً، ولا وضع علامة "مشاهَد" عليها.** وهي تعمل فقط في التطبيقات التي تطلب من rex تحويلها (تطبيقات Plex وPlezy، ولم يُختبر Plex Web). القنوات التي لا تعمل بثاً، أو التي تحمل DRM، مستبعدة.
- **أي شخص يستطيع الوصول إلى عنوان rex-stremio يستطيع التشغيل من خلاله.** أبقه على `127.0.0.1` ما لم يكن rex يعمل على جهاز آخر.

يسرد README [بقية حدوده](https://github.com/debridmediamanager/rex-stremio#limits) وكل إعداد في `config.json`. لبناء إضافة خاصة بك، راجع [بناء إضافات rex](addons.md)، وهو يشرح أيضاً كيف يعمل rex-stremio من الداخل.
