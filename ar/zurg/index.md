# zurg

zurg يجمع حساباتك في خدمات الدبريد ومكتبة Usenet في مجلد افتراضي واحد. لا يخزّن أي ملفات فيديو محلياً. ولا يتم جلب شيء حتى يطلبه المشغّل. ملف remux بحجم 60 GB لا يستهلك 60 GB من مساحة القرص المحلي.

أربعة عروض مختلفة لنفس المكتبة:

| Endpoint | For |
|---|---|
| `/dav/` | WebDAV، وهو ما يركّبه rclone |
| `/http/` | متصفح المجلدات بصيغة HTML |
| `/infuse/` | نسخة WebDAV مهيّأة لتوافق Infuse |
| `/strm/` | عناوين URL موقّعة داخل ملفات `.strm`، للمشغّلات التي تفضّل رابطاً بدلاً من التركيب |

## الإعداد {#setup}

ابدأ تشغيل zurg على جهازك.

- [Linux](setup/linux.md) — ‏FUSE 3 وبدء تشغيل تلقائي عبر systemd
- [Docker](setup/docker.md) — ‏مضيف Linux مع تركيب مرئي للمضيف
- [macOS](setup/macos.md) — ‏macFUSE وبدء تشغيل تلقائي عبر launchd
- [Windows](setup/windows.md) — ‏WinFsp ومهمة بحرف محرك أقراص

## المزوّدون {#providers}

وجّه zurg إلى حساب. كل صفحة تشرح بيانات الاعتماد وإدخال `config.yml`. الأمثلة تستخدم Docker. التثبيت الثنائي يستخدم إدخال الإعداد نفسه. انظر [الإعداد](setup/index.md) للأوامر.

| الصفحة | ما الذي يميزها |
|---|---|
| [Real-Debrid](providers/realdebrid.md) | اختيار الملفات واحدًا واحدًا، و`__downloads__`، واختيار مضيف CDN، ورمز `.strm` منفصل |
| [TorBox](providers/torbox.md) | طلب واحد لكل تحديث للمكتبة، وسقف للفتحات النشطة بدلًا من سقف عرض النطاق الترددي |
| [AllDebrid](providers/alldebrid.md) | قوائم الملفات تأتي من نقطة نهاية خاصة بها، لذلك يكتمل المسح الأول تدريجيًا |
| [Premiumize](providers/premiumize.md) | التحويلات المكتملة إضافة إلى ملفات السحابة المتبقية، مع بقاء مجلداتها سليمة |
| [Debrid-Link](providers/debridlink.md) | قائمة السيدبوكس تحتوي على كل الملفات، ولا يوجد فحص للتخزين المؤقت |
| [Offcloud](providers/offcloud.md) | الأحجام تُتحقق من خادم التوصيل، ومسارات المجلدات تأتي من البيانات الوصفية المخزنة مؤقتًا |
| [Usenet](providers/usenet.md) | النوع `nzb` كإدخال لمزود. لا يوجد رمز، بل مجلد مراقبة بدلًا منه |
| [حدود TorBox](providers/torbox-limits.md) | الأرقام المقاسة وراء تقييد TorBox، وكيف يضبط zurg سرعته وفقها |
| [خادم أخبار TorBox](providers/torbox-news-server.md) · [خادم أخبار ElfHosted](providers/elfhosted-news-server.md) | ما هي حسابات Usenet المرفقة، كما تظهر على الشبكة |

تحتوي [الصفحة المشتركة](providers/index.md) على الطرق الثلاث لإضافة حساب في Docker، والقواعد التي يفرضها محمّل الإعدادات.

## الأدلة {#guides}

