# الانتقال إلى zurg {#migrating-to-zurg}

اقرأ هذه الصفحة أولاً. فهي تنطبق على كل عمليات الترحيل، وتحتوي على معظم ما تحتاجه. صفحات كل خادم قصيرة لأن هذه الصفحة تتضمن الجزء المشترك.

## الخلاصة السريعة {#the-short-version}

**يُنشر zurg كل ملف وسائط يُنشره السيرفر الذي تتركه، وأكثر من ذلك.** تم قياس هذا بتاريخ 2026-09-01. دخلت الإصدارات الخمسة نفسها إلى السيرفرات الخمسة، وقُرئت الـ mounts بأمر `tree`. هذه هي [المقارنة الكاملة](https://github.com/debridmediamanager/usenet-streaming-benchmark).
الشيء الوحيد الذي ينشره zurg *بشكل أقل* هو ملفات par2 للتكافؤ، وPlex لا يحوّلها أبدًا إلى عنصر في المكتبة.

إذن **لن تفقد أي محتوى.** بعضه سيصل باسم ملف مختلف. وهذا هو كل ما تتناوله هذه الصفحة. يربط Plex عنصر المكتبة بمسار الملف، والملف الموجود في مسار جديد هو عنصر جديد.

ما تخسره ليس الملفات، بل **التنظيم**.

| يبقى | يضيع مع العنصر القديم |
|---|---|
| علامات المشاهدة وعدد مرات التشغيل ومواضع الاستئناف | عضوية المجموعات (Collections) |
| التقييمات التي تضعها | عناصر قوائم التشغيل (لأنها تخزن معرّفات العناصر) |
| الملفات نفسها | الملصقات والصور الفنية التي اخترتها وتصحيحات المطابقة اليدوية |
| | `added_at`. ستغمر مكتبتك قائمة Recently Added |

تبقى حالة المشاهدة لأن `metadata_item_settings` مفهرسة حسب الحساب وحسب GUID من نوع `plex://`، وليس حسب المسار أو معرّف العنصر. وتعود إلى مكانها عندما يتطابق العنصر الجديد مع الـ GUID نفسه. أما إذا أخطأ Plex في مطابقة العنصر المُعاد إضافته، فلن تعود الحالة. تحقّق من عدد قليل من العناصر بعد أول فحص للمكتبة.

يمكنك تجنب هذه المقايضة كليًا، لكن بثمن. أعد كتابة `media_parts.file` في قاعدة بيانات Plex حتى لا تموت الصفوف أبدًا. أو ابنِ شجرة من روابط رمزية (symlink) تعيد إنشاء كل مسار قديم فوق الـ mount الخاص بـ zurg. كلاهما يعمل. وكلاهما عملية جراحية غير مدعومة على مخطط غير موثّق يتغير بين إصدارات Plex. وإعادة كتابة نصف مكتملة أسوأ من أي من النتيجتين اللتين أُريد لها أن تمنعهما.

تسلك هذه الأدلة الطريق البسيط، وتخبرك بالضبط بما يكلّفه.

## مكتبتك تُحفظ في `__magic__` وليس في مزرعة روابط رمزية {#your-library-lands-in-__magic__-and-not-in-a-symlink-farm}

تُسلّم كل خادم في هذه القائمة مكتبته إلى \*arrs عبر مزرعة من الروابط الرمزية (symlinks). **لا يفعل zurg ذلك، ولا ينبغي لك أن تبني واحدة.** بدلًا من ذلك لديه [`__magic__`](../guides/magic.md). وهو المجلد الوحيد الذي تُخزَّن مساراته *بدلًا من أن تُحسب*. تعديل المسار داخله يعيد كتابة صف واحد في جدول صغير. لا تُنقل أي بايتات، ولا يُنسخ شيء. يبقى الإصدار في مكانه على الحساب. وجّه Sonarr وRadarr إليه، فيمكنهما التنظيم وإعادة التسمية كما يشاءان دون أي تكلفة.

ليس هذا مجرد جزء متحرك أقل. إنها طبقة لا يمكن أن تنكسر بالطريقة التي انكسرت بها القديمة. يجب أن يشير الرابط الرمزي إلى مسار حقيقي. الهدف الواضح هو `__all__/<release>/<file>` وهذا المسار *يُحسب*. يتغير عند إعادة تسمية الإصدار. ويتغير مرة أخرى عندما يتعارض إصداران فيضيف zurg لاحقة `{shorthash}` إلى أحدهما. كل تغيير من هذا النوع يترك الرابط معلّقًا دون أن ينبّهك أحد. أما تثبيت `__magic__` فيُفهرس بتجزئة محتوى الإصدار مضافًا إليها مسار الملف داخله. لذلك يبقى صامدًا أمام إعادة التسمية. ويبقى صامدًا أمام لاحقة `{shorthash}`. ويبقى صامدًا حتى بعد إصلاح يعيد إضافة الإصدار بمعرّف جديد تمامًا.

لذا، مهما كان لديك اليوم، **ستتغير المسارات وستُعاد إضافة المكتبة**. ينطبق هذا على مكتبة \*arr المبنية على الروابط الرمزية، وعلى Plex الموجّه مباشرة إلى التركيب القديم. هذه هي المقايضة المذكورة أعلاه، وهي التكلفة الكاملة لكل عملية ترحيل هنا.

## ما لديك اليوم يعتمد على منصتك {#what-you-have-today-depends-on-your-platform}

هذا يحدد ما إذا كانت جداول إعادة التسمية في الصفحات التالية تصف مكتبة Plex الخاصة بك أم المصدر الذي بُنيت منه فقط. تأكد من ذلك قبل أن تقرأها.

### Linux وmacOS. أدواتك \*arrs أعادت تسمية كل شيء بالفعل {#linux-and-macos-your-arrs-already-renamed-everything}

استراتيجية الروابط الرمزية (symlink) هي الإعداد الموثّق لجميع الخوادم الأربعة هنا، وهي موجودة فقط على هذه المنصات. الخادم ينشر `completed-symlinks/<category>/<release>/<file>.rclonelink`. بعدها يحوّل `rclone mount
--links` كل واحد منها إلى رابط رمزي حقيقي. **يستورد Sonarr وRadarr من تلك المزرعة إلى مكتبة في مسارات يختارانها بنفسيهما.** نقطة التركيب هي المصدر وليست المكتبة.

نتيجتان لذلك.

- **المسارات التي يراها Plex هي مسارات \*arr دائماً.** مجلد الجذر ثم مجلد المسلسل ثم مجلد الموسم. لا يحتوي أي منها على اسم الإصدار.
- **أسماء الملفات أيضاً تعود لـ\*arr إذا تركت إعادة التسمية مفعّلة.** وهذا يعني خياري "Rename Episodes" و"Rename Movies". وعند إيقاف إعادة التسمية تكون الأسماء هي أسماء الخادم المصدر، وتصف الجداول في الصفحات التالية ما تراه بالضبط.

لذلك إذا كنت تشغّل الـ\*arr مع تفعيل إعادة التسمية، فإن جداول إعادة التسمية الخاصة بكل خادم **لا** تصف مكتبتك. إنها تصف ما استلمه الـ\*arr وقت الاستيراد. ومع ذلك يبقى الأمر مهماً. اسم ملف مصدر أفضل يعني تحليلاً أفضل، وأنت على وشك إعادة الاستيراد.

### Windows. لا توجد طبقة روابط رمزية على الإطلاق {#windows-no-symlink-layer-at-all}

مزرعة الروابط الرمزية (symlink farm) تحتاج إلى `rclone mount --links`، وهذا الخيار غير متوفر في إعداد Windows. التركيب يتم عبر حرف محرك أقراص من خلال WinFsp، وتشير Plex وتطبيقات \*arrs مباشرةً إليه. لذلك **تعرض Plex أسماء الملفات الأصلية للخادم**، وجداول إعادة التسمية تصف بدقة ما ستلاحظ تغييره. تشرح صفحة [إعداد Windows](../setup/windows.md) حرف محرك الأقراص وقاعدة الجلسة.

أوامر الشِل في صفحات كل خادم مكتوبة لنظامَي Linux وmacOS (على macOS اقرأ `/mnt/zurg` على أنه `/Volumes/Zurg`). على Windows اقرأ `/mnt/zurg` على أنه `Z:\`، وأوقف الخادم القديم بالطريقة التي شغّلته بها، وأنشئ المجلدات وانقل الملفات داخل `__magic__` باستخدام أوامر PowerShell الموجودة في [دليل `__magic__`](../guides/magic.md).

### الانتقال من مكتبة روابط رمزية {#coming-off-a-symlink-library}

You are not moving a library. You are rebuilding one. And `__magic__` gives the
\*arrs exactly what the symlink farm gave them without the farm. They move and
rename inside it as freely as before. Each move is a row write instead of a
file operation.

!!!danger Never let an \*arr move the old library into `__magic__`
Changing a series or movie root folder makes Sonarr or Radarr offer to **move**
the files. Say no. A move inside `__magic__` is free. A move from anywhere else crosses the
mount boundary and that is a copy. So is a move between two volumes of the same
mount. In Docker give the \*arr one volume that holds zurg's whole mount. A copy off a streaming mount pulls your
entire library down through your news or debrid allowance. Your old library is
a tree of symlinks so what gets copied is every target they resolve to.
!!!

Move each file into place yourself instead. Every move is one rename through
zurg's mount. Nothing is copied and nothing on your account changes. The script
below does it from your old library of symlinks. A link's path under the old
root folder is where Sonarr or Radarr expects the episode or film. Its target
names the file. So each file lands at the same path under the new root folder
that its link had under the old one. The old library is only read. It keeps
working until you switch the \*arr over.

1. **Build zurg beside the old server** as its page shows. Let it list the
   whole library first.
2. **Turn on `__magic__`** as its page shows. Keep Plex scans off and the
   \*arr queues paused.
3. **Save the `zurg_path` function from your server's page** as
   `zurg_path.sh` beside the script. It turns an old link's target into the
   file zurg serves. Each server lays its files out differently.
4. **Run the script** once per root folder. Set `OLD` and `NEW` and `LOG` for
   each one. A setup with `sonarr4k` and `radarr4k` beside the regular pair
   needs four runs.

   ```bash
   #!/bin/bash
   # adopt.sh — move every file an old root folder links to into __magic__.
   # One rename per file through zurg's mount. Nothing is copied or downloaded.
   # The old root folder is only read. GNU find and bash required.
   ZURG=/mnt/zurg                  # zurg's own mount
   OLD=/data/media/tv              # the old root folder, a tree of symlinks
   NEW="$ZURG/__magic__/tv"        # the new root folder inside __magic__
   LOG=./adopt-tv.log              # what went where
   . ./zurg_path.sh                # the zurg_path function from your server's page
   find "$OLD" -type l | while IFS= read -r link; do
     dest="$NEW/${link#"$OLD"/}"
     [ -e "$dest" ] && { echo "ALREADY THERE: $dest"; continue; }
     src=$(zurg_path "$(readlink "$link")")
     [ -n "$src" ] && [ -f "$src" ] || { echo "NOT IN ZURG: $link"; continue; }
     mkdir -p "$(dirname "$dest")"
     if mv "$src" "$dest"; then
       printf '%s\t%s\n' "$src" "$dest" >> "$LOG"
     else
       echo "FAILED: $link"
     fi
   done
   # Real files such as subtitles are small. They are copied and land on zurg's own disk.
   find "$OLD" -type f -size -32M | while IFS= read -r file; do
     dest="$NEW/${file#"$OLD"/}"
     [ -e "$dest" ] || { mkdir -p "$(dirname "$dest")" && cp "$file" "$dest"; }
   done
   ```

   It prints a line for every link it leaves alone.

   - `NOT IN ZURG` is a link to a file zurg does not have. Its NZB could not be
     recovered or its account is not in zurg's config.
   - `FAILED` is a move zurg refused. A second link to a file the script
     already moved prints this after a line from `mv` that says `No such file
     or directory`. A file can sit at only one path in `__magic__`. It stays
     where the first link put it.
   - `ALREADY THERE` is a path the new root folder already holds. Running the
     script again skips everything it placed before.

5. **Switch each \*arr over.** Select every series or every movie and edit them
   together. Set the root folder to the new one under `__magic__`. When it asks
   whether to move the files answer **No, I'll Move the Files Myself**. The
   script already put them there. Then run **Update All** so it finds them.
6. **Point Plex at the new root folders** and at nothing else. The next box
   says why.

Each move took about 15 milliseconds on a test library and nothing was copied.
Watch `data/local` on zurg's `/magic/` dashboard while the script runs. It
grows only by the subtitles and other small files the script copies. A number
that grows by gigabytes means something is being copied. Stop and look.

The old links keep working. A moved file still shows at its old `__all__` path
as well as at its new one. Builds before the 2026.10.04 nightly hid it at the
old path for up to 12 hours even though zurg still served it there. On one of
those builds restart zurg once the script is done. Keep Plex away from the old
folders and from `__all__` until you have.

The zurg side of this was measured on 2026-10-03. The \*arr side is its
ordinary root folder edit and was not tested for this guide. Do one series
first.

!!!warning Point each Plex library at one directory and not two
A library that scans a filter directory such as `movies` or `shows` or
`__all__` **and** scans `__magic__` finds every episode twice — and `__magic__`
holds its own `__all__`, so pointing a library at the root of the namespace
scans the whole library along with what you organised. Pick one. If you use the
\*arrs then point Plex at the root folders you made, `__magic__/tv` and
`__magic__/movies`. If you browse a library nobody organises then pick the
filter directories and leave `__magic__` off.
!!!

## الحماية الوحيدة التي لا يجب أن تتجاوزها {#the-one-guard-you-must-not-skip}

**يجب أن يكون `autoEmptyTrash` مساوياً لـ `0` قبل أن تلمس أي شيء.**

```bash
TOKEN=<your plex token>
curl -s "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN" | tr '>' '\n' | grep autoEmptyTrash
# set it if needed:
curl -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

على Windows، في PowerShell:

```powershell
$TOKEN = 'your-plex-token'
((Invoke-RestMethod "http://localhost:32400/:/prefs?X-Plex-Token=$TOKEN").MediaContainer.Setting | Where-Object id -eq autoEmptyTrash).value
# set it if needed:
curl.exe -s -X PUT "http://localhost:32400/:/prefs?autoEmptyTrash=0&X-Plex-Token=$TOKEN"
```

يُظهر Plex الإعداد بقيمة `0` أو `false` عندما يكون معطلاً.

Plex يحذف بشكل ناعم. عند `0`، أي عنصر اختفى ملفه يبقى في سلة المهملات ويعود إذا عاد الملف. عند `1` يُحذف نهائياً في اللحظة التي يلاحظ فيها الفحص ذلك. إذا توقف الـ mount لعشر ثوانٍ أثناء الفحص، فسيأخذ معه المكتبة كاملة. وقد تسبب هذا من قبل في خسارة عشرات الآلاف من العناصر.

مع هذه الأدلة المبسطة، صار هذا الإعداد يقوم بعمل أكبر مما كان عليه سابقاً وليس أقل. **سلة المهملات هي المكان الذي تنتظر فيه عناصرك القديمة بينما تتحقق من الجديدة.** أفرغها عندما تكون راضياً عن النتيجة وليس قبل ذلك. هذه هي الخطوة التي تجعل الخسارة حقيقية، وهي الشيء الوحيد غير القابل للتراجع في كل هذه الأدلة.

وبينما أنت في الإعدادات، أوقف **"Generate video preview thumbnails"** للمكتبات المتأثرة. على mount للبث، كل عملية لإنشاء المصغرات هي قراءة كاملة للإصدار عبر حصتك من Usenet أو debrid. والترحيل يسلّم Plex عدداً كبيراً من العناصر الجديدة دفعة واحدة.

## ما الذي يكسبه كل انتقال {#what-every-migration-gains}

اثنان من هذه الأمور ملفات جديدة تظهر في مجلدات يفحصها Plex بالفعل، وتستحق المعرفة قبل أن تفاجئك.

- **ملفات العينات.** zurg هو الوحيد من الأدوات الخمس الذي ينشر ملف العينة الموجود داخل مجلد `Sample/` في إصدارات RAR. قد يلتقط Plex ملف `-sample.mp4` بحجم 9 MB ويعامله كمادة إضافية أو كنسخة ثانية من الحلقة. إذا كنت لا تريد ذلك، فاضبط [`only_show_the_biggest_file: true`](../reference/config.md) على المجلدات التي تفحصها مكتبات الوسائط لديك.
- **ملفات `.nfo`.** zurg هو الوحيد الذي يحتفظ بها. لا تؤثر في وكلاء Plex الافتراضية. يقرؤها وكيل XBMC و NFO إذا كنت تستخدمه.
- **ملفات `thumbnail.jpg` و `.url` الإعلانية.** لا تأثير لها. `thumbnail.jpg` ليس اسم ملف يستخدمه Plex للملصقات، وملفات `.url` هي إعلانات مرتبطة بالملصق.
- **مجلدات فارغة** تظهر عندما تنقطع سلسلة الأرشيفات في إصدار ما. يتجاهل Plex المجلدات التي لا تحتوي على وسائط.
- **يختفي ملفا par2 و sfv.** يخفيهما zurg عن طريق قراءة نوع الملف الفعلي بدلاً من قراءة اسمه. لم يسجّلهما Plex في مكتبتك قط، لذا لن تلاحظ ذلك فيها. الأمر يهم فقط الأدوات التي كانت تتصفح هذه الملفات.

## الأدلة {#the-guides}

- [من AltMount](altmount.md). يعيد تسمية إصدارات الأرشيف فقط
- [من decypharr](decypharr.md). يعيد تسمية الإصدارات ذات الملف الواحد وإصدارات الأرشيف
- [من InfiniDysk](infinidysk.md). يعيد تسمية الإصدارات ذات الملف الواحد وإصدارات الأرشيف
- [من nzbdav](nzbdav.md). لا يعيد تسمية أي شيء، وهو الأسهل بين الخمسة
- [من streamnzb](streamnzb.md). لا توجد مكتبة لترحيلها. لدى zurg إضافة Stremio خاصة به

هل تريد الانتقال بعيداً عن Plex بدلاً من الانتقال إلى zurg؟ [انتقل من Plex إلى rex](../../rex/from-plex.md) يُبقي zurg وتطبيقات Plex الخاصة بك، ويشغّل rex بجانب خادم Plex الخاص بك أو بدلاً منه.

تم قياس سلوك التسمية في كل صفحة بتاريخ 2026-09-01 على مجموعة من خمسة إصدارات.
كانت الإصدارات المستخدمة zurg `bda7e3c3` و AltMount `0614008b` و InfiniDysk `cd9b1205` و nzbdav `794948be` و decypharr `0dd1cbbd`.
قد تُسمّي الإصدارات الأقدم أو الأحدث من هذه الأشياء بطريقة مختلفة.
تحقّق من بعض الإصدارات على شجرة الملفات الخاصة بك قبل الاعتماد على قائمة إعادة الفحص بالكامل.
