# zurg Tags Documentation

هذا المستند يشرح جميع الوسوم الممكنة التي يمكن تطبيقها تلقائياً على التورنتات في zurg.

## Resolution Tags

تُضاف وسوم الدقة بناءً على أبعاد الفيديو مع عامل تسامح بنسبة 5%: يُعتبر البث مطابقًا لفئة معيّنة عندما يكون عرضه وارتفاعه كلاهما على الأقل 95% من الأبعاد المذكورة. يتم تجاهل الصور المضمّنة (صور الغلاف والصور المصغّرة). لا يُطبَّق إلا وسم الدقة الأعلى المطابق.

| الوسم | الوصف |
|-----|-------------|
| `zurg_8k` | الدقة >= 7680x4320 |
| `zurg_4k` | الدقة >= 3840x2160 |
| `zurg_1440p` | الدقة >= 2560x1440 |
| `zurg_1080p` | الدقة >= 1920x1080 |
| `zurg_720p` | الدقة >= 1280x720 |
| `zurg_480p` | الدقة >= 720x480 |

## Dynamic Range Tags

لا يُطبَّق إلا وسم واحد من هذه الوسوم، وذلك حسب خصائص النطاق الديناميكي للفيديو:

| الوسم | الوصف |
|-----|-------------|
| `zurg_hdr` | محتوى HDR (يُكتشف من خلال مساحة الألوان BT.2020) |
| `zurg_dv` | محتوى Dolby Vision |
| `zurg_sdr` | محتوى بنطاق ديناميكي قياسي (يُطبَّق عندما لا يُكتشف HDR ولا DV) |

إذا وُجدت بيانات HDR وDolby Vision معاً، فإن وسم Dolby Vision هو الذي يُعطى الأولوية ولا يُطبَّق `zurg_hdr`.

## Video Bitrate Tags

تعتمد وسوم معدل بت الفيديو على أعلى معدل بت لتدفق الفيديو الموجود في جميع الملفات التي تم تحليلها، مع تجاهل الصور المضمّنة (صور الغلاف والصور المصغّرة). يتم تطبيق المستوى الأعلى المطابق فقط.

| الوسم | الوصف |
|-----|-------------|
| `zurg_ultra_high_video_bitrate` | معدل بت الفيديو ≥ 100 Mbps |
| `zurg_high_video_bitrate` | معدل بت الفيديو ≥ 70 Mbps و < 100 Mbps |
| `zurg_moderate_video_bitrate` | معدل بت الفيديو ≥ 40 Mbps و < 70 Mbps |
| `zurg_low_video_bitrate` | معدل بت الفيديو ≥ 10 Mbps و < 40 Mbps |
| `zurg_very_low_video_bitrate` | معدل بت الفيديو ≥ 0 Mbps و < 10 Mbps |

## Audio Bitrate Tags

أوسمة معدل بت الصوت مبنية على أعلى معدل بت صوت موجود في كل مسارات الصوت. يُطبَّق المستوى الأعلى المطابق فقط.

| الوسم | الوصف |
|-----|-------------|
| `zurg_ultra_high_audio_bitrate` | معدل بت الصوت ≥ 2000 kbps (مثل DTS-HD MA وTrueHD وLPCM) |
| `zurg_high_audio_bitrate` | معدل بت الصوت ≥ 768 kbps و< 2000 kbps (مثل DTS وAC3 عالي المعدل) |
| `zurg_moderate_audio_bitrate` | معدل بت الصوت ≥ 384 kbps و< 768 kbps (مثل AC3 العادي وAAC بصيغة 5.1) |
| `zurg_low_audio_bitrate` | معدل بت الصوت ≥ 128 kbps و< 384 kbps (مثل AAC ستيريو وMP3) |
| `zurg_very_low_audio_bitrate` | معدل بت الصوت ≥ 0 kbps و< 128 kbps (مثل الستيريو منخفض الجودة) |

