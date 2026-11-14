# TorBox في DMM {#torbox-in-dmm}

DMM يعمل مع خطة TorBox مدفوعة: Essential أو Standard أو Pro. الصق مفتاح API الخاص بك من [torbox.app/settings](https://torbox.app/settings) في صفحة **Connect Torbox** الخاصة بـ DMM، ثم ابحث: الإصدارات التي يملكها TorBox بالفعل تحصل على **Instant TB**. الخطة المجانية لا تتيح الوصول إلى API، لذا لا يستطيع DMM استخدامها، وإرسال إصدارات Usenet إلى TorBox يتطلب خطة Pro.

## تسجيل الدخول {#sign-in}

1. في [debridmediamanager.com](https://debridmediamanager.com) اضغط **Login with Torbox**. إذا كنت مسجّل الدخول بالفعل بخدمة أخرى، افتح **Debrid services** من الصفحة الرئيسية واضغط **Torbox Login**.
2. اضغط **Get API Key from Torbox**. سيفتح الرابط [torbox.app/settings](https://torbox.app/settings)، وهناك يوجد مفتاح API الخاص بك.
3. الصق المفتاح في حقل **API Key** واضغط **Save API Key**.

![صفحة Connect Torbox في DMM ترفض مفتاح الخطة المجانية، والمفتاح مموّه](../assets/dmm-torbox/01-free-plan.webp)

بعد الدخول، تعرض الصفحة الرئيسية الزرين **Cast for TB** و**Requests**، وتعرض **Debrid services** حسابك في TorBox مع علامة ✓. اضغط عليه لرؤية خطتك وموعد انتهائها، أو لإضافة حساب آخر عبر **Add another account** أو لتسجيل الخروج عبر **Logout**.

## ما الذي تقدمه كل خطة {#what-each-plan-can-do}

| | Free | Essential or Standard | Pro |
|---|---|---|---|
| تسجيل الدخول إلى DMM | لا | نعم | نعم |
| **Instant TB** و**DL with TB** والمكتبة و**Cast (TB)** | لا | نعم | نعم |
| إرسال إصدارات Usenet إلى TorBox | لا | لا | نعم |
| التنزيلات في آنٍ واحد (الفتحات النشطة في TorBox) | 1 | 3 أو 5 | 10 |

إذا سجّلت الدخول بمفتاح من الخطة المجانية، يعرض DMM الرسالة **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** تذكر صفحة [الأسعار](https://torbox.app/pricing) الخاصة بـ TorBox أن الوصول إلى API غير مشمول في الخطة المجانية، وأن Usenet متاح في خطة Pro فقط.

## ابحث عمّا يملكه TorBox بالفعل {#find-what-torbox-already-has}

1. ابحث عن فيلم أو مسلسل وافتحه.
2. يسأل DMM موقع TorBox عن الإصدارات التي لديه مخزّنة مسبقاً. تظهر هذه بعلامات **Instant TB** و**Cast (TB)** وتُعرض في الأعلى. الشريحة **TB ✓** فوق النتائج تُظهر هذه فقط. تكتب `is:tb` في خانة الفلترة، واضغطها مرة أخرى لعرض كل شيء.
3. اضغط **Instant TB**. الإصدار يصبح في مكتبة TorBox الخاصة بك فوراً.

![Night of the Living Dead (1968) على DMM مع TorBox: Instant TB وCast (TB) وDL with TB](../assets/dmm-torbox/02-results.webp)

الإصدارات غير الموجودة لدى TorBox تظهر بعلامة **DL with TB**. عند الضغط عليها يطلب TorBox تنزيل الإصدار أولاً، وهذا يستهلك إحدى فتحاتك النشطة أثناء التنزيل. تعني **No seeders** بجانب الحجم أن لا أحد يشاركه الآن، لذا قد لا يكتمل التنزيل أبداً. يضيف TorBox الإصدار كاملاً دائماً، ولا يمكنك اختيار ملفات مفردة.

## مكتبتك {#your-library}

اضغط **Library**. تعرض هذه الصفحة تورنتات TorBox وتنزيلات الويب الخاصة بك.

- **TB Add** يفتح **Add to your TB library**. الصق روابط magnet، أو ارفع ملفات `.torrent`، أو الصق روابط تنزيل مباشرة، وسيجلبها TorBox كتنزيلات ويب.
- **Backup** يحفظ قائمتك في ملف. **TB Restore** يضيف قائمة محفوظة مرة أخرى.
- بقية الميزات تعمل كما في أي خدمة أخرى: انظر [مكتبتك](index.md#your-library).

التنزيلات من Usenet التي أرسلتها إلى TorBox لا تظهر في مكتبة DMM. ابحث عنها على موقع TorBox، أو في صف **DMM TB Library** داخل DMM Cast في Stremio، أو عبر [TorBox hosted Usenet](../zurg/providers/torbox-nzb.md) في zurg.

## شاهد في Stremio {#watch-in-stremio}

اضغط على **Cast for TB** في الصفحة الرئيسية وثبّت الإضافة من هناك. ثم اضغط على **Cast (TB)** لأي إصدار تخزّنه TorBox مؤقتًا. كل الخطوات موجودة في [DMM في Stremio](stremio.md).

في Stremio اسم الإضافة هو **DMM Cast for TorBox**. صفّ **DMM TB Library** فيها يعرض ملفات TorBox الخاصة بك من التورنتات بالإضافة إلى التنزيلات المكتملة من الويب و Usenet.

## أرسل إصدارات Usenet إلى TorBox (Pro) {#send-usenet-releases-to-torbox-pro}

1. افتح فيلمًا أو مسلسلًا واضغط على تبويب **Usenet**.
2. مع TorBox Pro تكون القائمة بعنوان **Send to TorBox** ولكل إصدار زر **TorBox**. اضغطه.
3. يخبرك DMM بما فعله TorBox به:
   - **Usenet → TorBox: TorBox already had it, it is ready in your TorBox Usenet downloads.**
   - **Usenet → TorBox: TorBox is downloading it, usually ready within a few minutes.**
   - **Usenet → TorBox: queued, it starts when one of your TorBox active slots frees up.**

![تبويب Usenet في DMM مع TorBox Pro: Send to TorBox](../assets/dmm-torbox/03-usenet-tab.webp)

مسجّل الدخول إلى Real-Debrid أيضًا؟ القائمة تكون بعنوان **Send to Real-Debrid or TorBox** وفيها الزرّان معًا. أيقونة الملف في نهاية كل صف تحفظ ملف NZB بدلًا من ذلك. جديد على Usenet؟ ابدأ مع [Usenet for beginners](../guides/usenet-for-beginners.md).

يحذف TorBox تنزيل Usenet بعد 30 يومًا من تخزينه مؤقتًا. أرسله مرة أخرى لاستعادته.

## املأ الطلبات باستخدام TorBox {#fill-requests-with-torbox}

يطلب مستخدمو Real-Debrid إصدارات على [لوحة الطلبات](https://debridmediamanager.com/requests) الخاصة بـ DMM. اضغط على **Requests** في الصفحة الرئيسية، ثم على **Fulfil** للإصدار الذي يكون مخزّنًا مؤقتًا على TorBox. فينتقل الإصدار من TorBox الخاص بك إلى Real-Debrid الخاص بهم. كل 10 عمليات إرسال تكسبك 7 أيام من مزايا الرعاية في DMM: راجع [اكسبها دون أن تدفع](../guides/sponsorship.md#earn-it-without-paying).

## عندما تحدث مشكلة {#when-something-is-wrong}

| ما تراه | ما الذي تفعله |
|---|---|
| **Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | هذا المفتاح تابع للخطة المجانية في TorBox. قم بالترقية أو التجديد من TorBox، ثم سجّل الدخول مرة أخرى. |
| **Failed to refresh torbox: Your TorBox account is on the free plan, which has no API access. DMM needs a paid TorBox plan.** | انتهت خطتك المدفوعة منذ أن سجّلت الدخول. جدّدها من TorBox. |
| **API Error: Request failed with status code 403. Status: 403** | لم يقبل TorBox هذا المفتاح. انسخه مرة أخرى من [torbox.app/settings](https://torbox.app/settings)، كاملاً. |
| لا يوجد زر **TorBox** في تبويب Usenet | إرسال إصدارات Usenet إلى TorBox يتطلب خطة Pro. الخطتان Essential وStandard لا تظهر فيهما هذا الزر. |
| **Usenet → TorBox: TorBox Usenet needs a Pro plan** | رفض TorBox ملف NZB لأن الخطة ليست Pro. |
| تظهر فقط **DL with TB** بدون **Instant TB** | لا يحتوي TorBox على أي من هذه الإصدارات مخزنة مؤقتاً. اضغط على أحدها وانتظر حتى يكتمل التنزيل، أو اختر إصداراً آخر. |
| تظهر فقط إصدارات **Instant TB** | شريحة **TB ✓** مفعّلة (`is:tb` في مربع الفلترة). اضغط عليها مرة أخرى، أو اضغط **Reset**. |
| **No torrents found yet. Use Want above to have zurg fetch it once one turns up, or try the Usenet tab.** | لا توجد لدى DMM أي تورنتات لهذا العنوان حتى الآن. الحلقات الجديدة قد تستغرق وقتاً. جرّب تبويب **Usenet** أو عُد لاحقاً. |
| في Stremio: **⚠️ TorBox refused your account** | يقبل TorBox مفتاح الإضافة لكنه يرفض تقديم الخدمة للحساب، غالباً لأن الخطة انتهت. تحقّق منه في [torbox.app/settings](https://torbox.app/settings). لا تحتاج إلى تغيير أي شيء في DMM. |
| zurg: `Acquisition: dmm-torbox refused the search: No TorBox key linked.` | يحتاج مصدر `tb/cached` في [صفحة Torznab الخاصة بـ DMM](https://debridmediamanager.com/torznab) إلى ربط مفتاح TorBox الخاص بك ضمن **Link a provider key** في تلك الصفحة. تسجيل الدخول إلى TorBox داخل DMM لا يكفي. ويبقى `api_key` في zurg هو مفتاح DMM API الخاص بك. |

هل TorBox نفسه معطّل؟ تحقّق من [Is TorBox Down Or Just Me?](https://debridmediamanager.com/is-torbox-down-or-just-me). متعثر؟ اسأل في منتدى **dmm-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يوضح [Getting help](../guides/remote-help.md) ما الذي يجب تضمينه.

## أسئلة {#questions}

### هل دعم TorBox غير متاح في الخطة المجانية من zurg؟ {#is-torbox-support-not-on-the-free-tier-of-zurg}

حسنًا. نسخة zurg العامة المجانية تعمل مع Real-Debrid فقط. أما TorBox والخدمات الأخرى وUsenet فموجودة في نسخ zurg الليلية الخاصة بالرعاة. يجب أن تكون خطة TorBox لديك مدفوعة أيضًا، لأن zurg لا يستطيع قراءة الحساب المجاني. قم بإعدادها باتباع [TorBox مع zurg](../zurg/providers/torbox.md).

### هل يستخدم zurg خطة TorBox الخاطئة؟ {#zurg-uses-the-wrong-torbox-plan}

إصدارات zurg الليلية السابقة لتاريخ 3 أكتوبر 2026 كانت تقرأ خطة Pro من TorBox على أنها Standard، وتسمح بـ 5 تنزيلات في وقت واحد بدلاً من 10. حدّث zurg. التفاصيل الباقية موجودة في [حدود TorBox مع zurg](../zurg/providers/torbox-limits.md).

### لا توجد نتائج بحث مع TB؟ {#no-search-results-with-tb}

DMM بحثه واحد بغض النظر عن الخدمة التي تسجل الدخول بها. TorBox يحدد فقط أي الإصدارات تظهر عليها **Instant TB**. إذا لم ترَ أي نتائج، تأكد من أن شريحة **TB ✓** مطفأة، أو أعد تحميل الصفحة، أو اضغط على **Show More Results** في أسفل الصفحة. قد لا تكون الحلقة الجديدة جداً متوفرة كتورنت على DMM بعد، فجرّب تبويب **Usenet**.

### هل يمكنني استخدام TorBox و Real-Debrid معًا؟ {#can-i-use-torbox-and-real-debrid-together}

نعم. سجّل الدخول إلى الخدمتين، وستظهر في كل إصدار أزرار الخدمتين معًا. إذا كان الإصدار مخزّنًا مؤقتًا على TorBox وغير موجود على Real-Debrid، سيظهر له زر **TB → RD**، وهو يرسله من TorBox إلى حسابك على Real-Debrid.

### أي خطة TorBox أحتاجها لـ DMM؟ {#which-torbox-plan-do-i-need-for-dmm}

أي خطة مدفوعة. اختر Pro إذا كنت تريد إرسال إصدارات Usenet إلى TorBox أو تريد 10 تنزيلات في وقت واحد.
