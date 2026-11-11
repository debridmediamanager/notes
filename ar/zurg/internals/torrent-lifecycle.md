# دورة حياة التورنت على Real-Debrid وAllDebrid وTorBox {#torrent-lifecycle-on-real-debrid-alldebrid-and-torbox}

**تم القياس بتاريخ 2026-08-30 على حسابات حية.** كل ما هو مكتوب أدناه بعلامة **observed** جاء من التقاط للبيانات. وكل ما هو مكتوب بعلامة **inferred** لم يأتِ من ذلك، والنص يوضح السبب.

يحتاج zurg إلى هذا لأن شيم qBittorrent يجب أن يخبر Sonarr وRadarr بالمرحلة التي وصل إليها التنزيل. ولا يستطيع zurg فعل ذلك اليوم. فحقل `TorrentInfo.Status` يحمل مفردات حالة Real-Debrid، وحزم AllDebrid وTorBox تحوّل حالاتها إليها قبل أن يرى كود zurg نفسه أي torrent. وتصل حالة TorBox `stalled (no seeds)` على أنها `queued`. ولا يُمرَّر أي شيء عن seeders أو speed أو eta على الإطلاق. لذلك كان لا بد من بناء جدول المراحل من البيانات الخام على الشبكة، لا من حزم المزودين التي تقوم أصلاً بتوحيد هذه الحالات وإخفائها.

أداة الاختبار هي `scripts/torrent_lifecycle_probe.py`. وهي تتصل مباشرة بواجهات REST الخام، فتكون الالتقاطات حالة wire الخام. وتحذف كل ما تضيفه أثناء العمل، حتى عند الضغط على Ctrl-C.

---

## كيف تم القياس {#how-this-was-measured}

### الحسابات {#the-accounts}

