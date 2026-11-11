# ما الذي تحصل عليه من الرعاية {#what-a-sponsorship-gives-you}

DMM مجاني. الرعاة يدفعون تكلفة استضافته ويبقون zurg وrex يعملان. هذه الصفحة تشرح كل ميزة وأين تفعّلها.

تقدر ترعى عبر [gatekeeper](https://gatekeeper.debridmediamanager.com/). سجّل الدخول هناك لتشوف مفتاح DMM API الخاص بك. **Open DMM with this key** يربطه في هذا المتصفح. أضف نفس المفتاح في الخدمات الأخرى اللي تطلبه. خليه سرًا لأنه يشتغل مثل كلمة المرور.

الميزات تتبع الرعاية. لما تنتهي، DMM يوقفها عند الطلب التالي. Gatekeeper يلغي وصول zurg ودور Discord في فحصه التالي. **Reset key** يوقف المفتاح القديم في كل مكان مرة واحدة.

## zurg

| ما ستحصل عليه | أين |
|---|---|
| البنيات الليلية مع كل المزودين وUsenet مع صورة Docker | [إعداد zurg](../zurg/setup/index.md) بعد قبول دعوة GitHub |
| تطبيق zurg+rex على Android، وخادم Plex على هاتفك | [دليل Android](../zurg/guides/android.md) بعد قبول دعوة GitHub |
| الكود المصدري الكامل لـ zurg | المستودع الخاص على GitHub |
| كل إصدار مُسمّى حسب rex وPlex | `dmm_api_key` في [إعدادات zurg](../zurg/reference/config.md) |
| تفاصيل الوسائط من DMM دون قراءة الملف أولاً، وفحص اللغات قبل إضافة أي إصدار | لا شيء إضافي غير `dmm_api_key` |
| مجلدات `__magic__` مرتّبة تلقائياً عند التفعيل | [\_\_magic\_\_](../zurg/guides/magic.md) |
| قائمة الرغبات الخاصة بك في DMM يجلبها zurg | [قائمة الرغبات في DMM](../zurg/guides/dmm-wanted.md) |
| البحث في فهارس Usenet والتورنت الخاصة بـ DMM عندما لا يكون لديك فهارس خاصة بك | `dmm_api_key` مع مزود Usenet أو حساب debrid يمكنه إضافة التورنتات |
| اختيار الإصدارات حسب اللغة الأصلية لكل عنوان | `original` في [لغات الصوت والترجمة](../zurg/guides/acquisition.md#choosing-by-audio-and-subtitle-language) |
| فيلم مطلوب لا يوجد في أي فهرس يُبثّ من نسخته الرسمية على YouTube | [بث فيلم من YouTube](../zurg/guides/acquisition.md#streaming-a-film-from-youtube) |

تحتاج ميزات `dmm_api_key` إلى بناء ليلي من zurg. البناء العام المجاني لا يتضمنها.

## DMM

| ما ستحصل عليه | أين |
|---|---|
| قائمة مطلوبات يجلبها zurg مع الحلقات الجديدة والترقيات. تعبئها من DMM أو Kodi أو قوائم Trakt وMDBList أو نسخة احتياطية من Radarr أو Sonarr | [قائمة DMM المطلوبة](../zurg/guides/dmm-wanted.md) |
| الطلبات من Seerr أو Overseerr أو Jellyseerr تصل إلى قائمة المطلوبات لديك | [Seerr عبر DMM](../dmm/seerr.md) |
| أي نتيجة من Easynews ترسلها إلى zurg بنقرة واحدة | نتائج Easynews في صفحة الفيلم أو المسلسل على DMM |
| DMM كفهرس Newznab لشبكة Usenet | [صفحة Newznab](https://debridmediamanager.com/newznab) في DMM |
| DMM كفهرس Torznab مع خلاصات مخزنة فقط لـ Real-Debrid وAllDebrid وDebrid-Link وTorBox وPremiumize وOffcloud | [صفحة Torznab](https://debridmediamanager.com/torznab) في DMM. تحتاج TorBox وPremiumize وOffcloud أيضاً إلى مفتاح الخدمة المرتبط بها |
| سبعة إضافات لـ Jellyfin لمكتبات debrid وUsenet، وست إضافات لـ Emby لمكتبات debrid دون أي شيء مركب | صفحتا [Jellyfin](https://debridmediamanager.com/jellyfin) و[Emby](https://debridmediamanager.com/emby) في DMM |
| عشرة مصادر بث إضافية لكل عنوان في Stremio Cast وKodi بدلاً من خمسة | إعدادات DMM لـ Real-Debrid وTorBox وAllDebrid؛ وصفحة Cast الخاصة بكل مزود للباقين |
| رفع ملفات NZB يأتي أولاً مع 2 TB من Usenet يومياً بدلاً من 300 GB | تبويب Usenet في DMM |
| الأولوية والحصة نفسها لـ Sonarr وRadarr | مفتاح API الخاص بك في DMM كـ Password في [صفحة SABnzbd](https://debridmediamanager.com/sabnzbd) في DMM |
| ثلاثة رفعات لملفات torrent إلى Real-Debrid في الوقت نفسه بدلاً من واحد | أزرار الرفع في نتائج البحث والمكتبة في DMM |
| Add to DMM Wanted ومجلد Wanted داخل Kodi | اقرن Kodi من [صفحة Kodi](https://debridmediamanager.com/kodi) في DMM |
| استعادة إعداداتك على جهاز آخر بعد تسجيل الدخول بمفتاح الراعي | Settings في DMM |
| واجهة DMM API لأسماء الإصدارات وفحوصات التخزين المؤقت وتفاصيل الوسائط والبيانات الوصفية | [توثيق API](https://debridmediamanager.com/api-docs) |

## rex

rex مجاني ولا يحتاج إلى رعاية. نسخة Android منه تأتي فقط داخل تطبيق zurg+rex الخاص بالرعاة. مع مفتاح، يضيف [rex-stremio](../rex/stremio.md) بثوثات debrid لملفات التورنت التي يملك DMM فحصها مسبقًا، فتظهر خلال ثوانٍ بدلًا من فحص كل واحد منها. الصق المفتاح في حقل **DMM** داخل rex-stremio. ويتشارك مع DMM نتائج فحص ملفات التورنت ما لم تعطّل هذا الخيار.

## مساعدة {#help}

| ما تحصل عليه | أين |
|---|---|
| مساعدة عن بُعد مجانية مع zurg و rex في الطرفية الخاصة بك بينما تشاهد | [الحصول على المساعدة](remote-help.md) |
| دور Sponsor على Discord | ربط Discord في gatekeeper |

## اكسبها دون أن تدفع {#earn-it-without-paying}

لملء الطلبات على [لوحة الطلبات](https://debridmediamanager.com/requests) في DMM. كل 10 طلبات تمنحك 7 أيام من مزايا DMM المذكورة أعلاه. لا يُحتسب إلا ملء واحد لنفس الشخص في اليوم الواحد. اربط المفتاح من حساب gatekeeper مجاني على اللوحة لتحصل عليها.

الوقت المكتسب يفتح جدول DMM المذكور أعلاه فقط. لا يفتح zurg nightly أو الشيفرة المصدرية أو دور Discord أو المساعدة عن بُعد أو تطبيق Android. هذه تحتاج رعاية مدفوعة. كما أن ميزات `dmm_api_key` تحتاج إلى nightly.

إذا علقت في أمر ما، اسأل في منتدى **dmm-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