## Duration Tags

ترتبط وسوم المدة بأطول مدة وُجدت في جميع الملفات التي تم تحليلها، بما في ذلك الملفات الصوتية فقط. يُطبَّق أعلى مستوى مطابق فقط.

| Tag | Description |
|-----|-------------|
| `zurg_80minsplus_duration` | Duration ≥ 80 minutes |
| `zurg_60to80mins_duration` | Duration ≥ 60 minutes and < 80 minutes |
| `zurg_40to60mins_duration` | Duration ≥ 40 minutes and < 60 minutes |
| `zurg_20to40mins_duration` | Duration ≥ 20 minutes and < 40 minutes |
| `zurg_0to20mins_duration` | Duration ≥ 0 minutes and < 20 minutes |

## Language Tags

تُطبَّق وسوم اللغات على كل لغة فريدة يتم اكتشافها في مسارات الصوت والترجمة. يجمع الاكتشاف كل ملف تم تحليله داخل التورنت، لذا تحمل حزمة الموسم اتحاد لغات حلقاتها. لا يُحسب إلا المسارات الموجودة داخل ملفات الفيديو/الصوت التي تم تحليلها، ولا يتم قراءة ملف `.srt` منفصل بجانبها أبدًا، والمسارات التي لا تحدد لغة تأخذ القيمة الافتراضية `und`.

### Audio Language Tags
- `zurg_aud_[language_code]`

  مثال:
- `zurg_aud_eng` - مسار صوت بالإنجليزية
- `zurg_aud_jpn` - مسار صوت باليابانية

### Subtitle Language Tags
الصيغة: `zurg_sub_[language_code]`

مثال:
- `zurg_sub_eng` - ترجمات إنجليزية
- `zurg_sub_spa` - ترجمات إسبانية

## Using Tags for Filtering

تُستخدم الوسوم (Tags) في ملف الإعدادات لتصفية التورنتات وتوجيهها إلى مجلدات محددة. هناك أربعة مرشحات وسوم قائمة متاحة، بالإضافة إلى شرطين لوسم واحد:

### Tag Filter Types

1. `tags_match_all`: يجب أن تكون جميع الوسوم المحددة موجودة
   ```yaml
   tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
   ```

2. `tags_match_any`: يجب أن يكون وسم واحد على الأقل من الوسوم المحددة موجودًا
   ```yaml
   tags_match_any: ["zurg_aud_eng", "zurg_sub_eng"]  # Must have either English audio or subtitles
   ```

3. `tags_missing_all`: يُرجع true إذا لم يكن أي وسم من وسوم الفلتر موجودًا (عكس "tags_match_any")
    ```yaml
    tags_missing_all: ["zurg_aud_eng", "zurg_sub_eng"]  # Must not have English audio or subtitles
    ```

4. `tags_missing_any`: يُرجع true إذا كان وسم واحد على الأقل من وسوم الفلتر مفقودًا (عكس "tags_match_all")
    ```yaml
    tags_missing_any: ["zurg_4k", "zurg_hdr"]  # Must be missing either 4K or HDR (or both)
    ```

أسماء الوسوم في هذه الفلاتر الأربعة تُقارن بغض النظر عن حالة الأحرف. التورنت الذي لا يحمل أي وسم يفشل في `tags_match_all` و`tags_match_any`، وينجح في `tags_missing_all` و`tags_missing_any`، وهنا تنتهي التورنتات التي لم يتم تحليلها أبدًا.

تُفحص المفاتيح الأربعة بالترتيب أعلاه، والأول الموجود منها يحسم كتلة الفلتر بأكملها، لذا أعطِ كل فلتر وسوم مدخلًا خاصًا به تحت `and:`/`or:` بدلًا من دمج عدة فلاتر في كتلة واحدة.

### Single-Tag Conditions

