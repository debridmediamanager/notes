# ميزات Jellyfin وإمكاناته {#jellyfin-features--capabilities}

## الإعدادات والتخزين {#configuration--storage}
- مفاتيح الإعدادات ([`config.md`](../reference/config.md), `config.example.yml`): `jellyfin_server_url` (النوع string، والقيمة الافتراضية `""`)، و`jellyfin_token` (النوع string، والقيمة الافتراضية `""`). كلاهما مكتوب كتعليق في `config.example.yml` وغير موجود في `config.simple.yml`. يجب تعيين `mount_path` وإلا يتم تعطيل فحص الوسائط (بما في ذلك Jellyfin) (`pkg/scan/scanner.go`).
- تُحفَظ القيم في `config.yml` عبر لوحة التحكم (`updateConfigFileAtomic`)؛ لا يوجد ملف بيانات منفصل لـ Jellyfin. الحقول ووظائف المساعدة `Get`/`Set` الخاصة بها موجودة في `zurgConfig` داخل `internal/config/config.go`، و`ZurgConfigV1` (`internal/config/filters.go`) يدمج هذه البنية بشكل مباشر.

## المصادقة والتحقق من الخادم (QuickConnect) {#authentication--server-validation-quickconnect}
- تدفق QuickConnect في لوحة التحكم:
  - `/jellyfin/check-server` يتحقق من إمكانية الوصول إلى الخادم عبر `System/Info/Public` ويعرض الإصدار والاسم وتوفر QuickConnect (`HandleJellyfinCheckServer`, `pkg/jellyfin/auth.go:CheckServerReachable/CheckQuickConnectEnabled`).
  - `/jellyfin/auth` يبدأ QuickConnect (`InitiateQuickConnect`)، وينشئ جلسة مصادقة مرتبطة بالكوكي (`pkg/jellyfin/auth_session.go`)، ويبدأ الاستطلاع في الخلفية.
  - `/jellyfin/auth/status` يعيد حالة الاكتمال أو الخطأ أثناء الاستطلاع عبر `/QuickConnect/Connect` + `/Users/AuthenticateWithQuickConnect` (`PollForQuickConnectAuth`، 60 محاولة كل 5 ثوانٍ قبل انتهاء المهلة).
  - `/jellyfin/server` يحفظ عنوان URL للخادم والتوكن في الإعدادات، ويعيد تهيئة عميل Jellyfin، ويرد برسالة نجاح أو تحذير إذا فشلت إعادة التهيئة (`HandleJellyfinServerSelect`).
  - `/jellyfin/logout` يمسح الإعدادات، ويعيد تهيئة الماسح بدون Jellyfin، ويحذف حالة لوحة التحكم المخزنة مؤقتاً (`JellyfinStatusFetcher.ClearCache`).
- مدير جلسات المصادقة يتتبع جلسات QuickConnect، ويخزن السر والرمز والتوكن ومعلومات المستخدم، وينظف الجلسات بعد 10 دقائق (فحص كل 5 دقائق)، ويوفر دوال getter آمنة للاستخدام المتزامن (`pkg/jellyfin/auth_session.go`؛ النسخة العامة في `auth_global.go`).
- دوال QuickConnect المساعدة في `pkg/jellyfin/auth.go` ترسل ترويسة `Authorization: MediaBrowser …` القياسية، وتعمل مع تعطيل التحقق من TLS لتقبل الشهادات الموقعة ذاتياً (`newHTTPClient`). أما عميل المسح فلا يفعل ذلك: `mediabrowser.NewCore` ينشئ `http.Client` عادياً بمهلة 30 ثانية (`pkg/mediabrowser/core.go`)، لذلك خادم خلف شهادة موقعة ذاتياً يتم ربطه والتحقق منه بنجاح، لكن استدعاءات الأقسام والتحديث تفشل بسبب خطأ TLS.
- نقطة التحقق من التوكن `/System/Info` تُستخدم للتأكد من بيانات الاعتماد قبل الحفظ (`ValidateToken`).

