# ملف Docker Compose واحد لـ zurg وPlex وrex {#one-docker-compose-file-for-zurg-plex-and-rex}

على جهاز Linux، يمكن لملف `docker-compose.yml` واحد أن يشغّل zurg وPlex Media Server وrex جنبًا إلى جنب. يعرض zurg مكتبتك كمجلدات تحت `/zurg_mnt/zurg`، ويقرأ Plex Media Server هذه المجلدات، ويحصل rex على المكتبة نفسها مباشرة من zurg، من دون الحاجة إلى مجلدات. شغّل مُثبِّت zurg عبر Docker مرة واحدة، ثم استبدل ملف `docker-compose.yml` الخاص به بالملف الموجود أدناه.

تريد Plex Media Server أو rex فقط، وليس الاثنين؟ احذف الخدمة الأخرى من الملف. وإذا لم تستخدم Plex، فاحذف أيضًا سطر `command:` الخاص بـ rex.

لا يمكن تشغيل هذا على Docker Desktop في Windows أو Mac، لأن مجلدات zurg لن تظهر في Explorer أو Finder، ولن يتمكن rex من الوصول إلى zurg الموجود داخل الجهاز. استخدم بدلًا من ذلك [zurg على Windows](../setup/windows.md) أو [zurg على macOS](../setup/macos.md).

## قبل أن تبدأ {#before-you-start}