`has_tag` و`not_has_tag` يقبلان اسم وسم واحد بدلاً من قائمة، ويفرّقان بين الأحرف الكبيرة والصغيرة. على عكس الفلاتر الأربعة أعلاه، لا يمكنهما إلا استبعاد تورنت، ولا يمكنهما اختياره بمفردهما: أي كتلة فلاتر تحتوي على `has_tag` وحده لن تطابق أي شيء، لذا يجب وضعهما إلى جانب شرط آخر في الكتلة نفسها.

```yaml
- has_tag: zurg_4k       # gate: torrent must carry this tag
  regex: /.*/            # and a condition that can match on its own
```

### Example Directory Configuration

إليك مثالاً على كيفية استخدام فلاتر الوسوم في إعدادات المجلد:

```yaml
"quality movies":
  filters:
    - and:
      - tags_match_all: ["zurg_4k", "zurg_hdr"]  # Must have both 4K and HDR
      - tags_match_any: ["zurg_high_video_bitrate", "zurg_ultra_high_video_bitrate"]  # Must have either high or ultra-high video bitrate
      - tags_match_any: ["zurg_high_audio_bitrate", "zurg_ultra_high_audio_bitrate"]  # Must have either high or ultra-high audio bitrate
      - tags_match_any: ["zurg_60to80mins_duration", "zurg_80minsplus_duration"]  # Must be at least 60 minutes long
      - tags_missing_all: ["zurg_sdr", "zurg_very_low_video_bitrate"]  # Must not have SDR or very low video bitrate
      - tags_missing_any: ["zurg_dv"]  # Must be missing Dolby Vision (prefer HDR10)
```

## ملاحظات {#notes}

- تُطبَّق الوسوم تلقائياً بناءً على تحليل الوسائط، وهذا يحتاج إلى الملف التنفيذي `ffprobe` ويعمل على التورنتات الجديدة فقط عند تفعيل `auto_analyze_new_torrents`. أما زر التحليل في لوحة المعلومات، وإجراء معلومات الوسائط لكل تورنت في صفحة الإدارة، فيشغّلان التحليل عند الطلب.
- لا يُطبَّق أي وسم حتى يُحلَّل ملف واحد على الأقل. التورنت غير المحلَّل لا يحمل `zurg_sdr` ولا فئة معدل البت ولا فئة المدة.
- يُمسح كل وسم من نوع `zurg_*` ويُعاد حسابه في كل تشغيل للتحليل. أما الوسوم التي لا تحمل هذه البادئة، مثل وسوم المستخدم وتعيينات المجلدات، فتبقى كما هي.
- يمكن أن تكون عدة وسوم للغات موجودة في الوقت نفسه.
- يُطبَّق وسم دقة واحد فقط، وهو الأعلى المطابق.
- يُطبَّق وسم نطاق ديناميكي واحد فقط.
- يُطبَّق وسم فئة معدل بت الفيديو واحد فقط، وهو الأعلى المطابق.
- يُطبَّق وسم فئة معدل بت الصوت واحد فقط، وهو الأعلى المطابق.
- يُطبَّق وسم فئة مدة واحد فقط، وهو الأعلى المطابق.
- يُطبَّق هامش تسامح بنسبة 5% عند فحوصات الدقة.
- تُحسب معدلات بت الفيديو بناءً على أعلى مسار فيديو من حيث معدل البت، وليس المتوسط.
- تُحسب معدلات بت الصوت بناءً على أعلى مسار صوت من حيث معدل البت، وليس المتوسط.
- المسار الذي لا يبلّغ عن معدل بت يُحسب على أنه 0، لذلك فالملف الذي لا تحمل مساراته أي بيانات عن معدل البت يقع في فئة `very_low`.
- تُحسب المدة بناءً على أطول ملف تم تحليله في التورنت، بما في ذلك ملفات الصوت فقط.
- يمكن دمج فلاتر الوسوم مع فلاتر أخرى لتنظيم المحتوى بدقة.