## إمكانات عميل Jellyfin (`pkg/jellyfin/client.go`) {#jellyfin-client-capabilities-pkgjellyfinclientgo}
- يُعد `Client` غلافًا خفيفًا فوق `mediabrowser.Core` المضمّن (`pkg/mediabrowser/core.go`)، ويشترك فيه مع `pkg/emby` لأن الخادمين مبنيان على الكود نفسه. الدالة الوحيدة الخاصة به هي `GetSections`. أما الفحص (`ProcessJob`)، والأنشطة، وحالة الخادم، ودورة الحياة، والطابور، وترويسة المصادقة، وتتبع المهام العالقة، فكلها تأتي من الـcore.
- المصادقة: طلبات Jellyfin ترسل الترويسة القياسية `Authorization: MediaBrowser … Token="<token>"`، أما عميل Emby فيرسل `X-Emby-Token` بدلًا منها.
- دورة الحياة: تقوم `NewClientWithLogger` ببناء الـcore (تزيل الشرطات المائلة الزائدة في نهاية الرابط، وتُصدر تحذيرًا وتُرجع nil إذا كان الرابط **أو** الرمز فارغًا). بعد ذلك تشغّل `StartWorker` عامل الفحص الديناميكي، إلا إذا كان `GO_TEST_MODE=1`. أما `Close` فتوقف العامل والطابور.
- طابور الفحص: طابور مهام ديناميكي مع `common.DefaultWorkerConfig`. تقرأ لوحة التحكم حجم الطابور من خلال `GetJobQueueSize` (عبر `MediaScanner.GetQueueSizes`). أما `GetJobQueue` فهي عنصر نائب للتوافق مع الإصدارات السابقة، يُرجع شريحة من مهام فارغة بالحجم نفسه للطابور.
- كشف الحمل والتعليق: تستعلم `CheckServerLoad` من `/ScheduledTasks` بشكل دوري، وتراقب المهام الجارية التي يحتوي اسمها على "scan"، وتتتبع عدد مرات تعليق كل مهمة، وتُبلغ بأن الخادم مشغول عندما تكون عمليات الفحص نشطة. وتُعلّم `IsJobStuck` المهام التي تتجاوز عتبة التعليق.
- تتبع الأنشطة: تُرجع `GetRunningTasks` بنيات `TaskActivity` مفصلة، تتضمن المعرّف والاسم والحالة والتقدم (المأخوذ من `CurrentProgressPercentage`) والوصف وحالة التعليق، وذلك لعرضها في لوحة التحكم.
- حالة الخادم: تستعلم `GetServerStatus` من `/Sessions` لحساب جلسات البث النشطة، وعمليات التحويل (الفيديو أو الصوت غير المباشر)، واستهلاك عرض النطاق الترددي، لعرضها في لوحة التحكم.
- اكتشاف المكتبات: تستدعي `GetSections` المسار `/Library/VirtualFolders`، وتُرجع الأقسام مع المعرّف والعنوان والمسارات (كل مجلد في المكتبة) والنوع. ثم تُضيف إلى كل قسم عدد عناصره عبر `Items?ParentId=<id>&Recursive=true&Limit=0`.
- التحديث: ترسل `ProcessJob` كل المسارات المتغيرة في المهمة دفعة واحدة عبر `POST /Library/Media/Updated`، ويكون كل مسار في الجسم بالشكل الذي يراه الخادم على نظام ملفاته. أما المهمة التي لا تحتوي على مسار فتُحدّث المكتبة كلها عبر `POST /Items/{id}/Refresh`. تُرجع الدالة `ServerBusyError` عند استلام 503، وخطأً يفيد بأن "المكتبة ربما حُذفت" عند استلام 404، وتُرجع نص الاستجابة عند أي رمز آخر من 4xx أو 5xx. أما `RefreshSection` فتضيف المهام إلى الطابور.
- دوال مساعدة: تطابق `FindSectionNormalized` بحسب بادئة المسار (أول تطابق يُعتمد)، وتُرجع المسار مع إعادة كتابة بادئته بحسب حالة الأحرف في موقع المكتبة. يكون فحص البادئة غير حساس لحالة الأحرف على macOS وWindows، ويكون دقيقًا في الأنظمة الأخرى (`pkg/common/pathutil.go`).

## تكامل ماسح الوسائط (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- يُهيّئ عميل Jellyfin عندما تكون `mount_path` وعنوان URL للخادم والرمز (token) موجودة، ويسجّل رسالة نجاح، ويُبقي العميل على nil عند الفشل. لا توجد حلقة إعادة محاولة (على عكس Plex)، لكن يمكنك إعادة التهيئة يدوياً.
- يُرسل `TriggerScan` الطلب إلى Jellyfin مع الخوادم الأخرى. تحدد `triggerJellyfinScan` الأقسام عبر `FindSectionNormalized` باستخدام المسارات التي تبدأ بـ `mount_path`، وترسل المسارات المتغيرة لكل قسم في طلب واحد (Plex يرسل مساراً واحداً في كل طلب).
- يُعيد `GetQueueSizes` أطوال قوائم الانتظار لكل من Plex وJellyfin وEmby معاً، ويستخدم -1 للخادم غير المتصل.
- يُغلق `ReinitializeJellyfinClient` أي عميل موجود ويعيد بناءه باستخدام الإعدادات الحالية (يُستخدم بعد المصادقة من لوحة التحكم وعند تسجيل الخروج).