- [Usenet](guides/usenet.md) — الواجهة `nzb` من البداية إلى النهاية: حسابات الأخبار، وملفات NZB، والتركيب، وPlex
- [Sonarr وRadarr لـUsenet](guides/sonarr-radarr.md) — يبحث تطبيقات \*arr ويرد عليها zurg كأنه SABnzbd، فتكون عمليات الاستيراد مجرد إعادة تسمية لا تنزيل
- [Sonarr وRadarr للتورنت](guides/sonarr-radarr-torrents.md) — الشيء نفسه، لكن مع رد zurg كأنه qBittorrent؛ وProwlarr أيضًا
- [البحث عبر zurg لـSonarr وRadarr](guides/sonarr-radarr-fetch.md). يحتفظ Radarr وSonarr بالقائمة، بينما يجد zurg الإصدار ويضعه في مكانه. لا توجد مفهرسات ولا عميل تنزيل في أي منهما.
- [`__magic__`](guides/magic.md) — المجلد الوحيد الذي يُحفظ تخطيطه، ولذلك فترتيبه يعود إليك، ومكتبتك مرتبة حسب العنوان لـKodi وPlex
- [إعادة التسمية](guides/renaming.md) — أعد تسمية إصدار أو ملف في أي مكان داخل المكتبة. يُرفض النقل، وتشرح الصفحة السبب
- [Plex](guides/plex.md) — ما الذي يفعله zurg برمز Plex، وما الذي يتعمد ألا يفعله
- [Jellyfin](guides/jellyfin.md) — الشيء نفسه، لكن مع Jellyfin
- [rex مع zurg](../rex/with-zurg.md) — خادم وسائط لتطبيقات Plex لا يملك أي ملفات، ويملؤه zurg من حساب الdebrid الخاص بك. للمزيد، انظر [rex](../rex/index.md)
- [إضافة Stremio](guides/stremio.md) — يبحث Stremio في المفهرسات الخاصة بك، ويشغّل المحتوى مباشرة من الواجهة الخلفية لـUsenet
- [قائمة المشاهدة وSeerr](guides/acquisition.md) تجلب ما تطلبه عبر المفهرسات الخاصة بك
- [قائمة مشاهدة Plex](guides/plex-watchlist.md) هي الجانب الخاص بـPlex من ذلك
- [قائمة DMM المطلوبة](guides/dmm-wanted.md) تجلب ما تضغط عليه Want في DMM، دون أي إعداد إضافي
- [المكتبات المحلية](guides/local-libraries.md) تشغّل قائمة مشتركة من الإصدارات عبر حسابك الخاص
- [Android وGoogle TV](guides/android.md) يشغّل المكتبة كاملة على هاتف أو جهاز TV box

## الترحيل {#migrating}

ابدأ من مكتبة موجودة وانقلها إلى zurg دون إعادة تنزيل ولا إعادة فحص.

- [من AltMount](migrate/altmount.md)
- [من decypharr](migrate/decypharr.md)
- [من InfiniDysk](migrate/infinidysk.md)
- [من nzbdav](migrate/nzbdav.md)
- [من streamnzb](migrate/streamnzb.md)

## المرجع {#reference}

- [الإعدادات](reference/config.md) — كل خيار موجود في `config.yml`
- [سطر الأوامر](reference/cli.md) يسرد كل أمر وكل علامة يقبلها البرنامج
- [الهوية الصادرة](reference/outbound-identity.md) يوضح ما الذي يخبر به zurg الخدمات التي يتصل بها عن نفسه
- [خادم MCP](reference/mcp.md) يتيح لوكيل ذكاء اصطناعي التحكم في zurg عبر Model Context Protocol
- [الوسوم](reference/tags.md) — ما الذي يُطبَّق على التورنت، ولماذا
- [سجل التغييرات](reference/changelog.md) — ما الذي تغيّر ومتى

## الداخليات {#internals}

كيف بُنيَ zurg، وما الأرقام التي قِيس بها، والملاحظات التصميمية وراء الأجزاء الصعبة.

- [البنية](internals/architecture.md) — شكل النظام ككل، والثوابت التي يسهل كسرها
- [خط الأساس للخدمات الوسيطة](internals/debrid-baseline.md) — تكلفة zurg وسرعة إحساسه عبر RD وAD وTorBox
- [دورة حياة التورنت](internals/torrent-lifecycle.md) — ما تُبلغ عنه كل حساب فعلاً أثناء عملية التنزيل، مقاساً مباشرةً
- [عقد عميل SABnzbd](internals/sabnzbd-client-contract.md) — الصيغ الدقيقة التي يتوقعها Sonarr وRadarr
- [تنظيف المهملات في Plex](internals/plex-trash-sweep.md) · [تراجع مهلة البث](internals/stream-timeout-regression.md) · [تهيئة الدلائل: واجهة وتجربة المستخدم](internals/uiux.md)
- [اختبار E2E](internals/e2e-test.md) · [ملاحظات واجهة Real-Debrid البرمجية](internals/realdebrid-behavior.md)
- [عقد عميل qBittorrent](internals/qbittorrent-client-contract.md) · [الذاكرات المؤقتة الدائمة](internals/persistent-caches.md)
- [التسمية](internals/naming.md) · [رفض نقل rclone](internals/rclone-move-refusal.md)

---

يتوفر zurg للرُعاة: [إصدارات GitHub](https://github.com/debridmediamanager/zurg/releases)
· [الرعاية](https://gatekeeper.debridmediamanager.com/) · [Discord](https://discord.com/invite/7u4YjMThXP)
