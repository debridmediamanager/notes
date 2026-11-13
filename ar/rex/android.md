# rex لأندرويد {#rex-for-android}

rex هو خادم وسائط لتطبيقات Plex لا يملك أي ملفات. يعمل rex for Android على الهاتف أو الجهاز اللوحي أو Android TV أو Google TV أو Fire TV، دون الحاجة إلى حاسوب. تجد تطبيقات Plex على أجهزتك هذا الخادم كما تجد أي خادم Plex آخر، وتشغّل منه المحتوى.

ما يتم تشغيله يأتي من **الإضافات**. تبدأ الأمور بأفلام الملك العام من Internet Archive. يمكنك تثبيت إضافات أخرى، مثل إضافات Stremio و YouTube و Spotify، من داخل التطبيق.

rex for Android مجاني. هل تريد إضافة حسابات debrid و Usenet إليه أيضًا؟ zurg+rex، وهو خادم Plex على هاتفك مع zurg مدمج، يأتي برعاية: راجع [zurg+rex for Android](../zurg/guides/android.md).

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

افتح **rex**.‏ الشاشة الأولى تقول **Welcome to rex.**

1. اضغط **Allow notifications**، ثم **Allow**. يعمل rex في الخلفية ويظهر له إشعار يمكنك إيقافه منه.
2. اضغط **Let rex keep running in the background**. في القائمة التي تفتح، اختر **rex** ثم **Don't optimize**. في أندرويد الأحدث يكون الخيار **Allow background usage**، ثم **Unrestricted**. ارجع إلى rex. سيبدأ الزران الآن بعلامة ✓.
3. **Name** هو الاسم الذي تعرضه تطبيقات Plex لهذا الخادم. غيّره إذا أردت.
4. اترك **Port** على `32400`. إذا كان هناك خادم Plex آخر يعمل على هذا الجهاز، سيقول rex **Another app here already uses this port, maybe a Plex server. Try 32500.** اكتب `32500`.
5. اضغط **Start rex**.

**ما يجب أن تراه.** **2 / 2** و**Sign in to Plex.**

## الخطوة 4. سجّل الدخول إلى Plex {#step-4-sign-in-to-plex}

اضغط على **Sign in to Plex**. يعرض rex رمزًا: **On any phone or computer, go to plex.tv/link and enter** it.