## لوحة التحكم والمسارات {#dashboard--routes}
- يُركّب الموجّه (Router) نقاط نهاية Jellyfin التالية: `/jellyfin/check-server`، `/jellyfin/auth`، `/jellyfin/auth/status`، `/jellyfin/server`، `/jellyfin/logout`، `/jellyfin/scan/{sectionID}`، `/jellyfin/scan-all` (`internal/handlers/router.go`).
- تتولّى النافذة المنبثقة للوحة التحكم (templates/scripts) عملية QuickConnect، وتعرض الحالة والأخطاء، وتحفظ بيانات الاعتماد وتحذفها. كما يعرض `dashboard.tmpl` حجم قائمة الانتظار، وبطاقات المكتبات مع أزرار المسح، وأنشطة الخادم.
- يملأ `JellyfinStatusFetcher` (`internal/handlers/dashboard/mediabrowser_status.go`) بيانات JSON الخاصة باللوحة من ذاكرة تخزين مؤقتة في الخلفية، بدلاً من تعطيل الصفحة. فهو يتحقق من الرمز المميّز (token)، ويسجّل حالة الاتصال، ويملأ قائمة المكتبات (ID/Name/Paths/Type/ItemCount)، ويجمع الأنشطة الجارية للمهام بالإضافة إلى عدد الجلسات وعمليات التحويل وعرض النطاق الترددي. تُحدَّث الأنشطة والجلسات كل 30 ثانية، أما الجلب الكامل، بما في ذلك المكتبات، فيُجرى كل 5 دقائق. يقدّم `response.go` النسخة المخزّنة مؤقتاً (`JellyfinServerInfo`، `jellyfin_queue_size`).
- تضع نقاط نهاية المسح (`HandleJellyfinScan`، `HandleJellyfinScanAll`) في قائمة الانتظار تحديثاً لكامل المكتبة دون تحديد مسار، سواء لقسم مكتبة واحد أو لجميع أقسام المكتبات، تماماً مثلما تفعل نظيراتها في Plex. وترجع 503 إذا لم يكن عميل Jellyfin مُهيّأً (`internal/handlers/dashboard/dashboard.go`).
- يمكنك أيضاً كتابة `jellyfin_server_url` و`jellyfin_token` عبر معالجات تحديث الإعدادات العامة، لذا يمكن ضبطهما دون الحاجة إلى نافذة QuickConnect المنبثقة (`handlers["jellyfin_server_url"]`/`["jellyfin_token"]` في `dashboard.go`؛ و`updateJellyfinServerURL` في `scripts.tmpl`).

## آثار جانبية على المكتبة والتحديث {#library-side-effects--refresh}
- أي تأثيرات جانبية على المكتبة (تغييرات تعيين المجلدات، ومزامنة STRM، والإصلاحات) تستدعي `MediaScanner.TriggerScan`، والذي يشمل تحديثات Jellyfin عندما يكون العميل متصلاً (`internal/torrent/hooks.go:TriggerLibrarySideEffects` → `pkg/scan/scanner.go`).
- الاستدعاء نفسه يمسح أولاً إدخالات dircache الخاصة بـ rclone VFS المتأثرة، حتى يرى فحص Jellyfin التغيير بدلاً من قائمة مخزنة مؤقتاً لساعات.
- تعمل مزامنة STRM والـ hooks الخاصة بـ `on_library_update` جنباً إلى جنب مع مُشغِّل الفحص (الـ hook يُؤخَّر 500 مللي ثانية ويُزال تكراره)؛ ويستقبل Jellyfin مسارات المكتبة مسبوقة بـ mount_path في مهام التحديث.

## متفرقات {#miscellaneous}
- Emby تكامل شقيق له مفاتيح إعداد خاصة به (`emby_server_url`، `emby_token`) ويشارك النواة المشتركة نفسها، لكن بدون QuickConnect. تسجّل الدخول بمفتاح API، أو تختار مستخدمًا وتدخل كلمة مروره (`/emby/users`، `/emby/auth`). تعرض بطاقة لوحة التحكم الخاصة به المكتبات مع أزرار المسح (`/emby/scan/{sectionID}`، `/emby/scan-all`)، والأنشطة والجلسات مثل Jellyfin (`EmbyStatusFetcher`).
- يتحقق `pkg/jellyfin/windows_path_test.go` من أن مسار Windows يبقى خارج عنوان الطلب ويصل إلى الجسم دون تغيير؛ ويغطي `find_section_test.go` مطابقة البادئة.
