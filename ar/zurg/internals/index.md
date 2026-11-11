# الداخليات {#internals}

كيف بُني zurg.
ما الذي قِيس أداؤه عليه.
ملاحظات التصميم وراء الأجزاء المعقّدة.
مكتوب لمن يوشك على تعديل الكود.
لا يلزمك شيء من هذا لتشغيل zurg.

## شكل الأمر {#the-shape-of-it}

| الصفحة | ما تحتويه |
|---|---|
| [Architecture](architecture.md) | شكل النظام كله والثوابت التي يسهل كسرها. ابدأ من هنا. |
| [Naming](naming.md) | كيف يحصل الإصدار وملفاته على الأسماء التي يعرضها الـ mount. |
| [Persistent caches](persistent-caches.md) | ما يُحفظ على القرص بين عمليات إعادة التشغيل وما الثمن الذي يتطلبه ذلك. |
| [Directory config UI/UX](uiux.md) | تقييم التصميم الذي يقوم عليه محرر الدلائل. |

## ما الذي تم قياسه {#what-was-measured}

| الصفحة | ما تحتويه |
|---|---|
| [خط الأساس لـ Debrid](debrid-baseline.md) | تكلفة zurg وسرعته عبر Real-Debrid وAllDebrid وTorBox. |
| [دورة حياة التورنت](torrent-lifecycle.md) | ما يبلغ عنه كل حساب فعلياً أثناء تنفيذ عملية الجلب، مسجّلاً مباشرةً. |
| [ملاحظات واجهة برمجة Real-Debrid](realdebrid-behavior.md) | دلالات الروابط، واختيار الملفات، والمعنى الحقيقي لكلمة cached. |

## العقود التي يجب أن يلتزم بها zurg {#contracts-zurg-has-to-satisfy}

| الصفحة | ما تحتويه |
|---|---|
| [عقد عميل SABnzbd](sabnzbd-client-contract.md) | الشكل الدقيق الذي يتوقعه Sonarr و Radarr من SABnzbd. |
| [عقد عميل qBittorrent](qbittorrent-client-contract.md) | الشيء نفسه لـ qBittorrent. |
| [plex_api.json](../../internals/plex_api.json) | واجهة Plex API الخام التي يعتمد عليها zurg في البرمجة. 1.2 MB. |

## الأشياء التي سارت على نحو خاطئ {#things-that-went-wrong}

| الصفحة | ما تحتويه |
|---|---|
| [تنظيف المهملات في Plex](plex-trash-sweep.md) | مواءمة عملية التنظيف مع رؤية zurg الخاصة لما هو معطل. |
| [تراجع مهلة البث](stream-timeout-regression.md) | بث عبر الوكيل توقف عن الصمود أمام القراءات الطويلة. |
| [رفض rclone لعملية النقل](rclone-move-refusal.md) | استيرادات فارغة بعد أن رفض أحد الخوادم عملية MOVE، والترقيع. |

## الاختبار {#testing}

- [اختبار E2E](e2e-test.md) يشرح ما الذي تغطيه مجموعة الاختبارات الشاملة (end to end) وما تكلفته عند التشغيل.

أما ما تفعله كل خدمة وما هي حدودها، فهذا موجود تحت [Providers](../providers/index.md) وليس هنا.
