# الانتقال من AltMount إلى zurg {#migrating-from-altmount-to-zurg}

اقرأ [الصفحة المشتركة](index.md) أولاً. فهي تشرح حارس المهملات (trash guard) ولماذا تنتهي مكتبتك في `__magic__`.

يقدّم AltMount أنظف شجرة ملفات بين الخمسة. ملف واحد بالضبط لكل إصدار. لا صور مصغّرة ولا إعلانات ولا عيّنات ولا بقايا ملفات. لذلك يكون الترحيل صغيراً أيضاً، لأن هناك القليل جداً مما يمكن الاختلاف عليه.

قِسناه مقابل zurg على الإصدارات الخمسة نفسها.

| | |
|---|---|
| zurg gains | يكسب zurg: مقطع العيّنة، ملف `.nfo`، `thumbnail.jpg`، إعلانات `.url`، المجلد الداخلي للأرشيف، **وكل إصدار رفضه AltMount** |
| zurg loses | لا يخسر شيئاً |
| renamed | **إصدارات الأرشيف (RAR) فقط** |

!!!info إعادة التسمية تحدث في مسار الأرشيف فقط
عبر ثلاث عمليات تشغيل مستقلة على نسخة البناء `0614008b`، احتفظت الإصدارات العادية المكوّنة من ملف واحد باسم الملف الذي اختاره الناشر. ويشمل ذلك إصداراً اسمه الداخلي يختلف عن اسم NZB، وآخر مُبهَم بالكامل. الإصدار الوحيد الذي أُعيد تسميته هو الذي احتاج إلى فك ضغط من RAR، وخرج باسم `<NZB name>.mp4`.

نسخ AltMount الأقدم أعادت التسمية أكثر من ذلك. تحقّق من شجرة ملفاتك قبل أن تثق بالقائمة أدناه. الأمر الوحيد تحت «شكل مكتبتك بعد ذلك» يخبرك بذلك في ثوانٍ.
!!!

## المشكلة الأكبر هي ما لم يستورده AltMount أبدًا {#the-bigger-issue-is-what-altmount-never-imported}

AltMount رفض حزمة موسم من 10 حلقات في كل محاولة من المحاولات الأربع. كانت المقالات متحقق منها على خادم الأخبار مسبقاً.

```
fast-fail segment check inconclusive: 93 segment(s) remained
unverified after 3 attempts: context deadline exceeded
```

الفحص غير حتمي. نفس الإصدار أعطى 196 مقطعاً غير متحقق منه، ثم 93، ثم 76. وهو أيضاً منحاز إلى الحجم. ضبط `import.segment_sample_percentage: 1` يأخذ عينة من 1% من المقاطع، لذلك الإصدار الأكبر يحتاج إلى عدد أكبر من أوامر STAT كي يصل ضمن المهلة الزمنية. وعند التكرار مع خادم أخبار *أسرع*، رفض أكثر بدلاً من أقل. تلك المحاولة خسرت حزمة الموسم وملف remux بحجم 41 GB معاً. الزمن ليس هو التفسير.

والنتيجة العملية بالنسبة لك هي التالية: **الإصدارات التي لم ينشرها AltMount بهدوء هي نفسها التي ستضيفها zurg.** ليس لها عنصر Plex اليوم، لذا لا شيء محفوظ ولا شيء معرض للخطر. ستظهر ببساطة. إذا كانت مكتبتك أصغر من مجموعة NZB لديك، فهذا هو السبب.

إذا أردت إبقاء AltMount يستورد أثناء الترحيل، فجرّب خفض `segment_sample_percentage`، فهو الخيار الذي يستحق التجربة. لم يُختبر هذا الخيار هنا.

## كيف ستبدو مكتبتك بعد ذلك {#what-your-library-looks-like-afterwards}

**تتم إعادة إضافة كل شيء** لأن جذر المكتبة ينتقل إلى `__magic__`. اطّلع على [الصفحة المشتركة](index.md) لمعرفة سبب عدم وجود طريقة أرخص.

التغيير الذي يحدث في الطريق بسيط. الإصدارات الفردية البسيطة (ملف واحد) تحتفظ باسم الملف الذي منحها إياه AltMount، لذا تبقى معظم المكتبة تُقرأ بالشكل نفسه. **تعود إصدارات الأرشيف باسم الناشر** ومن مجلد أعمق بمستوى واحد. وهذا أفضل بكثير لأدوات \*arr. الاسم `father.brown.2013.s02e05.hdtv.x264-tla.mp4` يحمل الجودة والمصدر والمجموعة التي أسقطها الاسم `FatherBrown.mp4`.

للعثور على إصدارات الأرشيف، ابحث عن مجلد الـ mount الذي يحتوي ملفًا واحدًا يحمل اسم المجلد نفسه.

