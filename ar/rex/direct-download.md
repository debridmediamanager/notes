# التطبيقات تنزّل من مزوّد الخدمة {#apps-download-from-your-provider}

rex عادةً يقرأ كل فيلم من مصدرك ويمرره إلى Plex. إذا أعاد المصدر رابط ملف مثل رابط تحميل من debrid، يستطيع rex أن يسلّم هذا الرابط إلى Plex. عندها يحمّل Plex الملف بنفسه، ولا يحمل جهاز rex أي وسائط.

هذا يعمل عندما يستطيع Plex تشغيل الملف مباشرةً (direct play). أما أي ملف يحتاج rex إلى تحويله، فيبقى يمر عبر rex، أو يُرفض إذا اخترت ذلك.

تم الاختبار بتاريخ 2026-10-25 باستخدام zurg مع Real-Debrid، وPlezy وPlex لنظام Android على جهاز Pixel 6، وPlex Web في Chrome.

## قبل أن تبدأ {#before-you-start}

**Keep the default proxy mode for shared debrid playback.** Redirects are not a safe way to share one debrid account:

- **Real-Debrid tracks each downloader's public IP.** Multi-IP use of one account earns a sharing warning even when the CDN serves the file successfully. Keep every use of that account on one public IP. A remote app downloading directly while rex or its source probes or converts from the server's IP violates that rule; a successful play does not prove it safe.
- **TorBox download URLs contain the full API key in `?token=`.** Redirecting gives every client and shared user account access, including deletion, not just access to that file. Player logs and browser history can retain the key. Do not hand these links to untrusted clients.

Only continue if these risks are acceptable. Keeping rex's default proxy mode means rex follows source redirects itself instead of handing the provider link to the app.

