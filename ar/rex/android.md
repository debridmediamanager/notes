# rex لأندرويد {#rex-for-android}

rex هو خادم وسائط لتطبيقات Plex لا يملك أي ملفات. يعمل rex for Android على الهاتف أو الجهاز اللوحي أو Android TV أو Google TV أو Fire TV، دون الحاجة إلى حاسوب. تجد تطبيقات Plex على أجهزتك هذا الخادم كما تجد أي خادم Plex آخر، وتشغّل منه.

ما يُشغَّل يأتي من **الإضافات**. تبدأ المجموعة بأفلام الملكية العامة من Internet Archive. وتُثبَّت إضافات أخرى، مثل إضافات Stremio وYouTube وSpotify، من داخل التطبيق بعد أن تضيف مستودعها.

rex for Android مجاني. هل تريد أن تضيف إليه حسابات debrid وUsenet الخاصة بك أيضاً؟ zurg+rex، وهو خادم Plex على هاتفك مع zurg مدمج، يأتي مع اشتراك رعاية: راجع [zurg+rex for Android](../zurg/guides/android.md).

## قبل أن تبدأ {#before-you-start}

| تحتاج إلى | السبب |
|---|---|
| جهاز يعمل بنظام Android 8.0 أو أحدث | هاتف أو جهاز لوحي أو Android TV أو Google TV أو Fire TV |
| حساب Plex | يظهر rex في تطبيقات Plex المسجّل فيها. يكفي حساب مجاني |
| تطبيق Plex على الجهاز الذي تشاهد عليه | Plex for Android أو Android TV أو iPhone أو تلفاز ذكي أو Plex Web أو Plexamp |

التطبيق غير متاح على Google Play بعد. تحتاج إلى تثبيت ملف التطبيق (APK) بنفسك.

## الخطوة 1. نزّله {#step-1-download-it}

على الجهاز، نزّل الملف المناسب لمعالجه. كل رابط يشير دائمًا إلى أحدث إصدار:

| جهازك | التحميل |
|---|---|
| معظم الهواتف والأجهزة اللوحية وصناديق التلفاز (64-bit) | [rex-android-arm64-v8a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-arm64-v8a.apk) |
| الصناديق القديمة أو الأرخص ذات 32-bit، ومنها Fire TV Stick | [rex-android-armeabi-v7a.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-armeabi-v7a.apk) |
| المحاكيات على الكمبيوتر | [rex-android-x86_64.apk](https://github.com/debridmediamanager/rex-android/releases/latest/download/rex-android-x86_64.apk) |

كل الإصدارات وتغييراتها موجودة في [صفحة الإصدارات](https://github.com/debridmediamanager/rex-android/releases).

لست متأكدًا؟ جرّب `arm64-v8a` أولًا. الملف الواحد يعمل على الهواتف والتلفاز معًا.

## الخطوة 2. ثبّته {#step-2-install-it}

افتح الملف الذي نزّلته. سيسألك Android أولاً:

1. سيقول إنه **لا يُسمح بتثبيت التطبيقات غير المعروفة من هذا المصدر**. اضغط **Settings** (الإعدادات)، وفعّل **Allow from this source** (السماح من هذا المصدر)، ثم ارجع.
2. اضغط **Install** (تثبيت).

على جهاز TV box بدون متصفح، نزّل الملف باستخدام تطبيق تنزيل يستطيع فتح ملفات APK.

**ما الذي يجب أن تراه.** **rex** في قائمة تطبيقاتك.

## الخطوة 3. شغّل rex {#step-3-start-rex}

افتح **rex**. أول شاشة تقول **Welcome to rex.**

1. اضغط **Allow notifications**، ثم **Allow**. يعمل rex في الخلفية ويظهر له إشعار يمكنك إيقافه منه.
2. اضغط **Let rex keep running in the background**. في القائمة التي تفتح، اختر **rex** ثم اختر **Don't optimize**. في أندرويد الأحدث يكون الخيار **Allow background usage**، ثم **Unrestricted**. ارجع إلى rex. الزرّان الآن يبدآن بعلامة ✓.
3. **Name** هو الاسم الذي تعرضه تطبيقات Plex لهذا الخادم. غيّره إذا أردت.
4. اترك **Port** على `32400`. إذا كان خادم Plex آخر يعمل على هذا الجهاز بالفعل، سيقول لك rex **Another app here already uses this port, maybe a Plex server. Try 32500.** اكتب `32500`.
5. اضغط **Start rex**.

**ماذا يجب أن تشاهد.** **2 / 2** و **Sign in to Plex.**

| الشاشة الأولى | صفحة الفيلم في تطبيق Plex (الخطوة 5) |
|---|---|
| ![الشاشة الأولى لـ rex على أندرويد، مع حقلي الاسم والمنفذ وزر Start rex](../assets/rex/android-setup.webp) | ![فيلم صامت من عام 1916 من Internet Archive في صفحته داخل Plex لأندرويد](../assets/rex/android-plex-film.webp) |

## الخطوة 4. سجّل الدخول إلى Plex {#step-4-sign-in-to-plex}

اضغط **Sign in to Plex**. يعرض rex رمزًا: **On any phone or computer, go to plex.tv/link and enter** it.

- **على الهاتف أو الجهاز اللوحي** سيفتح المتصفح أيضًا صفحة Plex تقول **rex for Android would like to sign in to your Plex account**. سجّل الدخول هناك.
- **على التلفاز** افتح [plex.tv/link](https://plex.tv/link) على هاتفك أو حاسوبك، وسجّل الدخول وأدخل الرمز.

استخدم الحساب الذي سجّلت الدخول إليه في تطبيقات Plex. يمكنك الضغط على **Skip for now** وتسجيل الدخول لاحقًا من **Status**.

![rex for Android على التلفاز يعرض الرمز الذي يجب إدخاله في plex.tv/link](../assets/rex/android-tv-signin.webp)

**ما الذي يجب أن تراه.** **Signed in. rex shows up in the Plex apps as** اسم الخادم الخاص بك. اضغط **Done**. تُظهر **Status** الحالة **RUNNING** والرسالة **Ready for the Plex apps.**

## الخطوة 5. شاهد من تطبيق Plex {#step-5-watch-in-a-plex-app}

افتح أي تطبيق Plex مسجّل الدخول بنفس الحساب. إذا كان Plex على هذا الجهاز، فستجد في **Status** زر **Open Plex**.

في تطبيق Plex للأندرويد، افتح **Libraries**، ثم **All Libraries**، ثم **Movies** تحت اسم الخادم الخاص بك. تعرض تطبيقات Plex الأخرى المكتبة تحت اسم الخادم أيضاً.

تستغرق المزامنة الأولى لأرشيف الإنترنت وقتاً، نحو نصف ساعة على جهاز الاختبار لدينا، لأن rex يتحقق من كل فيلم. تبقى **Status** تعرض **Syncing** حتى تنتهي، ثم تعرض العدد، مثل **Ready · 97 titles**. اضغط على التشغيل لأي فيلم.

![تطبيق Plex على تلفاز يعرض فيلماً قصيراً لتشابلن من عام 1914 من rex على التلفاز نفسه](../assets/rex/android-tv-playing.webp)

## الإضافات {#addons}

**Addons** تعرض ما قمت بتثبيته. تعرض كل إضافة عناوينها ووقت آخر مزامنة لها. أزرارها هي **Sync now** و**Settings** و**Log** و**Remove**. على الهاتف، مرّر صف الأزرار جانبًا لترى كلها. مفتاح **Enabled** يوقف الإضافة دون حذفها.

تأتي الإضافات من **مستودعات**، وهي مستودعات git تحتوي على إضافات. يبدأ التطبيق ومعه إضافة [rex-addons](https://github.com/debridmediamanager/rex-addons)، وهي تقدم أفلام الملك العام من Internet Archive، وتكون مثبتة من البداية. لمزيد من الإضافات، أضف [rex-community-addons](https://github.com/debridmediamanager/rex-community-addons) (انظر **Add a repository** أدناه)، وهي تقدم:

| الإضافة | ما تضيفه |
|---|---|
| إضافات Stremio | كتالوجات الأفلام والمسلسلات من إضافات Stremio الخاصة بك، وتُشغَّل من البثوث التي تقدمها إضافات البث لديك |
| YouTube | قوائم تشغيل YouTube الخاصة بك. تسجل الدخول برمز |
| Spotify | مكتبة Spotify الخاصة بك كموسيقى لـ Plex وPlexamp. تحتاج إلى إضافة YouTube، وأن تكون مسجلاً فيها |

**تثبيت إضافة.** ضمن **Repositories**، اضغط **Addons** بجانب المستودع، ثم **Install** أسفل الإضافة. يعرض rex المواقع التي يمكنه الوصول إليها ويسألك مرة أخرى، ثم يبدأ بمزامنتها.

**تسجيل الدخول.** إضافة تحتاج إلى حسابك تعرض **Sign in to start.** اضغط زر **Sign in** الخاص بها: افتح الصفحة المذكورة على أي جهاز وأدخل الرمز الظاهر.

**إضافة مستودع.** ضمن **Add a repository**، اكتب رابطه (يكفي `github.com/user/repo`) واضغط **Add**. ثبّت فقط من أشخاص تثق بهم. لكتابة إضافتك الخاصة، راجع [rex-addons](https://github.com/debridmediamanager/rex-addons).

## شاهد على أجهزة أخرى في المنزل {#watch-on-other-devices-at-home}

كل تطبيق Plex مسجّل الدخول بنفس الحساب يجد rex على شبكتك المنزلية باسمه: التلفاز عندك، هاتف آخر، أو Plex Web على الكمبيوتر. تُظهر **Status** عنوان rex داخل المنزل، مثل `http://192.168.1.20:32400`.

إذا أردت أن تشاهد أفراد العائلة بحساباتهم الخاصة في Plex، فراجع [Share rex with family and friends](sharing.md).

## أبقه يعمل {#keep-it-running}

- يعمل rex طالما الجهاز مُشغّل. زر **Stop** في الإشعار يوقفه، وتحتوي **Status** على **Start** و**Stop** و**Restart**.
- في **Settings**، فعّل **Start when this device turns on**. وإلا افتح rex واضغط **Start** بعد إعادة التشغيل.
- بعض الهواتف ما زالت توقف التطبيقات التي تعمل في الخلفية. يشرح [Don't kill my app](https://dontkillmyapp.com/) ما يحتاجه تطبيقك.
- لتغيير اسم الخادم، افتح **Settings** ثم **General** في تطبيق Plex وغيّر **Friendly name**.

## القيود {#limits}

- **Funktioniert zu Hause.** Außerhalb deines Zuhauses brauchen Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür musst du auf deinem Router eine Portweiterleitung zu diesem Gerät einrichten. Siehe [Außerhalb deines Zuhauses nutzen](any-source.md#use-it-outside-your-home-optional).
- **Das Gerät ist der Server.** Lass es eingeschaltet, verbinde es per WLAN oder Ethernet und steck es ein. Wenn Videos für einen Player umgewandelt werden müssen, der eine Datei nicht abspielen kann, nutzt das die Hardware des Geräts. Auf einem günstigen Gerät kann das langsam sein.
- **Nur was Addons liefern.** Auf dem Gerät selbst liegt keine Dateibibliothek.
- **Noch nicht im Google Play Store.** Zum Aktualisieren installierst du die neue Datei aus [den Releases](https://github.com/debridmediamanager/rex-android/releases/latest) über die alte. rex startet danach von selbst neu. Deine Anmeldung und deine Addons bleiben erhalten.

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

| ما تراه | ما الذي تفعله |
|---|---|
| **App not installed as app isn't compatible with your phone.** | اخترت الملف الخطأ لمعالج جهازك. جرّب الملف الآخر من الجدول في الخطوة 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | اكتب `32500` كمنفذ |
| **Use a number from 1024 to 65535** | يجب أن يكون المنفذ رقمًا ضمن هذا النطاق |
| لا يظهر الخادم في تطبيق Plex | سجّل الدخول إلى تطبيق Plex بالحساب نفسه الذي استخدمته في الخطوة 4، وأبقِ الجهازين على شبكة المنزل نفسها |
| المكتبة فارغة | ما زالت المزامنة الأولى تعمل: انتظر حتى يظهر عدد من العناوين في **Status** |
| **Sign in needed** under an addon | اضغط على زر **Sign in** الخاص بها وأدخل الرمز |
| **That isn't a repository link. Try github.com/user/repo.** | اكتب رابط المستودع، مثل `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | الرابط خاطئ أو أن المستودع خاص. تحقق منه في المتصفح |
| rex يتوقف عندما تنطفئ الشاشة | أعد ضبط إعداد الخلفية في الخطوة 3، وراجع [لا تُغلق تطبيقي](https://dontkillmyapp.com/) |

**Logs** يعرض ما قاله rex والإضافات مؤخرًا، مع إخفاء المفاتيح وكلمات المرور. إذا طلب فريق الدعم السجلات، فاضغط على **Send logs to support**: سترى كل شيء قبل إرسال أي شيء، ثم اضغط على **Send** وانشر الرمز الذي تحصل عليه.

ما يرسله التطبيق وإلى أين يُرسل مذكور في [سياسة الخصوصية](android-privacy.md) الخاصة به.

هل علقت؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
