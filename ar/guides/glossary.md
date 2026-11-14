# ما الذي تفعله كل قطعة {#what-each-piece-does}

إذا لم تكن الأسماء واضحة بما يكفي لمعرفة وظيفة كل منها، فإليك سطر واحد لكل منها. كل ما ليس مميزًا بعبارة **For sponsors** مجاني. ولمعرفة ما تحتاجه منها، استخدم [Choose your setup](choose-your-setup.md).

## المشاريع الثلاثة {#the-three-projects}

| الاسم | ماذا يفعل |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | موقع لإيجاد الإصدارات وإضافتها إلى حسابك على debrid. كما يبحث في Usenet وEasynews |
| [zurg](../zurg/index.md) | يجمع كل حسابات debrid وUsenet في مكتبة واحدة. يقرأها Plex وJellyfin وEmby كمجلد، ويقرأها Infuse وKodi عبر WebDAV، ويصل إليها rex مباشرة. الإصدارات الحالية مخصصة للداعمين |
| [rex](../rex/index.md) | خادم وسائط لتطبيقات Plex لا يحتوي على ملفات خاصة به. يخبره zurg أو إضافة ما الموجود. مجاني للاستخدام الشخصي |

## المشاهدة مباشرةً من DMM {#watching-straight-from-dmm}

لا حاجة لأي خادم لأي من هذه.