| You need | Why |
|---|---|
| rex set up as in [rex with your own app](any-source.md), [rex with your Stremio addons](stremio.md) or [rex with zurg](with-zurg.md), and a movie that plays | This page changes rex's start command and, for some sources, one of the source's settings |
| rex nightly **2026.10.26 or newer** | Older builds do not have this setting. Update as in [rex's Updating section](any-source.md#updating) |
| A source that can answer with a link | rex can only pass on a link the source gives it. [Step 1](#step-1-let-your-source-hand-out-links) says which sources do |

## اختر مدى الصرامة {#choose-how-strict}

| | `redirect` | `redirect-only` |
|---|---|---|
| التطبيق يشغّل الملف كما هو | التطبيق ينزّل من مزوّد الخدمة عندك | التطبيق ينزّل من مزوّد الخدمة عندك |
| التطبيق يحتاج تحويل الملف (جودة أقل، أو صوت لا يقدر على تشغيله، أو ترجمات مدمجة في الصورة) | يحوّله rex، ويقرأ الملف من مصدرك كالمعتاد | مرفوض: يعرض التطبيق خطأ |
| الملفات التي يرسلها مصدرك بنفسه، لا كرابط (ملفات Usenet في zurg مثلاً) | يُشغَّل عبر rex كالمعتاد | مرفوض |
| Plex Web | يشتغل، عبر rex | يُرفض كل ملف من Real-Debrid (انظر أدناه) |

اختر `redirect` إذا أردت أن يبقى كل شيء يعمل، وتوفّر ما تستطيع توفيره. اختر `redirect-only` إذا كان يجب ألا يحمل جهاز rex أي فيلم أبداً، مثلاً VPS صغير له حد للبيانات.

مع أي تطبيق أو شخص تشارك معه rex، يحصل كل واحد منهم على الرابط الذي أعطاك إياه مصدرك لما يشغّله، والخدمة التي وراء هذا الرابط، مثل خدمة debrid التي تستخدمها، ترى كل واحد منهم وهو ينزّل الملف.

## الخطوة 1. اسمح لمصدرك بتوفير الروابط {#step-1-let-your-source-hand-out-links}

**ما الذي تفعله الميزة.** مصدرك يرد على كل طلب قراءة برابط إلى الملف في مكان آخر (إعادة توجيه HTTP) بدلاً من إرسال الملف نفسه.

**لماذا هذا مهم.** rex يستطيع تمرير الرابط الذي يعطيه مصدره فقط. المصدر الذي يرسل الملف بنفسه سيظل يمرره عبر rex.

| المصدر | ما الذي يجب فعله |
|---|---|
| [rex-stremio](stremio.md) | لا شيء: يرد بالرابط الذي أعطاه إضافة البث (stream addon). الرابط الذي يحتاج ترويسات خاصة به، وقائمة التشغيل المباشرة، يرسلهما بنفسه ما زال |
| [zurg](with-zurg.md) | فعّل `disable_stream_proxy`، كما هو موضح أدناه. zurg لا يملك رابطاً لملف Usenet، لذلك يرسل تلك الملفات بنفسه دائماً |
| [تطبيقك الخاص](any-source.md) | رد على طلب `GET` للملف بـ `302` أو `307` إلى الرابط |

### zurg

الإعداد هذا خاص بـ zurg، لذلك أي شيء آخر يقرأ من zurg (مثل rclone أو خادم Plex أو Jellyfin على مسار تركيب zurg) سيحصل على الروابط أيضًا. تفاصيل الإعداد موجودة في [مرجع الإعدادات](../zurg/reference/config.md) الخاص بـ zurg.

+++ Linux and macOS
تأكد أولًا إن كان الإعداد موجودًا في ملف إعدادات zurg:

```bash
grep -n '^disable_stream_proxy:' ~/zurg/config.yml
```

إذا طبع سطرًا، غيّره إلى `disable_stream_proxy: true` باستخدام `nano ~/zurg/config.yml`. إذا لم يطبع شيئًا، أضفه:

```bash
printf '\ndisable_stream_proxy: true\n' >> ~/zurg/config.yml
cd ~/zurg && ./zurg service restart
```
+++ Windows
افتح ملف إعدادات zurg باستخدام `notepad $HOME\zurg\config.yml`. إذا كان فيه سطر `disable_stream_proxy:`، غيّره إلى `disable_stream_proxy: true`؛ وإذا لم يكن موجودًا، أضف هذا السطر في نهاية الملف. احفظ الملف وأعد تشغيل zurg:

```powershell
cd $HOME\zurg; .\zurg.exe service restart
```
+++ Docker
في مجلد zurg:

```bash
sudo grep -n '^disable_stream_proxy:' config.yml
```

إذا طبع سطرًا، غيّره باستخدام `sudo nano config.yml`. وإذا لم يطبع شيئًا:

```bash
printf '\ndisable_stream_proxy: true\n' | sudo tee -a config.yml >/dev/null
docker compose restart zurg
```
+++

**ما الذي يجب أن تراه.** يبدأ zurg من جديد كالمعتاد. تُشغَّل الأفلام عبر rex في هذه المرحلة: يتبع rex الروابط بنفسه حتى الخطوة 2.

## الخطوة 2. اسمح لـ rex بتمرير الروابط {#step-2-let-rex-pass-the-links-on}

**ما تفعله الأداة.** يسلّم rex للتطبيق الرابط الذي أعطاك إياه المصدر، بدلًا من تنزيل الفيلم نيابةً عنه.

أضف `--part-mode redirect` (أو `--part-mode redirect-only`) في نهاية أمر تشغيل rex، ثم أعد تشغيل rex وافتح سجله. يوضّح [تثبيت rex](any-source.md#step-1-install-rex) مكان أمر التشغيل على نظامك، وكيف تعيد تشغيل rex وتشاهد سجله. على Linux يصبح سطر `ExecStart` في الملف `~/.config/systemd/user/rex.service` كالتالي، دون أي شيء زائد:

```ini
ExecStart=%h/rex/rex --part-mode redirect
```

احتفظ بأي شيء موجود أصلًا في السطر، مثل `--port 32500` أو `--announce-url ...`.

**ما ينبغي أن تراه.** ينتهي سطر التشغيل بـ `parts=redirect`:

```
INFO    rex on http://192.168.1.20:32400  machine=...  items=...  parts=redirect
```

مع `redirect-only` ينتهي بـ `parts=redirect-only`، وقبله بأسطر قليلة يقول rex: `transcoder off: --part-mode redirect-only`.

## الخطوة 3. شغّل أي شيء {#step-3-play-something}

ابقِ سجل rex مفتوحًا وشغّل فيلمًا في Plezy أو Plex لأندرويد.

**ما الذي يجب أن تراه.** لكل قراءة يُجريها التطبيق، يظهر سطر يذكر خادم مزوّد الخدمة الخاص بك:

```
INFO    PART 1000010 range=bytes=0- -> 302 to 129-4.download.real-debrid.com
```

هذا يعني أن rex يرسل التطبيق إلى خادم الرابط، وهو خادم Real-Debrid هنا. أما السطر الذي ينتهي بـ `-> 206 len=...` فيعني أن rex أرسل الفيلم نفسه بدلًا من ذلك: راجع [إذا لم يعمل](#if-it-does-not-work).

## ماذا يفعل كل تطبيق {#what-each-app-does}

| App | `redirect` | `redirect-only` |
|---|---|---|
| Plezy | تُنزَّل من مزوّد الخدمة الخاص بك | تُنزَّل من مزوّد الخدمة الخاص بك |
| Plex for Android, Original quality | تُنزَّل من مزوّد الخدمة الخاص بك، عندما يسمح rex بتشغيل الملف كما هو | نفس الشيء |
| Plex for Android, a lower quality, or audio it cannot play | يحوّله rex | "Playback Error: This item can't be played right now. Please try again." |
| Plex Web | يُشغَّل عبر rex | "Playback Error: This server is not powerful enough to convert video." |

لا يستطيع Plex Web استخدام روابط Real-Debrid إطلاقاً، فـ Real-Debrid يعدّ ملفاته تنزيلات وليست فيديو، والمتصفح يرفض تشغيلها. في وضع `redirect` يتحوّل Plex Web بهدوء إلى التحويل عبر rex خلال ثانية، فيبقى كل شيء يعمل. أما في وضع `redirect-only` فلا يوجد بديل يعود إليه.

## في Docker {#in-docker}

إذا اتبعت [تشغيل rex في Docker](any-source.md#run-rex-in-docker)، فالخطوة 2 هي سطر `command:` تحت `rex:` في ملف `compose.yml` الخاص بـ rex، بجانب `image:`:

```yaml
    command: --part-mode redirect
```

هل لديك `command: --port 32500` مسبقاً؟ غيّره إلى `command: --port 32500 --part-mode redirect`. ثم نفّذ `docker compose up -d` في مجلد rex، وسيظهر لك السطر نفسه `parts=redirect` عند تشغيل `docker compose logs -f rex`.

## إذا لم يعمل {#if-it-does-not-work}

| ما تراه | ماذا يعني ذلك |
|---|---|
| يتوقف rex مع الخطأ `invalid choice` عند استخدام `--part-mode` | إصدار rex أقدم من 2026.10.26. حدّثه كما هو موضح في [قسم التحديث في دليل rex](any-source.md#updating) |
| سجلّ rex يعرض `-> 206 len=...` مع كل قراءة | المصدر ما زال يرسل الملف بنفسه. مع zurg: إما أن `disable_stream_proxy: true` غير موجود في إعدادات zurg، أو أنك لم تعد تشغيل zurg بعد الخطوة 1 |
| `-> 206 len=...` لبعض العناوين فقط | المصدر يرسل هذه بنفسه: ملفات Usenet الخاصة بـ zurg، أو روابط rex-stremio التي يجب على rex تمريرها |
| `-> 403: the source answered with the bytes, not a link` | `redirect-only` يرفض ملفاً أرسله المصدر بنفسه، للأسباب نفسها المذكورة أعلاه |
| لا توجد أي أسطر `PART` أثناء تشغيل فيلم | التطبيق يشغّل نسخة محوّلة وليس الملف نفسه. اضبط الجودة على Original |

ما زلت عالقاً؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يشرح [طلب المساعدة](../guides/remote-help.md) ما يجب تضمينه.

## الرجوع {#going-back}

احذف `--part-mode ...` من أمر تشغيل rex (أو من سطر `command:` في Docker) ثم أعد تشغيل rex. يمكن لمصدرك أن يستمر في تقديم الروابط، فبعد إزالة إعداد rex سيتابع rex الروابط بنفسه. أما مع zurg، فاضبط `disable_stream_proxy` مرة أخرى على `false` ثم أعد تشغيل zurg، وسيعود zurg إلى تمرير الملفات بنفسه، وذلك لـ rclone وأي برنامج آخر يقرأ منه أيضًا.
