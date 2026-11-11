# الترجمات باستخدام Bazarr {#subtitles-with-bazarr}

Bazarr يبحث عن الترجمات للملفات التي يستوردها Sonarr وRadarr، ويحفظ كل ترجمة بجانب الفيديو الخاص بها. مع zurg يكون الفيديو داخل `__magic__`، والترجمة كذلك. مكتبات Plex وJellyfin التي تشير إلى `__magic__` تقرأها مثل أي ترجمة موجودة على القرص، وrex يعرضها أيضًا، باسم **English (SRT External)** في قائمة الترجمات.

يتطلب هذا zurg وrex من الإصدار الليلي بتاريخ 2026-10-24 أو أحدث.

جرى اختبار كل ما يلي بتاريخ 2026-10-23 باستخدام Radarr `6.3.0.10514`، وصورة `lscr.io/linuxserver/bazarr` الحالية، وzurg وrex بإصدار ذلك اليوم، وحساب Real-Debrid.

## قبل أن تبدأ {#before-you-start}

يستورد Radarr (أو Sonarr) بالفعل عبر zurg، ومجلد الجذر الخاص به موجود داخل `__magic__`، على سبيل المثال `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` على macOS، و`Z:\__magic__\movies` على Windows). إذا لم يكن الأمر كذلك بعد، فاتبع أولاً [إعداد Sonarr وRadarr للتورنتات](sonarr-radarr-torrents.md) أو [للـ Usenet](sonarr-radarr.md).

## 1. تشغيل Bazarr {#1-run-bazarr}

على مضيف Linux، أعطِ Bazarr نفس الـ volume الذي يستخدمه Radarr، حتى يرى الاثنان الفيلم على المسار نفسه ولا تحتاج إلى path mapping:

```yaml
services:
  bazarr:
    image: lscr.io/linuxserver/bazarr:latest
    container_name: bazarr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Etc/UTC
    volumes:
      - ./bazarr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6767:6767
    restart: unless-stopped
```

