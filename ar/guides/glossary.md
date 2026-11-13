# ما الذي تفعله كل قطعة {#what-each-piece-does}

الأسماء وحدها لا تخبرك بما يفعله كل شيء، لذا إليك سطرًا واحدًا لكل منها. لمعرفة أيّها تحتاج، استخدم [اختر إعدادك](choose-your-setup.md).

## المشاريع الثلاثة {#the-three-projects}

| الاسم | ماذا يفعل |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | موقع لإيجاد الإصدارات وإضافتها إلى حساب الـ debrid الخاص بك. كما يبحث في Usenet وEasynews. مجاني |
| [zurg](../zurg/index.md) | كل حسابات الـ debrid وUsenet في مجلد واحد. تقرأ Plex وJellyfin وEmby وInfuse وrex هذا المجلد كأنه قرص عادي. للرعاة |
| [rex](../rex/index.md) | خادم وسائط لا يملك أي ملفات. مصادره تخبره بما لديها، وكل تطبيق Plex يشغّله. مجاني للاستخدام الشخصي |

## المشاهدة مباشرةً من DMM {#watching-straight-from-dmm}

لا يلزم أي خادم لأي من هذه.

| الاسم | ما الذي تفعله |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio/) | إضافة Stremio تشغّل الإصدارات من حسابك على debrid أو Easynews |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | تصفّح حسابك على debrid أو Easynews وابحث فيه وشغّل منه داخل Kodi |
| DMM Watch | زر في DMM يفتح الملف في مشغّلك الخاص، مثل VLC أو Infuse |
| [DMM Music](https://debridmediamanager.com/music/) | شغّل الموسيقى من Real-Debrid ونزّلها في متصفحك |

## تغذية rex {#feeding-rex}

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Verwandelt deine Stremio-Addons in rex-Bibliotheken, damit sie in Plex-Apps abgespielt werden. Kostenlos |
| [rex addons](../rex/addons.md) | Kleine Programme, die rex etwas zum Abspielen geben: YouTube, Spotify, IPTV, Heimvideos oder was auch immer du schreibst |
| [rex for Android](../rex/android.md) | rex und seine Addons auf einem Android-Handy oder einer TV-Box, ganz ohne Computer. Kostenlos. Für deine Debrid- und Usenet-Bibliothek nutzen Sponsoren zurg+rex |
| [zurg+rex for Android](../zurg/guides/android.md) | Ein Plex-Server auf deinem Handy: zurg und rex gemeinsam auf einem Android-Gerät. Für Sponsoren |

## داخل Jellyfin وEmby {#inside-jellyfin-and-emby}

| الاسم | وظيفته |
|---|---|
| [RD، AD، TB، PM، OC وDL zurg](https://debridmediamanager.com/jellyfin) | إضافة منفصلة لكل مزوّد debrid. تظهر مكتبة debrid الخاصة بك في Jellyfin أو [Emby](https://debridmediamanager.com/emby) دون أي تطبيق zurg أو تركيب. للرعاة |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | إضافة Jellyfin تبثّ ملفات NZB عبر حساب Usenet الخاص بك. للرعاة |

## إضافة العناوين نيابةً عنك {#adding-titles-for-you}

| الاسم | ماذا يفعل |
|---|---|
| [المطلوبات](../zurg/guides/dmm-wanted.md) | اضغط **Want** في DMM وسيجلبه zurg لك، بما في ذلك الحلقات الجديدة. للرعاة |
| [Seerr عبر DMM](../dmm/seerr.md) | طلبات العائلة في Seerr تذهب إلى قائمة Wanted الخاصة بك. للرعاة |
| [Torznab و Newznab](https://debridmediamanager.com/torznab) | DMM كمفهرس لـ Sonarr وRadarr وProwlarr، مع zurg كعميل تنزيل. للرعاة |
| [إضافة zurg لـ Stremio](../zurg/guides/stremio.md) | تبحث في Usenet عندما تضغط تشغيل في Stremio وتبثه عبر zurg |
| [`__magic__`](../zurg/guides/magic.md) | مجلد zurg ترتّبه بنفسك، أو تدع Sonarr وRadarr يرتّبانه |

## بقية DMM {#the-rest-of-dmm}

| الاسم | وظيفته |
|---|---|
| [لوحة الطلبات](https://debridmediamanager.com/requests) | اطلب إصدارًا لا يملكه Real-Debrid. يقوم مستخدم آخر في DMM بنقله إلى مكتبتك. ملء الطلبات يمنحك مزايا الرعاية في DMM |
| [قوائم الهاش](https://debridmediamanager.com/hashlists) | شارك قائمة بالإصدارات حتى يتمكن الآخرون من إضافتها إلى حساباتهم |
| [إضافة المتصفح](../dmm/safari.md) | تضيف أزرار DMM إلى مواقع الأفلام والمسلسلات وبجوار روابط magnet |
| [صفحة الرعاية](https://gatekeeper.debridmediamanager.com) | المكان الذي ترعى فيه المشروع وتربط اشتراكك في Patreon أو GitHub Sponsors. [ما الذي تمنحه الرعاية لك](sponsorship.md) |

## المصطلحات التي ستراها في الأدلة {#words-youll-see-in-the-guides}

| Word | What it means |
|---|---|
| Debrid provider | خدمة مدفوعة تنزّل التورنتات نيابةً عنك وتتيح لك بثّها: Real-Debrid وAllDebrid وTorBox وPremiumize وOffcloud وDebrid-Link |
| Cached | المزوّد لديه الإصدار بالفعل، لذلك يعمل التشغيل فوراً |
| Usenet | مصدر آخر للإصدارات. تحتاج إلى حساب لدى مزوّد Usenet، أو إلى TorBox Pro ليقوم بذلك عنك |
| NZB | ملف صغير يحدد مكان إصدار Usenet، تماماً كما يفعل ملف التورنت مع التورنتات |
| Indexer | موقع بحث عن الإصدارات. يستخدم Sonarr وRadarr واحداً منها للعثور على الأشياء |
| WebDAV | طريقة لمشاركة الملفات عبر الويب. يمكن لـ Infuse وKodi وكثير من مشغّلات التلفاز فتحه |
| Mount | يجعل مجلد zurg يبدو كقرص محلي، فيستطيع Plex أو Jellyfin أو Emby فحصه |
| Plex Media Server vs Plex apps | الخادم يحتفظ بمكتبتك، والتطبيقات على التلفاز والهاتف تشغّلها. يحلّ rex محل الخادم، لا محل التطبيقات |