| الاسم | ماذا يفعل |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | إضافة لـ Stremio تشغّل الإصدارات من حسابك في debrid أو Easynews |
| [إضافة DMM لـ Kodi](https://debridmediamanager.com/kodi) | تصفّح وابحث وشغّل من حسابك في debrid أو Easynews داخل Kodi |
| DMM Watch | زر في DMM يفتح الملف في مشغّلك الخاص، مثل VLC أو Infuse |
| [DMM Music](https://debridmediamanager.com/music) | شغّل الموسيقى ونزّلها من Real-Debrid في متصفحك |

## تغذية rex {#feeding-rex}

| Name | What it does |
|---|---|
| [rex-stremio](../rex/stremio.md) | Turns your Stremio addons into rex libraries, so they play in Plex apps |
| [rex addons](../rex/addons.md) | Kleine Programme, die rex etwas zum Abspielen geben: YouTube, Spotify, IPTV, Heimvideos oder was auch immer du schreibst |
| [rex-live-sports](../rex/live-tv.md) | Ein rex-Addon, das Live-Sport-Kanäle und einen Programmführer in die Live-TV-Funktion der Plex-Apps bringt |
| [rex-direct](../rex/any-source.md#rex-direct) | Gibt deinem rex seine eigene sichere Adresse, damit die Plex-Apps auch von unterwegs drankommen |
| [rex for Android](../rex/android.md) | rex und seine Addons auf einem Android-Handy oder einer Android-TV-Box, ganz ohne Computer |
| [zurg+rex for Android](../zurg/guides/android.md) | Ein Plex-Server auf deinem Handy: zurg und rex zusammen auf einem Android-Gerät, mit deiner Debrid- und Usenet-Bibliothek. Für Sponsoren |

## داخل Jellyfin وEmby {#inside-jellyfin-and-emby}

| الاسم | ماذا يفعل |
|---|---|
| [إضافات Debrid](https://debridmediamanager.com/jellyfin) (RD zurg، AD zurg، TB zurg، PM zurg، OC zurg، DL zurg) | إضافة واحدة لكل مزود debrid: Real-Debrid وAllDebrid وTorBox وPremiumize وOffcloud وDebrid-Link. تظهر مكتبة debrid الخاصة بك في Jellyfin أو [Emby](https://debridmediamanager.com/emby) دون الحاجة إلى تطبيق zurg أو أي mount. للرعاة |
| [NZB zurg](https://debridmediamanager.com/jellyfin) | إضافة Jellyfin تبث ملفات NZB عبر حساب Usenet الخاص بك. للرعاة |

## إضافة العناوين نيابةً عنك {#adding-titles-for-you}

| Name | What it does |
|---|---|
| [Wanted](../zurg/guides/dmm-wanted.md) | اضغط **Want** في DMM وسيجلبه zurg الخاص بك، والحلقات الجديدة تُضاف تلقائيًا. للرعاة |
| [Seerr through DMM](../dmm/seerr.md) | طلبات العائلة في Seerr تذهب إلى قائمة Wanted الخاصة بك. للرعاة |
| [Torznab](https://debridmediamanager.com/torznab) and [Newznab](https://debridmediamanager.com/newznab) | DMM كمفهرس لـ Sonarr وRadarr وProwlarr. للرعاة |
| zurg as the download client | zurg يرد على Sonarr وRadarr كـ qBittorrent للـ [torrents](../zurg/guides/sonarr-radarr-torrents.md) وكـ SABnzbd للـ [Usenet](../zurg/guides/sonarr-radarr.md)، فلا تحتاج لتشغيل أيٍّ منهما. للرعاة |
| [zurg's Stremio addon](../zurg/guides/stremio.md) | يبحث في Usenet عندما تضغط تشغيل في Stremio ويبثه عبر zurg. للرعاة |
| [`__magic__`](../zurg/guides/magic.md) | مجلد zurg ترتبه بنفسك، أو تتركه لـ Sonarr وRadarr يرتبانه. للرعاة |

## بقية DMM {#the-rest-of-dmm}

| الاسم | ماذا يفعل |
|---|---|
| Usenet tab | يرسل إصدارًا من Usenet إلى مكتبة Real-Debrid الخاصة بك، دون الحاجة إلى حساب Usenet. يحصل الرعاة على الأولوية ويحصلون على حصة يومية أكبر |
| [طلبات](https://debridmediamanager.com/requests) | اطلب إصدارًا غير متوفر في Real-Debrid. يقوم مستخدم آخر في DMM بنقله إلى مكتبتك. قدّم 10 طلبات واحصل على 7 أيام من مزايا رعاة DMM |
| [قوائم Hash](https://debridmediamanager.com/hashlists) | شارك قائمة بالإصدارات حتى يتمكن الآخرون من إضافتها إلى حساباتهم |
| إضافة المتصفح | تضيف أزرار DMM إلى مواقع الأفلام والمسلسلات وبجانب روابط magnet. متوفرة لـ [Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) و[Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/) و[Safari](../dmm/safari.md) |
| [gatekeeper](https://gatekeeper.debridmediamanager.com) | موقع الرعاة. ادعم المشروع هناك، واربط اشتراكك في Patreon أو GitHub Sponsors، واحصل على مفتاح API الخاص بـ DMM. [ما الذي تمنحه الرعاية](sponsorship.md) |

## المصطلحات التي ستراها في الأدلة {#words-youll-see-in-the-guides}

| الكلمة | معناها |
|---|---|
| Release | نسخة واحدة من فيلم أو حلقة أو موسم كما نشرها شخص ما. العنوان عادةً له نسخ كثيرة بجودات مختلفة |
| Debrid provider | خدمة مدفوعة تنزّل التورنتات نيابةً عنك وتتيح لك بثها: Real-Debrid وAllDebrid وTorBox وPremiumize وOffcloud وDebrid-Link |
| Cached | المزوّد يملك الإصدار مسبقاً، لذلك يُشغَّل فوراً |
| Usenet | مكان آخر للحصول على الإصدارات. استخدم حساب Usenet الخاص بك، أو دع TorBox Pro أو Easynews يتولّون ذلك، أو اطلب من DMM إرسال نتيجة إلى Real-Debrid |
| Easynews | خدمة Usenet مدفوعة لها بحث خاص بها، وتشغّل الملفات مباشرةً عبر الويب |
| NZB | ملف صغير يحدد مكان إصدار Usenet، مثلما يفعل ملف التورنت مع التورنتات |
| Indexer | موقع بحث عن الإصدارات. يستخدمه Sonarr وRadarr للعثور على الأشياء |
| Sonarr, Radarr and Prowlarr | تطبيقات تجلب العناوين لك: Sonarr للمسلسلات وRadarr للأفلام. Prowlarr يجمع الـ indexers الخاصة بها في مكان واحد |
| Seerr | موقع طلبات للعائلة والأصدقاء. Overseerr وJellyseerr يعملان بالطريقة نفسها |
| Stremio and Kodi | تطبيقات مشغّلات وسائط. الإضافات (Addons) تزوّدها بما تشغّله |
| DMM API key | مفتاح راعٍ من gatekeeper. الصقه حيث يطلب الدليل، واحتفظ به سرّياً كأنه كلمة مرور |
| Nightly | أحدث نسخة من zurg أو rex، وتُبنى كل ليلة. نسخ zurg الليلية مخصصة للرعاة |
| WebDAV | طريقة لمشاركة الملفات عبر الويب. يمكن لـ Infuse وKodi وكثير من مشغّلات التلفاز فتحها |
| Mount | يجعل مجلد zurg يبدو كقرص محلي، حتى تستطيع Plex أو Jellyfin أو Emby فحصه |
| rclone | الأداة التي يستخدمها zurg لإنشاء الـ mount. إعداد zurg يحضّرها لك |
| `.strm` | ملف صغير يحمل رابطاً بدلاً من الفيديو، لمشغّلات مثل Kodi |
| Source | أي شيء يخبر rex بما لديه ويقدّم الملفات: zurg أو rex-stremio أو إضافة (addon) |
| Claim | ربط rex بحساب Plex، فيتمكن من عرض العناوين والملصقات وتجد تطبيقات Plex له |
| Plex Media Server vs Plex apps | الخادم يحتفظ بمكتبتك. التطبيقات على التلفاز وهاتفك تشغّلها. rex يحل محل الخادم، وليس محل التطبيقات |
