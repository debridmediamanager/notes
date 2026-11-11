# Seerr عبر DMM {#seerr-through-dmm}

أضف DMM إلى [Seerr](https://github.com/seerr-team/seerr) كما تضيف Radarr وSonarr. تصل الطلبات المعتمدة
إلى [قائمة DMM المطلوبة](../zurg/guides/dmm-wanted.md) الخاصة بك ليجلبها zurg. لست بحاجة إلى
Radarr أو Sonarr. يحتاج Seerr فقط إلى الوصول إلى debridmediamanager.com. يعمل Overseerr وJellyseerr
بالطريقة نفسها.

هذا الإعداد مخصص للرعاة. يسجّل Seerr الدخول باستخدام مفتاح API الخاص بـ DMM من [gatekeeper](https://gatekeeper.debridmediamanager.com/).

## ما تحتاجه {#what-you-need}

- zurg يقرأ قائمة الرغبات الخاصة بك من DMM باستخدام `dmm_api_key` في `config.yml`. راجع [جلب ما تريده من DMM](../zurg/guides/dmm-wanted.md#what-you-need).
- Seerr مُعدّ مع خادم Plex أو Jellyfin أو Emby الخاص بك حتى يعرف الحلقات التي لديك.

## إضافة DMM كـ Radarr {#add-dmm-as-radarr}

في Seerr، افتح **Settings → Services** واضغط على **Add Radarr Server**. املأ الحقول كما يلي:

| Field | Value |
|---|---|
| Default Server | مُفعّل |
| 4K Server | غير مُفعّل |
| Server Name | `DMM`، أو أي اسم آخر |
| Hostname or IP Address | `debridmediamanager.com` |
| Port | `443` |
| Use SSL | مُفعّل |
| API Key | مفتاح API الخاص بـ DMM |
| URL Base | `/api/arr/radarr` |

اضغط على **Test**. عند نجاح الاتصال، اختر **Any** في Quality Profile و**/dmm** في Root Folder.
اترك Minimum Availability كما هو. فعّل **Enable Scan** واضغط على **Add Server**.

![نافذة Add Radarr Server في Seerr بعد تعبئتها لـ DMM](../assets/seerr-dmm/01-seerr-radarr-dmm.webp)

إذا فشل Test، تحقّق من المفتاح: هو المفتاح الموجود في صفحة [الإعدادات](https://debridmediamanager.com/settings) الخاصة بـ DMM. كما يرفض DMM المفتاح بمجرد انتهاء رعايتك.

## إضافة DMM كـ Sonarr {#add-dmm-as-sonarr}

اضغط على **Add Sonarr Server** واستخدم URL Base بالقيمة `/api/arr/sonarr`. بعد **Test** اختر **Any** للخيارين `/dmm` في كل من profiles وroot folders. فعّل **Enable Scan** واضغط **Add Server**.

![مربع حوار Add Sonarr Server في Seerr بعد تعبئته لـ DMM](../assets/seerr-dmm/02-seerr-sonarr-dmm.webp)

## الطلب {#requesting}

قدّم الطلب كالمعتاد. يُضاف الفيلم المعتمد إلى قائمة المطلوبات الخاصة بك:

![طلب فيلم في Seerr](../assets/seerr-dmm/03-seerr-request-movie.webp)

![الفيلم يظهر كمطلوب](../assets/seerr-dmm/04-seerr-movie-requested.webp)

بالنسبة للمسلسل، اختر المواسم التي تريدها. يمكن لطلب لاحق أن يضيف مواسم أخرى. لمتابعة المسلسل كاملاً بما فيه المواسم الجديدة، اضغط على **Want all seasons** في صفحة DMM الخاصة به.

![اختيار مواسم مسلسل](../assets/seerr-dmm/05-seerr-request-seasons.webp)

تظهر كل عناوينك في [قائمة المطلوبات](https://debridmediamanager.com/wanted) خلال ثوانٍ. يلتقطها zurg خلال دقيقة.

## ما يعرضه Seerr {#what-seerr-shows}

يقرأ Seerr قائمة DMM مرة واحدة كل يوم في **Radarr Scan** و**Sonarr Scan**. لتشغيلهما الآن، افتح
**Settings → Jobs & Cache** واضغط **Run Now** بجوار كل واحد منهما.

- **الفيلم** الذي جلبه zurg يظهر بحالة **Available**.

  ![فيلم تم جلبه يظهر بحالة متاحة](../assets/seerr-dmm/06-seerr-movie-available.webp)

- **المسلسل** يبقى بحالة **Processing** حتى تصل حلقاته إلى مكتبة Plex أو Jellyfin أو Emby الخاصة بك، ويعثر فحص Seerr لذلك الخادم عليها. DMM لا يعرف أي حلقات يحتفظ بها zurg.

## إزالة عنوان {#removing-a-title}

فتح العنوان في Seerr، ثم اضغط على زر الترس واختر **Remove from Radarr** (أو **Remove from Sonarr**). سيؤدي ذلك إلى إزالته من قائمة المطلوبات لديك. ما جلبه zurg بالفعل يبقى في مكتبتك. **Open in Radarr** بجانبه يفتح العنوان على DMM.

هل تحتاج إلى مساعدة؟ اسأل في منتدى **dmm-support** على [Discord](https://discord.com/invite/7u4YjMThXP). صفحة [Getting help](../guides/remote-help.md) تشرح ما يجب تضمينه.

## Seerr عبر DMM أو مصدر Seerr الخاص بـ zurg {#seerr-through-dmm-or-zurgs-own-seerr-source}

zurg يمكنه أيضًا قراءة Seerr نفسه، عبر [`seerr` source](../zurg/guides/acquisition.md#configuration).
اختر واحدًا من الاثنين، لا كليهما:

- **عبر DMM**، يحتاج Seerr فقط إلى الوصول إلى الإنترنت. تظهر الطلبات في قائمة **المطلوب** لديك بجانب ما أضفته بزر **Want**، ويقوم الفحص اليومي لـ Seerr بوضع علامة متاح على الأفلام التي جلبها zurg.
- **مصدر zurg الخاص** يتعامل مع طلب 4K بشكل منفصل عن طلب 1080p، لكن يجب أن يكون zurg قادرًا على الوصول إلى Seerr.