- **جهاز Linux** يبقى مشغّلاً طوال الوقت. المثبّت يضيف Docker إذا لم يكن موجوداً.
- **رعاية zurg.** صورة zurg خاصة. ارعَ المشروع على [gatekeeper](https://gatekeeper.debridmediamanager.com/) وسيمنح حسابك على GitHub صلاحية الوصول.
- **مفتاح API الخاص بك من Real-Debrid**، أو تسجيل الدخول لخدمة أخرى يدعمها zurg: [Your Real-Debrid API token](../../guides/real-debrid-api-token.md).
- **لخادم Plex Media Server**، حساب Plex الخاص بك. **أما لـ rex**، فأنشئ حساب Plex جديداً خصيصاً له: [rex مع zurg](../../rex/with-zurg.md#before-you-start) يشرح السبب.

## 1. شغّل مثبّت zurg الخاص بـ Docker {#1-run-zurgs-docker-installer}

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

يقوم بتثبيت Docker إذا كان غير موجود (وسيسألك أولاً)، ويجهّز `/zurg_mnt` لمجلدات zurg الآن وبعد كل إعادة تشغيل، ويسجّل دخولك إلى GitHub لسحب صورة zurg، ويكتب `~/zurg/docker-compose.yml`، ويطلب منك الخدمات والرمز المميز، ثم يشغّل zurg ويُنفّذ `zurg doctor`. يقوم [إعداد zurg على Docker](../setup/docker.md) بالعمل نفسه يدوياً.

**ما يجب أن تراه.**

```bash
ls /zurg_mnt/zurg
```

يعرض المجلدات `__all__` و`__downloads__` و`__unplayable__` و`movies` و`shows` والملف `version.txt`.

## 2. استبدل الملف بالملف الكامل {#2-swap-in-the-full-file}

```bash
cd ~/zurg
nano docker-compose.yml
```

استبدل كل ما فيه بهذا:

```yaml
services:
  zurg:
    image: ghcr.io/debridmediamanager/zurg:${ZURG_TAG}
    container_name: zurg
    restart: unless-stopped
    devices:
      - /dev/fuse
    cap_add:
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    ports:
      - 9999:9999
    volumes:
      - ./:/config
      - /zurg_mnt:/zurg_mnt:rshared

  plex:
    image: plexinc/pms-docker
    container_name: plex
    restart: unless-stopped
    network_mode: host
    environment:
      - TZ=Europe/London
      - PLEX_CLAIM=
    volumes:
      - ../plex/config:/config
      - ../plex/transcode:/transcode
      - /zurg_mnt:/zurg_mnt:rslave
    depends_on:
      zurg:
        condition: service_healthy

  rex:
    image: ghcr.io/debridmediamanager/rex:nightly
    container_name: rex
    restart: unless-stopped
    network_mode: host
    command: --port 32500
    volumes:
      - ../rex/config:/config
```

- **zurg** هي خدمة المثبّت نفسها، دون تغيير.
- **plex** يرى مجلدات zurg في المسار نفسه الذي يستخدمه zurg، أي `/zurg_mnt/zurg`، لذلك فإن الفحص الذي يطلبه zurg بالاسم يشير إلى مجلد يعرفه Plex. يحافظ `rslave` على بقاء المجلدات في مكانها عند إعادة تشغيل zurg. ضع منطقتك الزمنية في `TZ`.
- **PLEX_CLAIM** يسجّل دخول Plex Media Server إلى حسابك عند أول تشغيل. سجّل الدخول إلى Plex، ثم افتح [plex.tv/claim](https://www.plex.tv/claim)، وانسخ الرمز والصقه مباشرة بعد علامة `=`. تنتهي صلاحيته بعد بضع دقائق، لذلك ابدأ تشغيل الحزمة فورا.
- **rex** هي الخدمة من [rex مع zurg](../../rex/with-zurg.md#d2-start-rex-in-docker)، وتعمل على المنفذ 32500 لأن Plex Media Server يستخدم 32400. ملفاتها تنتهي في `~/rex/config`، وهو المكان الذي يبحث فيه rex مع zurg عن ملفاته.

احفظ الملف وشغّل كل شيء:

```bash
docker compose up -d
docker compose ps
```

إذا ظهرت لك الرسالة permission denied عند تشغيل `docker`، فضع `sudo` قبل كل أمر `docker` في هذه الصفحة.

**ما الذي يجب أن تراه.** ثلاث حاويات: `plex` و`zurg` تظهران `(healthy)`، و`rex` تظهر `Up`. تذهب ملفات Plex Media Server الخاصة به إلى `~/plex`.

## 3. أضف مجلدات zurg في Plex {#3-add-zurgs-folders-in-plex}

افتح Plex Web على `http://<this machine's LAN IP>:32400/web`. أضف مكتبة **Movies** بالمجلد `/zurg_mnt/zurg/movies` ومكتبة **TV Shows** بالمجلد `/zurg_mnt/zurg/shows`، كما يظهر في [Real-Debrid في Plex](../../guides/real-debrid-plex.md#3-add-the-folders-in-plex).

حتى يعرف Plex بالمحتوى الجديد، افتح لوحة zurg على `http://<this machine's LAN IP>:9999/config/` واضغط **Login with Plex** تحت **Media Server Integration** ([الخطوة 4 هناك](../../guides/real-debrid-plex.md#4-let-zurg-tell-plex-about-new-things)).

## 4. إعداد rex {#4-set-up-rex}

اتبع [rex مع zurg](../../rex/with-zurg.md) من [D3](../../rex/with-zurg.md#d3-add-it-to-a-plex-account) إلى [D5](../../rex/with-zurg.md#d5-watch)، واستخدم `32500` بدلًا من `32400` في كل مكان يُذكر فيه. على سبيل المثال، سطر zurg هو `rex_url: http://192.168.1.20:32500` مع عنوان IP الخاص بـ rex على الشبكة المحلية. ثم ستعرض تطبيقات Plex الخاصة بك الخادمين معًا: [الخطوة 2 من rex مع zurg](../../rex/with-zurg.md#step-2-install-rex) توضح كيفية التمييز بينهما.

## التحديث {#updating}

```bash
cd ~/zurg
docker compose pull
docker compose up -d
```

يقوم ذلك بتحديث zurg وPlex وrex معًا. وفي الحالة التي يشغّل فيها rex مع zurg الأمر `docker compose` داخل `~/rex`، شغّله هنا داخل `~/zurg` مع إضافة `rex` في نهايته، بحيث يؤثر على rex وحده: `docker compose stop rex` بدلًا من `docker compose down`، و`docker compose up -d rex` بدلًا من `docker compose up -d`.

## عندما تحدث مشكلة {#when-something-is-wrong}

`docker compose logs --tail=100 zurg` (أو `plex`، `rex`) يعرض آخر ما قالته الحاوية.

| ما تراه | ما الذي يجب فعله |
|---|---|
| المثبِّت يقول `Host-visible Docker mounts require a Linux host. Use the binary installer on macOS or Windows.` | أنت على جهاز Mac أو Windows. ثبّت zurg باستخدام [مثبّت Windows](../setup/windows.md) أو [مثبّت macOS](../setup/macos.md) بدلاً من ذلك. |
| `Error response from daemon: error from registry: unauthorized` عندما يسحب Docker صورة zurg | هذا الجهاز غير مسجّل الدخول إلى سجل حزم GitHub بحساب له صلاحية الوصول إلى zurg. ادعم المشروع عبر [gatekeeper](https://gatekeeper.debridmediamanager.com/)، ثم شغّل المثبّت مرة أخرى. لتسجيل الدخول يدوياً، راجع [إعداد Docker لـ zurg](../setup/docker.md#1-install-docker-and-unlock-the-image): يحتاج الرمز إلى الصلاحيتين `read:packages` و`repo`. |
| `path /zurg_mnt is mounted on ... but it is not a shared mount` | المسار `/zurg_mnt` غير مُشارَك بعد. شغّل `sudo mount --bind /zurg_mnt /zurg_mnt` ثم `sudo mount --make-rshared /zurg_mnt`، ثم `docker compose up -d`. المثبّت يجعل هذا الإعداد دائماً بعد إعادة التشغيل؛ يدوياً، راجع [الخطوة 7 من إعداد Docker لـ zurg](../setup/docker.md#7-make-the-shared-parent-survive-reboots). |
| `zurg` يستمر في إعادة التشغيل، وينتهي سجله بـ `Error: config ./config.yml is not valid YAML: yaml: unmarshal errors:` و`mapping key "..." already defined` | هذا الإعداد موجود مرتين في ملف إعدادات zurg. شغّل `sudo nano ~/zurg/config.yml`، واحذف أحد السطرين اللذين تذكرهما الرسالة، ثم احفظ، وشغّل `docker compose restart zurg`. |
| سجل zurg يقول `Mount verification failed: mount verification timeout: /zurg_mnt/zurg/version.txt not accessible after 60 attempts -- you appear to be running inside Docker, mount a parent directory with rshared propagation` | مجلدات zurg لم تظهر. تأكد أن سطر الـ volume في zurg هو `/zurg_mnt:/zurg_mnt:rshared`، أي المجلد الأب وليس `/zurg_mnt/zurg`، وأن `/zurg_mnt` مُشارَك (الصف الذي فوق). يحتوي [المجلد فارغ](../setup/docker.md#mount-is-empty) على فحوصات إضافية. |
| مكتبات Plex تصبح فارغة بعد إعادة تشغيل zurg، ويقول `docker exec plex ls /zurg_mnt/zurg` إن `cannot access '/zurg_mnt/zurg': Transport endpoint is not connected` | سطر الـ volume الخاص بـ Plex ينقصه `rslave`. يجب أن يكون `/zurg_mnt:/zurg_mnt:rslave`. صحّحه ثم شغّل `docker compose up -d`. |
| rex يتوقف مع `rex: cannot bind 0.0.0.0:32400: Address already in use (os error 98) (another rex or Plex on this port? --port picks another)` | Plex Media Server يستخدم المنفذ 32400 أصلاً. أبقِ `command: --port 32500` في rex. |
| `/zurg_mnt/zurg/movies` فارغ، أو يقول `Input/output error`، مباشرة بعد البدء | zurg ما زال يقرأ حسابك. يطبع `curl http://localhost:9999/ready` كلمة `ready` عندما ينتهي. لا تعيد تشغيل zurg في هذه الأثناء، فذلك يبدأ القراءة من جديد. |
| العناوين تظهر في rex لكن لا شيء يُشغَّل | الصف `upstream failed` في [rex مع zurg، عند وجود مشكلة](../../rex/with-zurg.md#when-something-is-wrong) يفحص ما إذا كان rex يستطيع الوصول إلى zurg. |
| القرص يمتلئ | يحتفظ zurg بنسخة مما تم تشغيله في `~/zurg/data/rclone-cache`، حتى 256G افتراضياً. يوضح [ما الذي يوجد أين](../setup/docker.md#what-lives-where) كيفية تحديد الحد الأقصى. |

ما زلت عالقاً؟ اسأل في منتدى **zurg-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يوضح [الحصول على المساعدة](../../guides/remote-help.md) ما الذي يجب تضمينه.

## أسئلة {#questions}

### هل يمكنك مراجعة ملف docker compose الخاص بي؟ {#can-you-check-my-docker-compose-file}

لا أرى أي نص سابق في هذه المحادثة لأقارنه به. الرسالة الوحيدة هي ملاحظاتك عن الإعدادات. أرسل النص الذي تريد ترجمته، وسأحافظ على هذه النقاط كما هي:

- يربط `zurg` المسار `/zurg_mnt` بخيار `rshared`.
- يربط Plex المسار نفسه `/zurg_mnt` بخيار `rslave`.
- يستخدم `rex` الصورة `ghcr.io/debridmediamanager/rex` مع `network_mode: host`.
- الخدمة التي اسمها `rex` وتشغّل `plexinc/pms-docker` هي خادم Plex Media Server ثانٍ، وليست `rex`.

### هل أحتاج إلى حاوية rclone منفصلة؟ {#do-i-need-a-separate-rclone-container}

لا. يشغّل zurg برنامج rclone داخل الحاوية الخاصة به، ويضع مكتبتك في `/zurg_mnt/zurg` بنفسه.

### هل يمكنني استخدام Plex Media Server وrex معاً؟ {#can-i-use-plex-media-server-and-rex-together}

هذا ما يفعله هذا الملف بالضبط. يشغّل Plex Media Server المحتوى من مجلدات zurg، ويشغّل rex المحتوى من zurg مباشرة. وستظهر لك المكتبتان في تطبيقات Plex. إذا لم تكن تريد المكتبتين معًا، فاحتفظ بالواحدة التي تستخدمها فقط.

### هل يعمل هذا على NAS؟ {#does-this-work-on-a-nas}

تم اختباره على كمبيوتر يعمل بنظام Linux، وليس على NAS. يحتاج المثبّت إلى نافذة طرفية (SSH) مع `sudo`، وإلى FUSE (`/dev/fuse`). إذا انتهت الخطوة 1 وظهرت مجلدات zurg داخل `/zurg_mnt/zurg`، فتابع إلى الخطوة 2.

### مع أي إصدارات تم اختبار هذا؟ {#which-versions-was-this-tested-with}

zurg `2026.11.14.1134-nightly` و rex `2026.11.14.1123-nightly` و Plex Media Server `1.43.5.11079`، بتاريخ 14 نوفمبر 2026.