الربط يكون للمجلد **الأعلى** من نقطة تركيب zurg (`/mnt`، الذي يحتوي على `/mnt/zurg`)، وليس نقطة التركيب نفسها. الحاوية التي تربط نقطة التركيب نفسها تحتفظ بنقطة تركيب ميتة بعد إعادة تشغيل zurg، وكل قراءة تردّ بـ `Socket not connected`. [خطوة Docker في دليل التورنت](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker) تشرح السبب. يحتاج `PUID` و `PGID` إلى نفس العناية كما في Whisparr: [انظر هناك](whisparr.md#2-run-whisparr).

على macOS و Windows لا ينطبق ملف compose هذا، للسبب الذي تذكره [الخطوة 8 في دليل Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). شغّل Bazarr من الكود المصدري (`python bazarr.py`) على الجهاز نفسه الذي يعمل عليه Radarr و zurg، وبالمستخدم نفسه الذي يعمل به zurg، واتبع صفحات Bazarr الخاصة بـ [macOS](https://wiki.bazarr.media/Getting-Started/Installation/MacOS/macos/) و [Windows](https://wiki.bazarr.media/Getting-Started/Installation/Windows/source/). على Windows، تخطَّ مثبّت Bazarr: فهو يُعدّ Bazarr كخدمة Windows، والخدمة لا ترى القرص `Z:` الخاص بـ zurg ([السبب](sonarr-radarr.md#before-you-start)). بدلاً من ذلك، شغّل `bazarr.py` من جلستك الشخصية التي سجلت دخولها. عندها يرى كل فيلم على المسار الذي يبلغ عنه Radarr، ولا تحتاج إلى path mapping. صورة Docker أعلاه هي الوحيدة التي جرى اختبارها.

افتح `http://<your server>:6767`.

## 2. ربطه بـ Radarr وSonarr {#2-connect-it-to-radarr-and-sonarr}

**الإعدادات ← Radarr**: فعّله وأدخل عنوان Radarr والمنفذ ومفتاح API (من **Settings → General** في Radarr). إذا كنت تشغّله من داخل حاوية، استخدم عنوان LAN IP للجهاز المضيف، وليس `localhost`. اضغط **Test** ثم **Save**. الإعداد في **Settings → Sonarr** نفسه تماماً.

## 3. اللغات {#3-languages}

**Settings → Languages**: أضف اللغات التي تريدها، وأنشئ ملف لغة يحتوي عليها، واجعله الملف الافتراضي للأفلام وللمسلسلات. بعدها يطلب Bazarr الترجمات لكل شيء موجود أصلاً في Radarr وSonarr.

## 4. المزوّدون {#4-providers}

**الإعدادات ← المزوّدون (Settings → Providers)**: أضف مواقع الترجمات التي يبحث فيها Bazarr. بعضها يحتاج حسابًا وبعضها لا يحتاج. وهذان الأمران ظهرا لنا أثناء الاختبار:

- **subf2m** يحتاج User-Agent في إعدادات المزوّد. بدونه يوقفه Bazarr لمدة 12 ساعة عند أول بحث.
- يوقف Bazarr المزوّد الذي يفشل لفترة. وإذا أُوقفت كل المزوّدات، فلن يجد البحث أي نتيجة. قائمة **النظام ← المزوّدون (System → Providers)** تعرض هذه المزوّدات وتعيد ضبطها.

## 5. الترجمات المضمّنة {#5-embedded-subtitles}

لكثير من الإصدارات مسار إنجليزي مدمج بالفعل داخل ملف الفيديو. يعتبر Bazarr أن الإنجليزية موجودة في هذه الحالة، فلا يحمّل أي ملف ترجمة. إذا أردت ملف ترجمة على كل حال، فأوقف **Use Embedded Subtitles** من **Settings → Subtitles**.

## 6. فحص عنصر واحد {#6-check-one}

صفحة **Movies** في Bazarr تُظهر ما ينقص كل فيلم. ابحث عن فيلم من هناك، وستظهر الترجمة بجانب الفيديو (على Windows، ابحث في المجلد نفسه `Z:\__magic__\movies` داخل Explorer):

```bash
$ ls "/mnt/zurg/__magic__/movies/Night of the Living Dead (1968)/"
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.en.hi.srt
Night Of The Living Dead 1968 Upscaled BluRay 2160p HDR10 HEVC.mkv
```

الترجمة ملف حقيقي على قرص zurg، داخل `data/local/__magic__/` (انظر [الملفات المرافقة](magic.md#sidecars-nfo-posters-subtitles)). الفيديو ما زال يُبث من حسابك.

## في rex {#in-rex}

zurg يرسل إلى rex كل ملف ترجمة موجود بجانب فيديو في `__magic__`، بغض النظر عن المكان الذي نقله إليه Radarr أو Sonarr. يفحص zurg الترجمات الجديدة والمعدّلة والمحذوفة مرة كل دقيقة، لذلك فالترجمة التي يحفظها Bazarr تظهر في rex خلال دقيقة تقريباً، والترجمة التي تحذفها تختفي بالسرعة نفسها. لا تحتاج إلى أي إعداد إضافي غير `rex_url` في إعدادات zurg، وهو الإعداد الذي يطلبه منك [دليل rex](../../rex/with-zurg.md) أصلاً.

اسم الملف يحدد نوع الترجمة، بالطريقة نفسها التي يقرأ بها Plex أسماء الترجمات:

| ينتهي اسم الملف بـ | يعرض rex |
|---|---|
| `.srt` | Unknown (SRT External) |
| `.en.srt` | English (SRT External) |
| `.en.forced.srt` | English Forced (SRT External) |
| `.en.hi.srt`، `.en.sdh.srt`، `.en.cc.srt` | English SDH (SRT External) |

ملفات `.srt` و`.ass` و`.ssa` و`.smi` و`.txt` تُقرأ. يمكن أن تكون اللغة رمزاً من حرفين أو ثلاثة أحرف (`en` و`eng` و`de` و`ger`). ويجب أن يكون الاسم الذي يسبق رمز اللغة هو اسم الفيديو نفسه كما يكتبه Bazarr.

فقط الترجمات الموجودة في `__magic__` تصل إلى rex. الترجمة المحفوظة بجانب ملف في مجلد آخر من مجلدات zurg، مثل `/mnt/zurg/movies`، لا تُرسل.

يمكن لـ rex أن يبحث عن الترجمات بنفسه أيضاً: اضغط **Search Subtitles** في أي تطبيق Plex، ومن دون الحاجة إلى Bazarr أصلاً. انظر [ترجمات rex](../../rex/with-zurg.md#subtitles).
