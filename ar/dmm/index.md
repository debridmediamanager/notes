# DMM

[Debrid Media Manager](https://debridmediamanager.com) يساعدك على العثور على الأفلام والمسلسلات والاحتفاظ بها في مكتبة debrid الخاصة بك.

للمشاهدة في Stremio، أضف الإضافة الخاصة بـ DMM، وهي DMM Cast. يوضح [DMM في Stremio](stremio.md) الطريقة.

تضيف إضافة DMM للمتصفح زرًا إلى IMDb وTrakt ومواقع الأفلام والمسلسلات الأخرى. يشرح [أزرار DMM في Safari](safari.md) إعداد Safari.

كما يعمل DMM مع المشاريع الأخرى:

- **zurg** يسأل DMM عن الفيلم أو الحلقة التي يمثلها كل ملف. يحصل الراعي على مفتاح API الخاص بـ DMM من [gatekeeper](https://gatekeeper.debridmediamanager.com/). بدون هذا المفتاح يعتمد zurg على أسماء الملفات، فتتطابق عناوين أقل. يشرح [rex مع zurg](../rex/with-zurg.md#why-dmm-places-the-files) الفرق.
- **Sonarr Radarr and Prowlarr** يمكنها البحث في DMM كفهرس torrent من نوع Torznab، أو كفهرس Usenet من نوع Newznab. يتطلب الأمر رعاية نشطة ومفتاح API الخاص بـ DMM. اضبطها في صفحتي [Torznab](https://debridmediamanager.com/torznab) و[Newznab](https://debridmediamanager.com/newznab).
- **قائمة الرغبات الخاصة بك**: اضغط **Want** أو اتبع قائمة Trakt أو MDBList. يجلب zurg القائمة والحلقات الجديدة فور عرضها. يتطلب رعاية نشطة. انظر [قائمة الرغبات في DMM](../zurg/guides/dmm-wanted.md).
- **Seerr Overseerr and Jellyseerr** يمكنها استخدام DMM كـ Radarr وSonarr. تصل الطلبات بعد ذلك إلى قائمة الرغبات، ليجلبها zurg. يتطلب رعاية نشطة. انظر [Seerr عبر DMM](seerr.md).
- **rex-direct** يمنح rex المُطالَب به عنوانه الخاص وشهادته. انظر [rex-direct](../rex/any-source.md#rex-direct).

كل ما تتيحه الرعاية، وأين يُضبط كل شيء، موجود في [ما تمنحك إياه الرعاية](../guides/sponsorship.md).

هل تواجه مشكلة؟ اسأل في منتدى **dmm-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يشرح [الحصول على المساعدة](../guides/remote-help.md) ما يجب ذكره.
