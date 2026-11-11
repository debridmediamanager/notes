# متابعة قائمة في Sonarr وRadarr {#following-a-list-in-sonarr-and-radarr}

تستطيع Sonarr وRadarr متابعة قائمة من المسلسلات أو الأفلام. تُضاف كل عنوان موجود فيها وتُبحث عنه. ومع zurg كعميل تنزيل، تصل كل عملية تنزيل إلى حساب debrid الخاص بك وتُستورد إلى `__magic__` مثل أي عملية أخرى. لذلك تصبح القائمة قسمًا كاملًا من المكتبة يمتلئ بنفسه. فقائمة الرعب مثلًا تمنحك قسم رعب، وتظهر فيه عناوين جديدة كلما كبرت القائمة.

تفترض هذه الصفحة أن \*arrs تُنزّل بالفعل عبر zurg. إذا لم تكن كذلك بعد، فابدأ بـ [Sonarr وRadarr للتورنتات](sonarr-radarr-torrents.md).

## استخدم MDBList وليس IMDb {#use-mdblist-and-not-imdb}

ما زال التطبيقان يعرضان نوع قائمة IMDb، ولا يعمل أي منهما مع قائمة IMDb العادية بعد الآن.

- يرفض Radarr معرّف القائمة بالشكل `ls12345678`. يقبل فقط `top250` أو `popular` أو قائمة المشاهدة الخاصة بالمستخدم `ur12345678`.
- يقبل Sonarr المعرّف، ثم يحصل على رد فارغ من IMDb. يقول زر Test: `Imdb call resulted in an unexpected StatusCode [Accepted]`.

[MDBList](https://mdblist.com) هو الحل البديل لكلتا المشكلتين. ينشر أي قائمة كملف JSON يقرؤه التطبيقان من خلال نوع Custom List. القوائم الخاصة بالأفلام والمسلسلات منفصلة، لذا تضيف قائمة واحدة لكل تطبيق.

## 1. اختر قائمة {#1-pick-a-list}

لا تحتاج القوائم العامة إلى حساب. ابحث في MDBList عن النوع الذي تريده وافتح قائمة. قائمتان للرعب تعملان حتى أكتوبر 2026

| القائمة | تحتوي على | رابط التغذية |
|---|---|---|
| Horror | movies | `https://mdblist.com/lists/garycrawfordgc/horror/json` |
| Horror Shows | shows | `https://mdblist.com/lists/garycrawfordgc/horror-shows/json` |

رابط التغذية هو رابط صفحة القائمة مع `/json` في نهايته. افتحه في المتصفح أولاً. يفترض أن ترى صفحة نصية تبدأ بـ `[{"id":`.

لإنشاء قائمتك الخاصة، سجّل الدخول إلى MDBList وأنشئ قائمة. يمكنها أن تتبع فلاتر مثل النوع والحد الأدنى للتقييم، أو أن تنسخ قائمة IMDb تملكها بالفعل. يعمل رابط التغذية بالطريقة نفسها.

## 2. أضفها إلى Radarr {#2-add-it-to-radarr}

**Settings → Import Lists → + → Custom Lists**

| Field | Value |
|---|---|
| Name | أي اسم تريده، مثلاً `Horror` |
| Enable | تشغيل |
| Enable Automatic Add | تشغيل |
| Search on Add | اقرأ التحذير أدناه أولاً |
| Monitor | Movie Only |
| Root Folder | مجلد الأفلام الخاص بك داخل `__magic__`، مثلاً `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` على macOS، و`Z:\__magic__\movies` على Windows) |
| Quality Profile | الملف الشخصي الذي تستخدمه |
| List URL | رابط قائمة الأفلام |

اضغط على **Test** ثم **Save**.

## 3. أضفها إلى Sonarr {#3-add-it-to-sonarr}

**الإعدادات → Import Lists → + → Custom List**

| الحقل | القيمة |
|---|---|
| Name | أي اسم تريده، مثلاً `Horror Shows` |
| Enable Automatic Add | مفعّل |
| Monitor | All Episodes، أو Pilot Episode إذا أردت تجربة المسلسل أولاً |
| Root Folder | مجلد المسلسلات داخل `__magic__`، مثلاً `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` على macOS، و`Z:\__magic__\tv` على Windows) |
| Quality Profile | الملف الذي تستخدمه |
| Series Type | Standard |
| Season Folder | مفعّل |
| Search for Missing Episodes | اقرأ التحذير أدناه أولاً |
| List URL | رابط تغذية المسلسلات |

اضغط **Test** ثم **Save**.

## القوائم الكبيرة تسحب كل شيء دفعة واحدة {#big-lists-grab-everything-at-once}

قائمة بها خيار Search on add مفعّل ستجلب كل عنوان في اللحظة التي تتم فيها المزامنة. تحتوي قائمة الأفلام أعلاه على 400 عنوان، وقائمة المسلسلات على 148 مسلسلًا بكل حلقاتها. هذا عدد كبير من عمليات الجلب دفعة واحدة. سيشعر بها حساب الـ debrid الخاص بك والمفهرسات، وإذا كان لدى أحد المفهرسات حد لعدد الطلبات فسيبدأ برفض عمليات البحث.

هناك طريقتان أهدأ للبدء.

- اترك خيار Search on add غير مفعّل. ستتم إضافة العناوين ووضعها تحت المراقبة دون أي بحث. ابحث عن العناوين التي تريدها من صفحة Movies أو Series.
- ابدأ بقائمة قصيرة. أضف القائمة الكبيرة بعد أن تصل الدفعة الأولى.

تقوم التطبيقات أيضًا بمزامنة القوائم وفق جدولها الخاص. لتشغيل المزامنة الآن، اختر **System → Tasks → Import List Sync**.

## إزالة قائمة {#removing-a-list}

حذف قائمة يوقف وصول عناوين جديدة منها. العناوين التي أضافتها سابقاً تبقى كما هي. ضمن **Settings → Import Lists**، يحدد **Clean Library Level** ما يحدث للعناوين التي تختفي من القائمة. اتركه على Disabled إلا إذا أردت أن تقوم التطبيقات بالحذف عنك.
