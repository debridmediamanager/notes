# ما الذي تحصل عليه من الرعاية {#what-a-sponsorship-gives-you}

DMM مجاني. رعاية الداعمين تغطي تكلفة استضافته وتُبقي zurg و rex يعملان. تعرض هذه الصفحة كل الميزات وأين تُفعّلها.

ارعَ DMM عبر [gatekeeper](https://gatekeeper.debridmediamanager.com/). سجّل الدخول هناك لترى مفتاح DMM API الخاص بك. **Open DMM with this key** يربطه بالمتصفح الذي تستخدمه. أضف المفتاح نفسه في الخدمات الأخرى التي تطلبه. احتفظ به سرياً لأنه يعمل مثل كلمة المرور.

الميزات تتبع الرعاية. عندما تنتهي الرعاية يوقفها DMM عند الطلب التالي. إضافات Jellyfin وEmby التي ثبّتها من قبل تستمر في العمل، لكن التنزيلات الجديدة والتحديثات تتوقف. يسحب gatekeeper صلاحية الوصول إلى zurg ودور Discord في فحصه التالي. **Reset key** يوقف المفتاح القديم في كل مكان دفعة واحدة.

## zurg

| ما ستحصل عليه | أين |
|---|---|
| البنيات الليلية مع كل المزودين وUsenet مع صورة Docker | [إعداد zurg](../zurg/setup/index.md) بعد قبول دعوة GitHub |
| تطبيق zurg+rex على Android، وخادم Plex على هاتفك | [دليل Android](../zurg/guides/android.md) بعد قبول دعوة GitHub |
| الكود المصدري الكامل لـ zurg | المستودع الخاص على GitHub |
| كل إصدار مُسمّى حسب rex وPlex | `dmm_api_key` في [إعدادات zurg](../zurg/reference/config.md) |
| تفاصيل الوسائط من DMM دون قراءة الملف أولاً، وفحص اللغات قبل إضافة أي إصدار | لا شيء إضافي غير `dmm_api_key` |
| مجلدات `__magic__` مرتّبة تلقائياً عند التفعيل | [\_\_السحر\_\_](../zurg/guides/magic.md) |
| قائمة الرغبات الخاصة بك في DMM يجلبها zurg | [قائمة الرغبات في DMM](../zurg/guides/dmm-wanted.md) |
| البحث في فهارس Usenet والتورنت الخاصة بـ DMM عندما لا يكون لديك فهارس خاصة بك | `dmm_api_key` مع مزود Usenet أو حساب debrid يمكنه إضافة التورنتات |
| اختيار الإصدارات حسب اللغة الأصلية لكل عنوان | `original` في [لغات الصوت والترجمة](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| فيلم مطلوب لا يوجد في أي فهرس يُبثّ من نسخته الرسمية على YouTube | [بث فيلم من YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

تحتاج ميزات `dmm_api_key` إلى بناء ليلي من zurg. البناء العام المجاني لا يتضمنها.

## DMM

| ما تحصل عليه | المكان |
|---|---|
| قائمة مطلوبات (wanted list) يجلبها zurg مع الحلقات الجديدة والترقيات. املأها من DMM أو Kodi أو Trakt، أو من قوائم MDBList وTMDB وSimkl، أو من نسخة احتياطية لـ Radarr أو Sonarr | [قائمة DMM المطلوبة](../zurg/guides/dmm-wanted.md) |
| الطلبات من Seerr أو Overseerr أو Jellyseerr تصل إلى قائمة المطلوبات لديك | [Seerr عبر DMM](../dmm/seerr.md) |
| أي نتيجة من Easynews ترسلها إلى zurg بنقرة واحدة | نتائج Easynews في صفحة الفيلم أو المسلسل على DMM |
| DMM كفهرس Newznab لـ Usenet | [صفحة Newznab](https://debridmediamanager.com/newznab) الخاصة بـ DMM |
| DMM كفهرس Torznab مع خلاصات مخزنة مؤقتاً فقط لـ Real-Debrid وAllDebrid وDebrid-Link وTorBox وPremiumize وOffcloud | [صفحة Torznab](https://debridmediamanager.com/torznab) الخاصة بـ DMM. تحتاج TorBox وPremiumize وOffcloud أيضاً إلى مفتاح الخدمة المرتبطة بها |
| سبعة إضافات Jellyfin لمكتبات debrid وUsenet، وست إضافات Emby لمكتبات debrid بدون أي شيء مركّب | صفحتا [Jellyfin](https://debridmediamanager.com/jellyfin) و[Emby](https://debridmediamanager.com/emby) الخاصتان بـ DMM |
| عشرة تدفقات إضافية لكل عنوان في Stremio Cast وKodi بدلاً من خمسة | إعدادات DMM لـ Real-Debrid وTorBox وAllDebrid؛ وصفحة Cast الخاصة بكل مزوّد للبقية |
| رفع NZB يأتي أولاً مع 2 TB من Usenet يومياً بدلاً من 300 GB | تبويب Usenet في DMM |
| الأولوية والحصة نفسهما لـ Sonarr وRadarr | مفتاح API الخاص بك في DMM كـ Password في [صفحة SABnzbd](https://debridmediamanager.com/sabnzbd) الخاصة بـ DMM |
| ثلاثة رفعات torrent إلى Real-Debrid في وقت واحد بدلاً من واحد | أزرار الرفع في نتائج البحث وفي المكتبة على DMM |
| Add to DMM Wanted ومجلد Wanted داخل Kodi | اقرن Kodi من [صفحة Kodi](https://debridmediamanager.com/kodi) الخاصة بـ DMM |
| واجهة DMM API لأسماء الإصدارات وفحوصات التخزين المؤقت وتفاصيل الوسائط والبيانات الوصفية | [وثائق API](https://debridmediamanager.com/api-docs) |

## rex

rex مجاني ولا يحتاج إلى رعاية، وهذا ينطبق على Android أيضًا: [rex لأندرويد](../rex/android.md) يشغّل rex وإضافاته على الهاتف أو على جهاز TV box. أما الرعاة فيحصلون كذلك على zurg+rex (في الجدول أعلاه)، وهذا يربط مكتبة debrid وUsenet الخاصة بهم بـ rex على الجهاز. ومع مفتاح، يضيف [rex-stremio](../rex/stremio.md) تدفقات debrid للتورنتات التي يحتفظ بها DMM بالفعل بفحص جاهز، فتظهر في ثوانٍ بدلًا من فحص كل تورنت على حدة. الصق المفتاح في حقل **DMM** داخل rex-stremio. وهو يشارك فحوصاته لملفات التورنت مع DMM ما لم تُوقف هذه الخاصية.

## مساعدة {#help}

| ما تحصل عليه | أين |
|---|---|
| مساعدة عن بُعد مجانية مع zurg و rex في الطرفية الخاصة بك بينما تشاهد | [الحصول على المساعدة](remote-help.md) |
| دور Sponsor على Discord | ربط Discord في gatekeeper |

## اكسبها دون أن تدفع {#earn-it-without-paying}

لملء الطلبات على [لوحة الطلبات](https://debridmediamanager.com/requests) في DMM. كل 10 طلبات تمنحك 7 أيام من مزايا DMM المذكورة أعلاه. لا يُحتسب إلا ملء واحد لنفس الشخص في اليوم الواحد. اربط المفتاح من حساب gatekeeper مجاني على اللوحة لتحصل عليها.

الوقت المكتسب يفتح جدول DMM المذكور أعلاه فقط. لا يفتح zurg nightly أو الشيفرة المصدرية أو دور Discord أو المساعدة عن بُعد أو تطبيق Android. هذه تحتاج رعاية مدفوعة. كما أن ميزات `dmm_api_key` تحتاج إلى nightly.

إذا علقت في أمر ما، اسأل في منتدى **dmm-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
