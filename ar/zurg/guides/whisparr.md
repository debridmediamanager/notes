# Whisparr

Whisparr هو Radarr للأفلام والمشاهد للكبار. يستخدم zurg كعميل qBittorrent له. عمليات الجلب تذهب إلى حسابك في خدمة debrid. الاستيراد لا يفعل أكثر من إعادة تسمية مسار داخل `__magic__`؛ لا يتم تنزيل أي شيء ولا نسخه.

كل ما يلي اختُبر في 2026-10-23 مع Whisparr `3.6.5.1886` (صورة `ghcr.io/hotio/whisparr:v3`)، وProwlarr، وzurg مبني من فرع `main` في ذلك اليوم، وحساب Real-Debrid. تم جلب فيلم بحجم 17 GB واستيراده ثم تشغيله من المركب.

## قبل أن تبدأ {#before-you-start}

اضبط zurg لـ Radarr أولاً، مع [Sonarr و Radarr للتورنت](sonarr-radarr-torrents.md): حساب يقبل التورنت، و`__magic__` مفعّل، ونقطة نهاية qBittorrent مفعّلة. يعيد Whisparr استخدام كل ذلك.

## 1. فئة Whisparr في zurg {#1-whisparrs-category-in-zurg}

يرسل Whisparr طلبات التنزيل تحت الفئة `whisparr`. زر **Test** في الخطوة 3 ينشئ هذه الفئة في zurg، لذا لا حاجة لإضافة أي شيء. مع ذلك، إذا أردت إدراجها في `config.yml`، أضفها بجانب الفئات الموجودة هناك:

```yaml
qbittorrent:
  enabled: true
  categories: [tv-sonarr, radarr, whisparr]
```

## 2. تشغيل Whisparr {#2-run-whisparr}

على مضيف Linux، أعطِ Whisparr نفس الـ volume الذي يستخدمه Radarr، أي المجلد **الأعلى** من مسار تركيب zurg، مع `rslave` ([لماذا](sonarr-radarr-torrents.md#8-if-your-arr-is-in-docker)):

```yaml
services:
  whisparr:
    image: ghcr.io/hotio/whisparr:v3
    container_name: whisparr
    environment:
      - PUID=1000
      - PGID=1000
      - UMASK=002
      - TZ=Etc/UTC
    volumes:
      - ./whisparr:/config
      - /mnt:/mnt:rslave
    ports:
      - 6969:6969
    restart: unless-stopped
```

`PUID` و`PGID` هما مستخدم Linux الذي يعمل به Whisparr. صورة Docker الخاصة بـ zurg تسمح لأي مستخدم بقراءة مساره المركّب. أما zurg المثبّت كملف تنفيذي عادي فيفعل ذلك فقط إذا كان يعمل كـ root أو كان `user_allow_other` مفعّلاً ([إعداد Linux](../setup/linux.md#1-install-fuse-3))؛ وإلا فاضبط `PUID` و`PGID` على المستخدم الذي يعمل به zurg (الأمر `id -u` و`id -g` يطبعانه)، وإلا سيرى Whisparr المسار فارغاً.

على macOS وWindows لا ينطبق ملف compose هذا، للسبب الذي يذكره [الخطوة 8 من دليل Usenet](sonarr-radarr.md#8-if-your-arr-is-in-docker). ثبّت Whisparr هناك كتطبيق عادي، مع الانتباه للنقاط المذكورة تحت [قبل أن تبدأ](sonarr-radarr.md#before-you-start) في ذلك الدليل: استخدم نفس المستخدم الذي يعمل به zurg على macOS، واستخدم تطبيق الشريط (tray) لا خدمة Windows على Windows. لم أختبر سوى صورة Docker أعلاه.

افتح `http://<your server>:6969`.

## 3. إضافة zurg كعميل تنزيل {#3-add-zurg-as-the-download-client}

**Settings → Download Clients → + → qBittorrent**، واملأ الحقول تماماً كما فعلت مع Radarr ([الحقول](sonarr-radarr-torrents.md#what-to-put-in-each-field))، باستثناء **Category** فيجب أن يكون `whisparr`. اترك **Remove Completed** مفعّلاً. اضغط **Test**، ثم **Save**.

## 4. إضافة مجلد الجذر {#4-add-the-root-folder}

أنشئ المجلد على الـ mount، ثم أضفه من **Settings → Media Management → Root Folders**:

+++ Linux

```bash
mkdir -p /mnt/zurg/__magic__/whisparr
```

+++ macOS

```bash
mkdir -p /Volumes/Zurg/__magic__/whisparr
```

+++ Windows

```powershell
New-Item -ItemType Directory -Force Z:\__magic__\whisparr
```

+++

يقع بجانب `__magic__/movies`، وليس داخله. يضع Whisparr كل فيلم تحت اسم الاستوديو الخاص به، بهذا الشكل: `__magic__/whisparr/movies/<Studio>/<Title (Year)>/`.

## 5. المفهرسات {#5-indexers}

DMM لا يملك فئة للمحتوى البالغ في الفهرسة، لذلك يحتاج Whisparr إلى فهارس أخرى. في Prowlarr، نجحت الفهارس العامة **Knaben** و**The Pirate Bay** معًا. أما **XXXClub** فمحمي بخدمة Cloudflare، ولن يتمكن Prowlarr من إضافته دون أداة حلّ Cloudflare.

بعد ذلك، وصّل Prowlarr بـ Whisparr من خلال **Settings → Apps → + → Whisparr** في Prowlarr، وأدخل عنوان Whisparr ومفتاح API الخاص به (من **Settings → General** في Whisparr). يضيف Prowlarr فهارسه إلى Whisparr بنفسه.

لا يقبل zurg إلا الإصدارات التي يملكها حسابك مسبقًا (`cached_only`، وهو مفعّل افتراضيًا). وعندما يرفض إصدارًا، ينتقل Whisparr تلقائيًا إلى النتيجة التالية.

## 6. جلب عنصر واحد {#6-grab-one}

أضف فيلمًا في Whisparr مع تحديد **Start search for missing movie**. عندما ينجح الأمر، يعرض سجل Whisparr الحالة **Grabbed** ثم **Imported** خلال ثوانٍ، ويكون الفيلم موجودًا في نقطة التثبيت:

```bash
$ ls "/mnt/zurg/__magic__/whisparr/movies/<Studio>/<Title (Year)>/"
<Title> 1080p.mkv
```

على macOS يبدأ المسار بـ`/Volumes/Zurg`، أما على Windows فابحث في `Z:\__magic__\whisparr\movies` داخل Explorer. لا يُحفظ أي شيء في مجلد `data/local` الخاص بـzurg. الملف يُبث من حسابك.

## مشاهدته {#watching-it}

قم بتوجيه مكتبة Plex أو Jellyfin إلى `/mnt/zurg/__magic__/whisparr` (`/Volumes/Zurg/__magic__/whisparr` على ماك أو إس، و`Z:\__magic__\whisparr` على ويندوز) لتحتفظ بهذه الأفلام في مكتبة خاصة بها.

في rex تظهر هذه الأفلام في أي مكتبة توزعها مجلدات zurg، مثل أي إصدار آخر، وفي معظم الإعدادات يكون ذلك مكتبة الأفلام.
