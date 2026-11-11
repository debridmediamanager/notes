# ميزات Plex وإمكانياتها {#plex-features--capabilities}

هل تشغّل rex بجانب Plex Media Server، أم بدلاً منه؟ [انتقل من Plex إلى rex](../../rex/from-plex.md) يوضّح ما الذي تحتفظ به في zurg، بما في ذلك تركيب rclone الخاص بك، وأي إعدادات Plex في zurg يجب إزالتها.

## الإعدادات والتخزين {#configuration--storage}
- Config keys documented in [`config.md`](../reference/config.md)/`config.example.yml`: `plex_server_url`, `plex_token`, `plex_match_every_mins` (default 1440), `plex_watchlist_enabled`, `plex_watchlist_check_every_secs` (the legacy spelling of `watchlist.check_every_secs`, default 60s), `mount_path` (required for matching/scan path building). Dashboard-authored settings are saved directly to `config.yml` via the config writer (`updateConfigFileAtomic`).
- ‏الفاصل الزمني لقائمة المراقبة يرجع إلى قيمته الافتراضية لأي قيمة تساوي 0 أو أقل (`GetWatchlistCheckEverySecs`)، أما `plex_match_every_mins` فيرجع إلى قيمته الافتراضية فقط إذا كانت تساوي `0` بالضبط (`intOr`، `internal/config/config.go`). ولا يمكن تعطيل أيٍّ منهما. الداشبورد يرفض أي قيمة أقل من 1 (`internal/handlers/dashboard/dashboard.go`)، وإذا كانت قيمة `plex_match_every_mins` سالبة في `config.yml` فإن zurg يتوقف عند بدء التشغيل مع الرسالة `is negative; use 0 for the default`، ولا يوقف المطابقة أبدًا.
- يُضبط اكتساب قائمة المراقبة من خلال كتلة `watchlist:`، وفيها المفاتيح `enabled` و`check_every_secs` و`indexers` و`max_size_gb` و`max_season_size_gb` و`quality` (القيمة الافتراضية `best`). إذا كانت `indexers` فارغة فإنها تستعير القيمة من `stremio.indexers`. ولا تزال المفاتيح القديمة المسطحة `plex_watchlist_enabled` و`plex_watchlist_check_every_secs` و`watchlist_quality` تُعتبر الكتابات القديمة للمفاتيح الأول والثاني والأخير من هذه المفاتيح على التوالي. راجع [config.md](../reference/config.md#watchlist).
- `mount_path` هو أيضًا البادئة لمسارات الفحص التي تُرسل إلى Plex وإلى تركيب rclone المُدار ([`config.md`](../reference/config.md)، `pkg/scan/scanner.go`).
- يُمرَّر الخطاف `on_library_update` كل مسار تغيّر كوسيطات، مع تأخير مدته 500 ms وإزالة التكرار، ولا يعمل إلا استدعاء واحد في كل مرة، وهو ما يتيح سكربتات الفحص التلقائي في Plex (`internal/torrent/hooks.go`).

## المصادقة واكتشاف الخادم {#authentication--server-discovery}
- تدفق لوحة الويب: يُنشئ `/plex/auth` جلسة PIN (`pkg/plex/auth.go`، `CreatePlexAuthURL`)، ويخزّنها في `pkg/plex/auth_session.go` (تُحذف تلقائيًا بعد 10 دقائق، ويُفحص كل 5)، ويستعلم عن اكتمال التفويض عبر `/plex/auth/status` (`PollForAuthToken`، 60 محاولة كل 5 ثوانٍ قبل انتهاء المهلة).
- يعرض `/plex/callback` صفحة تقدّم، وعند اكتمال التفويض تستدعي `/plex/servers` لعرض الخوادم، و`/plex/server` لاختيار أحدها (`internal/handlers/dashboard/dashboard.go`).
- اكتشاف الخوادم (`pkg/plex/auth.go`): يجلب موارد Plex مع نقاط النهاية HTTP وHTTPS معًا، ويستبعد نقطة الـ relay إذا كانت هناك نقطة مباشرة (direct)، ويتعامل مع عناوين IPv6، ويفحص `/identity` لكل عنصر (مع تعطيل التحقق من TLS). تُؤخذ في الاعتبار الخوادم **المملوكة** لحسابك فقط (`device.Owned`، `auth.go`)، فلن تظهر الخوادم المشتركة أبدًا، والعناصر التي تفشل في الفحص تُحذف من الاستجابة بدلًا من إرجاعها مع ضبط `last_error` (`enrichServersWithIdentity`، `auth.go`).
- عند اختيار خادم، يُكتب `plex_server_url` و`plex_token` في الإعدادات، ثم يُعاد تهيئة عميل Plex، ويُعاد تشغيل جدولة المطابق (matcher scheduler) إن لزم، ويُطلق محفّز المطابقة (match trigger)، ويُحدَّث تخزين حالة لوحة التحكم المؤقت (cached dashboard status) (`HandlePlexServerSelect`، `internal/handlers/dashboard/dashboard.go`). أما `/plex/logout` فيمسح القيم المخزّنة وذاكرة حالة اللوحة.

## إمكانيات عميل Plex (`pkg/plex/client.go`) {#plex-client-capabilities-pkgplexclientgo}
- دورة حياة الاتصال: خيار البدء المؤجل (`WithDeferredStart`)، وحارس `ValidateConnection` الذي يمنع الوصول إلى `/identity`، والإغلاق المنظم عبر `Close`. لا توجد واجهة لإعادة التشغيل. القيمتان `RestartAllowed` و`RestartReason` في لوحة التحكم تُستنتجان من عنوان URL للخادم (محلي/LAN مقابل بعيد)، وهما للعرض فقط (`internal/handlers/dashboard/plex_status.go:getPlexConnectionDetails`).
- قائمة انتظار الفحص: قائمة مهام وعامل ديناميكيان (`common.DynamicJobQueue`). تُرسل `ProcessJob` الطلب `GET /library/sections/{key}/refresh` مع ترويسات Plex ومعامل `path` واحد على الأكثر لكل مهمة، وأي عدد أكبر يُرفض مباشرة (`client.go`). المهمة بدون مسار تعني تحديث القسم بالكامل. الرد 503 يصبح خطأ "الخادم مشغول"، والرد 404 يبلغ بأن المكتبة حُذفت من Plex. و`GetJobQueueSize` يعرض حجم المتراكم.
- كشف الحمل والتوقف: تفحص `CheckServerLoad` الطلب `/activities`، وتتبع تقدّم `library.update.section` لكل UUID (يُعد تغيّر التقدّم *أو* العنوان الفرعي تقدّماً)، و`IsJobStuck` يعلّم المهام القديمة حسب `librarySectionID` مع الرجوع إلى Title عند الحاجة. تُنشئ `GetServerActivitiesDetails` المتتبعات نفسها وتُنهيها. السبب أن `CheckServerLoad` يعمل فقط عندما تكون مهمة في قائمة الانتظار. وكان الفحص الذي يبدأه Plex بنفسه لا يحصل على متتبع أبداً، فلا يمكن الإبلاغ عنه متوقفاً، وكان زمنه المنقضي يُقرأ صفراً في كل تحديث. يحتفظ المساران بالسجل لـ `library.update.section` فقط، لأن تتبع أي شيء آخر هنا سيتذبذب مع عملية التنظيف (prune) الخاصة بالعامل.
- **العنوان الفرعي لنشاط Plex ليس الملف الذي يتوقف عنده الفحص المعلّق.** قيس على جهاز plex503 بتاريخ 2026-09-15: العنوان الفرعي `library.update.section` هو مؤشر تعداد الماسح، ويسبق القراءات الفعلية. ومع رفض التركيب لثلاثة ملفات، سمّى رابعاً لم يُطلب قط، وسمّى الملف المحجوب لمدة 290 ms فقط من دورة مدتها 56 s. تعرضه لوحة التحكم تحت "Plex reports" ولا تربطه بإصدار. أما ما ينتظره الفحص فعلاً فيأتي من رفضات zurg نفسها (`internal/universal/refused_reads.go`)، وهي الجهة الوحيدة التي تعرف ذلك. البيانات موجودة في `internal/handlers/dashboard/testdata/plex503-*`.
- استعلامات المكتبة: `GetSections` (أقسام الأفلام والمسلسلات مع المواقع)، و`GetSectionItemCount`، و`FindSectionNormalized` (يطابق مساراً مع موقع قسم ويصحح بادئة المسار لتطابق حالة أحرف المكتبة)، و`GetAllMediaItemsConcurrent` (جلب دفعي ومتزامن مع `includeGuids` لجمع المسارات ومعرّفات GUID ومعرّفات IMDB)، و`GetShowLevelIMDBIndex` (معرّفات مستوى المسلسل لأقسام المسلسلات حتى تتوارثها الحلقات).
- مساعدات البيانات الوصفية والمطابقة (`pkg/plex/match.go`): `GetMetadataSummary` (`GET /library/metadata/{ratingKey}`)، و`GetMatchCandidates` (`GET /library/metadata/{ratingKey}/matches?manual=1`، مع تجاوزات العنوان والسنة واللغة)، و`LookupMetadataByGUID`/`LookupRatingKeyByGUID` (`GET /library/all?guid=…`)، و`ApplyManualMatch` (`PUT /library/metadata/{ratingKey}/match`)، وتحليل GUID (`ExtractIMDBIDFromGUID`، `ExtractTMDBIDFromGUID`، `ExtractTVDBIDFromGUID`، `ExtractAnyIDFromGUIDs`؛ والأنواع `MatchResult`/`MatchSelection`).
- معلومات الخادم: `GetServerIdentityOnly` و`GetServerDetails` (معرّف الجهاز والإصدار؛ والثانية تجمع أيضاً عدد الجلسات والتحويلات وعرض النطاق)، و`GetStreamingSessions`، و`GetTranscodeSessions`، و`GetServerActivitiesDetails` (مع حالة التوقف).
- سجل المشاهدة: `GetWatchHistory` (`GET /status/sessions/history/all`)، و`GetMetadataBatch` (مفاتيح التقييم ratingKey مدمجة بفواصل على `/library/metadata`)، و`GetWatchHistoryWithMetadata` (`pkg/plex/history.go`)، وهي تغذي الإحصاءات في `pkg/plex/stats.go`.

## تكامل ماسح الوسائط (`pkg/scan/scanner.go`) {#media-scanner-integration-pkgscanscannergo}
- يُهيّئ عميل Plex عندما تكون `mount_path` و`plex_server_url` و`plex_token` مضبوطة، ويعيد المحاولة كل 5 ثوانٍ حتى يتصل، ويستدعي دوال `OnPlexReconnected` عند كل إعادة اتصال.
- تُجمّع `TriggerScan` المسارات حسب كل قسم في Plex (عبر `FindSectionNormalized`)، وتضع في الطابور مهمة تحديث واحدة لكل مسار يبدأ بـ `mount_path`، وتسجّل التقدم كل 50 مساراً. وتدعم أيضاً Jellyfin وEmby، وهما يسلكان المسار غير المجمّع. المسار الذي لا يقع في أي قسم لا يُحذَّر منه إلا إذا *لم* يطابق أي مسار من الدفعة. وغير ذلك يُكتب كسطر debug فقط. لذلك لن يظهر أي تحذير إذا كان الملف موجوداً في مجلد مكتبة ومجلد zurg فقط (recent وmusic وغيرهما…).
- تتيح `ReinitializePlexClient` لتحديثات لوحة التحكم تبديل الخوادم أو الرموز مباشرةً أثناء التشغيل.
- تعرض `GetQueueSizes` عمق طابور Plex، لتستخدمه الواجهة أو أدوات المراقبة.

## المطابقة ومزامنة البيانات الوصفية (`internal/plex/matcher.go`, `internal/plex/schedule.go`) {#matching--metadata-sync-internalplexmatchergo-internalplexschedulego}
- الشروط المسبقة: يحتاج إلى رابط Plex و token مُعدّين، و`mount_path`، و`scanner.PlexClient` يعمل فعلياً. وإلا فإنه يُرجع أخطاءً واضحة.
- الحالة الوحيدة الخاصة بـ Plex المحفوظة في كل تورنت هي `PlexRatingKey` (على مستوى المسلسل للمحتوى الحلقي) إلى جانب `IMDBID` (`internal/torrent/torrent_types.go`). أما معرّفات Plex GUIDs فتُستخدم أثناء التشغيل لاستخراج المعرّفات وإعداد التقارير فقط، ولا تُحفظ أبداً.
- جمع البيانات: يسحب كل التورنتات من خريطة المجلدات، وكل عناصر Plex عبر `GetAllMediaItemsConcurrent`، ويسبقهما تمريرة `GetShowLevelIMDBIndex` حتى ترث الحلقات معرّفات IMDB/TVDB/TMDB الخاصة بالمسلسل بدلاً من معرّفات خاصة بكل حلقة. تُفهرس العناصر بـ `GrandparentRatingKey` عند توفره.
- خطوات المزامنة:
  - التحقق من كل مفتاح تقييم محفوظ مقابل عناصر Plex المجلوبة حديثاً. إذا لم يعد Plex يملك المفتاح، يُمسح مع معرّف IMDB الخاص بالتورنت، ويُعاد التورنت إلى قائمة المطابقة.
  - المطابقة بالمسار للتورنتات التي لا تملك مفتاح تقييم: تقوم `buildPlexDirIndex` بفهرسة كل مكوّن من مكوّنات المسار بحروف صغيرة لكل ملف في Plex، ثم يُبحث عن `GetKey` الخاص بالتورنت داخل هذا الفهرس (بزمن O(1)، والإدخال الأول هو الذي يفوز). التورنتات التي لا تطابق مجلداتها المخصصة أي موقع لأي قسم في Plex تُتخطى أولاً.
  - ملء معرّفات IMDB الناقصة: أولاً من الدفعة التي جُلبت مسبقاً (دون أي استدعاءات API)، ثم لكل تورنت على حدة عبر `GetMetadataSummary` (بحد أقصى 20 في الوقت نفسه).
  - يكتشف عناصر Plex التي لا تملك أي تورنت.
  - يرسل إلى DMM أزواج الـ hash وIMDB التي أدخلها المستخدم يدوياً فقط، ولا يرسل أبداً المعرّفات التي خمّنها Plex. يقبلها DMM دون مفتاح، ويُرفق `dmm_api_key` معها عند تعيينه (`sendHashImdbPairs` → `TorrentManager.SendHashImdbPairs`, `internal/torrent/mediainfo.go`).
- يشغّل `MatchSingleTorrent` عملية البحث بالمسار نفسها لتورنت واحد، وذلك مباشرةً بعد فحص مستهدف. ولا يفعل شيئاً إذا كان للتورنت مفتاح تقييم مسبقاً.
- التقارير: يكتب `logs/match_report.txt` ملخصاً يتضمن الأعداد، والتورنتات غير المطابقة، والتورنتات المتخطاة، وعناصر Plex التي لا تملك تورنتات، والتورنتات التي ينقصها IMDB.
- الجدولة (`internal/plex/schedule.go`): كل تشغيل مكتمل يضع ختماً زمنياً في `data/plex_match_timestamp`. عند البدء، يعمل `StartMatchingJob` فوراً فقط إذا كان هذا الختم مفقوداً أو أقدم من `plex_match_every_mins`، وإلا فإنه ينتظر المدة المتبقية أولاً. يستمع للتشغيل اليدوي عبر `TorrentManager.PlexMatchTrigger`، ولتغييرات الفاصل الزمني أثناء التشغيل عبر `ResetPlexMatchTicker`، ويعيد تشغيل المهمة حتى ثلاث مرات إذا تعطّلت بسبب panic.
- نقطة التشغيل اليدوي `/plex/match-torrents` ترسل إشارة إلى قناة التشغيل، وترفض العمل إذا كانت هناك عملية جارية. أما `/plex/match-torrents/status` فيخبرك إن كانت هناك عملية قيد التشغيل حالياً (`internal/handlers/utilities.go`).

## المطابقة اليدوية وواجهة الإدارة (`internal/handlers/manage`) {#manual-matching--manage-ui-internalhandlersmanage}
- فلاتر قائمة التورنتات تعرض حالات Plex (`plex_matched`، `plex_in_library_not_matched`، `plex_no_imdb`، `plex_missing_metadata`) للعرض السريع (`torrent_list_state.go`).
- صفحة المطابقة اليدوية لكل تورنت `/manage/{hash}/plex-match`:
  - تحتاج التورنت أن تكون مرتبطة بالفعل بـ `PlexRatingKey` (يضبطها المطابِق)، وإلا تعرض الصفحة الرسالة "torrent is not linked to Plex". تتحقق `resolvePlexRatingKey` من هذا المفتاح باستخدام `GetMetadataSummary`، وتملأ معرّف IMDB الناقص من خلاله، وإذا كان المفتاح قديماً تعيد البحث عنه عبر `LookupRatingKeyByGUID` باستخدام معرّف `tt…`/`tvdb://`/`tmdb://` المخزَّن للتورنت (`internal/handlers/manage/handler.go`).
  - تجلب مرشحي المطابقة اليدوية من Plex مع تجاوزات اختيارية للعنوان والسنة واللغة (44 خياراً للغة، والافتراضي `en-US`)، وتعرض النتائج مع تمييز الاختيار الحالي (`torrent_matches.go`).
  - عند تطبيق مطابقة (`HandleApplyPlexMatch`) تستدعي `ApplyManualMatch`، ثم تعيد البحث عن مفتاح التقييم بالمعرّف GUID الذي اخترته لأن Plex قد يعيد تعيين المفتاح. بعد ذلك تحدّث مفتاح التقييم ومعرّف IMDB للتورنت (بما في ذلك معرّف IMDB الاختياري الذي يدخله المستخدم)، وتحفظ التغييرات، ثم تعيد التوجيه مع حالات النجاح أو الخطأ.

## الحصول على الأعمال من قائمة المشاهدة {#watchlist-acquisition}

- يعمل وضع قائمة المشاهدة في Plex كمحوّل داخل `internal/acquisition/plex`، ويشتغل على خدمة الحصول المشتركة إلى جانب Seerr. إعدادات قائمة المشاهدة الحالية ما زالت تعمل، ويمكنك أيضًا ضبط المحوّلات من خلال `acquisition.sources`.
- يتصل العميل بـ `discover.provider.plex.tv` ويقرأ العناصر على دفعات من 100 عنصر. يُقرأ رمز Plex من جديد مع كل طلب، لذلك تسري إعادة المصادقة من دون الحاجة إلى إعادة تشغيل المحوّل.
- يحصل المنفِّذ المشترك على الأفلام، أو على كل موسم مخطَّط له، من فهارس Newznab وTorznab، ويفضّل حزم المواسم. أما عمليات البحث عن المسلسلات فتجرّب TVDB قبل IMDb، لأن تطابقات الفهارس تختلف من فهرس لآخر.
- يُحفَظ التقدّم ومواعيد إعادة المحاولة والإيصالات لكل حلقة في `data/acquisition.json`، فتبقى بعد إعادة التشغيل. ويُستورد سجل Plex القديم تلقائيًا.
- تُحذف العناصر بعد الانتهاء من الحصول على كل الأهداف المخطَّط لها. تبقى الطلبات الفاشلة في قائمة المشاهدة وتُعاد محاولتها مع تراجع تدريجي دائم. وإعادة المحاولة التي تقتصر على الحذف لا تعيد عملية الحصول. للاطلاع على الحدود، راجع [الحصول على قائمة مشاهدة Plex](plex-watchlist.md)، وللإعدادات المشتركة راجع [مصادر الحصول](acquisition.md).

## لوحة التحكم ونقاط نهاية API (`internal/handlers/router.go`, `internal/handlers/dashboard`) {#dashboard--api-endpoints-internalhandlersroutergo-internalhandlersdashboard}
- المسارات: `/plex/auth`، `/plex/callback`، `/plex/auth/status`، `/plex/servers`، `/plex/server`، `/plex/logout`، `/plex/match-torrents`، `/plex/match-torrents/status`، `/plex/scan/{sectionKey}`، `/plex/scan-all`، `/plex-stats`، `/plex-stats/data`، `/plex-stats/image`، `/manage/{hash}/plex-match`.
- تعرض لوحة التحكم معلومات Plex وحالة الخادم عبر `PlexStatusFetcher` على مؤقتين. كل 30 ثانية تُحدَّث جلسات البث وعمليات إعادة الترميز وعرض النطاق وأنشطة الخادم (`GetStreamingSessions`/`GetTranscodeSessions`/`GetServerActivitiesDetails`). وكل 5 دقائق يُجرى جلب كامل يعيد قراءة الهوية (`GetServerIdentityOnly`) وأقسام المكتبة وأعداد العناصر في كل قسم. تُقارَن أنشطة المسح بقائمة التورنت حسب اسم الملف، حتى تتمكن لوحة التحكم من ربط النشاط بـ hash التورنت.
- تضع نقاط نهاية مسح القسم والمسح الشامل في قائمة الانتظار **تحديثًا كاملًا** للقسم (`RefreshSection(key, nil)`، بدون مسار) لقسم واحد أو لكل الأقسام. لا تمس ملفات STRM ولا تُطلق أي آثار جانبية للمكتبة (`HandlePlexScan`/`HandlePlexScanAll`).

## Plex Wrapped (`internal/handlers/dashboard/plex_wrapped.go`)
- يعرض `/plex-stats` عرضًا من 9 شرائح يلخّص سنتك في Plex، مبنيًا على سجل المشاهدة للأشهر الـ 12 الأخيرة.
- يعيد `/plex-stats/data` الإحصائيات نفسها بصيغة JSON.
- يُنشئ `/plex-stats/image` صورة PNG قابلة للمشاركة باستخدام chromedp في وضع headless. المقاسات المتاحة هي `square` بحجم 1080x1080 وهو الافتراضي، و`instagram` بحجم 1080x1920، و`facebook` بحجم 1200x630.

- لا تُجلب الإحصائيات أكثر من مرة واحدة كل 24 ساعة كحد أقصى (استخدم `?refresh=true` لفرض التحديث). يقتصر السجل على 10000 عنصر كحد أقصى. تُخزَّن الإحصائيات مؤقتًا في الذاكرة وعلى القرص في الملف `data/plex_wrapped_cache.json`، ويُعاد تحميلها عند بدء التشغيل. وأثناء جلب البيانات تعرض الصفحة حالة التحميل بدلًا من تجميد الواجهة.

## الآثار الجانبية على المكتبة وروابط التحديث {#library-side-effects--refresh-links}
- تُفعَّل تأثيرات جانبية للمكتبة عند تغيير تعيين المجلدات، وإعادة التسمية، والحذف، وإصلاح الملفات. تقوم `TriggerLibrarySideEffects` بإبطال dircache الخاص بـ rclone VFS للمسارات المتأثرة (حتى لا تفحص خوادم الوسائط قائمة قديمة)، وتستدعي `MediaScanner.TriggerScan` (فتستدعي تحديث Plex)، وتشغّل الخطاف `on_library_update` الخاص بالمستخدم (`internal/torrent/hooks.go`).
- لا يعمل خط معالجة التحديث على إنشاء STRM والتأثيرات الجانبية إلا بعد اكتمال التهيئة، وذلك لتجنب عمليات فحص Plex المبكرة (`internal/torrent/refresh.go`).

## البنية التحتية والسكربتات {#infrastructure--scripts}
- نموذج لملف vhost في Nginx لتمرير حركة Plex (`nginx/plex.conf`).
- `plex_update.sh` هو سكربت الفحص الجزئي المرجعي لـ `on_library_update: sh plex_update.sh "$@"`. ضعه بجانب `docker-compose.yml`، لأن مجلد هذا الملف مركّب على `/config`، وبالتالي يكون السكربت موجودًا داخل الحاوية أصلًا. على Windows يعمل الـ hook عبر PowerShell وليس `/bin/sh` (`pkg/script/script.go`)، لذا لن يعمل هذا السكربت هناك. أما الصيغة الخاصة بـ PowerShell فموضحة في [Usenet → Point Plex at it](usenet.md#6-point-plex-at-it).
- `integration/plex_integration.sh` يعمل عند تشغيل `make integration-test` و`make integration-test-media`. إذا لم يكن على الجهاز خادم Plex فإنه يتخطى نفسه ويطبع تحذيرًا واضحًا، لذا اقرأ المخرجات بدلًا من الاعتماد على رمز الخروج. أما `scripts/plex-e2e-test.sh` فهو فحص تشغيل مستقل يقرأ `plex_server_url` و`plex_token` من الملف `config.yml`.

## إعدادات Plex الموصى بها {#recommended-plex-settings}

تفترض الإعدادات الافتراضية في Plex أن القرص المحلي موجود دائماً ومتاح للقراءة في أي وقت. أما تركيب zurg فليس كذلك. بياناته تأتي من مزوّد عبر HTTP، وقد لا يمكن قراءته لفترة قصيرة أثناء إعادة اتصال rclone. وبعض الإعدادات الافتراضية في Plex تضرّ فعلاً في هذه الظروف.

يقوم zurg بمطابقة هذه الإعدادات مع كل تحديث لحالة Plex. ويحدد `plex_settings_policy` مدى تدخله: `off` أو `warn` أو `guard` (وهو الافتراضي) أو `enforce`. توجد القائمة في `pkg/plex/settings.go` (`RecommendedSettings`)، أما السياسة فهي في `pkg/plex/reconcile.go`.

يُتجاهل أي إعداد لا يُبلغ عنه الخادم، فلا يُعتبر إصدار Plex الذي لا يحتوي على إعداد معين مُهيّأً بشكل خاطئ.

من القيم الستة عشر أدناه، تسع منها تختلف عن القيمة الافتراضية لـ Plex نفسه. أما السبع الباقية فتطابق الافتراضي، وهي حمايات لا تصحيحات، ولا تُطبَّق إلا على المشغّل الذي فعّل أحد هذه الإعدادات. لذلك تُظهر تلك الصفوف القيمة نفسها في العمودين، وهذا ليس خطأ. فـ Plex يضبط `GenerateBIFBehavior` على `never`، بينما كان الخادم الذي أُجريت عليه القياسات على `scheduled`. يعرض Plex الإعداد الافتراضي لكل إعداد في `/:/prefs`، لذا فإن العمود "Plex ships" أدناه مأخوذ من الخادم نفسه وليس مفترضاً (قيس بتاريخ 2026-09-05 مع Plex 1.42.2).

### إلغاء تفعيل إعداد واحد {#opting-out-of-one-setting}

`plex_settings_policy` مُقسَّمة إلى مستويات، ولا يكون المستوى دائمًا هو المسألة المطروحة. المشغِّل الذي تنتقل ملفاته بين مجلدات المكتبة، مثلًا الفرز المدفوع بالوسوم، يعتمد على أن يفرِّغ Plex سلة المهملات الخاصة به ليمسح الإدخال الذي تركه الملف، والمستوى `guard` يوقف ذلك. أما الانتقال إلى `warn` لاستعادته فيُسقط حراس أحداث نظام الملفات أيضًا، وهي من المستوى نفسه وليست ما طلبوه.

`plex_settings_ignore` يسمّي الإعدادات واحدًا واحدًا:

```yaml
plex_settings_policy: guard
plex_settings_ignore:
  - autoEmptyTrash
```

تكتب لوحة التحكم هذا الإعداد نيابةً عنك. تحتوي صفحة الإعدادات على مفتاح **Let Plex Empty Its Own Trash** فوق إعدادات Library Trash Sweep. يضيف المفتاح `autoEmptyTrash` إلى هذه القائمة ويحذفه منها، ويترك بقية القائمة كما هي. يسري التفعيل عند إعادة التشغيل التالية.

الإعداد المتجاهَل ما زال يُقرأ ويظهر في لوحة التحكم وفي `zurg plex-settings` (معلَّمًا بـ `skip`)، فلا شيء مخفي. لكنه لا يُكتب أبدًا، ولا يُحسب مشكلةً، ولا يظهر خلف شريط سلة المهملات في لوحة التحكم. تُطابَق المعرّفات دون اعتبار لحالة الأحرف. أما المعرّف الذي لا يسمّي أي إعداد في الجداول أدناه فيُبلَّغ عنه عند البدء، ويبقى الإعداد محميًا، لأن الخطأ المطبعي يجب ألا يُفهم على أنه انسحاب.

تجاهل إعداد أمان يكون على مسؤوليتك، وتنبّه zurg إلى ذلك مرة واحدة عند البدء لا في كل تحديث. و`autoEmptyTrash` تحديدًا هو الإعداد الذي يفرّغ المكتبة كاملةً عندما يصادف الفحص تركيبًا انقطع لحظيًا. وتجاهله يعيد أيضًا مهمة التنظيف إلى Plex، انظر أدناه.

### من يفرغ سلة المهملات {#who-empties-the-trash}

إيقاف `autoEmptyTrash` يترك مهمة بلا من يقوم بها. طلب Plex ألا يمسح الإدخالات التي اختفت ملفاتها، ولفترة طويلة كانت إزالة zurg لهذه الإدخالات اختيارية، فكانت المكتبة تتراكم فيها إدخالات ميتة دون أن يلتقطها أحد. لم يكن أيٌّ من الطرفين مخطئاً، لكن الفجوة كانت حقيقية: هي ما يصطدم به المستخدم حين ينتقل ملف بين مجلدات المكتبة فيبقى الإدخال القديم إلى الأبد.

صار zurg الآن يتولى المهمة التي تخلّى عنها. عند ترك `plex_trash_sweep_every_mins` بلا قيمة، يزيل [الكنس الدوري لسلة المهملات](../internals/plex-trash-sweep.md) الإدخالات كل 60 دقيقة، لكن فقط حين لا يقوم بذلك أحدٌ غيره. إذا كان Plex ما زال يفرّغ سلة مهملاته بنفسه، لأن `plex_settings_policy` قيمته `off` أو `warn`، أو لأن `autoEmptyTrash` موجود في `plex_settings_ignore`، يتنحّى zurg ويترك الأمر لـ Plex. فوجود جامعَين للمهملات على مكتبة واحدة هو ما يحوّل الخلاف بينهما إلى عملية حذف.

الكنس الدوري أضيق بكثير من تفريغ Plex لسلته، وهذا هو سبب تفضيله. يحذف إدخالاً واحداً في كل مرة، ولا يحذف أي إدخال ما زال له ملف، ولا يعمل إلا على جهاز تركيب يُقرأ في تلك اللحظة، ويقتصر على 50 عملية حذف و10% من السلة في كل دورة. والإدخالات التي لا يملك zurg حكماً واضحاً عليها تبقى ظاهرة كمعطوبة لمدة 14 يوماً أولاً. كما يحتاج الكنس إلى ضبط `plex_database_path`، فيعمل فقط حيث يعمل Plex على هذا المضيف، وأن يشغّل zurg جهاز التركيب بنفسه (`rclone_enabled` مع ضبط `mount_path`). يقرأ zurg قاعدة البيانات هذه بالبرنامج `Plex SQLite` الذي يثبّته Plex، ويجده في المكان الذي يضعه فيه مثبّت Plex على Linux وmacOS وWindows، لذا فالمفتاح الوحيد الذي يلزم ضبطه هو `plex_database_path`:

+++ Linux
```yaml
plex_database_path: "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ macOS
```yaml
plex_database_path: "/Users/YOU/Library/Application Support/Plex Media Server/Plug-in Support/Databases/com.plexapp.plugins.library.db"
```
+++ Windows
```yaml
plex_database_path: 'C:\Users\YOU\AppData\Local\Plex Media Server\Plug-in Support\Databases\com.plexapp.plugins.library.db'
```
أبقِ علامات الاقتباس المفردة، لأن YAML داخل علامات الاقتباس المزدوجة يقرأ الشرطة المائلة العكسية على أنها محرف هروب. واضبط `plex_sqlite_binary` فقط إذا كان Plex مثبتاً في مكان آخر، مثل نسخة Plex ذات 32 بت: `'C:\Program Files (x86)\Plex\Plex Media Server\Plex SQLite.exe'`.
+++

استبدل `YOU` باسم مستخدمك، فـ zurg لا يفسّر `~` ولا `%LOCALAPPDATA%`. يطابق الكنس المسارات التي يخزنها Plex مع `mount_path`، وهذا يشمل حرف محرك مثل `Z:` (`pkg/utils/path_within.go`).

لإيقاف الإزالة وإفراغ السلة بنفسك، اكتب `plex_trash_sweep_every_mins: 0`. هذا رفض صريح، وهو يختلف عن ترك المفتاح غير موجود.

هذا المفتاح يوقف إزالة zurg فقط، ولا يعيد الإعداد إلى Plex. مع `guard` ما زال zurg يكتب `autoEmptyTrash` بقيمة off، فلن يفرّغ Plex سلته بعد الفحص، وتتراكم الإدخالات دون أن يلتقطها أحد. استخدم مفتاح لوحة التحكم أو `plex_settings_ignore` لتعيد المهمة إلى Plex.

### الأمان — يُصحَّح ضمن `guard` و `enforce` {#safety--corrected-under-guard-and-enforce}

| الإعداد | الافتراضي في Plex | ما يريده zurg | السبب |
|---|---|---|---|
| `autoEmptyTrash` | `1` | `0` | يفرّغ Plex سلة المهملات بعد كل فحص. إذا أصبح الـ mount غير قابل للقراءة لفترة وجيزة أثناء مرور الفحص عليه، فسيبدو كل ملف محذوفاً، وعندها يزيل Plex الملفات نهائياً بدلاً من تركها في السلة لتعود مع عودة الـ mount. |
| `FSEventLibraryUpdatesEnabled` | `0` | `0` | التحديثات المعتمدة على الأحداث تفوّت ما يتغيّر فعلاً هنا. شجرة zurg تتغيّر من جهتها الخاصة، وهذا التغيير لا يمرّ عبر النواة المحلية، فلا يُطلق أي حدث، فتبقى المكتبة متأخرة دون أن ينتبه أحد. أما الأحداث التي تصل فعلاً فهي عمليات كتابة تتم *عبر* الـ mount، وتحدث بينما لا يزال المجلد يُجمَّع. |
| `FSEventLibraryPartialScanEnabled` | `0` | `0` | الفحص الجزئي يعمل بناءً على تلك الأحداث نفسها، فيُطلق عند عمليات الكتابة القادمة عبر الـ mount، أي تحديداً عندما يكون المجلد مكتوباً نصفه، ولا يُطلق أبداً عند التغييرات من الجهة البعيدة، وهي التي كانت تحتاج فعلاً إلى فحص. |
| `ButlerTaskBackupDatabase` | `1` | `1` | النسخ الاحتياطي الليلي لقاعدة البيانات هو الشيء الوحيد الذي يستعيد مكتبة حذفها Plex بالفعل. |

هذه الإعدادات تُفقد بيانات لا وقتاً، ولهذا تكتب السياسة الافتراضية قيمها بدلاً من الاكتفاء بالتحذير. فقط `autoEmptyTrash` يأتي بالقيمة المدمّرة افتراضياً؛ أما الثلاثة الأخرى فقيمها الافتراضية هي بالفعل ما يريده zurg، وهي موجودة هنا لتنبيه المشغّل إذا كان قد فعّل أياً منها.

أُعيدت كتابة السببين الخاصّين بـ `FSEvent` بعد القياس، على كل منصة يركّب عليها zurg. الصياغة السابقة قالت إن mount من نوع FUSE "لا يُصدر هذه الأحداث بشكل موثوق، لذا فهو يُنتج فحوصات في لحظات لم يطلب أحد فيها فحصاً". والنصفان كلاهما خاطئان.

القياس جرى بتاريخ 2026-09-05: راقبت كل منصة بالواجهة البرمجية التي يستخدمها خادم الوسائط فعلاً، على mount من rclone يمكن تغيير مجلده الخلفي مباشرة. **A** هي عملية كتابة تتم عبر الـ mount؛ **B** هي الملف نفسه يظهر من الجهة البعيدة، كما يحدث عندما تتغير شجرة zurg من جهتها.

| المنصة | الـ mount | المراقبة بواسطة | A: عبر الـ mount | B: تغيير من الجهة البعيدة |
|---|---|---|---|---|
| Linux | `fuse.rclone` | inotify | `CREATE` `OPEN` `ATTRIB` `CLOSE_WRITE` | **بلا أحداث** |
| Docker | نفس الـ mount مُركّب كـ bind mount داخل حاوية | inotify، داخل الحاوية | نفس الأحداث الأربعة، كما تُرى داخل الحاوية | **بلا أحداث** |
| macOS | macFUSE | FSEvents | `Created IsFile` | **بلا أحداث** |
| Windows | WinFsp | `ReadDirectoryChangesW` | `Created` `Changed` | **بلا أحداث** |

وصلت كل المنصات الحدث A، وأنتج تحكّم مُتزامن على نظام ملفات أصلي (APFS، NTFS) الأحداث نفسها، أي أن المراقبين كانوا يعملون. ولم تصل أي منصة الحدث B، رغم أن الملف كان مرئياً عبر الـ mount بعد انتهاء صلاحية ذاكرة التخزين المؤقت للمجلد.

إذن نمط الفشل معكوس عما زُعم: التحديث المعتمد على الأحداث يُطلق عند عمليات الكتابة القادمة *عبر* الـ mount، كأن يصل استيراد من \*arr إلى مجلد لا يزال يُجمَّع، ولا يُطلق أبداً للتغييرات من الجهة البعيدة، وهي السبب الوحيد الذي يجعل الفحص مطلوباً أصلاً. المشكلة ليست أن الأحداث غير موثوقة؛ المشكلة أنها تبلّغ عن النصف الخاطئ مما يحدث على mount لخدمة debrid.

### عرض النطاق الترددي — يُصحَّح ضمن `enforce` فقط {#bandwidth--corrected-under-enforce-only}

كل واحد من هذه الإعدادات يجعل Plex يفكّ ترميز ملفات كاملة من أجل نتيجة لا ينظر إليها أحد. هذا لا يضر على التخزين المحلي، لكن فوق mount من debrid كل بايت يصبح طلبًا إلى المزوّد، وهذه العمليات تعمل على المكتبة كلها. أما التحليل الذي يكون ناتجه *مرئيًا* مثل معاينات التمرير، وصور الفصول، وتسوية مستوى الصوت، والتحليل الصوتي، فيُنقل بدلًا من ذلك إلى فئة الذوق أدناه، حيث لن يمسّه `enforce`.

| الإعداد | الافتراضي في Plex | ما يريده zurg |
|---|---|---|
| `ButlerTaskDeepMediaAnalysis` | `1` | `0` |
| `ButlerTaskUpgradeMediaAnalysis` | `1` | `0` |
| `GenerateAdMarkerBehavior` | `scheduled` | `never` |
| `GenerateVADBehavior` | `never` | `never` |
| `GenerateIndexFilesDuringAnalysis` | `0` | `0` |
| `ButlerTaskGenerateMediaIndexFiles` | `0` | `0` |

### الذوق — يُبلَّغ عنه دائماً ولا يُصحَّح أبداً {#taste--always-reported-never-corrected}

لكل من هذه الإعدادات ميزة وراءها، لذلك يذكر zurg التكلفة ويترك الاختيار لك. إيقاف أحدها دون طلب منك سيحرمك من شيء يراه المشغّل، وهذا ليس قراراً يتخذه zurg مهما كان سيوفّر من عرض النطاق. بالنسبة للإعدادين الأولين، الخيار الأرخص يُبقي الميزة ويُنقل العمل إلى نافذة الصيانة. أما بقية الإعدادات فالاختيار فيها بين الميزة وعرض النطاق.

| الإعداد | الافتراضي في Plex | ما يقترحه zurg | السبب |
|---|---|---|---|
| `GenerateIntroMarkerBehavior` | `asap` | `scheduled` أو `never` | يفكّ `asap` ترميز كل ملف فور وصوله، خارج أي نافذة صيانة. أما `scheduled` فيُبقي زر Skip Intro ويُنقل العمل إلى النافذة. |
| `GenerateCreditsMarkerBehavior` | `asap` | `scheduled` أو `never` | الأمر نفسه، لكن لزر Skip Credits. |
| `GenerateBIFBehavior` | `never` | `never` | يفكّ ترميز الفيديو كاملاً لبناء شريط الصور الذي يظهر أثناء التقديم والتأخير. التشغيل لا يحتاج إليه. |
| `GenerateChapterThumbBehavior` | `scheduled` | `never` | يفكّ ترميز الملف ليستخرج إطاراً واحداً لكل فصل، وهو الصورة المعروضة بجانب كل مدخل في قائمة الفصول. |
| `LoudnessAnalysisBehavior` | `scheduled` | `never` | يفكّ ترميز صوت كل ملف بالكامل لقياسه، وذلك لتسوية مستوى الصوت بين المقاطع والعناوين. |
| `MusicAnalysisBehavior` | `scheduled` | `never` | يفكّ ترميز كل مقطع صوتي. الملفات كثيرة وصغيرة، لذلك هذا هو الإعداد الذي يرفع عدد الطلبات ويؤدي إلى تقييد الحساب. يوفّر التحليل الصوتي مزجات لمقاطع متشابهة وعرض المؤثرات البصرية للصوت. |

### نافذة الصيانة {#the-maintenance-window}

لا يغيّر zurg قيمتي `ButlerStartHour` و`ButlerEndHour`، لأنه لا توجد ساعة واحدة تناسب الجميع. يستحق أن تضبطهما بنفسك. Plex يستخدم افتراضياً الفترة من 02:00 إلى 05:00، وإذا تداخلت هذه الفترة مع الساعات التي يشاهد فيها أحدٌ ما، فستتحول كل مهمة صيانة إلى تعطّل. وكل ما يبقى ضمن مستوى النطاق الترددي يعمل داخل هذه الفترة.

### إيقاف عملية قيد التنفيذ {#stopping-a-pass-already-in-flight}

تغيير التفضيل يوقف *التشغيلات القادمة* فقط، وليس التشغيل الجاري حالياً. يعيد Plex Media Server إنشاء العمليات الفرعية للماسح الضوئي، لذلك فإن إنهاءها لا يفيد بشيء:

+++ Linux و macOS
```bash
curl -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
+++ Windows
```powershell
curl.exe -X DELETE "http://localhost:32400/butler?X-Plex-Token=$TOKEN"
```
في Windows PowerShell 5.1 يكون `curl` اسماً آخر لـ `Invoke-WebRequest`، لذا اكتب `curl.exe`.
+++

اضبط `$TOKEN` على رمز Plex الخاص بك أولاً: `TOKEN=your-token` في الصدفة، و`$TOKEN = 'your-token'` في PowerShell.
