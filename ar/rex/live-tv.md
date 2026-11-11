# البث المباشر مع rex {#live-tv-with-rex}

rex يعرض قنوات الإضافات في Plex Web وفي **Live TV** على Plex for Android، مع دليل و What's On. اختر قناة فتعمل فورًا.
[rex-live-sports](https://github.com/debridmediamanager/rex-live-sports) جاهز للاستخدام مع خادم البث الرياضي المباشر.
أما لدليل IPTV بصيغة M3U وXMLTV فراجع [Tutorial: an IPTV addon](addon-iptv.md).

ما ستحصل عليه:

- **دليل.** كل القنوات برقمها، مع ما يُعرض الآن وما يليه.
- **What's On.** ما يُعرض الآن، وما يبدأ لاحقًا، والأفلام القادمة.
- **بحث.** اسم البرنامج يجده في Live TV وفي مكتباتك أيضًا.
- **المشاهدة.** اختر قناة فتعمل مباشرة. القناة لا تحتفظ بنقطة استئناف ولا تُعلَّم كمشاهَدة أبدًا.
- **قائمة قنوات، مثل مزوّد التلفزيون.** يبدأ rex-live-sports بقائمته الأمريكية: نحو 30 شبكة رياضية بأرقام لا تتغير أبدًا (ESPN رقم 2، وCBS رقم 7)، وجدول مباريات ESPN على هذه القنوات، وقنوات فتحات (`NFL 1` و`NBA 1` وغيرها) تعرض مباريات اليوم قبل بدئها وتبث كل مباراة مباشرة. وتتوفر أيضًا قائمتان بريطانية وألمانية.
- **المكتبة أيضًا.** تبقى القنوات في مكتبتها الخاصة **Live Sports**، مرتبة في مجموعة لكل فئة.

## قبل أن تبدأ {#before-you-start}

| تحتاج إلى | السبب |
|---|---|
| نسخة ليلية من rex بتاريخ 2026.11.02 أو أحدث | البث المباشر للتلفزيون وصل في هذا الإصدار |
| rex مُعدّ كما في [rex مع تطبيقك الخاص](any-source.md)، مع [تحويل الفيديو](any-source.md#converting-video-optional) | rex يحوّل كل قناة أثناء مشاهدتها (نسخة، وهي رخيصة) |
| خادم رياضة مباشرة، على جهاز rex أو على شبكتك المنزلية | rex-live-sports يأخذ القنوات منه |
| Docker | يُستخدم لتشغيل live-sports في الخطوة 2. يحتوي [README](https://github.com/yowmamasita/live-sports-public) الخاص به على الطرق الأخرى |
| Python 3.9 أو أحدث، و`git`، و`ffmpeg` و`ffprobe` على جهاز rex | rex-live-sports يتحقق من بث كل قناة باستخدام ffprobe ويرسم ملصقها باستخدام ffmpeg |

## الخطوة 1. تثبيت rex وإضافته إلى حساب Plex {#step-1-install-rex-and-add-it-to-a-plex-account}

تابع [rex مع تطبيقك الخاص](any-source.md):

1. [الخطوة 1. ثبّت rex](any-source.md#step-1-install-rex)، بما في ذلك معرفة عنوان IP لـ rex على شبكتك المحلية. تكتب هذه الصفحة العنوان `192.168.1.20`، فضع عنوانك أنت مكانه.
2. [الخطوة 3. أضفه إلى حساب Plex](any-source.md#step-3-add-it-to-a-plex-account): سجّل rex في الحساب الجديد وشاركه مع حسابك.
3. [تحويل الفيديو](any-source.md#converting-video-optional).

تخطَّ الخطوتين 2 و4 هنا: rex-live-sports هو تطبيقك.

## الخطوة 2. تشغيل خادم الرياضة المباشرة {#step-2-start-a-live-sports-server}

**ما الذي يفعله.** يشغّل live-sports، فيبحث عن قنوات الرياضة ويتحقق كل بضع دقائق من القنوات التي تعمل.

```bash
docker run -d --name live-sports --restart unless-stopped -p 8765:8765 ghcr.io/yowmamasita/live-sports:latest
```

**ما الذي يجب أن تراه.** يعرض `http://192.168.1.20:8765` لوحة تحكم live-sports في المتصفح. يستغرق أول فحص لكل قناة بضع دقائق.

## الخطوة 3. تثبيت rex-live-sports {#step-3-install-rex-live-sports}

**ما يفعله.** يُنزّل rex-live-sports إلى `~/rex-live-sports` على جهاز rex ويشغّله.

+++ Linux
```bash
sudo apt install -y git python3 ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

في `config.json`، اضبط `live_sports_url` على `http://192.168.1.20:8765` و`rex_url` على `http://192.168.1.20:32400`. ثم:

```bash
mkdir -p ~/.config/systemd/user
cp ~/rex-live-sports/rex-live-sports.service ~/.config/systemd/user/
systemctl --user daemon-reload && systemctl --user enable --now rex-live-sports
journalctl --user -u rex-live-sports -f
```
+++ macOS
```bash
brew install ffmpeg
cd ~ && git clone https://github.com/debridmediamanager/rex-live-sports
cd ~/rex-live-sports && cp config.example.json config.json
```

في `config.json`، اضبط `live_sports_url` على `http://192.168.1.20:8765` و`rex_url` على `http://192.168.1.20:32400`. ثم:

```bash
python3 rex_live_sports.py
```

يبقى يعمل ما دامت نافذة Terminal تلك مفتوحة.
+++

**ما يجب أن تراه.** سطر يشبه:

```
INFO relay on http://127.0.0.1:9983/, live-sports at http://192.168.1.20:8765, rex at http://192.168.1.20:32400
```

إلى أن ينتهي أول فحص لـ live-sports، يسجّل السطر `live-sports lists no channel that plays yet`. بعدها تفحص أول مزامنة بث كل قناة في قائمة live-sports، ويستغرق ذلك نحو دقيقة لـ 30 قناة، ثم يسجّل:

```
INFO pushed 38 of 30 channels, 38 with their Live TV channel: ...
```

هذه هي القنوات الثلاثون في قائمة live-sports، إضافةً إلى الفترات التي فيها مباراة في ذلك اليوم. تُزامن مرة أخرى كل خمس دقائق، وتفحص فقط القنوات التي لم تُرصد في ذلك اليوم.

## الخطوة 4. مشاركة المكتبة وفتح البث المباشر {#step-4-share-the-library-and-open-live-tv}

المكتبة **Live Sports** جديدة، لذا لا توجد في مشاركة أي حساب بعد. سجّل الدخول بالحساب الجديد، ثم أضفها إلى مشاركة حسابك ومشاركة الجميع الآخرين من **Manage Library Access** ([مشاركة rex](sharing.md)). تتيح المشاركة لحسابها مشاهدة Live TV ما لم تكن قد أوقفت ذلك له.

ثم افتح تطبيق Plex باسمك:

- **Plex Web**: توجد **Live TV & DVR** في الشريط الجانبي، مع مكتبات rex.
- **Plex for Android**: تبويب **Live TV** في الأسفل، مع اختيار rex في الأعلى؛ و**Live TV & DVR** مدرجة هي الأخرى مع مكتبات rex.

**ما الذي يجب أن تراه.** **Guide** و**What's On** في الأعلى. يعرض الدليل كل قناة برقمها مع ما يُعرض عليها. اختر برنامجًا واضغط **Watch Now**.

## القنوات والأرقام والأدلة {#channels-numbers-and-guides}

`config.json` تسرد التشكيلة: `lineups/us.json` كما هو منسوخ، و`lineups/uk.json` أو `lineups/de.json` لشبكات المملكة المتحدة أو ألمانيا. تكون قناة التشكيلة موجودة عند رقمها، بينما يحتوي live-sports على نسخة منها تعمل.

تأخذ شبكة أمريكية مبارياتها من جدول ESPN (`Chicago Bears at Seattle Seahawks`، من بداية المباراة لمدة الطول المعتاد للرياضة؛ NFL، وكرة القدم الجامعية الأمريكية، وNBA، وNHL، وMLB، والدوريات الأوروبية الكبرى، وMLS وF1). لا يذكر ESPN إلا الشبكات الأمريكية، لذا تحصل شبكات المملكة المتحدة وألمانيا بدلاً من ذلك على الدليل الذي يوفره [epgshare01](https://epgshare01.online/) للقناة التي تحمل اسمها، كما تفعل كل قناة حول مبارياتها. تعرض القناة التي لا يدرجها أي دليل اسمها الخاص في كتل مدة كل منها ست ساعات.

تأتي الفتحات بعد الشبكات: من `NFL 1` إلى `NFL 10` على `700.1` إلى `700.10`، و`NBA 1` إلى `NBA 6` ابتداءً من `701.1`، ثم NHL وMLB وكرة القدم وF1. تذهب كل مباراة في اليوم إلى أول فتحة فارغة من رياضتها، فيعرضها الدليل قبل بدايتها، ومن 15 دقيقة قبل الانطلاق حتى تنتهي تعرض الفتحة بث live-sports الذي يحتويها، ويُعثر عليه من خلال اسمي الفريقين. بين المباريات لا تعرض الفتحة شيئاً. تظهر الفتحة لأول مرة عندما تعرض مباراة.

من دون تشكيلة (`"lineup": ""` في `config.json`)، تكون كل قنوات مجموعتي `Live:` و`Sports` في live-sports موجودة بدلاً من ذلك، مرقمة حسب المجموعة: `100.1`، `100.2` للمجموعة الأولى، و`101.1` للتالية، بعيداً عن الأرقام المنخفضة التي يستخدمها جهاز الالتقاط أو مصدر آخر. تحتفظ القناة برقمها ما دام live-sports يدرجها مرة واحدة على الأقل في الأسبوع. تحصل قنوات Pluto TV على جدول Pluto TV الخاص بها، وتُستبعد ما لم تطلبها: `"groups": ["Live:", "Sports", "Pluto:"]`. كل الإعدادات موجودة في [README](https://github.com/debridmediamanager/rex-live-sports#settings) الخاص بـ rex-live-sports.

## التحديث {#updating}

```bash
cd ~/rex-live-sports && git pull && systemctl --user restart rex-live-sports
```

على macOS، أوقفه بـ Ctrl+C، ثم شغّل `git pull` داخل `~/rex-live-sports` وأعد تشغيله.

## ما الذي لا يستطيع فعله {#what-it-cannot-do}

- **لا يوجد تسجيل.** Plex Web وPlex لنظام Android لا يعرضان زر Record.
- **يُطابَق الدليل بالاسم.** قد تحصل قناة على دليل قناة أخرى من العلامة نفسها، وكثير من قنوات الأحداث لا يوجد لها دليل أصلاً.
- **يبحث الفتحة عن بث المباراة بحسب اسمَي الفريقين فيها.** البث الذي يحمل اسمًا مختلفًا (`nfl ravens`) لا يُعثر عليه، والمباراة التي لا يوجد لها أي بث تظهر في الدليل لكنها لا تعمل.
- **يصنّف Plex البرنامج الذي لا يحمل رقم حلقة كفيلم**، كما يفعل مع أي دليل تلفزيوني، لذلك تظهر المطابقات أيضًا ضمن أفلام What's On.
- **جرى اختبار البث المباشر في Plex Web وPlex لنظام Android فقط.** لم تُجرَّب تطبيقات Plex الأخرى بعد.
- **أي شخص يصل إلى عنوان rex-live-sports يستطيع التشغيل من خلاله.** أبقِ `listen` على `127.0.0.1`.

لإضافة قنوات خاصة بك، مع دليل لديك بالفعل، راجع [Building rex addons](addons.md#live-tv).