- **على الهاتف أو الجهاز اللوحي** سيفتح متصفحك أيضًا صفحة Plex تقول **rex for Android would like to sign in to your Plex account**. سجّل الدخول هناك.
- **على التلفاز** ادخل إلى [plex.tv/link](https://plex.tv/link) من هاتفك أو حاسوبك، وسجّل الدخول وأدخل الرمز.

استخدم الحساب الذي سجّلت الدخول إليه في تطبيقات Plex الخاصة بك. يمكنك الضغط على **Skip for now** وتسجيل الدخول لاحقًا من **Status**.

**ما الذي يجب أن تراه.** **Signed in. rex shows up in the Plex apps as** اسم الخادم الخاص بك. اضغط على **Done**. تُظهر **Status** الحالة **RUNNING** و**Ready for the Plex apps.**

## الخطوة 5. شاهد من تطبيق Plex {#step-5-watch-in-a-plex-app}

Open any Plex app signed in to the same account. If Plex is on this device, **Status** has an **Open Plex** button.

في تطبيق Plex على Android، افتح **Libraries** ثم **All Libraries**، ثم **Movies** تحت اسم الخادم الخاص بك. تطبيقات Plex الأخرى تعرضها أيضًا تحت اسم الخادم.

المزامنة الأولى لـ Internet Archive تأخذ وقتًا: حوالي نصف ساعة على جهاز الاختبار الخاص بنا، while rex يتحقق من كل فيلم. تعرض **Status** الحالة **Syncing** حتى تنتهي، ثم العدد مثل **Ready · 97 titles**. اضغط تشغيل على أي فيلم.

## الإضافات {#addons}

**Addons** lista los que tienes instalados. Cada uno muestra sus títulos y cuándo se sincronizó por última vez. Sus botones son **Sync now**, **Settings**, **Log** y **Remove**; en el móvil, desliza la fila de botones hacia los lados para verlos todos. El interruptor **Enabled** desactiva un addon sin eliminarlo.

Los addons vienen de **repositories**: repositorios de git que contienen addons. La app empieza con [rex-addons](https://github.com/debridmediamanager/rex-addons) añadido, que ofrece:

| Addon | Qué aporta |
|---|---|
| Internet Archive | Películas de dominio público. Instalado desde el principio |
| Stremio addons | Los catálogos de películas y series de tus addons de Stremio, reproducidos desde los streams que te dan tus addons de streams |
| YouTube | Tus listas de reproducción de YouTube. Inicias sesión con un código |
| Spotify | Tu biblioteca de Spotify como música para Plex y Plexamp. Necesita el addon de YouTube, con sesión iniciada |

**Instala uno.** En **Repositories**, pulsa **Addons** junto a un repositorio y luego **Install** debajo del addon. rex te muestra a qué sitios web puede acceder y te vuelve a preguntar una vez, y después empieza a sincronizarlo.

**Inicia sesión.** Un addon que necesita tu cuenta dice **Sign in to start.** Pulsa su botón **Sign in**: ve a la página que te indica desde cualquier dispositivo e introduce el código que aparece.

**Añade un repositorio.** En **Add a repository**, escribe su enlace (`github.com/user/repo` es suficiente) y pulsa **Add**. Instala solo desde personas en las que confíes. Para escribir tu propio addon, consulta [rex-addons](https://github.com/debridmediamanager/rex-addons).

## شاهد على أجهزة أخرى في المنزل {#watch-on-other-devices-at-home}

كل تطبيق Plex مسجّل الدخول بنفس الحساب يجد rex على شبكتك المنزلية باسمه: التلفاز عندك، هاتف آخر، أو Plex Web على الكمبيوتر. تُظهر **Status** عنوان rex داخل المنزل، مثل `http://192.168.1.20:32400`.

إذا أردت أن تشاهد أفراد العائلة بحساباتهم الخاصة في Plex، فراجع [Share rex with family and friends](sharing.md).

## أبقه يعمل {#keep-it-running}

- يعمل rex طالما الجهاز مُشغّل. زر **Stop** في الإشعار يوقفه، وتحتوي **Status** على **Start** و**Stop** و**Restart**.
- في **Settings**، فعّل **Start when this device turns on**. وإلا افتح rex واضغط **Start** بعد إعادة التشغيل.
- بعض الهواتف ما زالت توقف التطبيقات التي تعمل في الخلفية. يشرح [Don't kill my app](https://dontkillmyapp.com/) ما يحتاجه تطبيقك.
- لتغيير اسم الخادم، افتح **Settings** ثم **General** في تطبيق Plex وغيّر **Friendly name**.

## القيود {#limits}

- **Funktioniert zu Hause.** Außerhalb deines Zuhauses brauchen die Plex-Apps eine HTTPS-Adresse, die das Gerät erreicht. Dafür musst du an deinem Router eine Portweiterleitung auf das Gerät einrichten. Siehe [Außerhalb deines Zuhauses nutzen](any-source.md#use-it-outside-your-home-optional).
- **Das Gerät ist der Server.** Lass es eingeschaltet, mit WLAN oder Ethernet verbunden und am Strom. Wenn Videos für einen Player umgewandelt werden müssen, der eine Datei nicht abspielen kann, nutzt das die eigene Hardware des Geräts. Auf einem günstigen Gerät kann das langsam sein.
- **Nur, was Addons liefern.** Auf dem Gerät selbst liegt keine Dateibibliothek.
- **Noch nicht im Google Play Store.** Zum Aktualisieren installierst du die neue Datei aus [den Releases](https://github.com/debridmediamanager/rex-android/releases/latest) über die alte. Öffne dann rex und tippe auf **Start**. Deine Anmeldung und deine Addons bleiben erhalten.

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

| ما تراه | ما يجب فعله |
|---|---|
| **App not installed as app isn't compatible with your phone.** | اخترت الملف الخطأ لمعالج هاتفك. جرّب الملف الآخر من الجدول في الخطوة 1 |
| **Another app here already uses this port, maybe a Plex server. Try 32500.** | اكتب `32500` كرقم للمنفذ |
| **Use a number from 1024 to 65535** | يجب أن يكون المنفذ رقمًا ضمن هذا النطاق |
| الخادم غير ظاهر في تطبيق Plex | سجّل الدخول إلى تطبيق Plex بالحساب نفسه الذي استخدمته في الخطوة 4، واجعل الجهازين على شبكة المنزل نفسها |
| المكتبة فارغة | المزامنة الأولى ما زالت تعمل: انتظر حتى يعرض **Status** عددًا من العناوين |
| **Sign in needed** under an addon | اضغط زر **Sign in** الخاص بها وأدخل الرمز |
| **That isn't a repository link. Try github.com/user/repo.** | اكتب رابط المستودع، مثل `github.com/user/repo` |
| **no public git repository there (it asks for a login)** | الرابط خاطئ أو أن المستودع خاص. تحقق منه في المتصفح |
| يتوقف rex عندما تُطفأ الشاشة | أعد ضبط إعداد الخلفية في الخطوة 3، وراجع [Don't kill my app](https://dontkillmyapp.com/) |

**Logs** يعرض ما قاله rex والإضافات مؤخرًا، مع إخفاء المفاتيح وكلمات المرور. إذا طلب الدعم السجلات، اضغط **Send logs to support**: سترى كل شيء قبل إرساله، ثم اضغط **Send** وأرسل الرمز الذي تحصل عليه.

تحتاج مساعدة؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP).