```bash
AM=/mnt/altmount
for d in "$AM"/*/; do
  r=$(basename "$d")
  for f in "$d"*; do
    b=$(basename "$f")
    [ "${b%.*}" = "$r" ] && echo "RENAMED BY ALTMOUNT: $f"
  done
done
```

!!!info ما إذا كنت سترى أيًا من هذا يعتمد على إعدادك
إذا كان Plex يقرأ الـ mount مباشرة، فالأسماء أعلاه هي ما يتغير في مكتبتك. ويشمل ذلك كل إعداد على Windows، وأي إعداد على Linux أو macOS لا يحتوي على مزرعة روابط رمزية (symlink) لأدوات \*arr.

إذا كان Sonarr وRadarr ينظّمان مكتبة روابط رمزية مع تفعيل إعادة التسمية، فأسماء ملفاتك تكون قد أصبحت أسماءهم أصلًا، ولن تظهر أيٌّ من الأسماء أعلاه في Plex. عندها، ما تخبرك به الأسماء هو مدى جودة التحليل (parse) الذي كانت أداة \*arr تعمل عليه. وهذا مهم عند إعادة الاستيراد. راجع [الصفحة المشتركة](index.md).
!!!

## ما المحتوى الجديد الذي يظهر {#what-new-content-shows-up}

لا تنشر AltMount أيًّا من هذه الملفات، لذا ينطبق عليك كل ما في القائمة المشتركة في الصفحة.

- **مقاطع العينات** داخل `Sample/`. هذا هو الشيء الوحيد الذي يستحق الضبط. اضبط [`only_show_the_biggest_file: true`](../reference/config.md) إذا كنت لا تريد أن تظهر عينة بحجم 9 MB كنسخة ثانية.
- ملف `thumbnail.jpg` وملف `.nfo` وملفات `.url` الإعلانية للملصق. كلها غير فعّالة.
- **إصدارات كاملة رفضتها AltMount** تظهر كعناصر جديدة في المكتبة.
- مجلدات فارغة حيث تكون سلسلة الأرشيف مكسورة.

## استخرج ملفات NZB الخاصة بك {#get-your-nzbs-out}

استحوذ AltMount على كل ملف NZB أرسلته إليه. نُقل الملف الأصلي بعيدًا، وبقيت نسخة مضغوطة في `<config>/.nzbs/<category>/<queueID>-<name>.nzbz`. تجد الربط بين مجلد التثبيت (mount folder) وملف `.nzbz` في ملفات `.meta` الموجودة تحت `<config>/metadata/complete/<Release>/`. هذه الملفات ثنائية وتبدأ بالتوقيع `AM3`، ومسار ملف `.nzbz` مكتوب فيها كنص عادي.

يريد zurg ملف `.nzb` واحدًا لكل إصدار، يحمل اسم الإصدار، ويكون موجودًا مباشرة داخل `nzbs/` بدون مجلدات فرعية، لأن zurg يتجاهل المجلدات الفرعية. اسم مجلد `metadata/complete/<Release>` هو اسم مجلد التثبيت نفسه، وهذا بالضبط الاسم الذي يجب أن يحمله الملف.

```bash
AM=/path/to/altmount/config          # holds altmount.db, .nzbs/, metadata/
OUT=./recovered-nzbs
mkdir -p "$OUT"
for dir in "$AM"/metadata/complete/*/; do
  release=$(basename "$dir")
  meta=$(find "$dir" -maxdepth 1 -name '*.meta' | head -1)
  [ -n "$meta" ] || { echo "NO META: $release" >&2; continue; }
  nzbz=$(strings "$meta" | grep -m1 '\.nzbz$')
  case "$nzbz" in "") echo "NO NZBZ REF: $release" >&2; continue ;;
                  /*) src=$nzbz ;; *) src="$AM/$nzbz" ;; esac
  [ -f "$src" ] || { echo "NZBZ MISSING: $release" >&2; continue; }
  [ -e "$OUT/$release.nzb" ] && { echo "NAME COLLISION: $release" >&2; continue; }
  if zcat "$src" > "$OUT/$release.nzb" 2>/dev/null && grep -q '<nzb' "$OUT/$release.nzb"; then
    echo "OK: $release"
  else
    rm -f "$OUT/$release.nzb"
    echo "NOT A GZIPPED NZB: $release. Use the API export instead" >&2
  fi
done
```

في تثبيت v0.3.2 الذي جربناه، كان ملف `.nzbz` نسخة مضغوطة بصيغة gzip من ملف NZB المستورد. الكود المصدري يحتوي أيضًا على مسار zstd-protobuf لهذه الملفات، لذلك فإن التحقق بـ `zcat` و`grep` ليس مبالغة. أي ملف يرفضه هذا المسار يمكنك استرجاعه عبر الـ API. يقوم `GET /api/files/export-nzb?path=<virtual path>` بإعادة بناء ملف NZB مطابق من المخزن، ويرجع `POST /api/files/export-batch` ملف ZIP. يحتاج الطلبان إلى JWT وليس مفتاح API.

