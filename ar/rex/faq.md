# أسئلة rex {#rex-questions}

Short answers to what people ask before they install rex, and soon after. Each answer links to the guide that has the details.

Wait — the translation target is Arabic. Here is the translation:

إجابات قصيرة لأكثر ما يسأله الناس قبل تثبيت rex، وبعد ذلك بقليل. كل إجابة ترتبط بالدليل الذي يحتوي على التفاصيل.

## قبل التثبيت {#before-you-install}

### ما هو rex؟ {#what-is-rex}

خادم وسائط للتطبيقات الرسمية لـ Plex، ولا يملك أي ملفات. يرى تطبيقاتك خادم Plex إضافيًا فيه الملصقات والمواسم وسجل المشاهدة و Continue Watching. يُخبر **المصدر** rex بما في المكتبة ويُقدّم كل ملف. يبثّ rex الملف عندما تضغط على التشغيل. لا يُنزَّل أي شيء أولًا.

إنه خادم مستقل بذاته. وليس إضافة لـ Plex Media Server ولا يحتاج إليها. شغّله بجانب Plex إذا أردت الاثنين معًا. يشرح [تثبيت rex](any-source.md#step-1-install-rex) معنى الأسماء، ويغطي [الانتقال من Plex إلى rex](from-plex.md) الطريقتين.

### كم تكلفته؟ {#what-does-it-cost}

rex مجاني للاستخدام الشخصي ولا توجد نسخة مدفوعة. شيفرته المصدرية عامة بموجب ترخيص PolyForm Noncommercial. الاستخدام التجاري غير مسموح. كل إصدار منشور على [GitHub Releases](https://github.com/debridmediamanager/rex/releases) ما عدا نسخة Android، التي تأتي فقط داخل [تطبيق zurg+rex لأندرويد](../zurg/guides/android.md) الخاص بالرعاة فقط، وهو خادم Plex على هاتفك.

بعض الأشياء المحيطة بـ rex قد تكلّف شيئاً:

| | |
|---|---|
| [rex-stremio](stremio.md)، تطبيقك الخاص أو إضافة كمصدر | مجاني |
| zurg nightly، مصدر لمكتبة debrid أو Usenet | ميزة لـ[رعاة DMM](https://gatekeeper.debridmediamanager.com) |
| مفتاح DMM API، لمطابقات DMM الدقيقة في zurg | اختياري، ويأتي أيضاً من رعاية DMM |
| صورة Docker الخاصة بـ rex | مجانية وعامة، لنظام Linux: [rex in Docker](any-source.md#run-rex-in-docker) |

### هل يتعرض حساب Plex الخاص بي للخطر؟ {#is-my-plex-account-at-risk}

rex ليس من إنتاج Plex، وقد تتخذ Plex إجراءً ضد حساب يُسجَّل فيه. استخدم **حساب Plex مجاني جديد** خصيصًا لـ rex، ثم شاركه مع حسابك. سجلّ المشاهدة وأصدقاؤك واشتراكك في Plex Pass يبقون على حسابك. يشرح [Add it to a Plex account](any-source.md#step-3-add-it-to-a-plex-account) الخطوات. استخدم rex على مسؤوليتك الخاصة.

### ما تطبيقات Plex التي تعمل معه؟ {#which-plex-apps-work}

| التطبيق | ما تم اختباره |
|---|---|
| Plex Web (app.plex.tv) | الأكثر: التصفح والتشغيل والتحويل والترجمات والموسيقى وLive TV، والتشغيل خارج المنزل باستخدام حسابات مجانية على الطرفين |
| Plex for Android (phone) | على Pixel 6: التشغيل والتحويل و[التنزيل من مزودك](direct-download.md). على محاكي: الموسيقى وLive TV |
| Plexamp | على محاكي Android: تصفح مكتبة موسيقى وتشغيلها، مع صور الفنانين وقوائم التشغيل |
| Plex for iOS | على iPad: التشغيل والتحويل. يوجد خلل في التطبيق مع Dolby Vision (انظر أدناه) |
| Plex for Apple TV | التشغيل، بما في ذلك القنوات المباشرة في المكتبة |
| Plex Desktop | Plex for Mac: التشغيل والتحويل |
| Plezy | على Pixel 6: التشغيل، والتنزيل من مزودك |
| Plex HTPC | لم يُختبر بعد |
| Plex for Android TV وNVIDIA Shield وGoogle TV | لم يُختبر بعد |
| Plex for Roku | لم يُختبر بعد |
| تطبيقات Smart TV (Samsung وLG وغيرها) | لم يُختبر بعد |
| Infuse | لم يُختبر بعد |

خارج المنزل، لم يُختبر سوى Plex Web.

### هل يشغّل 4K وHDR وDolby Vision؟ {#does-it-play-4k-hdr-and-dolby-vision}

لا، ليس ذلك صحيحاً، بل نعم: الملفات تُشغَّل بجودتها الأصلية. يسلّم rex الملف للتطبيق كما هو، والتطبيق هو الذي يقرر ما يستطيع عرضه. عندما لا يستطيع تطبيق تشغيل ملف كما هو، يحوّله rex إذا كان FFmpeg مُعدّاً ([تحويل الفيديو](any-source.md#converting-video-optional)). يحوّل التحويل فيديو HDR وDolby Vision إلى صورة قياسية (الإعدادات، Transcoder، **Enable HDR tone mapping**، وهو مفعّل افتراضياً)، ويُنفَّذ على معالج الرسوميات متى أمكن ذلك. مع تثبيت وقت تشغيل OpenCL الخاص بإنتل، يستطيع جهاز إنتل صغير (J4105) تحويل فيديو 4K بتقنية HDR10 وDolby Vision profile 5 إلى 1080p بسرعة قريبة من الوقت الفعلي. من دون FFmpeg، يظهر لملف لا يستطيع التطبيق تشغيله الرسالة "This server is not powerful enough to convert video". وإذا ظهرت هذه الرسالة لكل العناوين على كل الأجهزة، فإن FFmpeg ليس هو الحل: انظر [Nothing plays](#nothing-plays-or-every-app-says-it-is-not-powerful-enough).

**Plex لنظام iOS وDolby Vision.** يتوقف Plex for iOS 2026.20.0 عند 0:00 عندما يشغّل ملف Dolby Vision كما هو. ويتوقف خادم Plex Media Server حقيقي يقدّم الملف نفسه بالطريقة نفسها، إذن الخلل في التطبيق. أما ملفات HDR10 وSDR بدقة 4K فتُشغَّل بشكل طبيعي.

### هل أحتاج إلى Plex Pass؟ {#do-i-need-plex-pass}

لا. يخبر rex تطبيقات Plex بأن الحساب المسجَّل عليه يملك Plex Pass، لذلك يعمل التشغيل خارج المنزل وتحويل الفيديو مع الحسابات المجانية. جُرّب التشغيل خارج المنزل في Plex Web باستخدام حساب مجاني على الطرفين، أما التطبيقات الأخرى فلم تُختبر خارج المنزل بعد. وتعمل أيضاً إصدارات الأفلام، وDashboard، وDownloads، وتخطي المقدمة والنهاية، وبقية [قدرات الأفلام والمسلسلات](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#movie-and-tv-capabilities). لكن قد يطبّق كل تطبيق قواعده الخاصة أيضاً.

### هل يمكنني التنزيل للمشاهدة دون اتصال؟ {#can-i-download-for-offline-viewing}

ميزة **Downloads** موجودة في تطبيقات Plex. يُجهّز rex التنزيل على جهازه بنفسه، إما كالملف الأصلي أو بعد تحويله باستخدام FFmpeg، ويحتفظ به في مجلد بجانب `rex.db` إلى أن يجلبه التطبيق. الحساب الذي سجّلت به rex يمكنه التنزيل في أي وقت. أما من تشاركه معه فيحتاج إلى السماح بالتنزيلات في مشاركته ([مشاركة rex](sharing.md#what-each-person-may-see-and-do)). وقد يطبّق التطبيق قواعده الخاصة أيضًا. الملف المحوّل لا يتضمن ترجمات النص. حفظ تنزيل على الهاتف ومشاهدته دون اتصال لم يُختبر بعد.

### هل يمكن لعدة أشخاص استخدامه، لكل منهم سجله الخاص؟ {#can-several-people-use-it-each-with-their-own-history}

لا، هذا ليس مطلوبًا؛ لكل شخص تشاركون معه rex حسابه الخاص. نعم، كل شخص تشاركون معه rex يسجّل الدخول باسمه ويحصل على حالة المشاهدة الخاصة به، وقائمة "Continue Watching"، والتقييمات، وقوائم التشغيل. ويمكن لكل شخص أن ينسخ سجل مشاهدته من خادم Plex قديم ([Bring your watch history](import-watched.md)). يشرح [Share rex with family and friends](sharing.md) الخطوات، بما في ذلك المستخدمون المُدارون للأطفال.

### ما المواصفات المطلوبة للجهاز؟ {#what-hardware-does-it-need}

جهاز يبقى مشغّلاً طوال الوقت، ويعمل بنظام Linux (بمعالج amd64 أو arm64، مع glibc 2.35 أو أحدث، أي Ubuntu 22.04 وما بعده)، أو macOS (Intel أو Apple Silicon)، أو Windows 64 بت؛ أو تطبيق zurg+rex لأجهزة Android/Google TV (يعمل بنظام 64 بت حتى النسخة الليلية بتاريخ 11 نوفمبر 2026)، والذي يشغّل zurg وrex معاً (للداعمين فقط؛ راجع [دليل Android](../zurg/guides/android.md)).

**الذاكرة:** خصص لها 1 GB. على مكتبة تضم 4,062 فيلماً و656 مسلسلاً، استخدم rex أقل من 500 MB أثناء البدء، ونحو 730 MB أثناء تصفح المكتبة. تحويل الفيديو يحتاج ذاكرة إضافية فوق ذلك.

**القرص:** لا يحتاج إلى مساحة للأفلام. يحتفظ rex بمكتبته في `rex.db`. التنزيلات والصور التي يُنشئها التحليل (معاينات التقديم، وصور الفصول) تُحفظ بجانبه أيضاً، إذا كنت تستخدمها.

**التحويل:** يتم فقط باستخدام FFmpeg. شريحة الرسوميات تجعله أسرع: فيلم 1080p يبدأ تحويله على معالج Intel صغير في نحو ثانيتين. الشرائح التي يستخدمها rex على كل نظام مذكورة في [حسب المنصة](https://github.com/debridmediamanager/rex/blob/main/docs/setup.md#by-platform): على macOS يتم التحويل دائماً على المعالج.

### هل يقرأ ملفاتي المحلية؟ {#does-it-read-my-local-files}

لا. rex لا يفحص مجلداً أو قرصاً ولا يحتاج إلى تركيب (mount). كل ملف يأتي من مصدر عبر HTTP. ويمكن مع ذلك إدخال الملفات الموجودة على قرصك الخاص: يجب أن يخدمها شيء ما ويُبلغ rex عنها، كما يوضح [rex مع تطبيقك الخاص](any-source.md).

### هل يعمل مع Usenet؟ {#does-it-work-with-usenet}

نعم، عن طريق مصدر يقرأ من Usenet مثل zurg. لا يتصل rex أبدًا بمزوّد Usenet: يقرأ المصدر الملفات ويقدّمها إلى rex كأي ملف آخر. اضبط zurg لهذا الغرض باتباع [Usenet](../zurg/guides/usenet.md)، ثم وجّهه إلى rex كما في [rex مع zurg](with-zurg.md).

### هل أحتاج إلى zurg؟ {#do-i-need-zurg}

لا. zurg مصدر واحد من بين مصادر أخرى. يقبل rex أي شيء يتحدث واجهة الـ feed الخاصة به:

- [rex مع تطبيقك الخاص](any-source.md): أي تطبيق يقدم الملفات عبر HTTP
- [rex مع إضافات Stremio الخاصة بك](stremio.md): كتالوجات من إضافات Stremio
- [rex مع zurg](with-zurg.md): حسابك على debrid أو Usenet
- [بناء إضافات rex](addons.md): فيديوهات منزلية أو تسجيلات أو قنوات، ببرنامج خاص بك، وثلاثة [دروس](addon-home-videos.md) للبدء منها

يمكن لعدة مصادر أن تملأ مكتبات Movies وTV نفسها.

### هل أحتاج إلى فتح منفذ (port forwarding)؟ {#do-i-need-to-forward-a-port}

لستَ في المنزل. تجد تطبيقات Plex على شبكتك المنزلية rex دون الحاجة إلى تغيير إعدادات الراوتر. يعمل app.plex.tv أيضًا عبر عنوان HTTPS الذي يمنحه [الاتصال المباشر بـ rex](any-source.md#rex-direct) لـ rex الذي قمتَ بربطه.

يحتاج rex إلى عنوان خاص به لمشاهدته من خارج المنزل أو لأسرة أخرى. أبسط طريقة هي توجيه منفذ واحد (port forward) ([الاتصال المباشر بـ rex](any-source.md#rex-direct)). إذا كان لديك IPv6 ولا يوجد عنوان IPv4 عام، استخدم [الاتصال المباشر بـ rex عبر IPv6](any-source.md#rex-direct-over-ipv6). لا يحتاج [Tailscale serve](any-source.md#tailscale-serve) إلى توجيه منفذ على الأجهزة التي تشغّل Tailscale. يقارن [استخدامه خارج منزلك](any-source.md#use-it-outside-your-home-optional) الخيارات المتاحة.

### ما الذي لا يفعله؟ {#what-does-it-not-do}

لا يوجد مُعالج تلفزيون (tuner) ولا DVR. الموسيقى والبث المباشر للتلفزيون والصور تحتاج إلى مصدر يرسلها. راجع [الموسيقى مع rex](music.md) و[البث المباشر للتلفزيون مع rex](live-tv.md). يرسل zurg كتب الكوميكس كصور يعرضها Plex Web. محطات الراديو وخلطات Plexamp الراديوية غير متوفرة. لا يحتوي rex على خادم وسيط (relay)، لذا يحتاج الاستخدام عن بُعد إلى عنوانه الخاص ([استخدمه خارج منزلك](any-source.md#use-it-outside-your-home-optional)).

## بعد التثبيت {#after-you-install}

### لماذا يعرض التطبيق إصدار Plex وخيار "Check for Updates"؟ {#why-does-the-app-show-a-plex-version-and-check-for-updates}

rex يعرّف نفسه للتطبيقات وlplex.tv على أنه Plex Media Server، لذلك تعرض التطبيقات رقم إصدار Plex Media Server. هذا الرقم ليس رقم rex. **Check for Updates** يجيب دائمًا بأن الخادم محدّث، لأن rex لا يحدّث نفسه أبدًا. لتحديث rex، نزّل نسخة nightly أحدث كما هو موضّح في [Updating](any-source.md#updating).

### لماذا لا يعرض متصفحي على 32400/web أي مكتبة؟ {#why-does-my-browser-at-port-32400web-not-open-a-library}

rex ليس له تطبيق ويب خاص به. فتح `http://<rex's LAN IP>:32400/web` يعرض صفحة حالة قصيرة. شاهد من تطبيق Plex أو من المتصفح على [app.plex.tv](https://app.plex.tv).

![الصفحة التي يعرضها rex على /web قبل أن يتم ربطه](../assets/rex/80-rex-web-page.webp)

### ما الذي يغادر جهازي؟ {#what-leaves-my-machine}

- **plex.tv، عند البدء ومرة في اليوم، سواء كنت مسجلاً أم لا:** معرّف الخادم واسمه وإصداره، لقراءة قائمة Plex العامة بالإصدارات والحصول على أحدث رقم إصدار.
- **plex.tv، بعد التسجيل في حساب Plex:** رمز المطالبة (claim)، وعناوين الخادم (عنوان الشبكة المحلية LAN وعناوين HTTPS) وأسماء مكتباتك.
- **خدمة البيانات الوصفية لـ Plex، بعد التسجيل:** معرّف كل عنوان، للحصول على اسمه وملصقه وملخصه وحلقاته. عند البحث عن ترجمات، سواء بـ **Search Subtitles** أو عبر إعداد الترجمة التلقائية لأحد الأشخاص، يُرسَل اسم الملف وبصمته.
- **مضيفو الصور المصغّرة، عندما يعرضها تطبيق:** طلبات للملصقات والصور التي تذكرها مصادرك.
- **DMM، لـ rex-direct، بعد التسجيل ثم كل 6 ساعات:** معرّف الخادم ورمزه على حساب Plex وعنوان IP المحلي له. يتحقق DMM من plex.tv أن الخادم يخصك، ويرى عنوان IP العام لديك، ويوجّه أسماء rex-direct الخاصة بك إليه وإلى عنوان IP المحلي. إذا كان للجهاز عنوان IPv6 عالمي، يرسله rex أيضاً، بعد دقيقة من بدئه (أو من المطالبة به) ثم كل 6 ساعات، وفي كل مرة يتصل فيها DMM به ليتأكد من أنه يصل إلى الخادم نفسه. لإيقاف ذلك، استخدم `REX_DIRECT_URL=off`.
- **مصادرك، عند التشغيل أو الحذف:** طلبات للملفات التي تشغّلها، وعمليات الحذف (انظر أدناه).
- **خادم Plex القديم، فقط عند [نقل سجل المشاهدة](import-watched.md):** طلبات لسجل مشاهدتك.
- **Webhooks، فقط إذا أعددت أيّاً منها:** أحداث، إلى العناوين التي حددتها.

لا يسأل rex أحداً عمّا يكون الإصدار، بل المصدر هو من يقرر ويخبر rex. فـ zurg مثلاً يسأل DMM ([لماذا يضع DMM الملفات](with-zurg.md#why-dmm-places-the-files)).

### هل يؤدي الحذف من تطبيق Plex إلى حذف الملف؟ {#does-deleting-in-a-plex-app-delete-the-file}

نعم. حذف فيلم أو حلقة من تطبيق Plex، وأنت مسجّل الدخول بالحساب الذي سجّلت به rex، يحذف ملفاتها من المصدر، تماماً كما يحذف خادم Plex الملفات من قرصه. أما المصدر الموجود على حساب debrid، مثل zurg، فيحذفها من هناك. إذا رفض المصدر الحذف، يبقى العنوان ويُظهر التطبيق رسالة تفيد بأنه لم يتمكن من الحذف. الأشخاص الذين تشاركهم المكتبة لا يستطيعون الحذف. يشرح [الحذف من تطبيق Plex](any-source.md#step-5-watch-something) كيفية إيقاف هذا الخيار.

### لا يشغل شيء شيئًا، أو تقول كل التطبيقات إنه غير قوي بما يكفي {#nothing-plays-or-every-app-says-it-is-not-powerful-enough}

ألقِ نظرة على سجل rex مباشرة بعد أن تضغط على Play. إذا ظهر فيه `upstream failed` أو `502`، فهذا يعني أن rex لا يستطيع الوصول إلى مصدرك على العنوان الذي أعطاه إياه المصدر، وتثبيت FFmpeg لن يحل المشكلة. السبب المعتاد هو zurg داخل Docker Desktop على Windows أو macOS. الصف الخاص بـ `upstream failed` في [rex مع zurg](with-zurg.md#when-something-is-wrong) أو [rex مع تطبيقك الخاص](any-source.md#when-something-is-wrong) يتحقق من العنوان ويخبرك بما يجب تغييره. إذا فشلت بعض الملفات فقط، وغالبًا فقط في المتصفح، فالجهاز لا يستطيع تشغيلها كما هي، فقم بإعداد [تحويل الفيديو](any-source.md#converting-video-optional).

### عنوان مطابَق بشكل خاطئ. كيف أصلحه؟ {#a-title-is-matched-wrong-how-do-i-fix-it}

المصدر هو الذي يحدد ما هو كل ملف، وrex يعرض ذلك العنوان. سجّل الدخول بالحساب المسجّل عليه rex واستخدم **Fix Match**: يحتفظ rex باختيارك، ويمكن للمصدر أن يقرأه ويحتفظ به على أنه التطابق لذلك الإصدار، كما يفعل zurg ([Why DMM places the files](with-zurg.md#why-dmm-places-the-files)).

### أين أجد المساعدة؟ {#where-do-i-get-help}

[المساعدة عن بُعد](../guides/remote-help.md) توضح أين تطلب المساعدة وما الذي يجب أن تضمّنه في طلبك: منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP)، والمساعدة عن بُعد للرعاة.
