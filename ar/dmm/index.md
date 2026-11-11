# DMM

[Debrid Media Manager](https://debridmediamanager.com) يساعدك على إيجاد الأفلام والمسلسلات والاحتفاظ بها في مكتبة الدبريد الخاصة بك.

تضيف إضافة DMM للمتصفح زرًا إلى IMDb وTrakt ومواقع أفلام ومسلسلات أخرى. [أزرار DMM في Safari](safari.md) يشرح إعداد Safari.

يقدّم DMM خدمات للمشاريع الأخرى أيضًا:

- **zurg** يسأل DMM عن الفيلم أو الحلقة التي يمثلها كل ملف. يحصل الراعي على مفتاح API الخاص بـ DMM من [gatekeeper](https://gatekeeper.debridmediamanager.com/). بدونه يعتمد zurg على أسماء الملفات، فتتطابق عناوين أقل. [rex مع zurg](../rex/with-zurg.md#why-dmm-places-the-files) يشرح الفرق.
- **Sonarr Radarr وProwlarr** يمكنها البحث في DMM كفهرس تورنت من نوع Torznab أو فهرس Usenet من نوع Newznab. كلاهما يحتاج إلى رعاية نشطة ومفتاح API الخاص بـ DMM. اضبطهما في صفحتي [Torznab](https://debridmediamanager.com/torznab) و[Newznab](https://debridmediamanager.com/newznab).
- **قائمة المتابعة الخاصة بك**: اضغط **Want** أو تابع قائمة Trakt أو MDBList. يجلب zurg القائمة والحلقات الجديدة فور عرضها. تتطلب رعاية. راجع [قائمة متابعة DMM](../zurg/guides/dmm-wanted.md).
- **Seerr وOverseerr وJellyseerr** يمكنها استخدام DMM بدلاً من Radarr وSonarr. فتصل الطلبات إلى قائمة المتابعة الخاصة بك ليجلبها zurg. تتطلب رعاية. راجع [Seerr عبر DMM](seerr.md).
- **rex-direct** يمنح rex المطالَب به عنوانه وشهادته الخاصة. راجع [rex-direct](../rex/any-source.md#rex-direct).

كل ما تفتحه الرعاية وأين يُضبط كل شيء موجود في [ما تمنحك إياه الرعاية](../guides/sponsorship.md).

عالق؟ اسأل في منتدى **dmm-support** على [Discord](https://discord.com/invite/7u4YjMThXP). [الحصول على المساعدة](../guides/remote-help.md) يوضح ما يجب تضمينه.