| المزوّد | الحساب | لماذا هذا الحساب؟ |
|---|---|---|
| Real-Debrid | حساب تجريبي | لا يوجد zurg قيد التشغيل يستخدمه، لذلك لم يلمسه أي شيء آخر أثناء التشغيل |
| AllDebrid | مفتاح تجريبي | كان الحساب يحتوي بالفعل على روابط مغناطيسية أخرى، لذلك لم يُحذف إلا المعرّفات التي أنشأها التشغيل |
| TorBox | مفتاح حقيقي | **تم تحميل نسخة أخرى من zurg على الحساب نفسه**، وهذا ليس ملاحظة هامشية. راجع [المخاطر التي وُجدت في الطريق](#hazards-found-on-the-way) |

تُقرأ بيانات الاعتماد من `RD_TOKEN` و`AD_KEY` و`TB_KEY` في متغيرات البيئة. لا شيء يكتبها
في أي تسجيل التقاط.

### التورنتات {#the-torrents}

كلها قانونية. صور FOSS وفيلم في الملك العام. كل info hash جاء من ملف `.torrent` أعاد الـ harness حسابه من الملف نفسه، ولم يُكتب يدويًا. أحجام الـ swarm مأخوذة من scrape للـ tracker في نفس اليوم.

| الحالة | التورنت | Info hash | الحجم | Seeders في الـ tracker | Webseeds |
|---|---|---|---|---|---|
| cached | Big Buck Bunny | `dd8255ecdc7ca55fb0bbf81323d87062db1f6d1c` | 264 MiB | n/a | n/a |
| cached | Sintel | `08ada5a7a6183aae1e09d831df6748d566095a10` | 123 MiB | n/a | n/a |
| cached | ubuntu-26.04.1-desktop-amd64.iso | `5b1e0d988fc7a0c9e99bd852071681a59974b39f` | 6.04 GiB | 22 إلى 27 | لا يوجد |
| uncached | debian-13.6.0-arm64-DVD-1.iso | `4d38178b8f08447ea8609e844b0071354ed65887` | 3.72 GiB | 212 | 2 |
| uncached | debian-13.2.0-amd64-DVD-1.iso | `7f23b66ebc763f6d931e999583adfd22a7d796fa` | 3.71 GiB | 328 | 2 |
| webseed | Prelinger `205882_Home_Movie_005588` | `69e7bba940b3c2edf7ce517330e3ca904877d8d1` | 0.71 GiB | 0 seeders و 0 leechers | 3 |
| seedless | ubuntu-16.04.6-desktop-i386.iso | `c16796a74dc24cc7c6df2f7b66b861e22dec69b1` | 1.56 GiB | 0 | لا يوجد |
| seedless | ubuntu-24.04-beta-live-server-s390x.iso | `8e693ebcdda44f741e2034cedbb552e93944143d` | 1.18 GiB | 0 | لا يوجد |
| nometa | random 40-hex | `3f9c1a77b0e4d2568af3c01e9b7d4a5268c1f0e3` | لا يوجد | لا يوجد | لا يوجد |

الأصفار حقيقية وليست tracker ميتًا. تم scrape لـ `torrent.ubuntu.com` مرتين لكل إدخالات Ubuntu الثلاثة في نفس الحلقة، فأعطى 22 ثم 27 seeder لـ 26.04.1، بينما أعاد `d5:filesdee` فارغًا للإدخالين seedless. الأمر نفسه مع `bt1.archive.org` وعنصر Prelinger.

تم سؤال TorBox عبر `checkcached` عن كل hash قبل إضافة أي شيء. وهو الفحص الوحيد للكاش بين الثلاثة الذي لا يُحدث أي تغيير. أجاب بأنها cached لصفوف cached الثلاثة، وuncached للصفوف الستة الأخرى. وهذا هو التقسيم الذي تدّعيه أسماء الحالات.

### وتيرة الاستعلام والحدود {#poll-cadence-and-caps}

3 s خلال أول دقيقتين، ثم 15 s. و1 s للحالة المخزّنة مسبقاً (cached)، لأن دورة الحياة كاملةً هناك يمكن أن تنتهي خلال استطلاع (poll) عادي واحد.
حدّد الحد الأقصى بـ 15 دقيقة لكل تورنت في الحملة، بدلاً من الافتراضي في السكربت وهو 30 دقيقة. المهلة الافتراضية المقترحة في الطبقة الوسيطة (shim) هي 10 دقائق، والتورنت الذي ما زال يتحرك عند 15 دقيقة يكون قد تجاوز النافذة الوحيدة المهمة.
تفصل عمليات الإضافة في Real-Debrid 20 s على الأقل.

كان كل مزوّد يعمل كعملية مستقلة مع مجلد إخراج خاص به. هذا يُبقي تباعد إضافات Real-Debrid دقيقاً داخل عملية واحدة، ويسمح بتشغيل الثلاثة في الوقت نفسه.

---

## Real-Debrid

### نقاط النهاية {#endpoints}

```
POST   /rest/1.0/torrents/addMagnet          magnet=magnet:?xt=urn:btih:<hash>   -> 201 {"id","uri"}
POST   /rest/1.0/torrents/selectFiles/{id}   files=all                           -> 204
GET    /rest/1.0/torrents/info/{id}                                              -> 200 object
DELETE /rest/1.0/torrents/delete/{id}                                            -> 204
```

### قيم الحالة التي لوحظت {#status-values-observed}

`waiting_files_selection` `magnet_conversion` `magnet_error` `queued` `downloading` `uploading`
`downloaded`

لم نلاحظ ذلك هنا. `compressing` `virus` `error` `dead`. هذه الحالات تحتاج إلى محتوى لم يكن لدى هذه الحملة أي طريقة مشروعة لإنتاجه.

### أي حقول الشبكة تظهر في أي حالة {#which-wire-fields-exist-in-which-status}

هذا أهم من المفردات. الحقول تأتي وتذهب. الـ mapper الذي يقرأ `speed` في كل حالة يقرأ مفتاحاً غائباً نصف الوقت.

| Field | magnet_conversion | queued | downloading | uploading | downloaded |
|---|---|---|---|---|---|
| `status` | نعم | نعم | نعم | نعم | نعم |
| `progress` | 0 | 0 | **عدد عشري (float) نسبة مئوية** من 0 إلى 100 | **يبدأ من 0 من جديد** ويتصاعد حتى 100 | 100 |
| `seeders` | نعم | **غائب** | نعم | **غائب** | **غائب** |
| `speed` | **غائب** | **غائب** | نعم، بايت في الثانية | نعم، دائماً 0 في الالتقاط | **غائب** |
| `bytes` / `original_bytes` | 0 | الحجم الفعلي | الحجم الفعلي | الحجم الفعلي | الحجم الفعلي |
| `filename` | `"Magnet"` | الاسم الفعلي | الاسم الفعلي | الاسم الفعلي | الاسم الفعلي |
| `files` | `[]` | ممتلئ | ممتلئ | ممتلئ | ممتلئ |
| `links` | `[]` | `[]` | `[]` | تمتلئ خلال المرحلة | ممتلئ |
| `ended` | غائب | غائب | غائب | غائب | موجود |

`progress` هو **float** وليس عدداً صحيحاً. الالتقاط يحتوي على 0.4 و0.8 و1.4 إلى جانب 100.

كاشف التوقف الذي يقرب النسبة إلى عدد صحيح سيعتبر إصداراً بحجم 100 GB متوقفاً عند 1 MB/s.

`progress` **يرجع إلى الوراء عن قصد**. يُعاد ضبطه إلى 0 عندما تصبح الحالة `uploading` ثم يتصاعد إلى 100 من جديد. يجب تعريف الحركة على أنها تغيّر في المرحلة أو زيادة في progress، وليس كنسبة مئوية متصاعدة دائماً.

`seeders` يختفي بدلاً من أن يصبح صفراً عندما يغادر التورنت الحالة `downloading`. وكذلك `speed`. يجب أن يتعامل الـ mapper مع المفتاح الغائب على أنه مجهول، وليس على أنه صفر.

### ما الذي فعلته كل حالة {#what-each-case-did}

| الحالة | التورنت | الانتقالات مع الثواني منذ الإضافة | الحكم |
|---|---|---|---|
| مخزّن مؤقتاً | Big Buck Bunny | `downloaded`@0.0 | اكتمل في 1.32 ث من البداية إلى النهاية |
| مخزّن مؤقتاً | Sintel | `downloaded`@0.0 | اكتمل في 0.73 ث |
| مخزّن مؤقتاً | Ubuntu 26.04.1 | `downloaded`@0.0 | اكتمل في 0.32 ث |
| غير مخزّن | Debian 13.6.0 arm64 DVD-1 | `downloaded`@0.0 | مخزّن مسبقاً على هذا الحساب |
| غير مخزّن | Debian 13.2.0 amd64 DVD-1 | `queued`@0.0 `downloading`@3.1 `uploading`@166.5 `downloaded`@196.8 | اكتمل. 3.71 GiB في 197 ث |
| webseed | Prelinger home movie | `magnet_conversion`@0.0 `magnet_error`@318.0 | فشل |
| بلا بذور | ubuntu-16.04.6-desktop-i386 | `queued`@0.0 `downloading`@3.1 `uploading` `downloaded`@166.8 | اكتمل. لم تتكرر الحالة |
| بلا بذور | ubuntu-24.04-beta-live-server-s390x | `queued`@0.0 `downloading`@3.1 ولا شيء بعد ذلك | **توقف عند 907.6 ث وما زال `downloading`**. هذا هو شكل التعليق |
| بلا بيانات وصفية | 40 رقماً سداسياً عشرياً عشوائياً | `magnet_conversion`@0.0 `magnet_error`@317.9 | فشل |

### زمن الإضافة المخزنة مؤقتاً {#the-cached-add-latency}

هذا هو الرقم الذي يقوم عليه وضع الطبقة الوسيطة الخاص بالتورنتات المخزَّنة مؤقتًا فقط.

| التورنت | addMagnet returns | selectFiles returns | أول `/torrents/info` | الحالة |
|---|---|---|---|---|
| Big Buck Bunny | t=0 | t+1.211 s | t+1.318 s | `downloaded` |
| Sintel | t=0 | t+0.632 s | t+0.729 s | `downloaded` |
| Ubuntu 26.04.1 | t=0 | t+0.215 s | t+0.320 s | `downloaded` |

**ما لاحظناه.** التورنت المخزَّن مؤقتًا يصبح `downloaded` عند أول قراءة مباشرة بعد `selectFiles`. كامل التكلفة المتزامنة هي طلبان ذهابًا وإيابًا فقط. لا يمرّ أبدًا بالحالة `queued` ولا بالحالة `downloading`.

شغّلنا تجربة ثانية استعلمنا فيها `/torrents/info` كل 0.25 s في الفترة الفاصلة بين `addMagnet` و`selectFiles`، وكذلك بعدها. هذا ما يفعله `--rd-select-detail`، وهو يحسم الشكل النهائي.

| التورنت | الحالة قبل `selectFiles` | `selectFiles` | أول قراءة بعده | من addMagnet إلى `downloaded` |
|---|---|---|---|---|
| Big Buck Bunny | `waiting_files_selection` مع 3 ملفات مدرجة و`links` فارغ | 204 عند t+1.314 s | `downloaded` `progress` 100 `links` 1 | **1.535 s** |
| Sintel | `waiting_files_selection` مع 11 ملفًا مدرجًا | 204 عند t+0.627 s | `downloaded` `progress` 100 `links` 1 | **0.841 s** |
| Ubuntu 26.04.1 | `waiting_files_selection` مع ملف واحد مدرج | 204 عند t+0.219 s | `downloaded` `progress` 100 `links` 1 | **0.430 s** |

إذن التسلسل الكامل للتورنت المخزَّن مؤقتًا هو `waiting_files_selection` ثم `downloaded`، ولا شيء بينهما. قائمة الملفات موجودة أصلًا قبل `selectFiles`. و`links` هو ما يملؤه `selectFiles`.

**يمكن أن تكون نافذة الفحص للتخزين المؤقت فقط استعلامًا واحدًا.** تراوحت المدة من البداية للنهاية بين 0.43 s و1.54 s عبر ثلاثة تورنتات بأحجام 123 MiB و264 MiB و6.04 GiB. ونافذة مدتها ثانيتان مع استعلام كل ربع ثانية سخية.

ومقارنةً بالـ100 s التي تسمح بها Sonarr وRadarr لاستدعاء `torrents/add` (انظر [qbittorrent-client-contract.md §1.7a](qbittorrent-client-contract.md))، فإن نافذة فحص مدتها ثانيتان تقريبًا لا تكلّف شيئًا. ولا يوجد سبب لضبطها بعشرات الثواني.

(تم رفض ترجمة سابقة لأن الأكواد المكتوبة بين علامات الاقتباس الخلفية كانت مختلفة. حافظ على البنية تمامًا كما هي.)

### أمور غريبة على مُحوِّل المرحلة أن يتعامل معها {#quirks-a-stage-mapper-has-to-survive}

- **`selectFiles` يُرجع 404 بينما التورنت ما زال في `magnet_conversion`، والخطأ مُضلِّل.**
  نص الاستجابة هو `{"error":"parameter_missing","error_code":1,"error_details":"{files} is missing"}` مع أنه أُرسل
  `files=all`. ببساطة لا توجد ملفات لاختيارها بعد. هذا ليس فشلًا في الإضافة، والتورنت يبقى حيًا. كلتا التجربتين اللتين واجهتاه
  عاشتا 318 ثانية أخرى.
- **يمكن رفض هاش تورنت من تراكر خاص فورًا بدلًا من الانتظار 318 ثانية.** الهاش وراء تقرير qBittorrent بتاريخ
  2026-08-31 (نسخة remux من CiNEPHiLES من أرشيف UNIT3D، `45e1ec0d…`) أجاب `magnet_error` مع صفر ملفات في أول قراءة بعد addMagnet، ولم تكن هناك أي فترة `magnet_conversion` على الإطلاق، بل ثوانٍ فقط بعد الإضافة. سواء تعرّف Real-Debrid على الهاش أو فشل فيه سريعًا، فالنتيجة الملاحظة واحدة: الهاش الخاص ليس له سرب DHT، لذلك لا يمكن أن ينجح addMagnet معه أبدًا، ويُرجع selectFiles على النسخة الميتة الخطأ 404 المضلِّل أعلاه.
- **`addTorrent` لا يتجاوز أي خطوة للمحتوى غير المخزّن مؤقتًا، لكنه يتجاوز كل شيء للمحتوى المخزّن.** ملف `.torrent` رُفع لمحتوى لا يملكه Real-Debrid (نسخة Big Buck Bunny من archive.org، متاحة للتحميل لكنها غير مخزّنة)، ذهب إلى `magnet_conversion` كما لو كان magnet مجردًا، ولم يُستخدم بيانات الملف الوصفية للحل. أما الملف المخزّن (ISO من Ubuntu) فأجاب `waiting_files_selection` مع قائمة ملفاته في أول قراءة، وتم اختياره، وانتهى `downloaded` خلال ثانيتين، ولم يمر بـ `magnet_conversion` أصلًا. إذن قيمة الرفع تكمن في البحث الفوري من الهاش إلى التخزين المؤقت، وهذا ما يجعل إضافة إصدار من تراكر خاص ممكنة متى كان المحتوى مخزّنًا، ومستحيلة أبدًا كـ magnet.
- **حل البيانات الوصفية يستسلم بعد 318 ثانية.** تجربتان مستقلتان انتقلتا من `magnet_conversion` إلى `magnet_error` عند 317.9 ثانية و318.0 ثانية. هذا هو الحد الذي يصل إليه أي magnet لا توجد له نظراء يمكن الوصول إليهم. والأمر نفسه سواء وُجد تورنت للهاش أم لم يوجد.
- **`seeders` يكذب أثناء `magnet_conversion`.** الهاش العشوائي المكوّن من 40 حرفًا سداسيًا عشريًا أبلغ عن `seeders: 1` عند 80.9 ثانية. لا يوجد تورنت لهذا الهاش أصلًا.
- **حقل `ended` لتورنت مخزّن أُضيف حديثًا يحمل تاريخًا قديمًا.** تحتوي اللقطات على `2025-12-28` و`2026-07-28` لتورنتات أُضيفت بتاريخ 2026-08-30. هذا هو التاريخ الذي امتلك فيه Real-Debrid المحتوى لأول مرة، لا وقت انتهاء هذه النسخة. لا تحسب عمر التورنت منه.
- **عنصر webseed فقط يُضاف كـ magnet بلا نظراء ينتهي في حل البيانات الوصفية ولا يصل إلى الـ webseed أبدًا.** Real-Debrid يحترم الـ webseeds بمجرد أن يحصل على التورنت. لكنه لا يستطيع الحصول على التورنت من magnet بلا نظراء. لذلك ينتهي العنصر الذي يحتوي على webseed فقط ويُضاف كـ magnet بحالة `magnet_error`. وهذا فشل في البيانات الوصفية وليس فشلًا في الـ webseed، والاثنان يبدوان متطابقين من `/torrents/info`.

## AllDebrid

### نقاط النهاية {#endpoints-1}

`v4` و`v4.1` ليستا قابلتين للتبادل، وكان الفرق بينهما مؤثرًا في هذه الحملة.

```
POST /v4/magnet/upload      magnets[]=magnet:?xt=urn:btih:<hash>   -> 200, per-magnet `ready` flag
POST /v4/magnet/upload/file multipart files[]=<the .torrent>       -> 200, per-file `ready` flag
GET  /v4.1/magnet/status?id=<id>                                   -> 200, data.magnets is an OBJECT
GET  /v4.1/magnet/status                                           -> 200, data.magnets is a LIST
POST /v4/magnet/delete      id=<id>                                -> 200
```

**يردّ رفع الملفات تحت `files`، وليس `magnets`.** الحقول نفسها لكل عنصر: `id`، `hash`، `name`، `ready`، و`error` اختياري لكل عنصر. لذلك فإن علامة `ready` أدناه هي إجابة الذاكرة المؤقتة في الحالتين، لكن أداة فك الترميز المكتوبة لاستجابة الـ magnet ستقرأ قائمة فارغة.

**والملف هو الشكل الوحيد للإصدار الذي يستطيع AllDebrid وصفه دون swarm.** تم القياس بتاريخ 2026-09-01 على حساب الاختبار، باستخدام تورنتين خاصين اصطناعيين من الشكل نفسه، وتجزئتاهما لم يرهما أي swarm من قبل. عند رفعهما كملفات عادا بأسمائهما الحقيقية وأحجامهما الحقيقية (`"name":"zurg.private.ad.probe","size":65536`)، وظهرا في القائمة بحالة `In queue` والعدّاد لم يبدأ بعد. أما عند إرسالهما كتجزئة `magnets[]` مجردة فكانت الإجابة `"name":"noname","size":0`. قبِل AllDebrid التجزئة ولم تكن لديه عنها أي معلومة، وهذا ما يحدث لكل إصدار من متتبعات خاصة يُضاف بالتجزئة.

**نقطة `/v4/magnet/status` لم تعد موجودة.** سواء أُرسل معرّف أم لا، ترد بـ HTTP 200 مع `{"status":"error","error":{"code":"DISCONTINUED"},"deprecated":true}`. أما `/v4/magnet/upload` و`/v4/magnet/delete` فما زالتا تعملان. لذلك فافتراض الخطة بأن نقطة الحالة في v4 يمكن استخدامها، وأن v4.1 تُعاين مرة واحدة للمقارنة، كان خاطئًا. فـv4.1 هي نقطة الحالة الوحيدة، والأداة تسجّل قراءة v4 واحدة لكل تورنت، حتى يحمل التسجيل الدليل لا مجرد الادعاء.

المصادقة تتم عبر `Authorization: Bearer <apikey>`. لا حاجة إلى معامل `agent`.

### قيم الحالة التي لوحظت {#status-values-observed-1}

| `statusCode` | `status` | شوهدت |
|---|---|---|
| 0 | `In queue` | نعم |
| 1 | `Downloading` | نعم |
| 2 | `Compressing / Moving` | **لا** |
| 3 | `Uploading` | نعم |
| 4 | `Ready` | نعم |
| 5 فما فوق | أكواد الخطأ | **لا** |

### أي حقول الشبكة تظهر في أي حالة {#which-wire-fields-exist-in-which-status-1}

| الحقل | In queue (0) | Downloading (1) | Uploading (3) | Ready (4) |
|---|---|---|---|---|
| `status` / `statusCode` | نعم | نعم | نعم | نعم |
| `version` | 1 | 2 | 2 | 2 |
| `filename` | `"noname"` حتى تصل البيانات الوصفية | الاسم الحقيقي بعد وصول البيانات الوصفية | الاسم الحقيقي | الاسم الحقيقي |
| `size` | 0 حتى تصل البيانات الوصفية | الحجم الحقيقي | الحجم الحقيقي | الحجم الحقيقي |
| `downloaded` | 0 | **رقم التقدم، بالبايت** | يساوي `size` | **غير موجود** |
| `downloadSpeed` | 0 | نعم، بايت في الثانية | 0 | **غير موجود** |
| `seeders` | 0 | نعم | 0 | **غير موجود** |
| `uploaded` / `uploadSpeed` | 0 | 0 | **رقم التقدم لهذه المرحلة** | **غير موجود** |
| `processingPerc` | 0 | 0 | 0 | **غير موجود** |
| `files` / `nbLinks` | غير موجود | غير موجود | غير موجود | موجود |
| `completionDate` | 0 | 0 | 0 | مضبوط |

**لا توجد نسبة مئوية في أي مكان.** التقدم على AllDebrid هو `downloaded / size` وكلاهما أعداد صحيحة بالبايت.
بقيت `processingPerc` تساوي 0 في كل حالة وفي كل لقطة.

`Uploading` تعني أن AllDebrid تنقل التحميل المكتمل إلى مساحتها التخزينية الخاصة. لها عداد تقدم خاص بها في `uploaded` و`uploadSpeed`، و`downloadSpeed` تساوي 0 طوال المرحلة. قاعدة الكشف عن التوقف التي تراقب `downloaded` فقط ستعتبر مرحلة `Uploading` السليمة متوقفة.

### ما الذي فعلته كل حالة {#what-each-case-did-1}

| الحالة | التورّنت | `ready` عند الرفع | الانتقالات بالثواني منذ الإضافة | الحكم |
|---|---|---|---|---|
| مخزّن | Big Buck Bunny | true | `Ready`@0.0 | انتهى في 0.11 s |
| مخزّن | Sintel | true | `Ready`@0.0 | انتهى في 0.12 s |
| مخزّن | Ubuntu 26.04.1 | true | `Ready`@0.0 | انتهى في 0.11 s |
| غير مخزّن | Debian 13.6.0 arm64 DVD-1 | true | `Ready`@0.0 | مخزّن مسبقًا |
| غير مخزّن | Debian 13.2.0 amd64 DVD-1 | false | `In queue`@0.0 `Downloading`@12.5 وكل العدّادات صفر حتى 634.9 `Uploading`@650.1 `Ready`@876.9 | انتهى في 877 s |
| webseed | Prelinger home movie | false | `In queue`@0.0 `Downloading`@6.3 وكل العدّادات صفر بعد ذلك | **انتهت المهلة عند 907.8 s وما زالت `Downloading`** |
| بلا بذور | ubuntu-16.04.6-desktop-i386 | false | `In queue`@0.0 `Downloading`@9.4 وكل العدّادات صفر حتى 589.6 `Uploading`@619.9 `Ready`@650.2 | انتهى في 650 s |
| بلا بذور | ubuntu-24.04-beta-live-server-s390x | false | `In queue`@0.0 `Downloading`@3.2 وكل العدّادات صفر بعد ذلك | **انتهت المهلة عند 907.0 s وما زالت `Downloading`** |
| بلا بيانات وصفية | 40-hex عشوائي | false | `In queue`@0.0 `Downloading`@9.4 وكل العدّادات صفر بعد ذلك | **انتهت المهلة عند 907.4 s وما زالت `Downloading`** |

شغّلنا تجربة منفصلة على Debian 13.3.0 arm64 DVD-1 (`6aa9b0a4709a0d6c4982fd0363614d9006877223`) والتقطت دورة حياة كاملة لتورّنت غير مخزّن، وهي التسلسل المرجعي.

| الثواني | الحالة | ما الذي تغيّر |
|---|---|---|
| 0.0 | `In queue` 0 version 1 | `filename` هو `"noname"` و`size` هو 0 |
| 2.2 | `Downloading` 1 version 2 | ما زال بلا اسم ولا حجم |
| 4.3 | `Downloading` | يتم حل `filename` و`size` |
| 6.5 إلى 55.1 | `Downloading` | يرتفع `downloaded` حتى يصل إلى `size`. تبلغ `downloadSpeed` ذروتها قرب 110 MB/s. `seeders` من 8 إلى 9 |
| 57.2 | `Uploading` 3 | تنخفض `downloadSpeed` إلى 0. تبدأ `uploadSpeed` و`uploaded` بالارتفاع |
| 65.6 | `Ready` 4 | يظهر `files` و`nbLinks`. تختفي ستة حقول تقدّم |

3.72 GiB في 65.6 s.

### AllDebrid لا يُظهر أي تقدم إطلاقاً أثناء انتظار الjob للبنية التحتية الخاصة به {#alldebrid-reports-no-progress-at-all-while-a-job-waits-for-its-own-infrastructure}

هذه هي النتيجة التي تغيّر تصميم المهلة الزمنية أكثر من غيرها، ولم نثق بها إلا بعد تشغيلين مستقلين.

`Downloading` مع `statusCode` 1 يظهر خلال ثوانٍ من الرفع. ولفترة بعد ذلك يُبلغ AllDebrid عن `downloaded` 0 و`downloadSpeed` 0 و`seeders` 0 و`uploaded` 0 و`uploadSpeed` 0 و`processingPerc` 0. كما يعيد `size` إلى 0 و`filename` إلى الـ info hash، حتى لو كان قد أبلغ عن الاثنين بشكل صحيح من قبل.

| التشغيل | المدة التي بقيت فيها كل العدادات على الصفر | ما حدث بعد ذلك |
|---|---|---|
| Debian 13.2.0 amd64 DVD-1 | **622 s** من 12.5 s إلى 634.9 s | تم تنزيل 3.71 GiB خلال 15 s، ثم `Uploading`، ثم `Ready` عند 876.9 s |
| ubuntu-16.04.6-desktop-i386 | **580 s** من 9.4 s إلى 589.6 s | تم تنزيل 1.56 GiB خلال 30 s، ثم `Uploading`، ثم `Ready` عند 650.2 s |

انتهى الاثنان بنجاح. ولم يُبلغ أي منهما عن بايت واحد من الحركة خلال أول عشر دقائق.

**مهلة عشر دقائق بلا حركة ستُلغي مهام AllDebrid السليمة.** القيمة الافتراضية المقترحة لـ `download_timeout_mins` وهي 10 تقع داخل هذه النافذة في المرتين من أصل مرتين. لذلك إما أن تكون المهلة أطول من هذه النافذة، أو أن يُعامَل AllDebrid عند `Downloading` مع `size` 0 كمرحلة مستقلة لا تحتسب عليها الساعة. فخسارة الاسم والحجم هي طريقة AllDebrid في القول إن المهمة مُسندة لكنها لم تبدأ بعد، وليست فشلاً.

التشغيل الذي بدأ فوراً هو ما يُبرز الفرق. فقد انتقل Debian 13.3.0 arm64 DVD-1 من `In queue` إلى عدادات بايتات حقيقية خلال 6.5 s. إذن الانتظار هو طابور، وليس تأخيراً ثابتاً.

### العلامة `ready` إجابة حقيقية من الذاكرة المؤقتة {#the-ready-flag-is-a-real-cache-answer}

قيمة `ready` في استجابة `/v4/magnet/upload` كانت true لكل hash أكدت TorBox أنه مخزّن مؤقتاً، وكانت false للاثنين اللذين نزّلتهما الحملة. AllDebrid ليس عنده فحص cache منفصل، لذا هذا الـ flag هو إشارة الـ cache كلها. وzurg يمرّره الآن من مساري الإضافة، magnet ورفع الملف، كـ `MagnetResponse.Cached` مع ضبط `CacheKnown`، حتى لا يُعامَل backend لا يستطيع الإجابة على أنه أبلغ عن غياب النسخة المخزّنة.

**قيمة `ready` الـ false تعني أن الـ magnet مُضاف أصلاً.** ليس هناك طريقة لتسأل AllDebrid إن كان hash مخزّناً دون إضافته. أي مسار يقتصر على الـ cached في AllDebrid يجب أن يحذف الـ miss.

---

## TorBox

### نقاط النهاية {#endpoints-2}

```
GET  /v1/api/torrents/checkcached?hash=<hash>&format=list
POST /v1/api/torrents/createtorrent      magnet=…&seed=3&allow_zip=false   -> {"success":true,"data":{"torrent_id":N}}
POST /v1/api/torrents/createtorrent      multipart file=<the .torrent>    -> the same shape; `detail` says whether it was cached
GET  /v1/api/torrents/mylist?id=<id>&bypass_cache=true
POST /v1/api/torrents/controltorrent     {"torrent_id":N,"operation":"delete"}
```

### قيم الحالة التي لوحظت {#status-values-observed-2}

`metaDL` `checking` `stalledDL` `stalled (no seeds)` `downloading` `processing`
`uploading (no peers)` `uploading` `cached`

`processing` و`checking` و`stalledDL` **غير موجودة في جدول الترجمة الخاص بـ zurg**
(`internal/torbox/types.go` `normalizeStatus`). تقع الحالات الثلاث كلها في الفرع الافتراضي، ويُبلَّغ عنها على أنها
`downloading`.

`checking` هي المرحلة التي ينتظر فيها TorBox البيانات الوصفية، وليست المرحلة التي يتحقق فيها من الهاش. الـ magnet الذي لا يرد عليه السرب أبدًا ينتقل من `metaDL` إلى `checking` ويبقى هناك. الهاش العشوائي المكوّن من 40 خانة سداسية عشرية ما زال `checking` عند الحد الأقصى 910 ثوانٍ، وكذلك عنصر Prelinger الذي لا يملك أي أقران عند 911 ثانية. TorBox لا يتخلى عن المحاولة أبدًا كما يفعل Real-Debrid عند 318 ثانية.

**رفع ملف `.torrent` يتجاوز هذا الانتظار تمامًا، وهو الفرق كله بالنسبة لإصدار متتبع خاص.** تم القياس في 2026-09-01 على الحساب المذكور أعلاه، وأُرسل التورنت الخاص الاصطناعي نفسه بالطريقتين. كهاش: قُبل مع `torrent_id`، ثم جاءت الحالة `checking` مع `name` مضبوط على الهاش المجرد، و`size: -1`، و`files: null`، و`eta: 8640000`. أي أن TorBox يبحث عن سرب غير موجود في DHT، وسيستمر في ذلك حتى الحد الأقصى دون أن يُبلغ بشيء عنه. كملف: عبر `POST /torrents/createtorrent` مع البايتات في جزء `file` من نوع multipart. عند القراءة بعد ثلاث ثوانٍ كان يحمل اسم التورنت نفسه، وحجمه الحقيقي، والحالة `stalled (no seeds)`. إنه المحتوى نفسه الذي لا يملكه أحد، لكنه الآن موصوف. المرحلة هي المهم. تُربط `checking` مع `size: -1` بـ `StageResolvingMetadata`، وهي تعني أن العمل جارٍ ولا يمكن استخلاص أي نتيجة. أما `stalled (no seeds)` فتُربط بـ `StageStalledNoPeers`، وهي مرحلة يستطيع الـ endpoint الخاص بـ qBittorrent التصرف بناءً عليها. الإصدار المخزَّن مؤقتًا قُرئ بالحالة `done` عند 100% مع قائمة ملفاته خلال الثلاث ثوانٍ نفسها.

اسم الجزء أساسي: الملف المرسل باسم آخر لا يُرى أصلًا، ويرد الـ endpoint بـ `MISSING_REQUIRED_OPTION`، "You must provide either a file or magnet link".

(رُفضت ترجمة سابقة: امتدادات الكود مختلفة (` maps to `). حافظ على البنية تمامًا.)

### أي حقول الشبكة تظهر في أي حالة {#which-wire-fields-exist-in-which-status-2}

TorBox يرسل نفس مجموعة المفاتيح في كل حالة، ويغيّر القيم فقط. لذلك هو الأسهل في القراءة بين الثلاثة.
القيم هي التي تحمل المعنى.

| الحالة | `download_finished` | `download_present` | `cached` | `active` | `progress` | `eta` | `size` |
|---|---|---|---|---|---|---|---|
| `metaDL` | false | false | false | true | 0 | 8640000 | 0 |
| `checking` | false | false | false | true | 0 | 8640000 | **-1** |
| `stalledDL` | false | false | false | true | صغيرة جداً | 8640000 | قيمة حقيقية |
| `stalled (no seeds)` | false | false | false | true | 0 | 8640000 | قيمة حقيقية |
| `downloading` | false ثم **true** | false | false | true | كسر | ثوانٍ | قيمة حقيقية |
| `processing` | **true** | **false** | false | true | 1 | ثوانٍ | قيمة حقيقية |
| `uploading (no peers)` | **true** | **false** | false | true | 1 | 2591994 | قيمة حقيقية |
| `uploading` | true | **true** | true | true | 1 | 0 | قيمة حقيقية |
| `cached` | true | true | true | false | 1 | 0 | قيمة حقيقية |

أسماء الحقول. كانت الخطة تعتبر كل هذه الأسماء غير مُتحقَّق منها.

| المعلومة | حقل TorBox | الشكل |
|---|---|---|
| التقدم | `progress` | **كسر من الواحد**، وليس نسبة مئوية. `0.0793719` |
| عدد البذّارين | `seeds` | عدد صحيح |
| عدد الممتصّين | `peers` | عدد صحيح |
| سرعة التنزيل | `download_speed` | بايت في الثانية |
| سرعة الرفع | `upload_speed` | بايت في الثانية |
| الوقت المتبقي | `eta` | ثوانٍ. الرقم `8640000` يعني أن القيمة غير معروفة |
| البايتات المُنزَلة | `total_downloaded` | عدد صحيح |
| صحة السرب | `availability` | عدد عشري. يصبح **-1** في `uploading (no peers)` |
| مكان البيانات | `download_path` | null حتى تتوفر البيانات |

`8640000` هي 100 يوماً. هذه طريقة TorBox للقول إنه لا يعرف. وهي أيضاً نفس القيمة الثابتة التي تعطيها طبقة zurg المساعدة لـ Sonarr اليوم عندما لا يكون لديها ما تبلغ عنه.

### ما الذي فعلته كل حالة {#what-each-case-did-2}

| الحالة | التورنت | `checkcached` | الانتقالات مع الثواني منذ الإضافة | الحكم |
|---|---|---|---|---|
| cached | Big Buck Bunny | true | `cached`@0.0 | انتهى خلال 0.83 ث |
| cached | Sintel | true | `cached`@0.0 | انتهى خلال 0.94 ث |
| cached | Ubuntu 26.04.1 | true | `cached`@0.0 | انتهى خلال 0.69 ث |
| uncached | Debian 13.6.0 arm64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@7.3 `downloading`@24.1 ثم **اختفى**@48.6 | حذفه zurg الآخر عند 86.7% |
| uncached | Debian 13.2.0 amd64 DVD-1 | false | `metaDL`@0.0 `stalled (no seeds)`@13.8 `downloading`@27.8 `processing`@69.4 `downloading`@72.7 `uploading (no peers)`@83.1 ثم **اختفى**@86.7 | حذفه zurg الآخر |
| webseed | Prelinger home movie | false | `metaDL`@0.0 `checking`@23.3 ولم يحدث شيء آخر أبدًا | **عالق عند 911.3 ث في `checking`**. TorBox لم يستخدم الـ webseed |
| seedless | ubuntu-16.04.6-desktop-i386 | false | `metaDL`@0.0 `checking`@10.5 `downloading`@20.6 `processing`@184.4 ثم **اختفى**@200.4 | حذفه zurg الآخر أثناء `processing` |
| seedless | ubuntu-24.04-beta-live-server-s390x | false | `metaDL`@0.0 `checking`@18.9 `stalled (no seeds)`@169.3 `downloading`@230.9 ثم **اختفى**@462.3 | حذفه zurg الآخر عند 91.9 بالمئة |
| nometa | 40-hex عشوائي | false | `metaDL`@0.0 `checking`@10.2 ولم يحدث شيء آخر أبدًا | **عالق عند 910.3 ث في `checking`** |

تشغيل منفصل بفاصل استطلاع 0.5 ث على Debian 13.5.0 amd64 netinst (`58846860f0a766f8a42b0bb214d8c713fdf1b167`) صمد وقتًا كافيًا ليصل إلى مرحلة الانتهاء، وهو التسلسل المرجعي.

| الثواني | الحالة | `download_finished` | `download_present` | `progress` |
|---|---|---|---|---|
| 0.0 | `stalledDL` | false | false | 0.000289735 |
| 16.3 | `downloading` | false | false | 0.0608651 |
| 54.8 | `processing` | **true** | **false** | 1 |
| 59.1 | `downloading` | **true** | **false** | 0.997972 |
| 64.4 | `uploading` | true | **true** | 1 |

754 MiB خلال 64.4 ث.

اقرأ الصفوف الثلاثة الأخيرة مرتين. يضبط TorBox القيمة `download_finished` على true والقيمة `progress` على 1 قبل حوالي عشر ثوانٍ من **وصول** البيانات فعليًا. ثم يعود إلى `downloading` بقيمة progress أقل من التي أبلغ عنها للتو. يتراجع كل من `progress` و`download_state` إلى الخلف في تنزيل سليم.

## جدول المراحل {#the-stage-table}

قائمة القيم (enum) التي سيتحدث بها الـ shim هي `resolving-metadata` `queued` `downloading` `stalled-no-peers`
`finalizing` `done` `failed` والسلسلة النصية الفارغة (empty string) للحالة غير المعروفة.

(رُفضت ترجمة سابقة: مقاطع الكود لم تتطابق. حافظ على البنية تماماً كما هي.)

### Real-Debrid

| الحالة الخام `status` | المرحلة | الأساس |
|---|---|---|
| `magnet_conversion` | `resolving-metadata` | **ملاحَظ**. `bytes` يساوي 0 و`files` فارغ و`filename` هو النص الحرفي `"Magnet"` |
| `waiting_files_selection` | `queued` | **ملاحَظ** مع `--rd-select-detail`. الملفات معروضة بالفعل. `links` فارغ |
| `queued` | `queued` | **ملاحَظ**. الحجم الحقيقي والاسم الحقيقي معروفان بالفعل. لا توجد `seeders` ولا `speed` |
| `downloading` | `downloading` | **ملاحَظ** |
| `downloading` مع `seeders` تساوي 0 | `stalled-no-peers` | **ملاحَظ**. 904 ثانية من `progress` تساوي 0 و`seeders` تساوي 0 و`speed` تساوي 0 عبر 92 استطلاعاً |
| `compressing` | `finalizing` | **مُستنتَج**. لم يُشاهد |
| `uploading` | `finalizing` | **ملاحَظ**. يعود progress إلى 0 ويختفي `seeders` |
| `downloaded` | `done` | **ملاحَظ** |
| `magnet_error` | `failed` | **ملاحَظ** بعد 318 ثانية في `magnet_conversion` |
| `error` `virus` `dead` | `failed` | **مُستنتَج**. لم يُشاهد |

### AllDebrid

| `statusCode` | المرحلة | الأساس |
|---|---|---|
| 0 `In queue` | `queued` | **ملحوظ**. تستمر بضع ثوانٍ. قد يبقى `filename` على `"noname"` و`size` على 0 |
| 1 `Downloading` مع `size` 0 | `queued` | **ملحوظ**. ليست `downloading` ولا `stalled-no-peers`. أخذ AllDebrid المهمة ولم يبدأ بها. احتُجزت لمدة 622 s و580 s في تشغيلين اكتملا بعد ذلك |
| 1 `Downloading` مع `size` حقيقي | `downloading` | **ملحوظ** |
| 1 `Downloading` مع `seeders` 0 و`downloaded` ثابتًا | `stalled-no-peers` | **غير ملحوظ ولا يمكن استنتاجه بأمان**. انظر أدناه |
| 2 `Compressing / Moving` | `finalizing` | **مستنتَج**. لم يُشاهد |
| 3 `Uploading` | `finalizing` | **ملحوظ**. يحمل `uploaded` و`uploadSpeed` التقدم هنا، و`downloadSpeed` يساوي 0 |
| 4 `Ready` | `done` | **ملحوظ** |
| 5 فما فوق | `failed` | **مستنتَج**. لم يُشاهد |

**لا توجد على AllDebrid صورة يمكن رصدها للتوقف.** المهمة التي وضعها AllDebrid في الطابور والمهمة التي لا يستطيع AllDebrid أن يتقدم فيها تبدوان متطابقتين تمامًا على الشبكة.
كلتاهما `statusCode` 1 مع `size` 0 وكل العدادات عند صفر. عنصر Prelinger بقي في هذه الصورة بالضبط طوال الحد الأقصى البالغ 907.8 s، وبقي مرّان آخران في الحالة نفسها عشر دقائق لكل منهما ثم اكتملا. لذلك لا شيء في استجابة AllDebrid يميز بينهما، وحكم التوقف على AllDebrid لا يمكن أن يأتي إلا من ساعة.

### TorBox

| `download_state` الخام | المرحلة | الأساس |
|---|---|---|
| `metaDL` | `resolving-metadata` | **تمت ملاحظته**. `size` يساوي 0 و`name` يساوي الـhash |
| `checking` | `resolving-metadata` | **تمت ملاحظته**. يكون `size` **-1** طوال هذه المرحلة. هنا ينتظر TorBox التورنت، وليس فحص الـhash. غير موجود في جدول zurg حاليًا |
| `stalledDL` | `stalled-no-peers` | **تمت ملاحظته**. غير موجود في جدول zurg حاليًا |
| `stalled (no seeds)` | `stalled-no-peers` | **تمت ملاحظته**. الاسم يبالغ في الأمر. لقطتان سجّلتا `seeds` بقيمة 1 و2 وهو في هذه الحالة. يربطها zurg حاليًا بـ`queued` |
| `downloading` | `downloading` | **تمت ملاحظته** |
| `processing` | `finalizing` | **تمت ملاحظته**. غير موجود في جدول zurg حاليًا |
| `uploading (no peers)` | `finalizing` | **تمت ملاحظته** عندما تكون `download_present` قيمتها false |
| `uploading` | `done` | **تمت ملاحظته** عندما تكون `download_present` قيمتها true |
| `cached` `completed` `seeding` | `done` | `cached` **تمت ملاحظته**. الحالتان الأخريان **مستنتجتان** |
| `expired` `reported missing` `failed` `error` `missingfiles` | `failed` | **مستنتجة**. لم تُرصد أي منها |

**الزوج `download_finished` و`download_present` ليس بديلاً عن نص الحالة.** كلٌّ من
`processing` و`uploading (no peers)` وجزء من `downloading` يحمل `download_finished: true` مع
`download_present: false`. هذا المزيج طبيعي في مرحلة الإنهاء، وليس تورنتًا ميتًا. راجع
التحذير أدناه.

---

## ما الذي تعذّر قياسه {#what-could-not-be-measured}

- **تم إعادة إنتاج حالة عدم وجود البذور على مرشح واحد من أصل اثنين.** لم يكن لدى أي منهما أقران في المتتبع.
  تم تنزيل ubuntu-16.04.6-desktop-i386 على أي حال عبر المزودين الثلاثة، لأن DHT وفّر أقرانًا لم يكن المتتبع يعرفهم. تعثّر ubuntu-24.04-beta-live-server-s390x على Real-Debrid طوال الحد الأقصى كله، وهذه هي ملاحظة التوقف أعلاه. الصفر في استعلام المتتبع مؤشر ضعيف. أبقِ مرشحَين اثنين في الحالة. احتفظ Real-Debrid بالبيانات الوصفية لكليهما في كل الأحوال، وأبلغ عن `bytes` و`filename` بشكل صحيح في أول قراءة `queued`.
- **لم نرَ أبدًا الحالة `compressing` في Real-Debrid.** انتقلت كل التشغيلات المكتملة من `downloading` مباشرة إلى `uploading`.
- **لم نرَ أبدًا رمز الحالة 2 في AllDebrid.** انتقلت كل عملية رصد من 1 مباشرة إلى 3.
- **لم يُدفع أي مزود إلى مفردات الأخطاء الخاصة به.** لم تُقَس بعد الحالات `error` و`virus` و`dead` في Real-Debrid، وكذلك كل رمز في AllDebrid أعلى من 4، وكل حالات الفشل في TorBox. لإنتاجها نحتاج إلى محتوى محظور أو مصاب أو منتهي الصلاحية، لا إلى صورة ISO مفتوحة المصدر.
- **نادرًا ما أمكن متابعة TorBox حتى الاكتمال.** حُذفت أربعة تورنتات من الحملة وتورنت متابعة واحد أثناء التنزيل بواسطة zurg آخر على الحساب. راجع الخطر أدناه. لم تكتمل إلا صورة بحجم 754 MiB قبل أن تستعلم تلك العملية مرة أخرى.

---

## مخاطر وُجدت أثناء العمل {#hazards-found-on-the-way}

### zurg ثانٍ على حساب TorBox يحذف التنزيلات السليمة {#a-second-zurg-on-the-torbox-account-deletes-healthy-downloads}

حُمِّلت نسخة أخرى من zurg على حساب TorBox نفسه. ويقرأ ملف إعداداتها:

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

حُذفت **خمسة** تورنتات اختبار أثناء تنزيلها بشكل طبيعي. وهذا **ملاحَظ** من الجهتين. رصد الاختبار اختفاء كل تورنت، وسجلّ النسخة الأخرى يوضح السبب.

```
Aug 30 12:43:26 zurg-host zurg: INFO manager Deleting torrent 86695315 because it encountered an error status: error
Aug 30 12:43:27 zurg-host zurg: DEBUG torbox Deleted TorBox torrent id=86695315
Aug 30 12:44:56 zurg-host zurg: INFO manager Deleting torrent 86695708 because it encountered an error status: error
Aug 30 12:47:41 zurg-host zurg: INFO manager Deleting torrent 86697191 because it encountered an error status: error
```

التورنتات الخمسة هي `86695315` `86695708` `86697191` `86702627` `86704212`. وحمل كل واحد منها السبب نفسه. ولم يكن أيٌّ منها معطوباً.

والآلية هي القاعدة الثانية في `normalizeStatus` داخل `internal/torbox/types.go`.

```go
if w.DownloadFinished && !w.DownloadPresent {
    return "error"
}
```

هذا المزيج مرحلة إنهاء عادية في TorBox. ويعطينا التقاط الحالة كل 0.5 s رقماً محدداً لذلك. في صورة بحجم 754 MiB، كانت الفترة من تحوّل `download_finished` إلى true حتى تحوّل `download_present` إلى true **9.6 ثانية**. وفي صورة بحجم 3.7 GiB كانت 17 s على الأقل، وقد وقعت عملية المسح داخل هذه الفترة. أما النسخة الأخرى من zurg فتستعلم المكتبة كل 15 s تقريباً. وإن كان تنزيل سليم من TorBox سيبقى بعد اكتماله فهذا أشبه برمية عملة.

ثلاث نتائج. قد يختفي من مكتبة zurg الخاصة بالمستخدم تنزيلٌ من TorBox شاهده يكتمل في واجهة TorBox. والتوثيق يقول إن `delete_error_torrents` يحذف التورنتات التي يصفها المزوّد بأنها معطوبة، لكنه هنا يحذف تورنتات يصفها المزوّد بأنها سليمة. وأي قياس لـ TorBox على هذا الحساب يسابق عملية المسح هذه.

**لم يُصلَح هنا.** المرحلة 0 للقياس فقط. والإصلاح يندرج ضمن عمل المراحل. وهناك يصبح `download_finished && !download_present` الحالة `finalizing` بدلاً من `failed`.

### zurg ثانٍ على حساب AllDebrid مرّ دون مشاكل {#a-second-zurg-on-the-alldebrid-account-got-away-with-it}

استُخدم مفتاح AllDebrid في هذه الحملة من قبل نسخة zurg أخرى أيضًا، مع نفس الإعدادات الثلاثة لعملية المسح التي استُخدمت مع TorBox.

```yaml
enable_repair: true
delete_error_torrents: true
stalled_download_mins: 120
```

لم يُحذف أي فحص خاص بـ AllDebrid. والسبب موجود في الكود وليس في الحظ. تقوم الدالة `normalizeStatus` في `internal/alldebrid/types.go` بتحويل رموز الحالة التي قيمتها 5 أو أكبر فقط إلى `error`، ولا تحتوي على أي قاعدة بنيوية من نوع `download_finished && !download_present`. لذلك لا يمكن أبدًا أن تُقرأ عملية تنزيل سليمة في AllDebrid على أنها معطلة. خلل TorBox يكمن في تلك القاعدة الإضافية وحدها، وليس في عملية المسح بشكل عام.

Real-Debrid هو الاستثناء. لم تكن أي نسخة zurg أخرى محمّلة بحساب الاختبار. ولم يكن هناك أي شيء يمسح حسابه، ولم يتدخل فيه شيء.

### TorBox يرد برمز HTTP 500 عند طلب حذف معرّف غير معروف {#torbox-answers-a-delete-for-an-unknown-id-with-http-500}

```
POST /v1/api/torrents/controltorrent  {"torrent_id":86695315,"operation":"delete"}
-> HTTP 500 {"success":false,"error":"DATABASE_ERROR","detail":"There was an error processing your request. Please try again later."}
```

`GET /torrents/mylist?id=<gone>` يعطي الرد نفسه. لذلك لا يمكن تمييز torrent لم يعد موجودًا عن انقطاع TorBox بالاعتماد على رمز الحالة وحده. يُبلغ zurg عنه بالرسالة `account temporarily unavailable`. ويُظهر سجل المثيل الآخر أنه يعيد محاولة حذف id محذوف بالفعل كل 15 ثانية. يتجاوز الـ harness هذه المشكلة بطلب `mylist` بعد فشل الحذف، ويعتبر torrent المفقود محذوفًا.

### لم يظهر تقييد Real-Debrid {#real-debrid-throttling-did-not-appear}

تسع إضافات بفاصل 20 ثانية لم تُنتج أي استجابة 451 ولا أي استجابة 429 طوال الحملة كلها. وهذا يتوافق مع الملاحظة في `CLAUDE.md` الموجود في الجذر، التي تقول إن 6 إضافات بفاصل 10 ثوانٍ فشلت 0/6، وإن الست نفسها بفاصل 20 ثانية نجحت 6/6. إذن الحد الأدنى 20 ثانية يؤدي دورًا فعليًا وليس مجرد خرافة.

## إعادة تشغيل الحملة {#re-running-the-campaign}

```bash
export RD_TOKEN=…   # a Real-Debrid test account
export AD_KEY=…     # AllDebrid test
export TB_KEY=…     # TorBox

# 1. check the catalog still resolves and the swarms are still what the tables claim
./scripts/torrent_lifecycle_probe.py --inspect-torrents

# 2. non-destructive. Confirms the cached/uncached split before anything is added
./scripts/torrent_lifecycle_probe.py --cache-probe

# 3. record what each account holds now, so step 6 has something to compare against
./scripts/torrent_lifecycle_probe.py --list

# 4. the campaign. One process per provider, each with its own output directory
for p in rd ad tb; do
  LIFECYCLE_OUTDIR=~/lifecycle/$p ./scripts/torrent_lifecycle_probe.py \
    --provider $p --case all --cap-mins 15 > ~/lifecycle/$p.out 2>&1 &
done

# 5. the two follow-ups the campaign cannot do
./scripts/torrent_lifecycle_probe.py --provider rd --case cached --rd-select-detail
./scripts/torrent_lifecycle_probe.py --provider tb --case adhoc --fast-poll 0.5 --fast-window 480 \
  --extra-hash 58846860f0a766f8a42b0bb214d8c713fdf1b167:debian-netinst

# 6. verify nothing was left behind
./scripts/torrent_lifecycle_probe.py --cleanup-only
./scripts/torrent_lifecycle_probe.py --list
```

Spusť to z počítače s rezidenční IP. AllDebrid vrací `NO_SERVER` na IP z datacenter.

Krok 6 není volitelný a krok 3 je to, co z toho dělá smysl. Po kampani z 2026-08-30 nezůstala na žádném ze tří účtů ani jedna z 34 instance id, která si harness nárokoval. Stejně tak žádný z devíti probe hashů.

Než sáhneš na TorBox, zkontroluj, jestli není se stejným účtem načtený nějaký jiný zurg. Přečti jeho nastavení sweepu a počítej s tím sweepem, který je popsán výše.

```bash
grep -E "delete_error_torrents|stalled_download_mins|enable_repair" config.yml
```

Nikdy to neměň. Probe, který během běhu zmizí, je data.