```bash
curl -c jar -s -X POST http://localhost:8585/api/auth/login \
  -H 'Content-Type: application/json' -d '{"username":"admin","password":"…"}'
curl -b jar -s -G http://localhost:8585/api/files/export-nzb \
  --data-urlencode "path=/complete/<Release>/<file>" -o "$OUT/<Release>.nzb"
```

خذ المسارات الافتراضية (virtual paths) من عرض الملفات في واجهة AltMount، أو من `/api/files/info`، ولا تحاول تخمين الصيغة. يأتي الملف المُنزَّل باسم `<queueID>-<name>.nzb`. أعد تسميته إلى `<Release>.nzb` حتى يسمّي zurg المجلد بالاسم الصحيح.

وهناك فحص سريع للتأكد: يجب أن يساوي عدد ملفات `.nzb` المستعادة عدد المجلدات داخل `metadata/complete/*/`.

## ابنِ zurg بجانب الإعداد الحالي {#build-zurg-alongside}

يبقى AltMount يعمل طوال الوقت. شغّل zurg على المنفذ 9999. لا يوجد أي تعارض مع المنفذ 8585 الخاص بـ AltMount.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com   # copy host/port/TLS/credentials from AltMount
      port: 563
      tls: true
      username: USER
      password: PASS
      connections: 30          # your plan's real allowance
