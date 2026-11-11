# Kometa مع rex {#kometa-with-rex}

[Kometa](https://kometa.wiki) يبني مجموعات (collections)، ويضع شارات على الملصقات (4K، HDR، التقييمات) ويملأ التقييمات والأنواع (genres) على خادم Plex. يرد rex على Kometa بالطريقة نفسها التي يرد بها خادم Plex، لذلك يعمل الإعداد نفسه على مكتبات rex الخاصة بك.

تم اختبار كل ما يلي بتاريخ 2026-10-23 باستخدام Kometa 2.5.3 (صورة Docker `kometateam/kometa`)، ومع rex مُطالَب به (claimed) يحتوي على أفلام ومسلسل.

## قبل أن تبدأ {#before-you-start}

| ما تحتاجه | السبب |
|---|---|
| إعداد rex وإضافته إلى حساب Plex، كما في [إضافته إلى حساب Plex](any-source.md#step-3-add-it-to-a-plex-account) | Kometa يعدّل المكتبة، ولا يُسمح بذلك إلا للحساب المسجَّل عليه rex. rex غير المرتبط بحساب لا يخدم أحدًا |
| إصدار rex الليلي **2026.10.24 أو أحدث** | حدّثه كما في [قسم التحديث في rex](any-source.md#updating) |
| Docker على أي جهاز يستطيع الوصول إلى rex | Kometa يعمل كحاوية (container). توثيق Kometa نفسه يشرح [طرق التثبيت الأخرى](https://kometa.wiki/en/latest/kometa/install/overview/) |
| مفتاح API مجاني من TMDb | Kometa يحتاجه لنفسه، حتى وإن كان rex لا يحتاجه. أنشئه من **Settings → API** على themoviedb.org، كما تصف [صفحة البدء في TMDb](https://developer.themoviedb.org/docs/getting-started) |

## 1. احصل على token الخاص بـ rex {#1-get-rexs-token}

يسجّل Kometa الدخول إلى rex باستخدام توكن Plex. استخدم التوكن الذي أعطاه لك rex عند تسجيله. على الجهاز الذي يعمل عليه rex:

+++ Linux و macOS
```bash
grep -o '"token": "[^"]*"' ~/rex/claim_state.json
```
+++ Windows
```powershell
(Select-String '"token": "[^"]*"' $HOME\rex\claim_state.json).Matches.Value
```
+++

إذا كان rex يعمل داخل [Docker](any-source.md#run-rex-in-docker)، فالملف مخصص للجذر فقط، لذا استخدم: `sudo grep -o '"token": "[^"]*"' ~/rex/config/claim_state.json`.

**ما يجب أن تراه.** سطر واحد، `"token": "..."`. انسخ ما بين الزوج الثاني من علامات الاقتباس. تعامل معه كأنه كلمة مرور، فهو يفتح الخادم بالكامل. إذا سجّلت rex من جديد يوماً ما، سيتغير التوكن، وسيحتاج Kometa إلى التوكن الجديد.

**ليس توكن حسابك الخاص.** في [شاركه مع حسابك الخاص](any-source.md#share-it-with-your-own-account) حصل حسابك على rex كمشاركة. المشاركة تسمح بالمشاهدة فقط ولا تسمح بالتعديل، لذلك إذا استخدمت توكنها، سيتوقف Kometa مع الخطأ `Plex Token is read only`. أما إذا كانت المشاركة تسمح بالتنزيل، فسيفشل عند أول تغيير.

## 2. اكتب إعدادات Kometa {#2-write-kometas-config}

أنشئ مجلدًا لـ Kometa، مثلًا `~/kometa/config` (`$HOME\kometa\config` على ويندوز)، وضع هذا في ملف `config.yml` داخله:

```yaml
libraries:
  Movies:
    collection_files:
      - default: genre
    overlay_files:
      - default: resolution
      - default: ratings
        template_variables:
          rating1: critic
          rating1_image: tmdb
    operations:
      mass_critic_rating_update: tmdb
  TV Shows:
    overlay_files:
      - default: resolution
plex:
  url: http://192.168.1.20:32400
  token: the token from step 1
tmdb:
  apikey: your TMDb API key
```

- `url` هو عنوان IP للشبكة المحلية الخاص بـ rex مع المنفذ، وهو العنوان من [تثبيت rex](any-source.md#step-1-install-rex). لا تستخدم `127.0.0.1` أو `localhost`، لأنهما داخل حاوية Kometa يشيران إلى الحاوية نفسها.
- الأسماء تحت `libraries:` لازم تطابق مكتبات rex تمامًا: **Movies** و **TV Shows**، بالإضافة لأي مكتبات أضفتها أو غيّرت اسمها. احذف المكتبة التي لا تريد أن يلمسها Kometa.

هذه بداية بسيطة. توثيق Kometa يسرد [كل مجموعة وتراكب افتراضي](https://kometa.wiki/en/latest/defaults/guide/)، وملفات المجموعات الخاصة بك تعمل أيضًا.

## 3. شغّله مرة واحدة {#3-run-it-once}

+++ Linux و macOS
```bash
docker run --rm -v ~/kometa/config:/config kometateam/kometa:latest --run
```
+++ Windows
```powershell
docker run --rm -v "$HOME\kometa\config:/config" kometateam/kometa:latest --run
```
+++

`--run` يجعل Kometa ينفذ مرورًا واحدًا الآن ثم يُغلق. بدونه يبقى Kometa قيد التشغيل وينتظر جدوله اليومي.

**ما الذي يجب أن تراه.** في مخرجات Kometa، لكل مكتبة:

```
Movies Library Connection Successful
...
Overlays Applied: Overlay File (0) 1080P, Overlay File (1) Rating1Fresh
```

في تطبيق Plex، تحتوي مكتبة الأفلام على تبويب **Collections** فيه مجموعات الأنواع، وتحمل الملصقات شاراتها. حسابك وأي شخص آخر شاركته rex معه يرون المجموعات والشارات نفسها. أول تشغيل على مكتبة كبيرة يستغرق وقتًا: يقرأ Kometa كل عنوان ويعيد رسم كل ملصق يضع عليه شارة.

## إذا لم يعمل {#if-it-does-not-work}

| ما تقوله Kometa | ماذا يعني ذلك |
|---|---|
| `Plex Token is read only. Please get a new token` | لم تتم إضافة rex إلى حساب Plex بعد، أو أن الرمز المستخدم هو رمز حسابك الشخصي وليس الرمز من الخطوة 1 |
| تتصل Kometa، ثم تفشل كل التغييرات | الرمز هو رمز حسابك الشخصي. استخدم الرمز من الخطوة 1 |
| `url_poster failed to update poster` | جهاز rex لا يستطيع الوصول إلى الموقع الذي توجد عليه الصورة |
| `Plex URL is probably invalid` أو انتهاء المهلة | `url` لا يصل إلى rex من المكان الذي تعمل فيه Kometa. افتح `http://192.168.1.20:32400/identity` من ذلك الجهاز: يجب أن يعرض `machineIdentifier` الخاص بـ rex |
| `Plex Error: Plex Library '...' not found. Options: [...]` | اسم تحت `libraries:` غير مطابق. انسخ اسمًا من القائمة التي تطبعها |

لا تزال عالقًا؟ اسأل في منتدى **rex-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يوضح [الحصول على المساعدة](../guides/remote-help.md) ما يجب تضمينه.

## ما الذي يستطيع Kometa رؤيته وما الذي لا يستطيعه {#what-kometa-can-and-cannot-see}

يطابق Kometa العناوين بمعرّفات TMDb وTVDb وIMDb التي يعرضها rex لها. أما العنوان الذي لم يتعرّف عليه مصدره، فيظل يعرض اسم ملفه بدون ملصق، فليس له معرّفات، ولذلك يتجاهله Kometa في أي شيء يُبنى من تلك المعرّفات. أصلِح ذلك أولاً عبر الضغط على Fix Match في تطبيق Plex.

جربنا على rex: المجموعات عبر البحث بالعنوان، وعبر معرّف TMDb، والمجموعات الذكية؛ والمجموعات الافتراضية حسب النوع مع ملصقاتها؛ والتراكبات الخاصة بالدقة والتقييمات؛ وتحديثات تقييم النقاد والنوع من TMDb. لم نجرّب بعد: قوائم التشغيل، ومكتبات الموسيقى، والعمليات الأخرى في Kometa. إذا فشل شيء منها، فسجل Kometa نفسه يذكر الطلب الذي فشل، ويستحق أن تبلّغ عنه على Discord.
