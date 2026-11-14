# ما الذي تفعله كل قطعة {#what-each-piece-does}

إذا لم تكن الأسماء واضحة بما يكفي لمعرفة وظيفة كل منها، فإليك سطر واحد لكل منها. كل ما ليس مميزًا بعبارة **For sponsors** مجاني. ولمعرفة ما تحتاجه منها، استخدم [Choose your setup](choose-your-setup.md).

## المشاريع الثلاثة {#the-three-projects}

| الاسم | ماذا يفعل |
|---|---|
| [DMM](https://debridmediamanager.com) (Debrid Media Manager) | موقع لإيجاد الإصدارات وإضافتها إلى حسابك على debrid. كما يبحث في Usenet وEasynews |
| [zurg](../zurg/index.md) | يجمع كل حسابات debrid وUsenet في مكتبة واحدة. يقرأها Plex وJellyfin وEmby كمجلد، ويقرأها Infuse وKodi عبر WebDAV، ويصل إليها rex مباشرة. الإصدارات الحالية مخصصة للداعمين |
| [rex](../rex/index.md) | خادم وسائط لتطبيقات Plex لا يحتوي على ملفات خاصة به. يخبره zurg أو إضافة ما الموجود. مجاني للاستخدام الشخصي |

## المشاهدة مباشرةً من DMM {#watching-straight-from-dmm}

لا حاجة إلى أي خادم لأي من هذه.

| الاسم | ماذا تفعل |
|---|---|
| [DMM Cast](https://debridmediamanager.com/stremio) | إضافة Stremio تشغّل الإصدارات من حسابك في debrid أو Easynews. تعمل أيضًا في Nuvio |
| [DMM Kodi addon](https://debridmediamanager.com/kodi) | تصفّح وابحث وشغّل من حسابك في debrid أو Easynews داخل Kodi |
| DMM Watch | زر في DMM يفتح الملف في مشغّلك الخاص، مثل VLC أو Infuse |

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
| Release | نسخة واحدة من فيلم أو حلقة أو موسم كما نشرها أحدهم. عادةً يكون للعنوان الواحد نسخ كثيرة بجودات مختلفة |
| مزوّد Debrid | خدمة مدفوعة تنزّل التورنتات نيابةً عنك وتتيح لك بثّها: Real-Debrid وAllDebrid وTorBox وPremiumize وOffcloud وDebrid-Link |
| Cached | المزوّد يملك الإصدار بالفعل، لذا يُشغَّل فوراً |
| Usenet | مصدر آخر للإصدارات. استخدم حسابك الخاص في Usenet، أو دع TorBox Pro أو Easynews يتولّى الأمر، أو اطلب من DMM إرسال نتيجة إلى Real-Debrid |
| Easynews | خدمة Usenet مدفوعة لها بحثها الخاص، وتشغّل الملفات مباشرةً عبر الويب |
| NZB | ملف صغير يحدد مكان إصدار Usenet، تماماً كما يفعل ملف التورنت مع التورنتات |
| مفهرِس | موقع بحث عن الإصدارات. تستخدمه Sonarr وRadarr للعثور على المحتوى |
| Sonarr وRadarr وProwlarr | تطبيقات تجلب العناوين نيابةً عنك: Sonarr للمسلسلات وRadarr للأفلام. أما Prowlarr فيجمع المفهرِسات الخاصة بهما في مكان واحد |
| Seerr | موقع طلبات للعائلة والأصدقاء. Overseerr وJellyseerr يعملان بالطريقة نفسها |
| Stremio وNuvio وKodi | تطبيقات لتشغيل الوسائط. الإضافات تزوّدها بما تشغّله. وNuvio يقبل إضافات Stremio |
| مفتاح DMM API | مفتاح خاص بالداعم من gatekeeper. الصقه حيث يطلبه الدليل، واحفظه بسرية كما تحفظ كلمة المرور |
| Nightly | أحدث نسخة من zurg أو rex، وتُبنى كل ليلة. نسخ zurg الليلية مخصصة للداعمين |
| WebDAV | طريقة لمشاركة الملفات عبر الويب. يستطيع Infuse وKodi وكثير من مشغّلات التلفاز فتحها |
| Mount | يجعل مجلد zurg يبدو كأنه قرص محلي، فتتمكن Plex أو Jellyfin أو Emby من فحصه |
| rclone | الأداة التي يستخدمها zurg لإنشاء الربط. إعداد zurg يحصل عليها لك |
| `.strm` | ملف صغير يحمل رابطاً بدلاً من الفيديو، وذلك لمشغّلات مثل Kodi |
| Source | أي شيء يخبر rex بما لديه ويقدّم الملفات، مثل zurg أو rex-stremio أو إحدى الإضافات |
| Claim | ربط rex بحساب Plex، ليتمكن من عرض العناوين والملصقات ويجد تطبيقات Plex الخادم |
| Plex Media Server مقابل تطبيقات Plex | الخادم يحتوي مكتبتك. أما التطبيقات على التلفاز والهاتف فتشغّلها. rex يحل محل الخادم، لا محل التطبيقات |