rclone_enabled: true
rclone_binary: bin/rclone
mount_path: "/mnt/zurg"
```

```bash
mkdir -p nzbs && cp recovered-nzbs/*.nzb nzbs/
./zurg
ls /mnt/zurg/__all__/ | wc -l
```

توقّع رؤية **عدد أكبر** من المجلدات هنا مقارنةً بما كان لدى AltMount. هذا يعني ظهور فئة الاستيرادات المرفوضة.

## التحويل الفعلي {#cut-over}

**مسار واحد مهما كان لديك الآن.** لا شيء هنا ينقل أي بيانات.

**1. فعّل `__magic__`** وأعد التشغيل. تُسجَّل المسارات عند بدء التشغيل، لذا يحتاج تبديل الخيار من لوحة التحكم إلى إعادة تشغيل قبل أن يستجيب النطاق.

```yaml
magic:
  enabled: true
```

**2. أنشئ المجلدات الجذرية.** تُوضع في جذر `__magic__`، بجانب `__all__` الذي يحتفظ به zurg هناك. لا في `__magic__/__all__`، ولا في `__magic__` نفسه، ولا في جذر الـ mount. يُطلق التطبيقان \*arr تحذير فحص صحة لهذه المواقع، أما المجلدات الشقيقة فلا تُطلق أيًّا منهما.

```bash
mkdir -p /mnt/zurg/__magic__/tv /mnt/zurg/__magic__/movies
ls /mnt/zurg/__magic__/__all__/   # your releases are already listed here
```

يعكس `__magic__/__all__` المكتبة، فيكون كل إصدار موجودًا قبل أن تبدأ بتنظيم أي شيء.

**3. نظّم المكتبة.** أمر `mv` داخل `__magic__` يكتب سطرًا ولا ينقل أي بيانات.

```bash
mv "/mnt/zurg/__magic__/__all__/Some.Release.S01E01.1080p/ep1.mkv" \
   "/mnt/zurg/__magic__/tv/The Show/Season 01/S01E01.mkv"
```

**إذا كان Sonarr وRadarr قد نظّما مكتبتك القديمة، فانقلها بسكربت واحد.** يعيد تسمية كل ملف تشير إليه المكتبة القديمة إلى مجلد جذر جديد تحت `__magic__`. يُوضع كل ملف في المسار الذي يتوقعه تطبيق \*arr. لا يُنسخ شيء. بعد ذلك تبدّل مجلد الجذر في تطبيق \*arr دون أن تسمح له بنقل أي شيء. الخطوات والسكربت موجودان في [الصفحة المشتركة](index.md#coming-off-a-symlink-library). لا تدع تطبيق \*arr ينقل الملفات بنفسه أبدًا، فذلك يعبر حدود الـ mount، وهو نسخ يُنزّل مكتبتك بالكامل.

يحتاج السكربت إلى دالة `zurg_path` لروابط AltMount. احفظ هذه الدالة باسم `zurg_path.sh` بجانب السكربت، واضبط `OLDMOUNT` على المسار الذي رُكّب عليه AltMount.

```bash
OLDMOUNT=/mnt/altmount          # AltMount's mount, where the old links point
zurg_path() {
  case "$1" in "$OLDMOUNT"/*) ;; *) return ;; esac   # not a link into AltMount
  local name=${1##*/} f videos
  local release; release=$(basename "$(dirname "$1")")
  [ -f "$ZURG/__all__/$release/$name" ] && { echo "$ZURG/__all__/$release/$name"; return; }
  # AltMount named a lone video or an unpacked archive after the release. Take its one video.
  case "$name" in "$release".*) ;; *) return ;; esac
  videos=$(find "$ZURG/__all__/$release" -type f \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \) ! -ipath '*sample*')
  [ "$(printf '%s\n' "$videos" | grep -c .)" -eq 1 ] && echo "$videos"
}
```

تتوقع الدالة أن يكون مجلد الإصدار مباشرة فوق الملف في هدف كل رابط. لم يُتحقق من المسار الدقيق الذي تستخدمه روابط AltMount لهذا الدليل، لذا شغّل `readlink` على رابط واحد أولًا. عندما يسمّي AltMount فيديو وحيدًا أو أرشيفًا غير مفكوك باسم الإصدار، تأخذ الدالة الفيديو الوحيد الذي يقدّمه zurg في ذلك الإصدار. لا يُخمَّن أبدًا في إصدار فيه أكثر من فيديو واحد، بل تطبع بدلًا من ذلك `NOT IN ZURG`.

**4. اجعل Plex يشير إلى المجلدات الجذرية التي أنشأتها**، وهي `__magic__/tv` و`__magic__/movies`، وإليها وحدها. لا تشر إلى جذر `__magic__` أبدًا، لأنه يحتوي المكتبة كاملة في `__magic__/__all__` أيضًا. ولا تشر إلى `__magic__` *و* مجلد فلتر معًا، وإلا فستُعثر على كل حلقة مرتين. تأكد أن قيمة `autoEmptyTrash` هي `0`. أضف الموقع الجديد وشغّل الفحص. ثم احذف الموقع القديم، وهو مسار مكتبة \*arr لديك، أو الـ mount الخاص بـ AltMount إذا كان Plex يقرأه مباشرة.

**5. أفرغ سلة المهملات** بعد أن تتحقق من عينة من العناصر. تعود حالة المشاهدة عبر مطابقة GUID. أما المجموعات واختيارات الصور الفنية فلا تعود.

ابقِ AltMount يعمل حتى ذلك الحين. فهو لا يكلّف شيئًا، وهو خطة الرجوع إن احتجتها. عندما تنتهي، أوقفه.

```bash
sudo systemctl stop altmount
```

## بعد ذلك {#afterwards}

لا تُوقف AltMount عن العمل قبل أن تبثّ من عيّنة تمثّل مكتبتك. مجلد الإعدادات الخاص به يحتوي على مخزن `.nzbz`، وهذه هي النسخة الوحيدة الأخرى من ملفات NZB لديك.

الآن لنتحدث عن الجلب. يوفّر zurg [نقطة نهاية متوافقة مع SABnzbd](../guides/sonarr-radarr.md) تفعّلها بنفسك، ويمكن لـ Sonarr وRadarr أن يجلبا عبرها. وهي تحلّ محل AltMount بوصفها عميل التنزيل لديهما. يتحقق zurg من كل عملية جلب قبل أن يبلّغ عن اكتمالها. يسأل خوادم الأخبار عن بداية كل ملف ونهايته، وينزّل أيضًا المقالة الأولى من كل ملف، أي حتى أربع وستين مقالة إضافية بالإضافة إلى بضع مقالات أخرى في الإصدارات القليلة الملفات. بعض خوادم الأخبار ما زالت تقول إن المقالة موجودة بعد أن أُزيل محتواها، ولا يكشف ذلك إلا التنزيل الفعلي. يعيد zurg بناء الإصدار إذا أمكنه ذلك، وذلك حين تكون المقالات المفقودة داخل ملفات PAR2. أما الإصدار الذي لا يمكن إعادة بنائه فيُبلَّغ عنه بأنه **Failed**. عندها يضعه \*arr في القائمة السوداء ويجلب إصدارًا آخر. الفحص عيّنة وليس المنشور كله. فالمنشور الذي فُقد فيه جزء لم تصل إليه العيّنة سيُبلَّغ عنه بأنه Completed، وسيفشل عند القراءة التي تصل إلى الفجوة.

احتفظ بمجلدات الجذر الخاصة بـ \*arrs داخل `__magic__`. أي مجلد جذر في مكان آخر سيحصل على نسخة كاملة من كل عملية استيراد. وفي Docker امنح \*arr وحدة تخزين واحدة تحتوي على نقطة تركيب zurg كاملةً. مجلد التنزيل ومجلدات الجذر الموزّعة على وحدتي تخزين أو أكثر ستنسخ كل عملية استيراد أيضًا. راجع [وحدة تخزين واحدة](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).
