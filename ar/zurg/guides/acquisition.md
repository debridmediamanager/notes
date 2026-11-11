# مصادر الحصول على الملفات {#acquisition-sources}

تمت إضافة قائمة مشاهدة Plex، و[قائمة DMM المطلوبة](#dmm-wanted-list) الخاصة بك، و[Seerr](https://github.com/seerr-team/seerr)
و[Radarr](https://radarr.video) و[Sonarr](https://sonarr.tv) تستخدم محرك جلب واحدًا. يتتبّع هذا المحرك التقدّم
وإعادة المحاولة والإقرار بالاستلام. تتحوّل نتائج Newznab إلى ملفات NZB لواجهة Usenet الخلفية في zurg. وتتحوّل نتائج Torznab إلى info hashes لحساب debrid. راجع [Newznab وTorznab](#newznab-and-torznab).

لا يُقرّ المحرك بعملية الجلب إلا بعد التحقق منها. يجب أن يصل ملف NZB إلى خادم الأخبار. في حساب `torbox_nzb` يجب أن يجلبه TorBox بدلاً من ذلك. يجب أن يظهر التورنت في المكتبة مع ملفاته. راجع [التحقق من عملية الجلب](#verifying-a-grab).

يحتفظ الإصدار الذي يجلبه zurg بمعرّفات العنوان الذي جُلب من أجله، كلها، وهي المعرّفات التي يطابق Plex العناوين بها: IMDb وTMDB، وTVDB للمسلسلات. لا يُعاد تعريفه من اسمه أبدًا. تحلّ هذه المعرّفات محل أي معرّف أعطاه إياه DMM أو اسم الإصدار، لكن لا تحل محل معرّف أدخلته بنفسك يدويًا. الإصدار الذي كان موجودًا بالفعل في مكتبتك عندما اختاره zurg ربما أُضيف من أجل عنوان آخر، لذلك لا يأخذ هذه المعرّفات إلا إذا لم يكن له معرّف، أو كان له المعرّف نفسه. عند ضبط [`rex_url`](../reference/config.md#rex)، يُرسَل الفيلم الذي جلبه zurg إلى rex على أنه ذلك الفيلم نفسه، بهذه المعرّفات، حتى لو لم يتمكّن DMM من تحديد مكانه. أما حلقات المسلسل فتبقى مرقّمة حسب تحديد DMM لها، وتحمل معرّفات المسلسل. وعند البدء، يفعل zurg الشيء نفسه مع كل إصدار جلبته المهام المحفوظة سابقًا، وهذا يُصلح الإصدارات التي فقدت معرّفاتها قبل هذا التغيير.

## الإعدادات {#configuration}

```yaml
acquisition:
  quality: best
  prefer: usenet          # usenet (default), torrents, or best
  best_first: false       # true makes Radarr and Sonarr take the profile's best quality first
  max_size_gb: 0          # a cap on a film or episode, and each episode of a season pack; 0, the default, is none
  max_season_size_gb: 0   # a cap on each season a pack holds; 0, the default, is none
  exclude_words: [DV, HDR10+]  # never take a release whose name says these
  prefer_words: [FraMeSToR]    # take a release whose name says these first, within its resolution
  audio_languages: [original]  # take only releases with this audio (any one), read from the streams
  subtitle_languages: [en]     # and with these subtitles
  concurrency: 8          # titles worked on at once (default 8, at most 200)
  indexer_concurrency: 3  # calls to one indexer at once (default 3, at most 16)
  indexers:
    - name: my-indexer
      url: https://indexer.example
      api_key: YOUR_INDEXER_API_KEY
      # type: newznab      # default, a Usenet indexer
    - name: my-trackers
      url: https://prowlarr.example
      api_key: YOUR_PROWLARR_API_KEY
      type: torznab        # a torrent indexer, handed to a debrid account
    - name: zilean
      url: http://zilean:8181/torznab
      type: torznab        # no api_key: Zilean takes none, and is asked without one
  sources:
    - name: plex-watchlist
      type: plex_watchlist
      enabled: true
      check_every_secs: 60
      remove_after_grab: true   # default; false keeps the watchlist intact
      only_new_items: true      # default; false works through the existing list
    - name: requests
      type: seerr
      enabled: true
      url: http://seerr:5055
      api_key: YOUR_SEERR_API_KEY
      check_every_secs: 60
    - name: movies
      type: radarr
      enabled: true
      url: http://radarr:7878
      api_key: YOUR_RADARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Radarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
    - name: shows
      type: sonarr
      enabled: true
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
      library_path: /mnt/zurg/__magic__   # where Sonarr sees __magic__; leave out if it sees zurg's own mount
      check_every_secs: 60
```

شغّل هذا على نسخة zurg فيها مزوّد `nzb` أو حساب `torbox_nzb` (TorBox Pro)، أو حساب debrid يقبل التورنتات، أو الاثنين معًا.
تُحفظ ملفات NZB القادمة من فهارس Newznab داخل المجلد `nzbs/`.
حساب `torbox_nzb` لا يملك خوادم أخبار للتحقق منها، لذلك يُتحقق من أي تنزيل هناك بمعرفة ما إذا كان TorBox قد جلبه.
تذهب التورنتات القادمة من فهارس Torznab إلى حساب debrid. ولا تُضاف إلا إذا كان الحساب يملكها مخزَّنة مسبقًا.
إذا لم يكن لديك أيٌّ من النوعين، فلن تبدأ المصادر. وصفحة الحصول على المحتوى توضح السبب.
يحتاج Plex إلى `plex_token` الموجود.
يحتاج Seerr إلى عنوان URL الأساسي ومفتاح API الخاص به، بشكل مستقل عن أي إعدادات Plex في zurg.
عناوين URL الفرعية والعناوين التي تنتهي بـ `/api/v1` مدعومة.
يحتاج Radarr إلى عنوان URL الأساسي الخاص به (مسار مثل `/radarr` و`/api/v3` في النهاية مقبولان)، ومفتاح API الخاص به من **Settings > General**، و`library_path` عندما يرى تركيب zurg في مسار مختلف: انظر [سلوك Radarr](#radarr-behavior).
يأخذ Sonarr الإعدادات الثلاثة نفسها: انظر [سلوك Sonarr](#sonarr-behavior).

يُقرأ الاثنان عند بدء zurg، مثل بقية الكتلة.
يشمل `indexer_concurrency` عمليات البحث وتنزيلات NZB معًا، لأن الفهرس يحسب الاستخدام على المفتاح وليس على نقطة الوصول.
غالبًا ما تكون مفاتيح الفهارس مشتركة، وثلاثة طلبات لكل مفتاح هي القيمة التي أثبتت الأمان في الاختبار على مفاتيح تخدم تطبيقًا آخر أيضًا.

حافظ على ثبات الأسماء وعناوين Seerr URL، فهي تُعرّف قوائم الانتظار المحفوظة. تدوير مفتاح Seerr يحتفظ بقائمة انتظاره.
أعد التشغيل بعد إضافة المصادر أو تغيير عناوينها أو بيانات اعتمادها.
تستمر إعدادات `watchlist:` و`plex_watchlist_enabled` الموجودة في العمل عبر محوِّل `plex-watchlist` تلقائي.
مصدر `plex_watchlist` الصريح يتجاوز مفتاح التفعيل القديم، حتى لو كان معطّلًا.
لا يمكن لمصدر Plex واحد فقط أن يستخدم حساب Plex المُعدّ.
إعدادات البحث المشتركة تعود إلى `watchlist:` وقيمه الافتراضية الحالية؛ والفهارس المحذوفة تعود إلى فهارس watchlist/Stremio.

## استبعاد الإصدارات بالاسم {#excluding-releases-by-name}

```yaml
acquisition:
  exclude_words: [DV, HDR10+]
```

تُدرج `exclude_words` الكلمات التي لا يجوز أن يحتوي اسم أي إصدار يتم جلبه عليها.
استخدمه لاستبعاد Dolby Vision أو HDR10+ من مشغّل لا يستطيع عرضهما، مع الاستمرار في جلب نسخ 4K.
ينطبق على كل المصادر بالتساوي: قائمة مشاهدة Plex، وSeerr، وRadarr، وSonarr.
وينطبق على نتائج Usenet والتورنت بالتساوي.
أي إصدار يستبعده لن يُجلب أبدًا، ولن يُحفظ، ولن يُضاف إلى حساب debrid، ولن يُرسل إلى Radarr أو Sonarr.
لا تضفه إذا لم ترد استبعاد أي شيء.
يقرأه zurg عند التشغيل مثل باقي إعدادات `config.yml`.

## تفضيل الإصدارات بالاسم {#preferring-releases-by-name}

```yaml
acquisition:
  prefer_words: [FraMeSToR, CiNEPHiLES]
```

تسرد `prefer_words` كلمات، مثل مجموعات الإصدارات (release groups)، تُقدّم الإصدار الذي يحملها على بقية الإصدارات ذات الدقة نفسها. تُطابق مثل `exclude_words` تمامًا: كلمات كاملة، دون تمييز بين الحروف الكبيرة والصغيرة. القائمة مرتبة: الإصدار الذي يحمل الكلمة الأولى يأتي قبل الذي يحمل الثانية، وهكذا. هذا تفضيل وليس فلترًا. وإذا لم يحمل أي إصدار إحدى الكلمات، يأخذ zurg ما كان سيأخذه لو لم تكن هذه الكلمات موجودة.

الإصدار المفضّل لا يتقدّم أبدًا على دقة أخرى. مع `quality: best` يأتي إصدار 2160p من أي مجموعة قبل إصدار 1080p مفضّل، ومع `quality: 1080p` لا يتقدّم إصدار 2160p مفضّل على إصدارات 1080p. وما زال الترقية إلى دقة أعلى تحدث إذا لم تملك المجموعة المفضّلة إصدارًا بتلك الدقة.

ينطبق هذا على كل المصادر، وعلى نتائج Usenet والتورنت على حد سواء. مع مصدر `radarr` أو `sonarr` يجب أن يقبل الملف الشخصي (profile) الإصدار المفضّل أيضًا. وعندما يستخدم Radarr أو Sonarr بوابة zurg كعميل تنزيل، فهما يختاران الإصدار بأنفسهما، ولا ينطبق `prefer_words` هناك. احذفه إن كنت لا تريد تفضيل أي شيء.

لا يُؤخذ إصدار فيلم أبدًا إذا كان اسمه يذكر سنة تختلف عن سنة الفيلم بأكثر من واحد، أيًّا كان المصدر. فبعض الفهارس (indexers) تضع بعض المنشورات تحت معرّف IMDb لفيلم آخر: مثلًا يضع DrunkenSlug فيلم The Aswang Chronicles (2012) تحت تكملته عام 2014. أما الاسم الذي لا يذكر سنة فلا يُرفض بسبب ذلك. أما قائمة DMM للأفلام المطلوبة، التي ترسل كل عنوان يُعرف به الفيلم (الأصلي والبدائل والترجمات)، فيُرفض فيها أيضًا كل إصدار لا يذكر أحد هذه العناوين كاملًا في اسمه. مثلًا يضع DrunkenSlug فيلم Przesluchanie (1982) تحت An Affair (1982)، و`Rocky.2015` ليس *Rocky Horror Show Live*. ويجوز أن يتوقف الاسم قبل بداية العنوان الفرعي للفيلم، بعد نقطتين أو شرطة بمسافات، فيكون `Diana.2021` هو *Diana: The Musical*. وتتطابق الحروف المشكّلة والأحرف ذات الإعجام (مثل ü) بالطريقتين، فتُحسب `Les.Miserables` و`Verwuenscht.nochmal` مطابقتين.

طريقة مطابقة الاسم:

- **كلمات كاملة فقط.** يُقرأ الاسم ككلمات مكوّنة من حروف وأرقام. النقاط والمسافات والشرطات والشرطات السفلية والأقواس كلها تفصل بين الكلمات. لا يهم حجم الحروف. تستبعد `DV` الاسمين `Avengers.Infinity.War.2018.DV.2160p.WEB.H265-RVKD` و`Mortal_Kombat_II_2026_COMPLETE_BLURAY_2160p_DV_HDR_TrueHD`. ولا تستبعد `DVDRip` أو `DVD9` أو `Come and See DvD 1` أو عنوانًا مثل *Adventures*، لأن أيًّا منها لا يحمل الكلمة DV.
- **تتطابق العبارات بالترتيب.** تطابق `Dolby Vision` أو `DV HDR` هذه الكلمات متجاورة وبهذا الترتيب، مهما كان الفاصل بينها.
- **علامة `+` في آخر الكلمة جزء منها.** `HDR10+` كلمة مستقلة. استبعاد `HDR10` يترك إصدارات HDR10+ كما هي، واستبعاد `HDR10+` يترك HDR10 العادي كما هو. ضع الاثنين في القائمة لاستبعادهما معًا. أما علامة `+` بين كلمتين فتفصل بينهما، كما في `DD+7.1` أو `DV+HDR10`.
- **عائلتان من الكتابات تُحسبان كلمة واحدة.** أي كتابة واحدة في القائمة تستبعد كل كتابات عائلتها.

  | اكتب أيًّا من | يستبعد الأسماء التي تحمل أيًّا من |
  |---|---|
  | `DV`، `DoVi`، `Dolby Vision`، `DolbyVision` | `DV`، `DoVi`، `Dolby.Vision`، `Dolby-Vision`، `Dolby Vision`، `DolbyVision` |
  | `HDR10+`، `HDR10Plus` | `HDR10+`، `HDR10Plus` |

  ولا يُعامل أي شيء آخر كبديل لغيره. يستبعد `HDR` الأسماء التي تحمل الكلمة HDR، ولا يستبعد `HDR10` أو `HDR10+` أو `HDRip`. ويطابق `WEB-DL` الكتابات `WEB-DL` و`WEB.DL` و`WEB DL`، ولا يطابق `WEBDL`.
- **يُقرأ اسم الإصدار فقط.** هذا هو العنوان الذي يرد به الفهرس قبل تنزيل أي شيء، ولا تُقرأ الملفات الموجودة داخله. فإصدار Dolby Vision لا يُستبعد إذا كان اسمه لا يذكر ذلك.

استبعاد كلمة لا يؤثر أبدًا في الدقة. فمع استبعاد `DV` يُؤخذ إصدار 2160p بتقنية HDR العادية أو HDR10، و`quality: 4k` ما زال يضع 2160p أولًا. والإصدار المستبعد يُعامل كأنه غير موجود. يواصل البحث عن فيلم أو حلقة التنقّل بين صفحات كل فهرس حتى يجمع عشرة إصدارات يجوز أخذها، أو ينتهي الفهرس، أو تُقرأ عشر صفحات. أما بحث الموسم فيقرأ صفحة واحدة، ثم يبحث بشكل منفصل عن كل حلقة لم تجد لها الصفحة إصدارًا. والعنوان الذي تُستبعد كل إصداراته يفشل برسالة "no eligible releases"، تمامًا مثل العنوان الذي تتجاوز كل إصداراته `max_size_gb`، ويُعاد المحاولة لاحقًا. وطلب Seerr بدقة 4K يأخذ إصدارات 2160p فقط، لذلك ينتظر عندما تُستبعد كل إصدارات 2160p.

### الاستبعادات وملفات تعريف Radarr أو Sonarr {#exclusions-and-radarr-or-sonarr-profiles}

مع مصدر `radarr` أو `sonarr`، يأتي الاستبعاد أولاً. لا يُعرض الإصدار المستبعد أبداً على محلل Radarr أو Sonarr. لا توجد درجة لتنسيق مخصص تعيده، ولا يُحتسب رفضاً من الملف الشخصي. يُقيَّم كل إصدار آخر بواسطة الملف الشخصي كما هو موضح في [سلوك Radarr](#radarr-behavior) و[سلوك Sonarr](#sonarr-behavior). يجب أن يجتاز الإصدار الاثنين معاً. تنسيق مخصص يعطي Dolby Vision درجة أقل من الحد الأدنى للملف الشخصي يؤدي المهمة نفسها داخل *arr، والإبقاء عليه لا يضر.

تتبع الترقيات القاعدة نفسها. إذا كانت الإصدارات الوحيدة التي ترفع الملف إلى cutoff الخاص بملفه الشخصي كلها مستبعدة، يبقى الملف دون cutoff وتواصل مرحلة الترقية في zurg البحث دون أن تأخذ شيئاً. يحدث ذلك عندما يمنح تنسيق مخصص Dolby Vision درجة عالية وتحتاج درجة cutoff إليها. خفّض درجة cutoff أو أزل تلك الدرجة من التنسيق المخصص.

عندما يستخدم Radarr أو Sonarr zurg كعميل تنزيل عبر كتلة `sabnzbd:` أو `qbittorrent:`، فإنهما يبحثان في المفهرسات الخاصة بهما ويختاران الإصدار بنفسيهما. لا تنطبق `exclude_words` هنا. استبعد الكلمات نفسها داخل *arr باستخدام تنسيق مخصص بدرجة أقل من الحد الأدنى للملف الشخصي، أو باستخدام **Must Not Contain** في ملف إصدار (release profile).

## الاختيار حسب لغة الصوت والترجمة {#choosing-by-audio-and-subtitle-language}

```yaml
acquisition:
  audio_languages: [original]   # or [de], [de, en], ...
  subtitle_languages: [en]
```

يقبل `audio_languages` الإصدارات التي تحتوي على مسار صوتي بإحدى اللغات المذكورة فقط، ويقبل `subtitle_languages` الإصدارات التي تحتوي على ترجمة بإحدى هذه اللغات فقط. اتركه فارغاً إذا لا تريد أن يطلب zurg أي شيء. ينطبق الاثنان على كل المصادر.

كل قائمة هي أيضاً ترتيب: الإصدار الذي تأتي لغته أولاً في القائمة يتقدم على الإصدار الذي فيه لغة متأخرة فقط. يأخذ `[de, original]` النسخة المدبلجة بالألمانية إذا وُجدت، وإلا يأخذ اللغة الأصلية.

يقرأ zurg اللغة من مسارات الإصدار نفسه، وليس من اسمه. معظم الإصدارات لا تذكر لغاتها في اسمها، فمثلاً قليلة جداً إصدارات Parasite التي تحمل كلمة KOREAN. اكتب رموز ISO 639 بحرفين أو ثلاثة: `en` و`eng` و`de` و`deu` و`ger` كلها تعمل. أما الاسم مثل `german` فيُرفض عند بدء التشغيل.

لبعض اللغات دبلجات أو ترجمات مختلفة، ويمكن للرمز أن يحدد واحدة منها:

| اكتب | المقصود |
|---|---|
| `es-419`, `es-ES` | الإسبانية اللاتينية (Latino) أو القشتالية |
| `pt-BR`, `pt-PT` | البرتغالية البرازيلية أو الأوروبية |
| `fr-CA`, `fr-FR` | الفرنسية الكيبيكية (VFQ) أو الفرنسية من فرنسا (VFF, VFI) |
| `nl-BE` | الفلمنكية |
| `yue`, `cmn` | الكانتونية أو الماندرين |
| `zh-Hant`, `zh-Hans` | ترجمات صينية تقليدية أو مبسطة (`zh-TW` و`zh-HK` تُقرأ كتقليدية، و`zh-CN` تُقرأ كمبسطة؛ أما للصوت الكانتوني فاكتب `yue`) |
| `nb`, `nn` | النرويجية Bokmål أو Nynorsk |

الرمز العادي يقبل كل هذه الأنواع: `es` يقبل اللاتينية والقشتالية، و`zh` يقبل الكانتونية والماندرين، و`no` يقبل Bokmål وNynorsk. الجزء الذي يأتي بعد اللغة ولا يستطيع zurg قراءته، مثل `es-latam`، يُرفض عند بدء التشغيل. يقرأ zurg نوع المسار من عنوانه، لأن المسارات نفسها لا تحمله بصيغة يستطيع zurg قراءتها: "Latino"، "Spanish (Latin American)"، "Castellano"، "French (Canada)"، "VFQ"، "Portuguese (Brazilian)"، "Chinese (Cantonese)"، "繁体中字". المسار الذي لا يذكر عنوانه أيّاً من هذه لا يُرفض بسببها أبداً. يحسم اسم الإصدار التعادل إذا ذكر شيئاً، مثل `Dual-Lat` أو `[Castellano]` أو `MULTi.VFQ` أو `VF2` أو `PT-BR` أو `[ES-LA]`. الاسم لا يرفض أي شيء أبداً، وعنوان المسار يتقدم عليه. مع `[es-419, es]` يأخذ zurg بالترتيب: مساراً عنوانه Latino، ثم مساراً بلا عنوان في إصدار اسمه Latino، ثم مساراً بلا عنوان، ثم مساراً بلا عنوان في إصدار اسمه Castellano، ثم مساراً عنوانه Castellano. لأسرة في أمريكا اللاتينية:

```yaml
acquisition:
  audio_languages: [es-419, es]  # Latino first, then Castilian
  subtitle_languages: [es]
  audio_or_subtitles: true       # or any audio with Spanish subtitles
```

يقبل `audio_or_subtitles: true` الإصدار الذي يحتوي على الصوت أو على الترجمة، بدلاً من الاثنين معاً. الإصدار الذي فيه الصوت يتقدم على الإصدار الذي فيه الترجمة فقط.

تعني `original` اللغة التي صُنع بها العمل، كما يسجلها TMDB: الكورية لفيلم Parasite، والفرنسية لفيلم Anatomy of a Fall. يطلب zurg هذه المعلومة من DMM، لذلك يحتاج إلى `dmm_api_key`. بدون هذا المفتاح، لا يطلب `original` أي شيء.

### كيف يتم تقييم الإصدار {#how-a-release-is-judged}

- **قبل إضافة الملف الtorrent.** يحتفظ DMM ببيانات ffprobe لكل إصدار حلّله zurg. إذا ضبطتَ `dmm_api_key`، يقرأ zurg هذه البيانات لكل نتيجة torrent بطلب واحد. الـtorrent الذي لا تحتوي مساراته على اللغة المطلوبة لا يُضاف أبدًا. أما الذي يحتويها فيُقدَّم على الـtorrents التي لا تتوفر عنها أي معلومات. في قياس أجري على خمسة أفلام بتاريخ 2026-10-25، احتفظ DMM بهذه البيانات لنحو ثلث الـtorrents التي كانت مخزّنة مؤقتًا لدى Real-Debrid.
- **بعد الجلب.** يُفحص كل ملف يُجلب، سواء كان torrent أو Usenet، بعد وصوله إلى المكتبة مرة واحدة: باستخدام بيانات DMM إن وجدها، وإلا فباستخدام ffprobe. الجلب الذي لا تحتوي مساراته على اللغة المطلوبة يُستبعد كما يُستبعد المنشور المعطّل. يُحذف من حساب الـdebrid أو من مجلد المراقبة، وتُجرَّب المرشحة التالية فورًا. تعرض لوحة التحكم السبب، مثلًا "it has no English audio, only French".
- **الترقية تحافظ على لغاتها.** عندما تقوم قائمة DMM المطلوبة (wanted list) بترقية فيلم إلى دقة أفضل، يجب أن يحتوي الإصدار الجديد على لغات تأتي في قوائمك بترتيب لا يقل تقدّمًا عن النسخة التي يحل محلها. لا تُستبدل نسخة 1080p باللاتينية بنسخة 2160p بالقشتالية.
- **المجهول يُقبل.** لا يُرفض أي إصدار بسبب ما لا يمكن قراءته. ويشمل ذلك المسارات غير الموسومة، والمسار الموسوم `und` أو `mul`، والإصدار الذي لا يُوصل إليه إلا عبر أرشيفاته، أو الذي لم يُفحص خلال دقيقة. يسجّل zurg أنه قبله كما هو.

لا تُحسب مسارات التعليق ووصف الصوت من صوت الفيلم، ولا تُحسب ترجمات التعليق من ترجماته. يشمل ذلك التعليق المسمّى في عنوانه فقط، مثل "Commentary by Bong Joon Ho" في فيلم Parasite. ولا تُحسب مسارات الترجمة الموسومة forced (forzados, forcés) أو signs أو songs ترجمةً للفيلم. علامة forced وحدها لا تستبعد المسار: فالنسخ المعاد تغليفها (remux) للأفلام الأجنبية تضع علامة forced على ترجماتها الإنجليزية الكاملة كي تظهرها المشغلات.

لا يُحكم إلا على ملفات الفيديو الرئيسية في الإصدار، أي التي لا يقل طولها عن خُمس أطول ملف. فالمواد الإضافية غالبًا ما يكون فيها من الأصوات المدبلجة أقل مما في الفيلم. وفي حزمة الموسم يجب أن تحتوي كل حلقة على اللغة.

يبقى الإصدار الذي استُبعد بسبب لغته مستبعدًا لمدة 30 يومًا، كما يحدث مع المنشور المعطّل، حتى لو غيّرتَ اللغات المطلوبة بعد ذلك.

## قائمة DMM المطلوبة {#dmm-wanted-list}

DMM يُضيف داعم DMM الأفلام والمسلسلات إلى قائمة رغبات باستخدام زر **Want** في صفحاته على debridmediamanager.com، ويعرضها في `/wanted`. يقرأ zurg هذه القائمة كلما كان `dmm_api_key` مضبوطاً، ولا يلزمك كتابة أي شيء آخر. لا يُركَّب أي شيء، ولا يُستخدم Sonarr أو Radarr. اسم المصدر `dmm-wanted`، ويُستعلَم كل 60 ثانية.

- **ما يُجلب.** فيلم مرة واحدة، ثم أي ترقية له (أدناه)، أو نسخة بكل دقة من عدة دقّات عندما يكون `quality` قائمة (أدناه). حلقات المسلسل التي عُرضت في المواسم المطلوبة، أو في كل المواسم إذا طُلب المسلسل كاملاً، وحلقاته الجديدة فور عرضها.
  يرسل DMM معرّفات IMDb وTMDB وTVDB لكل عنوان، وسنته، وبالنسبة للمسلسل الحلقات المعروضة حتى الآن، مرقّمةً كما يرقّمها TMDB. لا تُدرج الحلقات الخاصة أبداً. الموسم الذي لا يزال يُعرض يُجلب حلقةً حلقةً، لأنه لا توجد حزمة تغطيه بعد.
- **متى يُبحث عنه.** يُبحث عن الفيلم عند صدوره للمنزل: يرسل DMM تاريخ أقرب إصدار رقمي أو مادي أو تلفزيوني يعرفه TMDB، ولا ينتظر zurg أكثر من ذلك اليوم، ثم يبحث كل دقيقتين لمدة ست ساعات، وكل عشر دقائق حتى يومين بعد ذلك، كما يفعل مع [حلقة جديدة](#sonarr-behavior). لا يُعتمد أبداً تاريخ العرض في دور السينما: فـWEB-DL يُنشر مع الإصدار الرقمي. تاريخ أحدث حلقة في المسلسل يُحسب بالطريقة نفسها، من ساعة عرضها حين يعرفها DMM. العنوان الذي لا تاريخ له يحتفظ بالمحاولات المعتادة، بفارق أسبوع على الأكثر، ولا يُوضع أي شيء في القائمة أبداً [في وضع الإيقاف المؤقت](#persistence-and-recovery). الفيلم الذي ينتظر محاولته التالية يُبحث عنه عند الاستطلاع التالي حين يرى DMM منشور Usenet جديداً يذكره.
- **إلى أين يذهب.** كأي مصدر آخر: ملف NZB من مفهرس Newznab إلى خلفية Usenet لهذه النسخة، أو تورنت من مفهرس Torznab إلى حساب debrid مخزَّن عنده بالفعل، أيهما يصل إليه `prefer` أولاً. تُطبَّق `quality` و`max_size_gb` (لكل حلقة في حزمة موسم) و`exclude_words` و[اللغات](#choosing-by-audio-and-subtitle-language)، وكذلك `max_season_size_gb` إذا كتبته.
- **المفهرسات.** إذا لم تكتب أي مفهرس تحت `acquisition:` أو `watchlist:` أو `stremio:`، فإن المفتاح يبحث أيضاً في مفهرسات DMM الخاصة: مفهرس Usenet الخاص به، والتورنتات التي يعرف أن Real-Debrid أو AllDebrid تملكها (`/api/torznab/cached`). كتابة أي مفهرس تستبدل الاثنين.
- **التأكيد.** بعد فحص تنزيل الفيلم يُبلغ zurg الـDMM، ويخرج الفيلم من القائمة التي يقرؤها zurg، إلا إذا كان ينتظر ترقية أو نسخة أخرى من نسخه (أدناه)؛ ويُظهر `/wanted` متى حدث ذلك. يبقى المسلسل في القائمة ويستمر تتبعه حتى تزيله من هناك. إزالة العنوان توقف العمل عليه.
- **الترقيات.** يبقى الفيلم في القائمة إذا كان اسم إصداره يذكر دقة أقل من تلك التي يستهدفها `quality` (2160p لـ`best` و`4k`، و1080p لـ`1080p`، و720p لـ`720p`). يجلب zurg إصداراً يذكر دقة أعلى من النسخة التي يحتفظ بها حين يصدر، حتى يحتفظ بذلك الإصدار. بعد أن تجتاز النسخة الأفضل فحصها، تُحذف القديمة إذا كان zurg قد جلبها، وذلك بدءاً من بناء nightly بتاريخ 2026-10-30: تورنت من الحساب الذي أضافه zurg إليه، أو ملف NZB من دليل المراقبة. النسخة التي كانت ملكك من قبل تبقى، وكذلك أي نسخة وُضع أي جزء منها تحت `__magic__`، مثلاً عبر استيراد Radarr. الإصدار الذي لا يذكر اسمه دقة لا يُرقّى أبداً، و`quality: smallest` لا يرقّي شيئاً. إلى أن يظهر إصدار أفضل يُبحث عن الفيلم نحو مرة كل أسبوع، ولا يُوضع في [وضع الإيقاف المؤقت](#persistence-and-recovery) أبداً. مفعّل افتراضياً، و`upgrades: false` في كتلة `acquisition:` يوقفه.
- **نسخة بكل دقة من عدة دقّات.** عند كتابة `quality` كقائمة، مثل `[1080p, 4k]`، يُحتفظ لكل فيلم بنسخة بكل دقة واردة فيها. انظر [نسخة بكل دقة من عدة دقّات](#a-copy-at-each-of-several-resolutions).
- **بدون حساب للتنزيل.** النسخة التي لا تحتوي على مزوّد `nzb` ولا حساب `torbox_nzb` (TorBox Pro) ولا حساب debrid يقبل التورنتات لا تقرأ القائمة.

**نسختان من zurg بالمفتاح نفسه تجلبان كل عنوان.** تقرأ كل منهما القائمة نفسها، لذا شغّل قائمة الرغبات على واحدة منهما وأوقفها على البقية بكتابتها معطّلة:

```yaml
acquisition:
  sources:
    - name: dmm-wanted
      type: dmm
      enabled: false
```

ينتهي عمل القائمة إذا انتهى الدعم أو أُعيد ضبط المفتاح. يسجّل zurg تحذيراً بأن DMM رفض `dmm_api_key` ويسأل من جديد بعد ساعة، أو فوراً عندما تضبط مفتاحاً جديداً. ما جُلب سابقاً يبقى في مكتبتك.

(تم رفض ترجمة سابقة: فروق في نطاقات الكود. أبقِ البنية كما هي.)

### نسخة لكل دقة من عدة دقات {#a-copy-at-each-of-several-resolutions}

```yaml
acquisition:
  quality: [1080p, 4k]
```

تكتب `quality` كقائمة لكي تحتفظ بنسخة من كل فيلم في قائمة المطلوبات بكل دقة، مثلاً حتى يعرض تلفاز 1080p الفيلم دون أن يُعاد ترميز ملف 4K:

كل نسخة تأخذ أفضل إصدار بدقة أقل من دقتها أو مساوية لها، ولا تأخذ إصداراً بدقة أعلى منها أبداً. نسخة 1080p لا تأخذ إصدار 2160p، ولا أي إصدار لا يذكر اسمه دقةً، لأنه قد يكون أي شيء. أما نسخة 4K فتأخذ إصداراً كهذا فقط عندما لا يتوفر أي إصدار يذكر دقةً، وتحتفظ به بعد ذلك إلى الأبد، لأن الإصدار الذي لا يذكر دقة لا يُرقّى أبداً. تُرقّى كل نسخة بشكل مستقل، حتى دقتها هي فقط. وعندما تأخذ النسختان نفس الإصدار تتشاركان نسخة واحدة، ولا تُحذف تلك النسخة إلا عندما لا تحتفظ بها أي منهما:

| الإصدارات المتاحة | نسخة 1080p | نسخة 4K | في مكتبتك |
|---|---|---|---|
| 720p | إصدار 720p | نفس إصدار 720p | إصدار 720p |
| + 1080p | ترقى إلى إصدار 1080p | ترقى إلى إصدار 1080p | إصدار 1080p |
| + 2160p | تبقى كما هي | ترقى إلى إصدار 2160p | إصدار 1080p وإصدار 2160p |

الفيلم الذي يصدر بدقة 2160p فقط تحصل نسخته بدقة 4K فوراً، وتحصل نسخته بدقة 1080p عندما يظهر إصدار بدقة 1080p أو أقل. وحتى ذلك الحين يُبحث عنه مرة تقريباً كل أسبوع، ولا يُوضع أبداً في حالة الانتظار. لا يُزال الفيلم من القائمة التي يقرؤها zurg إلا بعد أن تحتفظ كل نسخة بإصدار لا تريد أفضل منه.

- **ما تقبله القائمة.** اثنتان أو أكثر من `4k` (أو `2160p`) و`1080p` و`720p`، كل واحدة مرة واحدة فقط، بأي ترتيب وبأي حالة للأحرف. يرفض zurg البدء مع أي قيمة أخرى، ويقول `acquisition.quality lists resolutions, each once: 4k, 1080p or 720p`. القائمة التي تحتوي على عنصر واحد تُقرأ كأنها تلك القيمة وحدها، فـ`[1080p]` تعني `quality: 1080p` وتحتفظ بنسخة واحدة. اكتب `4k` بدلاً منها هنا، لأن `[2160p]` مرفوضة.
- **داخل كتلة `acquisition:` فقط.** `quality` تحت `watchlist:` قيمة واحدة فقط، وإذا كانت قائمة هناك فلن يبدأ zurg. الإعداد quality في صفحة الإعدادات يعدّل `watchlist.quality` فقط، ولا يغيّر شيئاً طالما أن `acquisition.quality` مكتوب.
- **أفلام قائمة DMM المطلوبة فقط.** المسلسلات في تلك القائمة، وكل المصادر الأخرى، تحصل على نسخة واحدة فقط، تُختار كما لو أن `quality` يذكر أعلى دقة مدرجة فقط: `[1080p, 4k]` تعمل كأنها `quality: 4k` بالنسبة لها، و`[720p, 1080p]` كأنها `quality: 1080p`، وهذه ما زالت تأخذ إصدار 2160p عندما لا يكون إصدار 1080p متاحاً.
- **مع `upgrades: false`** تحتفظ كل نسخة بأول إصدار أخذته. وعندما يكون إصدار 720p هو الوحيد المتاح، تصبح النسختان هذا الإصدار بشكل دائم.
- **الأفلام التي جُلبت قبل أن تكتب القائمة** تُجلب من جديد، بنسخة لكل دقة. النسخة التي يكون أفضل إصدار لها موجوداً في مكتبتك تستخدمه كما هو. لا يحذف zurg النسخة التي جُلبت من قبل أبداً، لذا احذفها بنفسك إذا حلت محلها النسخ الجديدة.
- **العودة إلى قيمة واحدة** تترك النسخ في أماكنها.
- **يعرض `/wanted` الفيلم على أنه تم جلبه** بمجرد أن تصل نسخته الأولى، مع أول إصدار أخذه zurg. ولا يعرض أي دقة ما زالت في انتظار. وقد يستمر فيلم جُلب قبل كتابة القائمة في عرض "waiting for" للدقة التي كان ينتظرها وقتها.

### بث فيلم من YouTube {#streaming-a-film-from-youtube}

Many wanted films no indexer carries are on YouTube, uploaded whole by the studio that
made them. With `acquisition.youtube` set, zurg streams such a film from that upload
instead of leaving it unfetched. Nothing is downloaded.

```yaml
acquisition:
  youtube:
    cookies: /home/you/zurg/youtube-cookies.txt   # required: a signed-in account's cookies (Netscape format)
    # ytdlp_binary: yt-dlp                        # default; the standalone build
    # js_runtime: node                            # default; yt-dlp needs one to read YouTube's player
    # channels: [UC1D36wr10qyCfisHulZ5G8Q]       # the channel ids uploads are taken from
    # searches_per_hour: 20                       # default; films looked for on YouTube in an hour
```

- **When.** Only for a film on the DMM wanted list, and only when nothing the indexers
  return can be taken: no release passes `quality`, `max_size_gb`, `exclude_words` and
  the title and year checks, or every one was found gone, with every indexer answering.
  Never for a show or an upgrade, nor with `audio_languages` or `subtitle_languages`
  set, since an upload's languages cannot be read. Only the wanted list takes a stream:
  a film the Plex watchlist also wants is not settled for it by one, since Plex cannot
  play it, and the watchlist keeps looking for a release.
- **How often.** At most `searches_per_hour` films are looked for in an hour (20 by
  default: 1,820 films take four days), one at a time. A film YouTube has nothing for is
  asked about again a day later, restarts included.
- **Which upload.** zurg searches YouTube for the title and year, and for the original
  title when DMM sends one, and takes an upload only when all of these hold: it is on
  one of `channels`; it runs at least 90% of the film's runtime, or an hour when DMM does
  not know the runtime; its title begins with the film's title (`'Separada' FULL MOVIE |
  ...`), states no other year, and is no trailer, teaser, clip or `Part N`. Of those it
  takes the longest, then the most watched, and checks that YouTube streams it with
  picture and sound together.
- **Channels.** The default list is the Philippine studios' own channels: ABS-CBN Star
  Cinema, Regal Entertainment, VIVA Films, SOLAR WATCH NOW, OctoArts Films, CineMo and
  Cinema One. Of 100 random unfetched films on one wanted list (2026-10-31), 65 had a
  full-length upload and 33 were on these channels; the rest were re-uploads (every
  Disney one) and, for new releases, scams titled "full movie". Writing `channels`
  replaces the list. A channel's id is the `UC...` part of its address, or what
  `yt-dlp --print channel_id <a video's page>` prints.
- **What you get.** The film is named `Title.Year.1080p.YouTube.WEB-DL` and DMM is told
  it was fetched (`youtube:<video id>`). rex gets it as an HLS item in your movies
  library, read through zurg. Jellyfin and Kodi get
  `__magic__/__movies__/Title (Year) {tmdb-N}/Title (Year) {tmdb-N}.strm`, with `__magic__`
  on. The address in the `.strm` is zurg's own, from [`base_url`](../reference/config.md), and needs
  no login. Either address is the stream's playlist served by zurg, every segment in it
  an address on zurg too, which zurg fetches from YouTube itself. zurg resolves the
  stream with yt-dlp and keeps it until an hour before it expires. A segment's address
  is good for a day; a player that comes back later reads the playlist again.
- **Upgrades.** A streamed film stays on the wanted list while `upgrades` is on, and any
  release of it that comes out replaces the stream, whatever its resolution: the stream,
  its `.strm` and its rex item go once the release has passed its check.

Limits:

- **Plex cannot play it.** It is no file on the mount. Use rex, Jellyfin or Kodi.
- **Cookies are required.** Without a signed-in account's cookies YouTube offers an
  address that fetches much only video and audio apart, or nothing, so zurg starts with
  the fallback off and says why. Export them from a browser signed in to YouTube, ideally
  on the same network. Signing out in that browser ends them.
- **Every byte passes through zurg.** Nothing is redirected to YouTube: rex sends its
  source's login with every request its transcoder makes, redirected ones included, and
  YouTube ties a stream to the address that resolved it. So any player that reaches
  zurg plays it, and zurg carries the film's traffic.

## سلوك Seerr {#seerr-behavior}

يتّبع المحوّل **seerr-team/seerr** في
[مسارات الطلبات](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/routes/request.ts)،
[تعريفات الحالات](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/server/constants/media.ts)
و[عقد الـ API](https://github.com/seerr-team/seerr/blob/c604bccc003d4d2f74a66d8cb74d9e14d5ffda89/seerr-api.yml).

- يستعلم عن كل صفحات الطلبات الموافق عليها باستخدام `X-Api-Key`. إذا فشلت صفحة، تبقى القائمة السابقة كما هي ويتوقف العمل لهذا المصدر.
- يتحقق من الموافقة مرة أخرى قبل بدء التحميل. الطلبات المعلّقة والمرفوضة والفاشلة والمكتملة والمحذوفة والمتاحة مسبقًا لا تبدأ أي عملية جلب.
- يحوّل المعرّفات عبر Seerr. تقتصر عملية جلب المسلسلات على المواسم الموافق عليها والحلقات المعروفة التي عُرضت. الموسم الجزئي يبقى معلّقًا.
- يتعامل مع 4K وغير 4K بشكل منفصل. إصدار 1080p لا يمكن أن يلبّي طلب 4K.
- يعيد فحص الطلبات المفتوحة كل 30 دقيقة بعد نجاح الجلب، ليجد الحلقات الجديدة التي عُرضت في المواسم المطلوبة. الحلقات غير المعلنة لا تصبح مهامًا إلا بعد ظهورها في بيانات Seerr الوصفية.
- يفضّل الحزم الكاملة بعد عرض كل الحلقات المعروفة. المواسم التي ما زالت تُعرض تستخدم الحلقات المفردة. الموسم 0 (الحلقات الخاصة) غير مدعوم. الطلب الذي يتضمن الموسم 0 لا يُجلب إطلاقًا، ويفشل حتى يتم تعليقه (parked).
- لا يكتب أي تغييرات على حالة الطلبات أو التوفر. فحص المكتبة في خادم الوسائط الخاص بـ Seerr هو ما يحدد التوفر الفعلي، ويُبلغ الطالبين. حفظ ملف NZB لا يعني أنه مفهرس أو قابل للتشغيل، لذلك يتحقق المحرك منه قبل اعتبار الموسم مُجلبًا.

اضبط فحص المكتبة في Seerr ليشمل المكتبة التي يخدمها هذا النسخة. إذا كان Sonarr/Radarr يجلب الطلبات نفسها بالفعل، فعطّل سير العمل المتداخل ذلك قبل تفعيل هذا المحوّل. المحوّل لا يحاكي خادم *arr ولا يغيّر إعدادات خدمات Seerr. الاستعلام الدوري يوفّر الاستعادة بعد إعادة التشغيل، ولا يتطلب أي webhook.

## سلوك Radarr {#radarr-behavior}

يحتفظ Radarr بالقائمة ويملك المكتبة. ويتولى zurg البحث والتنزيل. لا يبحث Radarr ولا يجلب أي شيء أبدًا: يقرأ zurg ما يريده Radarr، ثم يختار إصدارًا من المفهرسات الخاصة به، ويتحقق منه عبر خوادم الأخبار (جلب TorBox على حساب `torbox_nzb`) أو عبر حساب الديبريد الذي يحتويه، ثم يضع الفيديو في مجلد الفيلم
داخل `__magic__` ويطلب من Radarr إعادة فحص ذلك الفيلم وحده. لا يُنسخ شيء: الفيديو ملف في مكتبة zurg، و Radarr يراه الآن في مجلده.

### إعداد Radarr {#setting-up-radarr}

1. **Root folder mit `__magic__`, eine Ebene tiefer.** Zum Beispiel
   `/mnt/zurg/__magic__/movies` (`/Volumes/Zurg/__magic__/movies` unter macOS,
   `Z:\__magic__\movies` unter Windows). Nicht `__magic__` selbst und nicht
   `__magic__/__all__`, denn dort sind alle Releases der Bibliothek aufgelistet. Ein Film,
   dessen Ordner woanders liegt, wird übersprungen, und zurg schreibt eine Warnung in sein Log.
   Unter Windows sieht Radarr `Z:` nur, wenn es in derselben Anmeldesitzung läuft wie zurg, also nicht
   als Windows-Dienst: siehe
   [die Sitzungsregeln](../setup/windows.md#keeping-it-running-the-session-rules).
2. **Import-Listen mit Suche beim Hinzufügen aus.** Füge Filme hinzu, wie du willst (von Hand, über Listen oder Seerr, das auf Radarr zeigt). Lass **Search for Movie** beim Hinzufügen aus, weil zurg die Suche übernimmt.
3. **Es werden keine Indexer und kein Download-Client benötigt.** Falls Radarr welche hat, kann es parallel zu zurg greifen. Schalte deshalb die automatische Suche bei seinen Indexern aus (oder entferne sie) für die Filme, um die sich zurg kümmert.
4. **`library_path` ist der Ort, an dem Radarr `__magic__` sieht.** Wenn Radarr auf demselben Rechner wie zurg läuft und dort den Mount sieht, an dem zurg ihn einhängt, lass die Option weg: Standardmäßig ist sie `mount_path` von zurg plus `/__magic__`. Wenn Radarr in einem Container läuft, der zurg an einem anderen Pfad einhängt, setze sie auf diesen Pfad, zum Beispiel `/data/zurg/__magic__`. Ein Film unter `/data/zurg/__magic__/movies/Heat (1995)` wird dann in `movies/Heat (1995)` innerhalb von `__magic__` von zurg abgelegt. Windows-Pfade wie `Z:\__magic__` funktionieren ebenfalls. Ein Radarr-Container wird nur auf einem Linux-Host unterstützt: Docker Desktop unter macOS und Windows läuft in einer VM, und das Durchreichen des zurg-Mounts dorthin ist nicht getestet. Betreibe Radarr dort deshalb nativ.

   Wenn Radarr außerdem Downloads über den [SABnzbd](sonarr-radarr.md)- oder [qBittorrent](sonarr-radarr-torrents.md)-Endpunkt von zurg entgegennimmt, muss es deren Download-Ordner unter `library_path/__all__` sehen, und zwar über dasselbe Volume wie seine Root-Folder. Sonst ist jeder Import daraus eine Kopie der ganzen Datei. zurg fragt bei Radarr ab, wo es beide sieht, und meldet das auf der Acquisition-Seite, im Log und in `zurg doctor`, falls sie sich kein Mount teilen können. Siehe [Ein Volume für den Download-Ordner und die Root-Folder](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

### ما يطلبه zurg من Radarr {#what-zurg-asks-radarr-for}

كل دورة فحص تقرأ قائمة الأفلام في Radarr وتتصرف مع كل فيلم يكون مراقَبًا (monitored) و**متاحًا** وفق الحد الأدنى للإتاحة (minimum availability) الخاص بالفيلم، ولا يملك ملفًا أصلًا، أو يملك ملفًا دون حد الترقية (cutoff) في ملف الجودة (quality profile) الخاص به، بشرط أن يسمح الملف بالترقيات. و"دون الحد" تعني أقل من جودة الحد أو أقل من درجة الحد للتنسيقات المخصصة (custom-format score)، كما يحسبها Radarr. أما الفيلم الذي لم يصدر بعد، مثل فيلم مؤرخ بعد شهور، فينتظر حتى يعلن Radarr أنه متاح.

كل إصدار مرشح يوشك zurg على فحصه يُعرض على محلل Radarr نفسه (`/api/v3/parse`) ويُحكم عليه بملف جودة الفيلم، لذلك ما يقبله zurg هو ما كان Radarr سيقبله:

- **يجب أن يكون هو الفيلم نفسه.** يجب أن يطابق Radarr العنوان مع الفيلم ذاته. فالبحث عبر معرّف الموفر (ID search) يعيد أفلامًا أخرى (البحث عن *Psycho* أعاد *Ed Gein: The Real Psycho*)، والعنوان الذي لا يطابق Radarr أي فيلم يُرفض. ويُرفض كذلك أي عنوان يتضمن سنة تبعد أكثر من سنة واحدة عن سنة الفيلم.
- **تُطبَّق قائمة السماح ودرجة الحد الأدنى في الملف أولًا.** يجب أن تكون الجودة المحللة مسموحًا بها في الملف، وأن تبلغ درجة التنسيق المخصص حد الملف الأدنى، وأن يتناسب الحجم مع حدود الجودة في **Settings > Quality** وفق مدة الفيلم.
- **يجب أن يكون الإصدار باللغة التي يحددها الملف.** مع الخيار **Original**، وهو الافتراضي، يجب أن يقرأ Radarr العنوان على أنه بلغة الفيلم الأصلية، فيُرفض إصدار فرنسي فقط لفيلم إنجليزي. والعنوان الذي لا يذكر أي لغة يُعد باللغة الأصلية. واللغة المحددة تتطلب تلك اللغة، والخيار **Any** يقبل كل اللغات. وينطبق هذا على الملف الأول وعلى الترقية على حد سواء.
- **الترقيات تتجه نحو الحد لاحقًا.** الفيلم الذي لا يملك ملفًا يقبل أي إصدار يجتاز الفحوص السابقة. أما الفيلم الذي يملك ملفًا دون الحد، فلا يُقبل له إلا إصدار أفضل: جودة أعلى وفق ترتيب الملف ما دام الملف دون جودة الحد، أو درجة تنسيق مخصص أعلى (بمقدار خطوة الترقية في الملف على الأقل) ما دام دون درجة الحد. ولا يُقبل أبدًا إصدار بجودة أدنى. والإصدارات PROPER وREPACK ذات الجودة نفسها لا تُعد ترقيات.

يُطبَّق الملف على الإصدار الذي يوشك zurg على أخذه كقائمة سماح: الفيلم الصحيح، وجودة مسموح بها، والحد الأدنى للدرجة، واللغة، وحدود الحجم.

افتراضيًا لا يُستخدم ترتيب تفضيل الملف للاختيار بين الإصدارات المسموح بها. يأخذ zurg أول إصدار مسموح به يكون الأرخص فحصًا، فيجرب إصدارات الويب (WEB-DL وWEBRip) أولًا، ثم إصدارات Blu-ray، ثم البقية، لأن إصدارات الويب هي الأكثر شيوعًا كملف فيديو واحد. وإذا كان الملف يفضل شيئًا أفضل مما وصل وكان يسمح بالترقيات، فسيرى Radarr ملف الفيلم دون الحد، وتبحث دورة الترقية في zurg عن الإصدار الأفضل بعد أن يصبح للفيلم ملف. يصل الملف الأول بسرعة، ويُخدَم ترتيب الملف عبر الترقية. اضبط `best_first: true` لتجعل أول عملية أخذ تتبع ترتيب الملف بدلًا من ذلك. انظر [أخذ الأفضل في الملف أولًا](#taking-the-profiles-best-first).

عندما لا يعيد البحث بمعرّف IMDb أو TMDB أي نتيجة إطلاقًا، يعيد zurg البحث بالعنوان والسنة، كما يفعل Radarr. فكثير من المنشورات، وخاصة الأفلام الوثائقية القصيرة، مفهرسة دون أي معرّف. ويقرر محلل Radarr إن كانت كل نتيجة هي الفيلم، فيُرفض فيلم يحمل الاسم نفسه كما يُرفض أي تطابق خاطئ آخر.

يُسأل Radarr عن إصدار فقط عندما يوشك zurg على فحصه، واحدًا تلو الآخر، لذلك يكلّف الفيلم ذو الإصدار المكوّن من ملف واحد من سؤال إلى ثلاثة أسئلة. ولا يُسأل شيء بعد حفظ منشور مباشر. والعنوان الذي يذكر دقة لا يسمح الملف بأي جودة لها، مثل إصدار 2160p لملف HD-1080p، يُرفض دون أن يُسأل Radarr أصلًا. أما العنوان الذي لا يذكر أي دقة، أو يذكر أكثر من واحدة، فيُرسل دائمًا إلى Radarr، وكذلك كل عنوان حين يسمح الملف بجودة لا يذكر اسمها أي دقة، مثل SDTV وDVD وUnknown وRaw-HD وBR-DISK. ولا يوجّه zurg أكثر من ثماني استدعاءات إلى Radarr واحد في الوقت نفسه.

إذا تعذر الوصول إلى Radarr، لا يُتخذ أي قرار: ينتظر الفيلم دورة الفحص التالية، ولا يُستبعد أي إصدار لأن Radarr لم يرد.

### وضع الملف {#placing-the-file}

بعد فحص الإصدار، يضع zurg الفيديو الخاص به في مجلد الفيلم بالطريقة التي كان سيستورده بها Radarr، وذلك بنقله داخل `__magic__`. لا يتم نسخ أي شيء أو تنزيله.

- **أكبر فيديو هو الذي يتم وضعه.** وهو أكبر ملف `.mkv` أو `.mp4` أو `.m4v` أو `.avi` أو `.mov` أو `.ts` في الإصدار، مع احتساب ما بداخل أرشيفاته. الإصدار الذي يُقدَّم من أرشيف واحد يُعامَل بمحتويات ذلك الأرشيف. مجموعة RAR مع ملفات منفصلة بجانبها، مثل منشور scene يحتوي على العينة وملف `.nfo`، يُتصفَّح كمجلد للإصدار، ويُوضع الفيديو الموجود بداخله من هناك. تبقى العينات والمواد الإضافية وملفات الترجمة وملفات `.nfo` داخل `__magic__/__all__`. يحتفظ الملف باسمه كما هو في الإصدار، ما لم يكن ذلك الاسم لا يدل على الفيلم (لا توجد سنة ولا أي كلمة من عنوانه)؛ عندها يأخذ اسم الإصدار، حتى يتمكن Radarr من قراءة جودته.
- **لا يتم وضع العينة أبدًا.** يُستبعد أي فيديو مسمّى كعينة (`sample-…`، `….sample.mkv`، أو مجلد `Sample/`) مهما كان حجمه، إلا إذا كان اسم الإصدار نفسه يحمل كلمة sample أيضًا. أما الفيلم الذي تحمل كلمة sample في عنوانه فقط (`Sample.Size.2019`، `Death.Proof.2007`)، فالكلمة تكون موجودة في اسم الإصدار أيضًا؛ وهنا لا يُستبعد الفيديو إلا إذا كان أقل من خُمس حجم الإصدار. الإصدار الذي لا يحتوي إلا على عينته، بما في ذلك المنشور الذي ليس فيه سوى العينة، يُترك جانبًا وتُجرَّب المرشحة التالية، حتى لا يستبدل الترقية ملفك بمقطع مدته دقيقة واحدة أبدًا.
- **يُرفض قبل نقله إذا تعذّرت قراءته.** هذا هو الفحص الذي يمر به استيراد Sonarr أو Radarr عبر الـ mount. الإصدار الذي لم تعد خوادم الأخبار تحتفظ بمقالاته، أو الذي لن يُفتح أرشيفه أبدًا، يُترك جانبًا كمنشور ميّت، وتُجرَّب المرشحة التالية. الإصدار الذي يتعذّر قراءته الآن، مثل إصدار على حساب في فترة تهدئة (cooling down)، يُعاد تجربته لاحقًا.
- **يحتفظ Radarr بملف واحد لكل فيلم، لذلك تستبدل الترقية الملف القديم.** عندما يصبح الفيديو الجديد داخل المجلد، يُخفى من المجلد كل فيديو آخر وضعته مكتبة zurg هناك. والإخفاء هنا يعني وضع علامة tombstone، كما يحدث عند الحذف عبر الـ mount: يبقى الإصدار القديم في `__all__` وفي حسابه. أما الملف الحقيقي الذي وضعته في المجلد بنفسك فيُترك كما هو. يُحذف الملف القديم بعد وضع الجديد، لذلك إذا فشل الوضع يبقى للفيلم الملف الذي كان لديه.
- **يعيد Radarr الفحص بعد ذلك.** يخبر zurg الـ mount بالمجلدات التي تغيّرت، حتى لا تقرأ إعادة الفحص مجلدًا ما زال الـ mount يتذكره فارغًا، ثم يطلب من Radarr إعادة فحص ذلك الفيلم وحده.

يحتاج مصدر Radarr إلى `__magic__` (`magic.enabled`). من دونه لا يبدأ المصدر، ويذكر ذلك في السجل وفي صفحة الاستحواذ.

### ما يعرضه Radarr {#what-radarr-shows}

**Activity** يبقى فارغاً: لا توجد عناصر في قائمة الانتظار ولا أحداث grab أو import، لأن Radarr لم يلتقط أي شيء. الفيلم يصبح له ملف ببساطة بعد عملية الفحص (rescan) التي يطلبها zurg، والجودة وال custom formats الخاصة به هي قراءة Radarr لذلك الملف. سجل zurg يسجّل كل فيلم ينتهي منه.

`only_new_items` و`remove_after_grab` لا يفعلان شيئاً مع مصدر Radarr. أفلام Radarr المطلوبة تُعامَل كعمل قائم، مثل طلبات Seerr المعتمدة، وRadarr هو الذي يقرر متى يتوقف الفيلم عن كونه مطلوباً. احتفظ بقيمة `name` للمصدر ثابتة، فهي تعرّف قائمة الانتظار المحفوظة، أما الرابط والمفتاح فيمكنك تغييرهما بحرية.

## سلوك Sonarr {#sonarr-behavior}

يعمل Sonarr بنفس طريقة Radarr.
يحتفظ Sonarr بالقائمة ويملك المكتبة.
يتولى zurg البحث والتنزيل. لا يبحث Sonarr أبدًا ولا يلتقط الإصدارات.
يقرأ zurg الحلقات المفقودة في Sonarr ويختار إصدارًا من فهارسه الخاصة.
ويتحقق من الإصدار عبر خوادم الأخبار (جلب TorBox عبر حساب `torbox_nzb`) أو عبر حساب debrid الذي يحتويه، ثم يضع فيديو كل حلقة في مجلد الموسم الخاص بالمسلسل داخل `__magic__`.
ثم يطلب من Sonarr إعادة فحص هذا المسلسل وحده.
لا يتم نسخ أي شيء.

### إعداد Sonarr {#setting-up-sonarr}

1. **المجلد الجذر داخل `__magic__`، بمستوى واحد أسفله.** على سبيل المثال
   `/mnt/zurg/__magic__/tv` (`/Volumes/Zurg/__magic__/tv` على macOS،
   `Z:\__magic__\tv` على Windows). أي مسلسل يقع مجلده في مكان آخر يُتخطّى
   مع تحذير واحد في سجل zurg.
   على Windows يجب أن يعمل Sonarr ضمن جلسة تسجيل الدخول الخاصة بـ zurg، كما يعمل Radarr.
2. **البحث عند الإضافة معطّل.** أضف المسلسلات بالطريقة التي تفضّلها. واترك **Start search
   for missing episodes** معطّلاً، لأن zurg هو من يتولى البحث.
3. **لا حاجة إلى مفهرسات ولا إلى عميل تنزيل.** إذا كانت لدى Sonarr فيمكنها أن تلتقط
   الملفات إلى جانب zurg، لذلك عطّل البحث التلقائي على المفهرسات للمسلسلات
   التي يتولاها zurg.
4. **`library_path` هو المكان الذي يرى فيه Sonarr المسار `__magic__`.** يعمل تماماً
   كما يعمل مع Radarr، بما في ذلك التحقق من أن Sonarr يصل إلى مجلد التنزيل
   والمجلدات الجذرية الخاصة بـ zurg عبر وحدة تخزين واحدة. اتركه خارج الإعدادات
   إذا كان Sonarr يرى الجبل في المكان نفسه الذي يركّبه فيه zurg.

### ما يطلبه zurg من Sonarr {#what-zurg-asks-sonarr-for}

كل فحص دوري يقرأ الحلقات المفقودة من Sonarr. وهي الحلقات المراقَبة لمسلسل مراقَب، وقد عُرضت بالفعل ولا يوجد لها ملف. يجمع zurg هذه الحلقات حسب الموسم، ويتعامل مع كل موسم كقطعة عمل واحدة.

- **الموسم كاملًا بعد انتهاء عرضه قد يأتي كحزمة.** عندما تكون كل حلقات الموسم مفقودة ولم تبقَ حلقة منه قيد العرض، تُجرَّب حزمة الموسم أولًا. وإلا تُؤخذ الحلقات المفقودة للموسم واحدة تلو الأخرى من نتائج بحث الموسم. والموسم الذي فيه بعض ملفاته موجودة بالفعل لا يُجرَّب له أبدًا حزمة، لأن ذلك سيضع نسخة ثانية من تلك الحلقات في المجلد.
- **الحلقة الجديدة عمل جديد.** عندما تُعرض حلقة الأسبوع القادم، يظهر الموسم من جديد مع تلك الحلقة. ولا يعيد zurg البحث عن الحلقات التي حصل عليها سابقًا.
- **الحلقة الجديدة تُبحث من جديد خلال دقائق.** غالبًا ما يُنشر إصدارها خلال ساعة من عرضها، لذا قد لا يجد البحث الذي يجري لحظة العرض أي شيء. خلال ست ساعات من عرض الحلقة يحاول zurg كل دقيقتين، وبعد ذلك كل عشر دقائق حتى يومين من عرضها. بعد ذلك يتراجع كما يفعل مع أي شيء آخر (انظر [الاستمرارية والتعافي](#persistence-and-recovery)). وعلى حساب debrid يجب أيضًا أن يكون الإصدار مخزَّنًا في ذلك الحساب مسبقًا، لأن zurg يضيف فقط ما يملكه الحساب.
- **الحلقة المحذوفة تُطلب من جديد.** عندما يدرج Sonarr حلقة حصل عليها zurg سابقًا، يبحث zurg في مجلد الموسم. فإذا لم يعد هناك أي فيديو لتلك الحلقة يُعاد البحث عنها. وإذا كان الفيديو موجودًا، فهذا يعني أن Sonarr لم يُعد الفحص بعد، فلا يُبحث عن شيء.
- **الترقيات تُحسب لكل ملف.** يُعدّ ملف الحلقة الأدنى من الحد (cutoff) في ملف الجودة الشخصي ترقيةً، ما دام الملف الشخصي يسمح بالترقيات. و"الأدنى من الحد" يعني أدنى من جودة الحد، أو أدنى من نقاط الصيغة المخصصة المطلوبة. وقائمة Cutoff Unmet في Sonarr تحسب الجودة وحدها. ففي Sonarr 4.0.20 لا يظهر في تلك القائمة ملف بجودة الحد يسجّل 0 من أصل حد 40. أما zurg فيحسب الاثنين، كما تفعل قاعدة الترقية في Sonarr نفسها. والملف الذي يحوي حلقتين يُعدّ ترقية واحدة للحلقتين معًا.
- **حلقات البرنامج اليومي تُوجد حسب يوم عرضها.** تُسمّى إصداراته باليوم (`The.Daily.Show.2026.11.03.Min.Jin.Lee...`)، والمفهرِسات لا تجدها برقم الحلقة، لذا يُطلب كل حلقة مفقودة أيضًا كبحث نصي باسم المسلسل واليوم، `The Daily Show 2026.11.03`. ويحوّل محلل Sonarr اليوم إلى الحلقة (S31E124)، كما يفعل مع العنوان المرقّم حسب الموسم.
- **حلقات الأنمي تُوجد بالرقم الذي يعدّها به المسلسل.** إصدارات مجموعات الترجمة الشعبية (fansub) مرقّمة من أول حلقة في المسلسل (`[SubsPlease] Jujutsu Kaisen - 30` هي الحلقة السادسة من الموسم الثاني)، لذا يُطلب كل حلقة مفقودة أيضًا كبحث نصي باسم المسلسل ورقم تلك الحلقة، `JUJUTSU KAISEN 30`. وتُعدّ الحزمة التي تمتد عبر أرقام الموسم (`(25-47)`) حزمةَ ذلك الموسم. ويربط محلل Sonarr الرقم بالحلقة، مستعينًا بأسماء الموسم البديلة فيه (`Jujutsu Kaisen 2nd Season` و`Jujutsu Kaisen S2`)، فيُحكم على العنوان المرقّم بأي من الطريقتين على أنه الحلقة التي هو عليها. ويُرفض الإصدار الذي لا يطابقه Sonarr بأي مسلسل، مثل إصدار يحمل اسمًا بديلًا لا يعرفه Sonarr، كما يُرفض أي إصدار آخر.
- **الحلقات الخاصة هي الموسم 0.** تُدرج الحلقات الخاصة المراقَبة في Sonarr كأي موسم، ويُطلب موسمها بالرقم `00` (لأن المفهرِس الذي يُطلب منه الموسم `0` يرد بموسم آخر)، ولا يطابق إلا إصدار يذكر `S00Exx`. فالحلقة الخاصة التي تُسمّى بعنوانها وحده لا يحلّلها أي شيء، ولا في Sonarr نفسه. وتوضع في المجلد الذي يسمّيه **Specials Folder Format** في Sonarr.

كل إصدار مرشح يُعرض على محلل Sonarr نفسه (`/api/v3/parse`) ويُحكم عليه وفق الملف الشخصي للجودة في المسلسل. ما يقبله zurg هو ما كان Sonarr سيقبله.

- **يجب أن يكون هذا المسلسل وهذا الموسم بعينه.** يجب أن يطابق Sonarr العنوان بالمسلسل نفسه. ويُرفض العنوان الذي لا يطابقه Sonarr بأي مسلسل، إلا إذا كان المسلسل لا يعتمد ترقيم scene وكان بحث Sonarr عن المسلسل بالاسم الوارد في العنوان يجد هذا المسلسل أولًا (كعنوان بلغة أجنبية مثلًا).
- **الحزمة يجب أن تكون الموسم كاملًا.** تُرفض الحزمة الجزئية. وتُقبل الحزمة المكتوبة كنطاق، مثل `Season 1 E01-E07`، عندما يكون النطاق هو الموسم كاملًا. والحزمة التي تضم عدة مواسم تُحسب لكل موسم تذكره (انظر [حزم عدة مواسم](#packs-of-several-seasons)). ولا يقرأ Sonarr النطاق `S01-S05` إلا على أنه الموسم 1 وحده، ولا يذكر أين ينتهي، لذا يقرأ zurg النطاق من العنوان. ويجب مع ذلك أن يطابقها Sonarr بالمسلسل ويعدّها حزمة كاملة متعددة المواسم. ويُحكم على حجمها بمدة تشغيل كل موسم تذكره.
- **الحلقة يجب أن تكون حلقة واحدة فقط.** يُرفض الإصدار الذي يحوي حلقتين عندما يُطلب حلقة واحدة.
- **يُطبَّق الملف الشخصي كما يُطبَّق في Radarr.** يجب أن تكون الجودة مسموحة. ويجب أن تبلغ نقاط الصيغة المخصصة الحد الأدنى للملف الشخصي. ويجب أن يناسب الحجم حدود الجودة في **Settings > Quality** لمدة تشغيل الحلقات التي يحتويها الإصدار. ويجب أن تتفوق الترقية على الملف الحالي وفق قواعد Sonarr. وملفات Sonarr الشخصية لا تحتوي على إعداد للغة، لذا لا تُحسب اللغة إلا من خلال نقاط الصيغة المخصصة، كما هو الحال في Sonarr.

ترتيب الإصدارات المسموحة يختلف عن Radarr. تُجرَّب حزمة الموسم قبل الحلقات المنفردة، لأنها عملية سحب واحدة بدل عمليات كثيرة. ومن بين الإصدارات التي يسمح بها Sonarr، يأخذ zurg الإصدار الذي يرتّبه أولًا إعداد `quality`. مع `best` يكون ذلك أعلى دقة ثم الأكبر حجمًا، والحزمة تُقاس بما تحويه لكل حلقة. لذا يُملأ موسم منتهٍ بحزمة 1080p حتى لو كان البحث نفسه يحوي كل الحلقات بدقة 2160p. ثم يستبدل مسار الترقية الحلقات واحدة تلو الأخرى. ولا يكون أي إصدار مرشحًا إذا احتوت الحزمة أكثر من `max_size_gb` لكل حلقة، أو أكثر من `max_season_size_gb` الذي كتبته للموسم. ويغيّر `best_first: true` الأمرين معًا. انظر [أخذ أفضل ما في الملف الشخصي أولًا](#taking-the-profiles-best-first).

يُرفض العنوان الذي يذكر دقة لا يسمح الملف الشخصي بأي جودة منها، دون أن يسأل zurg Sonarr. ولا يرسل zurg أكثر من ثماني طلبات إلى Sonarr واحد في وقت واحد. وإذا تعذر الوصول إلى Sonarr فلا يُحسم أي قرار: ينتظر الموسم الفحص التالي، ولا يُستبعد أي إصدار.

### وضع الملفات {#placing-the-files}

بعد فحص الإصدار، يُوضع فيديو كل حلقة في مجلد الموسم. هذا هو المجلد الذي توجد فيه ملفات الموسم الحالية. أما الموسم الذي لا توجد فيه ملفات بعد، فيكون المجلد هو الاسم الذي تحدده **Season Folder Format** في Sonarr، مثل `Season 1`. والمسلسل المضبوط على عدم استخدام مجلدات المواسم، تُوضع ملفاته في مجلد المسلسل نفسه.

- **لكل حلقة فيديو خاص بها.** يُعثر على الفيديو من خلال رقم الحلقة في اسمه، حتى داخل الأرشيفات الموجودة في الإصدار. الحزمة (pack) تضع كل حلقة قُصدت بها. تبقى العينات وملفات `.nfo` في `__magic__/__all__`، ولا تُوضع العينة أبداً كحلقة.
- **الحزمة التي تنقصها حلقة تُرفض قبل نقل أي شيء.** تُعزل كما تُعزل المشاركة الميتة، ثم تُجرَّب الحزمة التالية أو الحلقات المنفردة.
- **الحلقة المنفردة التي لا يحمل اسم ملفها أي رقم تأخذ أكبر فيديو في الإصدار.** كثيراً ما تبدو المشاركات المموّهة بهذا الشكل.
- **فيديو الأنمي أو البرنامج اليومي يُوضع تحت المسلسل والحلقة.** يقرأ الفحص الدوري الملف من خلال اسمه وحده، ولا يعرف شيئاً عن ترقيم الـ scene. الملف `[Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv` الموضوع في مجلد المسلسل استُورد كـ S01E08، بينما يقرأ محلل Sonarr العنوان نفسه كـ S02E08. لذلك يُوضع الفيديو باسم `JUJUTSU KAISEN - S02E08 - [Erai-raws] Jujutsu Kaisen 2nd Season - 08.mkv`، فيُستورد بشكل صحيح، ويبقى اسمه الأصلي بعد رقم الحلقة كي يقرأ Sonarr الجودة والمجموعة. أما فيديوهات المسلسل العادي والحلقات الخاصة فتحتفظ بأسمائها، لأنها تذكر رقم الحلقة أصلاً.
- **الترقية تستبدل حلقتها فقط.** يُخفى الفيديو القديم لتلك الحلقة من مجلد الموسم بعد وضع الجديد. بقية الحلقات في المجلد تبقى كما هي. والإخفاء هنا يعني وضع علامة حذف (tombstone)، كما يحدث مع Radarr.
- **Sonarr يعيد الفحص بعد ذلك.** يخبر zurg الـ mount بالمجلدات التي تغيّرت، ويطلب من Sonarr إعادة فحص المسلسل.
- **حلقة ناقصة لا توقف البقية.** عندما لا يكون لحلقة إصدار يستطيع zurg أخذه بعد، تُفحص الحلقات التي وجدها وتُوضع. ويُطلب من Sonarr إعادة الفحص من أجلها فوراً. أما الحلقة الناقصة فيُبحث عنها مرة أخرى وفق جدول إعادة المحاولة المعتاد.

يحتاج مصدر Sonarr إلى `__magic__` (`magic.enabled`). بدونه لا يبدأ المصدر، ويذكر ذلك في السجل وفي صفحة الاستحواذ.

تبقى **Activity** في Sonarr فارغة، كما في Radarr. تصبح للحلقات ملفات ببساطة بعد إعادة الفحص التي يطلبها zurg. الإعدادان `only_new_items` و`remove_after_grab` لا يفعلان شيئاً مع مصدر Sonarr.

## حزم تضم عدة مواسم {#packs-of-several-seasons}

**يمكن أخذ موسم من حزمة تحتوي على عدة مواسم**، مثل `Game.of.Thrones.S01-08.BDRip.1080p` أو `Breaking Bad Season 1-5`. تسجّل المفهرسات مثل هذه الحزمة تحت كل موسم تغطيه. في خلاصة DMM، كانت 72 نتيجة من أصل 691 لبحث Breaking Bad season 3 عبارة عن حزم تضم عدة مواسم. وبالنسبة لبعض المواسم، تكون إحدى هذه الحزم هي النسخة الوحيدة الموجودة في الحساب.

- **العنوان يحدد المواسم.** تُقرأ كل من `S01-S05` و`S01-05` و`[S01-08]` و`S1-9` و`Seasons 1-8` و`Season 1 to 5` و`Season 1 · 2 · 3` و`Stagioni 01-05` و`Temporadas 1-4`. أما العنوان الذي لا يحتوي على أرقام مواسم، مثل `Complete Series`، فلا يُؤخذ. ولا يُؤخذ كذلك العنوان الذي يذكر موسماً واحداً فقط كلفظ، مثل `Season 3 Complete`. فهذه لم تُقرأ يوماً على أنها حزم.
- **لا يُنقل إلا ذلك الموسم.** الحزمة المأخوذة للموسم 4 تضع حلقات الموسم 4 فقط في مجلد الموسم. وتبقى ملفات المواسم الأخرى حيث تسجلها المكتبة. وإذا لم تحتوِ ملفات الحزمة على كل حلقات الموسم، تُرفض قبل نقل أي شيء، مهما ادّعى عنوانها.
- **يُحكم على الحجم لكل حلقة.** يُقسَم حجم الحزمة على عدد المواسم التي تذكرها، ثم على عدد حلقات الموسم، ويُقارن الناتج بـ`max_size_gb`، كما تُقارن به النسخة نفسها لو نُشرت حلقةً حلقةً. فحزمة بحجم 346 GB لثمانية مواسم، كل موسم منها عشر حلقات، تعادل 4.3 GB للحلقة. أما ريمكس الموسم الثاني من I Love Lucy، وعدد حلقاته 31، فحجمه 106 GiB، أي 3.4 GiB للحلقة، وهو يقع تحت الحد المكتوب 40. وحين لا يذكر المصدر حلقات الموسم، لا تُفرض على الحزم أي حدود لكل حلقة. ويضيف `max_season_size_gb` الذي تكتبه سقفاً على كل موسم تذكره الحزمة، وافتراضياً لا يوجد هذا السقف.
- **الجودة تأتي أولاً.** تُرتَّب الحزم مثل أي إصدار آخر: الدقة أولاً، ثم ما تحمله لكل حلقة، كما ترتّبها صفحة المواسم في DMM. فحزمة 2160p لموسم واحد تُؤخذ قبل حزمة 1080p لثمانية مواسم. وضمن الدقة الواحدة، تأتي ريمكس الموسم نفسه قبل حزمة من ثمانية مواسم تكون أكبر إجمالاً لكنها أصغر لكل حلقة.
- **تأخذ بقية مواسم العرض الحزمة نفسها.** بمجرد أن يأخذ موسم واحد حزمةً تضم عدة مواسم، تجرّب بقية مواسم العرض تلك الحزمة أولاً، قبل أي حزمة بالدقة نفسها وجدها بحثها الخاص. فالحزمة موجودة في الحساب أصلاً، فلا تكلّف شيئاً. وبينما تختار مواسم العرض بين حزم متعددة المواسم، تختار واحدةً تلو الأخرى، حتى لا تستقر المواسم التي طُلبت معاً (مثلاً سلسلة Sonarr وكل مواسمها في استطلاع واحد) كلٌّ منها على نسخة مختلفة من العرض. وبمجرد أن يختار أحدها دون مثل هذه الحزمة، لأنه لم توجد أي حزمة في الحساب أو لأن الملف الشخصي لم يسمح بأي منها، تختار البقية دفعة واحدة. أما الموسم الذي يُطلب بعد ساعة فيبحث من جديد.

## مشاهدة العمل أثناء تشغيله {#watching-it-work}

لرابط **Acquisition** في لوحة التحكم يفتح `/acquisition/` على المنفذ الخاص بـ zurg.

يحصل كل مصدر على سطر يوضح عدد عناوينه المكتملة والجارية والمنتظرة والمؤجلة والموضوعة في الطابور، إلى جانب عدد العناوين التي يعالجها zurg في وقت واحد، وعدد الاستعلامات التي يرسلها إلى مفهرس واحد في وقت واحد، وعدد اتصالات الأخبار التي تسمح بها حسابات `nzb`. وتحت ذلك يحتوي كل مصدر على جدول فيه صف لكل عنوان. يعرض الصف الحالة، وما يفعله العنوان الجاري في تلك اللحظة (البحث، وعدد النتائج التي تم تقييمها وقبولها حتى الآن، والمرشح الذي يُفحص، والتحقق من خوادم الأخبار، والنقل)، وعدد محاولاته، والإصدار المختار مع الجودة والتقييم اللذين منحهما إياه المصدر، ومكان نقله، وموعد المحاولة التالية للعنوان المنتظر. ويُظهر العنوان الذي لم يبقَ من إصداراته ما يمكن تجربته سببَ ذلك، مع عدّ الإصدارات التي رفضها المصدر وفق قواعده الخاصة حسب كل قاعدة: `14 refused by the source's own rules (title mismatch 7, quality 5, size 2)`. أما الإصدارات التي رُفضت بسبب دقتها دون سؤال المصدر فتُحسب ضمن الجودة. تُحدَّث الصفحة تلقائياً كل خمس ثوانٍ. وتتوفر اللقطة نفسها على `/acquisition/status.json`، وفيها يكون هذا السبب هو الحقل `detail` الخاص بالعنوان. عند عدم تفعيل أي مصدر، أو عند ضبط Acquisition مع إيقافه مؤقتاً، تُبيّن الصفحة ذلك والسبب.

يحصل كل فيلم يُختار له إصدار على سطر واحد في السجل، لقياس أين يذهب الوقت:

```
Acquisition: chose <release> for <title>: results=143 local_refusals=97 radarr_refusals=1 inspected=2 radarr_calls=3 in 4.2s
```

`results` هو ما أعاده البحث، و`local_refusals` النتائج التي رُفضت دون سؤال المصدر، و`radarr_refusals` تلك التي رفضها المصدر وفق قواعده، و`inspected` ملفات NZB التي قُرئت، و`radarr_calls` الأسئلة الموجهة إلى المصدر (ملفات NZB المقروءة إضافةً إلى الرفوضات التي وقعت في الطريق إليها، عندما يكون المصدر Radarr)، والزمن يُحسب من بداية البحث. تُسجَّل الإصدارات المرفوضة دون سؤال واحداً تلو الآخر على مستوى debug فقط.

## فحص \*arr لا يستخدم zurg إلا كعميل تنزيل {#checking-an-arr-that-only-uses-zurg-as-its-download-client}

A Sonarr or Radarr pointed at zurg's [SABnzbd](sonarr-radarr.md) or
[qBittorrent](sonarr-radarr-torrents.md) endpoint does its own searching, and does not
need a source here. zurg still wants its API key, because three of its settings
decide whether every import is a free rename or a whole release downloaded
from the debrid account and written to zurg's disk: Remove Completed on a
qBittorrent client, the download folder and the root folders on one volume,
and root folders inside `__magic__`. With the key, zurg turns Remove Completed
on by itself (see [qbittorrent.md](sonarr-radarr-torrents.md#what-to-put-in-each-field))
and warns about the other two. See
[One volume for the download folder and the root folders](sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

The easiest way to give zurg the key is the banner on the main dashboard,
described below. Or add it as a source that is switched off:

```yaml
acquisition:
  sources:
    - name: sonarr
      type: sonarr
      enabled: false
      url: http://sonarr:8989
      api_key: YOUR_SONARR_API_KEY
```

A Radarr or Sonarr source with `enabled: false` acquires nothing. zurg never
reads its wanted list and never searches for it. With its `url` and `api_key`
set, and one of the two endpoints on, zurg only reads the \*arr's root folders,
remote path mappings and download clients, at start, every ten minutes and as
soon as the \*arr first calls one of the endpoints. It turns Remove Completed
on for the \*arr's zurg qBittorrent client when it is off, the one change zurg
makes, and reports a layout that makes imports copies. Every source with a URL
and an API key, enabled or not, is checked and corrected the same way. It is
listed on the acquisition page under **Checked, never searched for**, with
what zurg changed, the findings go to the log, and `zurg doctor` shows them as
`imports (<name>)`. `library_path` is not judged for such a source, since
nothing is placed for it. A source added to config.yml by hand is read at
start, so restart zurg after adding one that way.

zurg also notices a Sonarr or Radarr it cannot check. Both send their name in
every request to the endpoints (`Sonarr/4.0.20.3014 (alpine 3.24.1)`), so zurg
records which ones call it and from which address. When one calls and no
source of its kind has a URL and an API key, zurg logs one warning, `zurg
doctor` reports it on its `*arr settings` line, and the main dashboard shows a
banner with a form for its URL and API key. The URL is filled in with a guess:
the address the \*arr calls from, on its default port (8989 for Sonarr, 7878
for Radarr). That address is often a container's own, which zurg may or may
not reach, so change it to whatever URL reaches the \*arr from where zurg
runs. The API key is in the \*arr under Settings, General, Security. zurg
first asks the \*arr for its status with that key, and saves nothing unless it
answers as the app it was named as. It then adds the source above to
config.yml with `enabled: false`, keeping everything else in the file as it
was, and checks it straight away, with no restart. The form shows what zurg
found and changed. The key is written to config.yml and sent to the \*arr, and
nowhere else.

The banner matches by kind, not by address: an \*arr calls zurg from inside
its container, on an address that has nothing to do with the URL zurg reaches
it on, so one Sonarr source with a key silences the banner for every Sonarr.

## البحث عن الإصدارات المكررة {#finding-duplicate-releases}

ترقية تترك الإصدار الذي استبدلته في مكتبتك. مع إيقاف `magic.allow_delete`، لا يفعل حذف Radarr أو Sonarr للملف القديم سوى إخفائه في `__magic__`، فيبقى الإصدار القديم في `__all__` وفي حسابه.
وكذلك تترك عمليات الجلب من أكثر من indexer، أو حزمة موسم إلى جانب حلقات منفردة، عدة إصدارات للشيء نفسه. تعرض **Manage > Duplicates** (`/manage/duplicates/`) هذه الإصدارات، وتوضح أيّها يستخدمه Radarr أو Sonarr، وتتيح لك حذف البقية. ولا تحذف أي شيء بنفسها أبداً.

**يُقرأ الإصدار المستخدم من المسارات، لا من الأسماء.** كل ملف يحتفظ به Radarr وSonarr يُسمّى بمسار تحت `__magic__`، ويعرف zurg الإصدار الذي يأتي منه كل مسار، لأن عملية النقل التي وضعت الملف هناك سجّلت ذلك. تقرأ الصفحة كل ملف استوردته كل الـ\*arr، سواء كان مراقَباً أم لا، ووصل إلى حد القطع أم لا، وتتتبّع كل واحد منها إلى إصداره. يُتتبّع ملف Sonarr حلقةً حلقةً، لذلك تظهر حزمة الموسم التي يأخذ منها Sonarr ثلاث حلقات على أنها مستخدمة لتلك الحلقات الثلاث.

**أي الإصدارات قد تكون نسخاً مكررة هو تخمين، والصفحة تقول ذلك.** تُجمَع الإصدارات مع فيلم، أو مع موسم، في الحالات التالية:

- يوجد فيها ملف من \*arr،
- يقول سجل الـ\*arr إنه استورد منها، أو حذف ملفاً جاء منها (ترقية، أو يدوياً، أو مفقوداً من القرص)،
- عرّفها zurg بمعرّف IMDb الخاص بالفيلم أو المسلسل، أو
- يدل اسمها على العنوان والسنة (سنة تختلف بمقدار واحد، أو السنة الثانية لدى Radarr للفيلم، تُحسب أيضاً) أو على المسلسل والموسم.

يذكر كل إصدار أيّ من هذه الأسباب أدخله في المجموعة. لا يكون الموسم مجموعة إلا إذا احتوت الإصدارات الحلقة نفسها: ستون إصداراً لحلقة واحدة من موسم واحد هي ستون حلقة مختلفة. تعرض مجموعة الموسم الحلقات التي تحتويها أكثر من إصدار، وأي إصدار يحتوي كل حلقة، وأيّ إصدار يوجد فيه ملف Sonarr، وكم حلقة يحتوي كل إصدار ولا تحتويها أي إصدارات أخرى في المجموعة. لا يُختار أي إصدار كفائز. الإصدارات التي لا يطابقها أي عنصر في Radarr أو Sonarr تظهر تحت **Name matches only**، مجمّعةً حسب أسمائها ومعرّفات IMDb الخاصة بها.

**كل إصدار يكون إما In use أو No reference found أو Unknown.**

| الحالة | المعنى |
|---|---|
| In use | يوجد الآن في هذا الإصدار ملف يحتفظ به Radarr أو Sonarr. ولا يمكن اختياره. |
| No reference found | قرأت zurg كل Radarr وSonarr المُعدّة كاملةً، ولم يوجد في هذا الإصدار أي من ملفاتها. ولا تظهر هنا العملاء مثل Plex وJellyfin وغيرها التي تقرأ نقطة الربط (mount)، لذلك هذا ليس دليلاً على أن لا أحد يشغّله. |
| Unknown | لا تستطيع zurg التمييز. تكون كل الإصدارات Unknown طالما تعذّرت قراءة أحد الـ\*arr، أو ما زالت المكتبة تُحمَّل، أو كان `__magic__` متوقفاً. ويكون الإصدار Unknown أيضاً عندما لا يمكن تتبّع ملف \*arr لنفس الفيلم أو الحلقة إلى أي إصدار، أو عندما يُظهر سجل الـ\*arr أن ملفاً من هذا الإصدار فُقد من القرص ولم يكن للفيلم أو الحلقة أي ملف منذ ذلك الحين. |

**تُعرض الجودة بمصطلحات ملف الجودة (quality profile).** بالنسبة إلى إصدار يستخدمه الـ\*arr، تكون الجودة هي التقييم الذي يمنحه الـ\*arr للملف نفسه. وبالنسبة إلى إصدار استوردَه من قبل، تكون الجودة التقييم الذي أعطاه حينها. وإلا تُقرأ من اسم الإصدار وتُذكر هذه الحقيقة. وتُوضع كل قيمة في ملف الجودة الخاص بالعنصر، مثلاً "rank 15 of 17 in 4K or best available (cutoff at 17)".

**يُعاد القراءة قبل الحذف.** حدّد الإصدارات واختر **Check again and delete**. تعيد zurg قراءة الملفات الحالية لكل \*arr، ولا تعرض الحذف إلا بعد ذلك. يُستبعد أي إصدار دخل الاستخدام منذ تحميل الصفحة، ولا يُحذف إصدار Unknown إلا إذا أعدت تحديده في تلك النافذة. والحذف نفسه هو الحذف الجماعي في صفحة الإدارة، وهو يزيل كل نسخة من الإصدار من كل حساب يحتويه.

**متى تقرأ.** عند فتح الصفحة للمرة الأولى، تقرأ كل Radarr وSonarr المذكورة تحت `acquisition.sources`، بما في ذلك سجل الاستيراد والحذف. وقد تستغرق قراءة سجل مكتبة كبيرة دقيقة كاملة. بعد ذلك تعرض الصفحة آخر قراءة وموعدها، حتى تختار **Read Radarr and Sonarr again**. ويُقرأ المصدر الذي فيه `enabled: false` أيضاً: فإيقاف الجلب لا يغيّر ما يحتفظ به ذلك \*arr. وتعرض الصفحة أرقام كل مصدر: الملفات المقروءة، والملفات المتتبَّعة إلى إصدار، والملفات الواقعة على مسار خارج `library_path`، والملفات الموجودة داخل `__magic__` لكنها لا تؤدي إلى شيء. وإذا لم يتتبّع أي ملف من ملفات المصدر إلى إصدار، فتحقق من `library_path`.

التقرير نفسه متاح في `/manage/duplicates/report.json`، و`POST /manage/duplicates/check` مع `{"hashes": [...]}` يعيد قراءة الـ\*arr ويجيب بحالة كل إصدار.

## Newznab و Torznab {#newznab-and-torznab}

يحمل مدخل المفهرِس نوعه في `type`. إذا غاب الحقل فالمعنى `newznab`، وهذا ما كانت تعنيه كل المدخلات المكتوبة قبل وجود هذا الحقل. الاستعلام واحد في الحالتين، لكن الجواب يختلف. نتيجة Newznab هي NZB، تُجلب وتُكتب في `nzbs/` من أجل الواجهة الخلفية Usenet. ونتيجة Torznab هي info hash تُسلَّم إلى حساب debrid. ونتيجة Torznab التي لا تحمل خاصية magnet أو `infohash` تُتجاوَز، لأن zurg لا ينزّل ملفات `.torrent` أبداً، فالنتيجة التي لا يمكن الوصول إليها إلا بهذه الطريقة ليست شيئاً يستطيع zurg التصرف فيه.

**لا يُضاف تورنت أبداً إلا إلى حساب يملكه أصلاً.** كل حساب يقبل الإضافات يُعرض عليه الـ hash، باستثناء أن حساب Real-Debrid يُتجاوَز لاسم إصدار يرفضه صراحةً، لأن الذاكرات المؤقتة مستقلة، وحذف حساب لإصدار لا يعني شيئاً عن الحساب التالي. أول حساب يملكه يأخذه. إذا لم يملكه أي حساب فهذه محاولة فاشلة عادية للمرشح، فينتقل المسار إلى الإصدار التالي في الترتيب، وقد يكون تورنتاً آخر أو NZB.

في TorBox وDebrid-Link لا تضيف المحاولة الفاشلة شيئاً، أما في AllDebrid وOffcloud فتُحذف فوراً. وتضيف Real-Debrid وPremiumize التورنت وتراقبه لمدة تصل إلى 20 ثانية. المحتوى المخزَّن جاهز خلال ثانية أو ثانيتين. أي شيء ما زال يُنزَّل بعد ذلك يُحذف، فلا يبقى أي تنزيل يعمل على الحساب. لكن المحاولة الفاشلة ليست مجانية تماماً، فقد تُحتسب على حد الإضافات في الحساب. في TorBox تستهلك واحدة من 60 إضافةً لغير المخزَّن المسموح بها كل ساعة.

الحساب الذي عليه `watchlist: true` يُعرض عليه التورنت أولاً، والباقي يتبع ترتيب قائمة `providers:`. الحساب الذي عليه `add_torrents: false` لا يُعرض عليه التورنت أبداً.

`prefer` يحدد أي نوع يُجرَّب أولاً عندما يستطيع كلاهما تلبية الهدف بالدقة نفسها. الدقة تأتي أولاً: تورنت 2160p يملكه حساب يُؤخذ قبل NZB بدقة 1080p، مهما كانت قيمة `prefer`. القيمة `usenet` هي الافتراضية، لأن تنزيل Usenet يكلّف تنزيلاً واحداً، بينما يستهلك التورنت خانةً من خانات الإضافة في الحساب. القيمة `torrents` تعكس الترتيب، والقيمة `best` تلغي التفريق وتأخذ ما يضعه الترتيب أولاً، أي الإصدار الأكبر ضمن الدقة الواحدة.

الفيلم يجرّب حتى ثلاثة تورنتات في كل محاولة، وكل واحد منها يكلّف إضافة. ويُفحص حتى 24 من NZB الخاصة به بشكل منفرد، كما يصف قسم [اختيار إصدار الفيلم](#choosing-a-movies-release). مع `usenet` تُجرَّب NZB لدقة ما قبل تورنتاتها. مع `torrents` تأتي تورنتاتها أولاً. مع `best` ينتظر كل تورنت دوره في الترتيب. تُجرَّب NZB دقةٍ ما معاً عند موضع أفضلها. ومع مصدر Radarr تُجرَّب NZB كل الدقات معاً عند موضع الأفضل منها، الأرخص أولاً، كما يشرح ذلك القسم. وحزمة الموسم تجرّب ثلاثة إصدارات في كل محاولة من أي نوع كان، وكذلك كل حلقة منفردة.

التحقق الذي تنتظره عملية الجلب يختلف حسب المصدر. إصدار Usenet يُعرض على خوادم الأخبار، وهي الطريقة الوحيدة لمعرفة هل المنشور ما زال موجوداً. أما حساب `torbox_nzb` فلا تتوفر لديه خوادم أخبار للتحقق عليها، فالجلب هناك يُفحص بسؤال: هل جلبه TorBox؟ أما التورنت فلم يُضَف إلا لأن الحساب قال إنه يملك المحتوى أصلاً، فما يبقى للتأكد منه هو أن الإصدار وصل إلى المكتبة وفيه ملفات. هذا ما يتحقق منه الفحص، والإصدار الذي يعرضه الحساب فارغاً يُستبعد كما يُستبعد المنشور الميت.

التثبيت الذي لا يملك أي حساب NZB (`nzb` أو `torbox_nzb`) يستطيع مع ذلك تشغيل الجلب من مفهرِسات Torznab وحدها. لا تُبحث مفهرِسات Newznab لديه، لأن ما من شيء في هذا التثبيت يستطيع تشغيل NZB. ويسجّل السجل ذلك مرةً واحدة لكل منها. والتثبيت الذي لا يملك أي حساب يقبل التورنت لا يبحث في مفهرِسات Torznab، بالطريقة نفسها. وفي الحالتين، الإصدار من نوع لا يملك التثبيت مكاناً يضعه فيه لا يكون مرشحاً أبداً، فلا يستهلك أياً من الإصدارات التي تجرّبها المحاولة، ولا يُسأل عنه مصدر مثل Radarr.

### حدود الفهارس والمفاتيح المرفوضة {#indexer-limits-and-refused-keys}

**يلتزم zurg بحد DMM ولا يصطدم به.** يسمح DMM لمفتاح الراعي بـ 20 بحثاً في الدقيقة عبر جميع خلاصات التورنت، لذلك يرسل zurg إلى DMM بحثاً واحداً كحد أقصى كل ثلاث ثوانٍ. البحث الذي يتجاوز ذلك ينتظر دوره، والانتظار ليس بحثاً فاشلاً. أما البحث الذي سيأتي دوره بعد انتهاء محاولة عنوانه، أو بعد أكثر من دقيقتين، فلا يُنفَّذ، ويكمل العنوان بما وجده المفهرسون الآخرون.

**المفهرس الذي يرد برمز 429 أو 503 يُترك وشأنه للمدة التي يطلبها.** كل بحث وكل تنزيل لملف NZB وكل فحص للقدرات ينتظر مدة `Retry-After` كاملة، بحد أقصى دقيقتان، بما في ذلك الطلبات التي تنتظر دورها. والمفهرس الذي يطلب مدة أطول لا يُسأل حتى تنقضي تلك المدة.

**عدة نسخ من zurg على مفتاح DMM واحد تتشارك بحثه الـ 20.** كل نسخة تلتزم بالحصة الكاملة، لذلك إذا شغّلت نسختين أو ثلاثاً على مفتاح واحد فستظل تصطدم بحد DMM، وكل رفض يوقف بحث DMM لتلك النسخة لمدة دقيقة. وقد ينتظر العنوان وقتاً أطول للحصول على نتيجة بحثه وتنزيله.

**المفتاح المرفوض يُترك وشأنه لمدة ساعة.** المفهرس الذي يرد بالخطأ 100 (مفتاح خاطئ) أو 101 (الحساب موقوف، وهو ما يرد به DMM عند انتهاء الرعاية) لا يُسأل مرة أخرى لمدة ساعة، لا للبحث ولا لتنزيل ملفات NZB. يكتب السجل ذلك مرة واحدة، مثلاً `DMM torrents refused the API key: check dmm_api_key`، وتعرض صفحة الحصول على الملفات **Indexers not asked now** هذا المفهرس. المفتاح الذي تغيّره في `config.yml` يُستخدم فوراً. أما أي خطأ آخر فيؤثر في ذلك البحث وحده.

## اختيار إصدار الفيلم {#choosing-a-movies-release}

تُجرَّب مرشّحات Usenet الخاصة بالفيلم حسب تكلفة التحقق منها، وليس حسب جودتها فقط. منشور يحتوي على فيديو واحد مسمّى يكلّف zurg قراءتين للمقالات، وغالبًا ما يكون كاملًا. أما مجموعة أرشيف من أربعين جزءًا فتكلّف مرحلة تحجيم، وقراءةً عند طرفي كل جزء، ونحو ثلثي مجموعات remux متعددة الأجزاء على المفهرسات قد اختفت. يتنبأ عدد `files` الذي تعرضه المفهرسة بشكل المنشور، لذلك تُرتَّب المرشحات حسبه: 10 ملفات أو أقل، ثم حتى 30، ثم أكثر، ثم غير معروف، وحسب العدد داخل كل فئة. وبين المنشورات ذات التكلفة المتساوية، عندما يحكم مصدر مثل Radarr على الإصدارات وفق ملف تعريف خاص به، يأتي العنوان الذي يذكر WEB-DL أو WEBRip أولًا، ثم Blu-ray، ثم البقية، ويأتي المنشور الأكبر أولًا داخل كل فئة. لا يُستخدم ترتيب المصدر نفسه هنا، لأنه لا يُعرف إلا بسؤال المصدر، وzurg لا يسأله عن إصدار إلا حين يكون على وشك فحصه. ومن دون مصدر، يحسم ترتيبُ الجودة ثم الحجمُ الأمر. وحيث لا يحكم أي مصدر على المرشحات، تتقدّم الدقة التي يطلبها الإعداد `quality` على التكلفة، فإذا ضُبطت قائمة المراقبة على `best` ما زالت تحصل على أفضل دقة متاحة، مع أرخص منشور أولًا ضمنها. تُستبعد النتائج التي تحمل عنوان جزء من منشور مقسّم (`[1/9] "Movie.part1.rar"`) ولا تدخل المرشحات أبدًا، وإذا وُجد منشوران باسم واحد فلا يُحتفظ إلا بالمنشور الذي يحتوي على ملفات أقل، لأن المكتبة لا تستطيع أن تحمل إلا واحدًا منهما.

يُفحَص بعد ذلك ما يصل إلى 24 مرشحًا: يُجلب كل NZB ويُقرأ بمحلّل zurg نفسه. المنشور الذي يحتوي على ملفات محتوى لا تزيد عن اثنين، أحدهما فيديو مسمّى بصيغة `.mkv` أو `.mp4` أو `.m4v` أو `.avi` أو `.mov` أو `.ts` وحجمه 500 MB على الأقل، هو منشور مباشر، ولا تُحسب ملفات PAR2 والملفات المرافقة مثل `.nfo` و`.sfv` و`.srr` و`.nzb` والصور و`.txt` و`.url` و`.exe` ضمن المحتوى. أول منشور مباشر يُحفظ فورًا. أما منشورات الأرشيف فتُؤجَّل حتى تنتهي المنشورات المباشرة المتاحة، ثم تُجرَّب بحسب أقل عدد من الأجزاء أولًا، عبر بوّابة لا تسمح بأكثر من ستة إصدارات أرشيف تنتظر على خوادم الأخبار في وقت واحد. المنشور الذي لا يحتوي إلا على بيانات الإصلاح والملفات المرافقة لا يُحفظ أبدًا. تُحفظ في الذاكرة NZB التي فُحصت، فإذا وُجد أن إصدارًا محفوظًا لا يعمل وأُعيدت تجربة العنوان، يُنتقل إلى المرشح التالي من دون جلب المرشحات السابقة مرة ثانية. تشترك عمليات البحث وتنزيلات NZB في حدّ واحد للطلبات الجارية لكل مفهرسة، وإذا ردّت المفهرسة بالرمز `429` أو `503` يُطلب منها مرة أخرى بعد توقف، مع احترام قيمة `Retry-After`. تعرض لوحة التحكم كل خطوة: البحث، والمرشح الذي يُفحص الآن، وما الذي حُفظ.

تستخدم المسلسلات المسار الأسبق: أفضل ثلاثة إصدارات مرتبة ولم تُوضع جانبًا. وعندما يحكم المصدر على الإصدارات، كما يفعل Sonarr، تُعرض كل واحدة عليه أولًا، والإصدار الذي يرفضه لا يحسب ضمن الثلاثة. يغيّر `best_first` ترتيب المسارَين معًا كما يشرح القسم التالي.

## تفضيل الأفضل في الملف الشخصي أولاً {#taking-the-profiles-best-first}

```yaml
acquisition:
  best_first: true
```

معطّل افتراضيًا. عند تفعيله يجعل أول عملية جلب لمصدر Radarr أو Sonarr تتبع ترتيب التفضيل في ملف الجودة (quality profile) بدلًا من ترتيبها حسب تكلفة فحص الإصدار. قائمة مشاهدة Plex وSeerr ليس لها ملف جودة، فلا يتأثران بهذا الخيار. وصفحة الاستحواذ تُظهر ما إذا كان مفعّلًا.

- **أفضل دقة في الملف الشخصي تأتي أولًا.** تُرتَّب كل إصدار حسب الدقة المذكورة في عنوانه، ويأخذ ترتيبه أفضل جودة يسمح بها الملف الشخصي في تلك الدقة. يقرأ zurg ذلك من الملف الشخصي الذي يحتفظ به أصلًا، ولا يسأل Radarr وSonarr عن أي شيء إضافي. تشترك إصدارات WEB-DL وBlu-ray وremux من الدقة نفسها في المرتبة نفسها. وداخل المرتبة الواحدة يأخذ الفيلم الإصدار الأرخص في الفحص. أما المسلسل فيأخذ الإصدار الذي يرتّبه `quality` أولًا. والعنوان الذي لا يذكر دقة يأتي في الآخر.
- **يُعامَل cutoff كأعلى مرتبة.** طالما يسمح الملف الشخصي بالترقية، تُحسب كل جودة تساوي cutoff أو تفوقه بالمرتبة نفسها. فلن تستبدلها عملية الترقية أبدًا. فالملف الشخصي الذي يرقّي حتى WEB 1080p لا يستفيد شيئًا من خيار "الأفضل أولًا" حتى لو سمح أيضًا بدقة 2160p. أما الملف الذي لا يسمح بالترقيات فيحتفظ بترتيبه كاملًا، وأول ملف يُجلب هو الملف الذي يبقى.
- **يتراجع إلى أسفل الملف الشخصي.** الإصدار الذي لا يمكن جلب ملف NZB الخاص به أو قراءته يُتجاوز. والإصدار الذي ترفضه خوادم الأخبار يُوضع جانبًا كما كان من قبل. ثم يُجرَّب الإصدار التالي في ترتيب الملف الشخصي. ومحاولة واحدة لا تقرأ أكثر من 24 ملف NZB في المجموع، مهما كانت مرتبتها.
- **يأتي قبل تفضيل Usenet أو torrent.** يُؤخذ torrent يملكه حساب بعد ملف NZB يرتّبه الملف الشخصي أدنى. أما `prefer` فيظل يحسم الاختيار بين NZB وtorrent من المرتبة نفسها.
- **يجب أن تكون حزمة الموسم بجودة الحلقات المنفردة.** تُتجاوز الحزمة التي تأتي مرتبتها أدنى من حلقة منفردة من البحث نفسه، وتُؤخذ الحلقات بعد ذلك واحدة واحدة. ويتخذ Sonarr الخيار نفسه. وتُقارَن نتائج ذلك البحث وحده، ولا تُبحث الحلقة من جديد على حدة احتياطًا لوجود إصدار أفضل منها.

لهذا ثمن. أعلى مرتبة في ملف 2160p تتكون غالبًا من مجموعات remux وBlu-ray تضم أربعين جزءًا أو أكثر، لا من ملفات فيديو منفردة. فمثل هذه المجموعة يستغرق فحصها وقتًا أطول، وغالبًا ما تكون غير متوفرة على خوادم الأخبار، وتنتظر دورها أيضًا عند بوابة الأرشيف. لذلك يصل الملف الأول عادةً متأخرًا. والعنوان الذي اختفت كل أفضل إصداراته يُجلب كل واحد منها ويُفحص ثم يُوضع جانبًا قبل أن ينزل zurg إلى أسفل الملف الشخصي. والموسم الذي يُؤخذ كحلقات منفردة يحتاج عدة عمليات جلب بدلًا من عملية واحدة للحزمة. وما يوفّره هو عملية الجلب الثانية. ولا تُرقّى أبدًا الملفات الأولى التي تبلغ cutoff.

## ما الذي يفعله الحصول على الملف بقائمة المصدر الخاصة به {#what-acquiring-does-to-the-sources-own-list}

قائمة المشاهدة في Plex هي قائمة أنشأها شخص ما بعناية، وهي السجل الوحيد الذي يثبت أنه أراد عنواناً معيناً. Plex لا يحتفظ بأي سجل للعنصر بعد حذفه.
هناك إعدادان يحددان ما يُسمح لـ zurg بفعله بها. ينطبق الإعدادان على مصادر `plex_watchlist` فقط؛ فمصادر Seerr وRadarr لا تملك قائمة يكتب فيها zurg، لذا لا أثر لهما عليها.

يزيل `remove_after_grab` (القيمة الافتراضية `true`) العنوان الذي تم الحصول عليه من القائمة بعد التحقق من الإصدار الذي يقف وراءه. هذا هو ما كانت الميزة تفعله دائماً: تُقرأ القائمة كطابور من العناصر المطلوب الحصول عليها، والعنوان الذي حصل عليه zurg يكون قد انتهى أمره.
إذا ضبطته على `false` تبقى القائمة قائمة مشاهدة فعلاً، أي قائمة دائمة تتصفحها، ويلبي zurg ما فيها في الخلفية دون أن يعدّل عليها. وإبقاء العنوان في مكانه لا يكلّف شيئاً عند إعادة الفحص، فالإيصال يغطيه بالفعل، لذلك لا يُسأل أي فهرس عنه مرة أخرى.

أما العنوان الذي لم يحصل zurg له على أي شيء فيبقى في القائمة مهما كان هذا الإعداد. عندما تكون كل الإصدارات التي تحسم أمره موجودة في المكتبة بالفعل، سواء نسختك الخاصة أو نسخة أضافها طلب آخر، فلم يُجلب شيء ولم يُضف شيء، وحذفه لن يكون إلا تعديلاً على قائمتك. ومع ذلك تُفحص تلك الإصدارات ويُحسب العنوان منجزاً، فلا يُبحث عنه مرة أخرى ما دام باقياً في القائمة. وإذا حُذف ثم أُضيف من جديد، فسيبقى مرة أخرى. أما المسلسل الذي جلب zurg أي موسم أو حلقة منه فهو عنوان حصل عليه، ويُزال كما كان من قبل.

يتبنّى `only_new_items` (القيمة الافتراضية `true`) كل ما تحتويه القائمة أصلاً في أول تشغيل للمصدر، ولا يتصرف إلا فيما يُضاف إليها بعد ذلك. الهدف من تفعيل الميزة أن تبدأ متابعة القائمة، لا أن تقضي أمسية كاملة في معالجة كل ما فيها. أما إذا ضبطته على `false` فستعامل القائمة الموجودة كقائمة متأخرات تنتظر المعالجة.

يُطبَّق هذا الإعداد **مرة واحدة فقط، عند أول تشغيل للمصدر**. المصدر الذي لديه طابور بالفعل كان يعمل، وهذا الطابور، لا هذا المفتاح، هو ما يسجّل ما أنجزه وما لم ينجزه. لذلك فتفعيله لاحقاً لن يُسقط أي متأخرات قيد التنفيذ.
العنوان المتبنّى يبقى متبنّى ما دام في القائمة. أما حذفه ثم إضافته من جديد فهو طلب جديد عادي.

## التحقق من عملية الجلب {#verifying-a-grab}

النزل المحفوظ من NZB ليس إصداراً بعد. أن يرد المفهرِس، وأن تُحلَّل الإجابة كملف NZB، وأن يصل الملف إلى `nzbs/`، كلها حقائق تخص المفهرِس لا المنشور. لذلك يُعرض كل NZB مُستحصَل على حسابات الأخبار المُعدّة قبل أن يقرّ المحرك الطلب. تُسأل أول ستة عشر مادة وآخر مادة من كل ملف محتوى عبر `STAT`، ويُجلب كاملاً أول مادة من كل ملف، إضافة إلى عدد إضافي من مواد الإصدارات القليلة الملفات، بحد أقصى أربعٍ وستين مادة. يحدث ذلك لأن خادم الأخبار قد يردّ على `STAT` بالإيجاب لمادة سحب محتواها. وأي مادة يرفض `STAT` عنها تُجلب كاملة أيضاً قبل أن تُعدّ مفقودة، لأن خادم الأخبار قد يرفض `STAT` لمادة ما زال يقدّمها (فعل ذلك NewsDemon في 2026-10-21)، بحد أقصى ستة عشر مادة من هذا النوع لكل إصدار. وهذه هي الخطوة نفسها التي يقوم بها `/api?mode=addfile` لـ Sonarr وRadarr. وهناك ثلاث نتائج، والفرق بينها هو المهم:

- **مواد مفقودة.** لا يُحتسب الاستحصال. يُعاد فتح الإيصال، فيصبح الهدف مطلوباً من جديد، ويُسجَّل الإصدار كميت لمدة 30 يوماً كي تختار المحاولة التالية المرشح التالي بدلاً من أن تستقر على الإصدار الموجود في المكتبة. الإصدار المدرج في هذه القائمة ليس مرشحاً: لا يُجلب، ولا يستهلك واحداً من المرشحين الذين تجربهم المحاولة، فتُتجاوز سلسلة من المنشورات الميتة في أعلى الترتيب بدلاً من أن تحجب كل ما تحتها. وإذا كانت حزمة موسم ميتة، يعود الموسم كله إلى حالة المطلوب، وتُؤخذ الحلقات المنفردة بدلاً منها. ثم يُحذف ملف NZB الذي حفظته عملية الاستحصال من مجلد المراقبة، كي لا يُحمَّل ويُفحص من جديد عند إعادة التشغيل قبل أن تُفتح المكتبة. أما الملف الذي كان موجوداً سلفاً في مجلد المراقبة أو المكتبة، والملف الذي استوردته Sonarr أو Radarr، فيبقى في مكانه.
  - **تعذّر سؤال الحسابات.** خادم مُعطّل، أو حساب يُقيَّد معدل طلباته، أو الحالة المعتادة وهي أن المكتبة لم تُدرج ملف NZB الجديد بعد. لم يثبت شيء، لذلك لا يُتخذ قرار: يُعاد فحص الطلب بعد عشرين ثانية، ثم بعد 40 و80 ثانية، ثم كل دقيقتين، ولا يُحتسب هذا الانتظار ضمن محاولات إعادة الفحص. أما الفحص الذي نفد وقته ببساطة فليس من هذه الحالة: يُعاد تشغيله فوراً بوقته الكامل، حتى ثلاث مرات، قبل أن ينتظر. ومدة هذا الوقت خمس دقائق، أو أطول بالنسبة إلى إصدار كثير الملفات على حساب ذي اتصالات قليلة. يحسب zurg هذه المدة من عدد الملفات وعدد الاتصالات، ومن أبطأ مدة قيس بها فحص حتى الآن، ومن الفحوص الستة التي يشغّلها في وقت واحد، ثم يضاعفها. فإصدار من 90 جزءاً على أربعة اتصالات يحصل على نحو 53 دقيقة، بعد أن كانت الدقائق الخمس تنفد في كل محاولة، فيُترك الإصدار دون فحص حتى يُنحّى. وإذا انتهت عشرون عملية فحص خلال ساعتين دون أن تثبت شيئاً، يُنحّى الإصدار كما يُنحّى الميت، وتجرب المحاولة التالية إصداراً آخر. ولا يُقرّ الطلب أبداً على إصدار لم يتمكن أحد من فحصه.
  - **الإصدار موجود.** يتخلى الإيصال عما كان يحتفظ به، وتمضي عملية الإقرار.

ينتظر الفحص حتى ينتهي zurg من تعلّم الأحجام الدقيقة لملفات الإصدار، أو يتخلى عن تعلّمها، وهي النقطة نفسها التي تتحقق عندها نقطة نهاية SABnzbd. فتعلّم الأحجام يقرأ أول مادة من كل ملف، والفحص يقرأ المواد نفسها، لذلك لم يؤدِّ تشغيل الاثنين معاً إلا إلى إبطائهما. وفي قائمة من 99 فيلماً، أدى فحص كل إصدار لحظة إدراجه إلى أن يصل آخر ملف إلى مجلد Radarr بعد قرابة تسع دقائق. والفحص الذي ما زال ينتظر الأحجام حين ينفد وقته يُعاد تشغيله فوراً، مثل الفحص الذي نفد وقته. والإصدار الذي ما زال يُقاس حجمه بعد 30 دقيقة يُفحص على أي حال. ولا يُفحص في وقت واحد أكثر من ستة إصدارات، وتنتظر البقية دورها.

الفحص للقراءة فقط. لا ينقل محتويات المواد إلى الذاكرة المؤقتة، ولا يسجّل مواداً ميتة، فلا يمكنه إسكات ملف يعمل. وحين ينتهي مرور قياس الأحجام من جلب أول مادة لملف ما، يقرأ الفحص تلك النسخة بدلاً من جلبها مرة ثانية.

التثبيت الذي لا يملك حساب NZB (`nzb` أو `torbox_nzb`) لا يملك ما يفحص به استحصال NZB. ومع ذلك يعمل الاستحصال هناك إذا كان حساب debrid يقبل ملفات torrent. يُفحص كل torrent بالتحقق من أنه يصل إلى المكتبة وفيه ملفات، كما يصف ذلك [Newznab وTorznab](#newznab-and-torznab). ويجب أيضاً أن يحتوي على ما يُشغَّل: فيديو، أو صوت، أو أرشيف يبثه zurg (RAR أو 7z أو zip أو أجزاء مرقمة). أما torrent الذي لا يحتوي إلا على برنامج، أو صورة قرص، أو نص، فهو مزيف، وهذه المزيفات تكثر في الساعات الأولى بعد عرض الحلقات الجديدة. يُنحّى مثل المنشور الميت، وتُجرَّب الحزمة التالية فوراً. وإذا أضافه zurg إلى الحساب من أجل هذا الطلب، يُحذف من الحساب مرة أخرى. أما torrent كان الحساب يحتويه من قبل فيبقى في مكانه. ولا يُقرّ استحصال NZB أبداً دون حساب NZB، لأنه لا يمكن فحصه ولا تشغيله حينئذ. والإصدار الذي بقي في الانتظار منذ قبل إزالة آخر حساب NZB يُنحّى مثل المنشور الميت، وتُجرَّب الإصدار التالي.

## الحفظ والاستعادة بعد الانقطاع {#persistence-and-recovery}

`data/acquisition.json` يخزّن معرّفات المصدر والطلب، والمحاولات، ومواعيد إعادة المحاولة، والأعمال الجارية، والإيصالات الخاصة بكل عملية جلب، بما فيها الحلقات الفردية. ويسجّل أيضًا، لكل مصدر، أن لقطة أولى قد اعتُمدت، فيُحسم `only_new_items` مرة واحدة بدلًا من أن يُعاد النظر فيه عند كل إعادة تشغيل.

مطابقة أهداف الوسائط والإصدارات تُعيد استخدام الإيصالات عبر المصادر. وأسماء ملفات الإصدارات تُزال منها التكرارات أيضًا مقارنةً بالمكتبة وملفات NZB المحفوظة. والإيصال يحمل كذلك عمليات الجلب التي ما زال ينتظر فيها ردًّا من خادم أخبار، والدفتر يحمل الإصدارات التي ثبت أنها ميتة. بذلك، إذا أُعيد تشغيل النظام في منتصف الانتظار، لا تُعتمد عملية جلب لم تُتحقق منها، ولا يُعاد إصدار ميت إلى الترتيب.

الإيصال لا يُوثق به بشكل دائم. قبل أن يُعدّ العنوان محفوظًا، يتحقق zurg من أن الشيء الذي حسمه ما زال موجودًا: الفيديو الموضوع في مجلد Radarr أو Sonarr، أو بالنسبة لعنصر في قائمة الرغبات في DMM أو قائمة مشاهدة Plex أو عنوان في Seerr، الإصدار نفسه داخل المكتبة. وإذا حُذف منذ ذلك الحين، يُعاد البحث عنه، حتى لو ظل العنوان مدرجًا والمهمة قد انتهت. أما الإصدار المحذوف من صفحة الإدارة فلا يُعاد جلبه.

كل إصدار محفوظ يُكتب على القرص فورًا. وعدادات المحاولات وأوقات إعادة المحاولة تُكتب خلال دقيقة، لذلك قد يضيع عند الانهيار ما يصل إلى دقيقة منها، لكنه لا يُضيّع أي عملية جلب أبدًا.

عمليات الكتابة تُفرغ الملف المؤقت إلى القرص، ثم تستبدل الدفتر، ثم تفرغ المجلد الأب حيثما يُدعم ذلك. وملفات NZB التي كُتبت قبل الانهيار تُعاد استخدامها حتى لو لم تكتمل آخر كتابة للدفتر. وبعد تسجيل الاستحواذ، لا تعيد محاولات إزالة Plex جلب العنوان مرة أخرى.

الإخفاقات تُعاد بعد 5 و10 و15 دقيقة، ثم ساعة، ثم ست ساعات. ومن هناك ينتظر العنوان نصف المدة التي ظل يفشل خلالها، فتتزايد الفترات: نحو نصف يوم بعد يوم من الفشل، ويومان بعد أربعة أيام، وأسبوع تقريبًا كحد أقصى، بزيادة أو نقصان ربع، حتى لا تُعاد محاولة العناوين التي فشلت معًا في الوقت نفسه.

والمحاولة التي تنتهي بعد خمس دقائق دون أن تجد شيئًا تُحسب إخفاقًا أيضًا. أما المحاولة التي لم تجد شيئًا، بينما تعذّر سؤال أحد الفهارس لأنه طلب أن يُترك وشأنه حتى وقت لا يبعد أكثر من يوم (أي `Retry-After`)، فلا تُحسب إخفاقًا. يُعاد المحاولة للعنوان بعد ذلك الوقت، ولمدة لا تزيد على المدة نفسها بعده، حتى لا يطلب قائمة كاملة من العناوين من الفهرس دفعة واحدة. فإذا استراح الفهرس عشر دقائق، تكون المحاولة التالية خلال عشرين دقيقة. ويحدث ذلك ثلاث مرات متتالية كحد أقصى، وبعدها تُحسب المحاولة كالمعتاد. والفهرس الذي لا يحدد وقتًا، مثل فهرس يرد بـ 410 Gone أو يرفض مفتاحه، لا يُنتظر.

والعنوان الذي فشل لمدة أسبوعين، وبما لا يقل عن ثماني محاولات، يُوضع في حالة **parked**: يتوقف zurg عن السؤال عنه في الفهارس. ويبقى معلَّمًا كـ parked في صفحة الاستحواذ، مع مدة الفشل وسببه، ويكتب السجل ذلك مرة واحدة. وزر **Resume** في تلك الصفحة، سواء لعنوان واحد أو لكل العناوين المتوقفة من مصدر، يبدأ العنوان من جديد من أول فترة إعادة قصيرة. والمصدر الذي يتوقف عن عرض عنوان ثم يعرضه من جديد يكون قد طلبه من جديد، فهذا يستأنفه أيضًا.

وعملية جلب تؤكدها خوادم الأخبار تبدأ أسبوعي العنوان من جديد، فالموسم الذي ما زال يجد حلقات لا يُوضع أبدًا في حالة parked. ولا تُوضع الترقية كذلك، من أي مصدر: فقد يخرج إصدارها الأفضل بعد أشهر، ويبقى العنوان مدرجًا، لذلك تحتفظ بمحاولاتها بفاصل لا يزيد على أسبوع. ولا يُوضع أي شيء في قائمة الرغبات في DMM للسبب نفسه: فيلم لم يُعرض بعد، أو فيلم قديم لم ينشره أحد، يبقى مطلوبًا حتى يُجلب أو تزيله أنت. والعدادات والمواعيد تبقى بعد إعادة التشغيل، بما في ذلك الإيقاف الطويل.

قائمة تفشل إلى الأبد مكلفة بطريقة لا تظهرها قائمة العناوين. ففي إحدى التثبيتات، آلاف العناوين في Radarr وSonarr لم يُعثر لها على شيء، وأُعيد البحث عنها كل ست ساعات بلا نهاية، فانتقل الفهرس من بضع مئات من الاستعلامات يوميًا إلى عشرات الآلاف، فعلّق الفهرس الحساب. وأغلبها أفلام لا إصدار Usenet لها، وترقيات رفضت كل الإصدارات التي يسمح بها الملف الشخصي. وطلبات Seerr المفتوحة تبقى مراقبة.

وعناصر Plex لا تغادر قائمة المشاهدة إلا بعد اكتساب كل المواسم المخططة **والتحقق** منها (ملف NZB مقابل خوادم الأخبار، أو في حساب `torbox_nzb` بالتحقق من أن TorBox جلبه؛ وتورنت بالوصول إلى المكتبة مع وجود شيء قابل للتشغيل)، وفقط حين يسمح `remove_after_grab` بذلك، وفقط حين يكون zurg قد جلب شيئًا لها. ويبقى الاحتياط الخاص بالحلقات المفردة محصورًا في الحلقات التي وُجدت في نتائج الفهارس.

المصدر غير المتاح يوقف أعماله هو فقط. وفشل كتابة الحالة يوقف الاستحواذ الإضافي حتى تنجح عملية الحفظ. والدفتر غير المقروء أو غير المدعوم يوقف الاستحواذ ويُحفظ الملف كما هو: أصلحه أو استعده، ثم أعد تشغيل zurg. أما خدمات zurg الأخرى فتستمر في العمل.

الملف السابق `data/plex-watchlist.json` يُستورد مرة واحدة مع سجله ومحاولاته، ويبقى منه الانتظار لإزالة Plex فقط. والملف الأصلي يُحفظ. والدفتران يُدرجان في النسخ الاحتياطية العادية دون `--include-caches`. واحتفظ بـ `data/` و`nzbs/` عند استبدال الحاويات.

## إضافة محول آخر {#adding-another-adapter}

نفّذ `acquisition.Source` في حزمته الخاصة:

1. `ID()` يُعرّف المثيل بشكل ثابت عبر عمليات إعادة التشغيل.
2. `List(ctx)` يعيد لقطة كاملة من مراجع `Item`. أوقف اللقطة بالكامل عند حدوث أخطاء في الترقيم الصفحي (pagination). احفظ البيانات الوصفية فقط، ولا تحفظ أبداً بيانات الاعتماد أو كائنات المستخدم الكاملة من الـ API.
3. `Resolve(ctx, item)` يتحقق من صلاحية العنصر من جديد، ويعيد أهدافاً موحّدة من نوع فيلم أو موسم أو حلقة. `Gone` يلغي الأعمال غير المرغوبة. `Follow` يُبقي الطلب المفتوح تحت المراقبة بعد الحصول على الأهداف الحالية.
4. `Complete(ctx, item)` يُقرّ بإكمال عملية الحصول لمرة واحدة. يجب أن يتحمّل الاستدعاءات المتكررة بعد أي انهيار. يمكن لقائمة للقراءة فقط أن تستخدم no-op. لا يستدعي المحرك هذه الدالة إلا بعد أن يجيب كل عمليات الجلب المرتبطة بالعنصر، فلا يحتاج المحوّل أبداً إلى فحص الإصدار بنفسه، ويجب ألا يعتبر مجرد استدعائه دليلاً على أي شيء يتجاوز ذلك.

مصدر له ملف جودة خاص به يمكنه أيضاً تنفيذ `acquisition.Assessor`، فيقيّم كل إصدار مرشح وفق قواعده الخاصة. وهذا ما يفعله محوّلا Radarr وSonarr، عبر المحللات الخاصة بهما.

سجّل نوع الإعدادات والمصنع (factory) في خدمة الحصول. لا تحتاج قائمة الانتظار والتخزين الدائم وإعادة المحاولات والمنفّذ إلى أي فرع خاص بمصدر معيّن. يمكن أن تتناسب Trakt وMDBList وSimkl مع هذا العقد، لكنها غير منفّذة بعد.
