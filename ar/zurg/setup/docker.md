# إعداد Docker {#docker-setup}

هذا الدليل يشغّل zurg في Docker ويعرض جبل FUSE الخاص به على مضيف Linux. يوفّر Docker كلًا من zurg وrclone وffprobe. يُنشئ الأمر المدمج `setup` ملف الإعدادات، ويفحص `doctor` التثبيت.

تم التحقق من هذا المسار في 4 سبتمبر 2026 باستخدام Docker Engine 29.1.1. استخدم أحدث نسخة nightly مؤرخة حتى تحتوي الصورة على أداة اختيار المزوّد أدناه.

> **صورة للرعاة:** `ghcr.io/debridmediamanager/zurg` مخصصة للرعاة. كن راعيًا عبر [gatekeeper](https://gatekeeper.debridmediamanager.com/). بعدها يحصل حساب GitHub الخاص بك على وصول إلى الصورة.

> **مطلوب مضيف Linux:** يعتمد الجبل الظاهر على المضيف والموضّح أدناه على انتشار تركيبات Linux (mount propagation). لا يعمل Docker Desktop على macOS وWindows إلا داخل جهاز افتراضي، لذلك لا يمكنه نقل جبل FUSE هذا إلى Finder أو Explorer، ولا يستطيع rex الوصول إلى zurg داخله، فلن يشتغل التشغيل هناك. استخدم بدلًا من ذلك دليل الملف الثنائي لـ [macOS](https://notes.debridmediamanager.com/ar/zurg/setup/macos/) أو [Windows](https://notes.debridmediamanager.com/ar/zurg/setup/windows/) على أي منهما. أما على Linux مع تشغيل rex على جهاز آخر، فامنح حاوية zurg القيمة `network_mode: host` كما يوضح [rex with zurg](../../rex/with-zurg.md#d4-connect-zurg-to-rex).

## خيار سطر واحد {#one-line-option}

على خادم Linux جديد، يمكن لسكربت الإعداد الأولي الاختياري أن يثبّت Docker بعد موافقتك، ويضبط FUSE mount propagation بشكل دائم، ويسجّل الدخول إلى سجل الرعاة، ويكتب مشروع Compose، ويشغّل أداة اختيار المزوّد، ثم يتحقق من النتيجة:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```

ملفات Compose والإعدادات الموجودة تبقى كما هي دون تغيير. توضح الأقسام أدناه كل خطوة لمن يفضّل الطريقة اليدوية.

## ما الذي يفعله المثبّت داخل الحاوية {#what-the-installer-does-in-a-container}

الخيارات هنا مقصودة:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

- يسأل الأمر `setup` عن مزوّدي الخدمة المراد إعدادهم، ولا يطلب سوى بيانات الاعتماد الخاصة بهم، ثم يكتب الملف `config.yml` بالوضع `0600`.
- يترك الخيار `--no-service` مهمة التشغيل التلقائي لسياسة `restart: unless-stopped` في Docker، بدلاً من محاولة تثبيت systemd داخل Alpine.
- يستخدم الخيار `--skip-downloads` البرنامجين rclone و ffprobe المثبّتين مسبقاً في الصورة.
- يسجّل الخيار `--mount-path` المجلد الفرعي الذي ستنتقل منه نقطة تركيب FUSE إلى المضيف.

تشغيل setup مرة أخرى آمن. فهو يتحقق من التثبيت ويحدّثه، لكنه لا يستبدل الملف `config.yml` الموجود.

## 1. تثبيت Docker وفتح الصورة {#1-install-docker-and-unlock-the-image}

ثبّت Docker Engine مع إضافة Compose على الجهاز المضيف الذي يعمل بنظام Linux. تحقّق من الأمرين قبل المتابعة:

```bash
docker version
docker compose version
```

سجّل الدخول إلى GitHub Container Registry باستخدام اسم مستخدمك على GitHub. عندما يطلب منك كلمة المرور، الصق رمز وصول شخصي من نوع classic personal access token يحتوي على الصلاحيتين `read:packages` و`repo` معاً. الصورة تنتمي إلى مستودع خاص، والرمز الذي يحمل `read:packages` فقط يسمح لك بتسجيل الدخول، لكنه قد يفشل في سحب الصورة:

```bash
docker login ghcr.io -u YOUR_GITHUB_USERNAME
```

اضبط `ZURG_TAG` على أحدث إصدار مؤرّخ للداعمين. الاحتفاظ به في `.env` يمنحك نقطة عودة معروفة ويجعل الترقيات واضحة:

```bash
printf 'ZURG_TAG=YYYY.MM.DD.HHMM-nightly\n' > .env
```

استبدل العنصر النائب بوسم الإصدار الفعلي قبل المتابعة.

## 2. تجهيز انتشار تركيب FUSE {#2-prepare-fuse-mount-propagation}

يجب إنشاء نقطة تركيب FUSE أسفل نقطة تركيب أب مشتركة. شغّل هذا الأمر مرة واحدة قبل أن تبدأ أول حاوية:

```bash
sudo mkdir -p /zurg_mnt
sudo modprobe fuse
sudo mount --bind /zurg_mnt /zurg_mnt
sudo mount --make-rshared /zurg_mnt
```

تحقق من الجهاز ووضع الانتشار:

```bash
test -c /dev/fuse
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

يجب أن يعرض الأمر الثاني القيمة `shared` تحت `PROPAGATION`.

## 3. إنشاء مشروع Compose {#3-create-the-compose-project}

```bash
mkdir -p ~/zurg
cd ~/zurg
```

أنشئ `docker-compose.yml`:

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
```

`privileged: true` ليس مطلوباً. جهاز FUSE وقدرة `SYS_ADMIN` وملف AppArmor غير المقيّد هي المجموعة الأضيق التي يحتاجها التركيب (mount).

لا تربط `/zurg_mnt/zurg` مباشرةً. يجب أن يكون تركيب FUSE تابعاً لربط `rshared`، وإلا فلن يصل حدث التركيب إلى المضيف.

الحاويات التي تقرأ التركيب، وخاصةً Sonarr و Radarr، تتبع القاعدة نفسها من الجهة الأخرى: اربط الأب (`/zurg_mnt`) مرة واحدة مع `rslave`، ثم ادخل إلى كل مجلد عبر هذا الربط الواحد. ربط `__magic__/__all__` و `__magic__/tv` في \*arr كحجمين منفصلين يحوّل كل استيراد إلى نسخة كاملة من الملف. انظر [sabnzbd.md](../guides/sonarr-radarr.md#one-volume-for-the-download-folder-and-the-root-folders).

## 4. تشغيل الإعداد المدمج {#4-run-the-built-in-setup}

من المجلد `~/zurg` شغّل:

```bash
docker compose run --rm zurg setup \
  --no-service \
  --skip-downloads \
  --mount-path /zurg_mnt/zurg
```

اختر مزودًا واحدًا أو أكثر بترتيب الأولوية. مثلًا، اكتب `2,4` لاختيار TorBox ثم Usenet. يطلب الإعداد بيانات اعتماد هؤلاء المزودين فقط، وينشئ ملف `config.yml` داخل `~/zurg`، ويفعّل rclone وينشئ `/zurg_mnt/zurg`. لا يُحفظ أي بيان اعتماد في ملف compose ولا في سجلّ سطر الأوامر.

للأتمتة، كرّر `--provider` ومرّر ملف الرمز الخاص بكل مزود أو أعلام `--nntp-*`. يحافظ الإعداد على الإعدادات الموجودة عند التشغيلات اللاحقة.

يكتب الإعداد الحسابات فقط في التشغيل الذي ينشئ `config.yml`. لإضافة حساب إلى تثبيت لديه إعدادات مسبقًا، استخدم زر **Add provider** في Dashboard أو عدّل الملف، ثم أعد التشغيل. لكل خدمة صفحة خاصة بها تضم بيان الاعتماد وكتلة الإعدادات والحدود التي تستحق المعرفة: [المزودون](../providers/index.md).

## 5. تشغيل zurg {#5-start-zurg}

```bash
docker compose up -d
docker compose logs -f --tail=100 zurg
```

اخرج من عرض السجلات بالضغط على `Ctrl+C`، وستبقى الحاوية تعمل. لوحة الإعدادات موجودة على `http://localhost:9999/config/`، وتعدّل نفس ملف `config.yml` الموجود بجانب ملف compose.

قد تستغرق المكتبات الكبيرة بعض الوقت حتى تُحمَّل. المجلدات الموجودة في الـ mount لن تُعرض إلى أن ينتهي التحميل، وقد تظهر فارغة أو تظهر كخطأ `Input/output error`، بينما تعمل لوحة الإعدادات و`version.txt` بشكل طبيعي. هذا يعني أن zurg ما زال يحمّل، وليس أن الـ mount معطّل. يوضّح [الفرق بين Up والجاهز](#up-versus-ready) كيف تعرف متى ينتهي التحميل.

## 6. التحقق باستخدام doctor {#6-verify-with-doctor}

بمجرد أن تصبح المكتبة جاهزة، شغّل أداة التشخيص نفسها التي يستخدمها التثبيت الثنائي:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
```

يتحقق `doctor` من الإعدادات وصلاحيات الوصول إليها، وffprobe، وrclone، وFUSE، ونقطة نهاية HTTP، والتركيب الذي يبلغ عنه zurg. التحذير `WARN service zurg is not installed` متوقع في Docker لأن Compose هو المسؤول عن التشغيل التلقائي. التحذيرات لا تجعل الأمر يفشل، أما أي `FAIL` فيفعل ذلك.

تأكد من أن التركيب المنتشر مرئي أيضًا خارج الحاوية:

```bash
cat /zurg_mnt/zurg/version.txt
ls -la /zurg_mnt/zurg/
```

## 7. جعل المجلد الأب المشترك يصمد بعد إعادة التشغيل {#7-make-the-shared-parent-survive-reboots}

الربط الذاتي (self-bind) من الخطوة 2 لا يبقى بعد إعادة التشغيل. أنشئ وحدة systemd من نوع oneshot على الجهاز المضيف:

```bash
sudo tee /etc/systemd/system/rshared-zurg-mnt.service << 'EOF'
[Unit]
Description=Make /zurg_mnt rshared for Docker FUSE mounts
Before=docker.service

[Service]
Type=oneshot
ExecStart=/bin/sh -c "mount --bind /zurg_mnt /zurg_mnt && mount --make-rshared /zurg_mnt"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable rshared-zurg-mnt.service
```

عند إعادة التشغيل القادمة، يجهّز الجهاز المضيف المجلد الأب المشترك قبل أن يستعيد Docker حاوية zurg.

## Up مقابل ready {#up-versus-ready}

يجيب zurg على سؤالين مختلفين عبر HTTP. ولا يحتاج أيٌّ منهما إلى كلمة مرور، حتى لو كان `username` مضبوطًا.

| العنوان | يرجع 200 عندما | أثناء تحميل المكتبة |
|---|---|---|
| `/http/version.txt` | zurg يعمل | 200 |
| `/ready` | انتهى تحميل المكتبة | 503 مع `Retry-After: 5` |

يستخدم فحص الصحة في الحاوية العنوان الأول. يظهر `docker compose ps` الحالة `healthy` بمجرد أن يعمل zurg. وقد تستمر المكتبة الكبيرة في التحميل لوقت طويل بعد ذلك. استعلم عن `/ready` عندما تحتاج إلى المكتبة كاملة. سيطبع `ready` بعد انتهاء التحميل.

```bash
curl -fsS http://localhost:9999/ready
docker compose exec zurg /app/healthcheck.sh --ready && echo ready
```

يمكن للسكربت أن ينتظر بهذه الطريقة.

```bash
until curl -fsS http://localhost:9999/ready >/dev/null; do sleep 10; done
```

### لماذا لا ينتظر فحص الصحة المكتبة {#why-the-health-check-does-not-wait-for-the-library}

ترصد Docker حالة صحية واحدة لكل حاوية. والأدوات التي تقرأ هذه الحالة تفهمها على أنها "هل zurg حيّ؟". ‏autoheal وDocker Swarm يعيدان تشغيل الحاوية عندما تصبح غير سليمة. و`depends_on` مع `condition: service_healthy` يؤخّر الخدمات الأخرى إلى أن يصبح zurg سليمًا.

وقد أُبلغ عن بدء تشغيل بطيء يستغرق من 15 إلى 90 دقيقة في المكتبات الكبيرة. لو انتظر فحص الصحة تحميل المكتبة، لبقيت كل الخدمات التابعة متوقفة طوال تلك المدة. وحاوية rclone أمام zurg كانت ستترك مجلد التركيب فارغًا طوال الوقت. والمجلد الفارغ يبدو لخادم الوسائط وكأن المكتبة حُذفت. وأي تحميل تجاوز عدد محاولات فحص الصحة سيُعدّ هو أيضًا غير سليم. وأي أداة تعيد تشغيل الحاويات غير السليمة كانت ستبدأ التحميل من جديد، ولن ينتهي أبدًا.

### استخدام الجاهزية مع Compose {#using-readiness-with-compose}

```yaml
services:
  rclone:
    depends_on:
      zurg:
        condition: service_healthy
```

انتظر على `/ready` في أي شيء يحتاج المكتبة كاملة. ممكن يكون سكربت مسح أو مهمة استيراد.

تقدر تخلي حاوية zurg نفسها تعلن أنها سليمة بس بعد ما تتحمل المكتبة. عدّل الـ health check تبعها في `docker-compose.yml` واضبط `start_period` أطول من أبطأ تحميل عندك. Docker ما يحسب الفشل اللي يصير داخل فترة الـ start period. وبعدين أي خدمة تعتمد على zurg بتنتظر المكتبة هي كمان. لا تجمع هذا مع autoheal.

```yaml
services:
  zurg:
    healthcheck:
      test: ["CMD", "/app/healthcheck.sh", "--ready"]
      interval: 30s
      timeout: 10s
      start_period: 3h
      retries: 3
```

## إدارة zurg وتحديثه {#managing-and-updating-zurg}

نفّذ هذه الأوامر من داخل `~/zurg`:

```bash
docker compose ps
docker compose logs -f --tail=100 zurg
docker compose restart zurg
docker compose stop zurg
docker compose start zurg
```

يتتبّع مشروع compose القيمة `ZURG_TAG` من ملف `.env`، وهي التي يضبطها المثبّت على `latest` حتى يجلب السحب دائمًا أحدث نسخة ليلية. للترقية، اسحب الصورة وأعد إنشاء الحاوية، ثم شغّل doctor:

```bash
docker compose pull zurg
docker compose up -d zurg
docker compose exec zurg /app/zurg doctor --working-dir /config
```

`zurg update` ليس الخيار المناسب هنا، فهو يرفض العمل داخل الحاوية: الملف الثنائي الذي يكتبه يعيش في طبقة الحاوية، ويضيع في اللحظة التي تُعاد فيها إنشاء الحاوية، فيعود `up` التالي إلى البناء القديم دون أي تنبيه. اسحب الصورة بدلًا من ذلك. الخيار `--force` يتجاوز هذا الرفض للحاوية التي تنوي الاحتفاظ بها.

للتراجع عن الترقية، اضبط `ZURG_TAG` في `.env` على وسم ليلي محدد، ثم شغّل تلك الأوامر الثلاثة مرة أخرى. ملفات الإعداد وحالة المكتبة والسجلات والذاكرة المؤقتة المربوطة عبر bind mount لا تنتقل مع الحاوية.

أمر `docker compose down` يزيل الحاوية والشبكة، لكنه يترك الملفات المربوطة في `~/zurg` والمجلد الأب للتركيب في `/zurg_mnt` كما هي.

## ما الذي يوجد أين {#what-lives-where}

كل ما يكتبه zurg يُحفظ داخل `/config`، لذلك يحتوي الـ bind الوحيد `./:/config` على التثبيت كاملاً:

| Path | What it is |
|---|---|
| `config.yml` | الإعدادات وبيانات اعتماد المزوّدين؛ تعديلات Dashboard تُكتب هنا |
| `data/` | حالة المكتبة والملفات المحلية والمفاتيح المُنشأة وكاش VFS الخاص بـ rclone |
| `logs/` | سجلات zurg وrclone |
| `dump/` | ملفات تفريغ التورنت عند تفعيلها |
| `strm/` | ملفات `.strm` عند تفعيل `save_strm_files` |
| `nzbs/` | مجلد المراقبة للواجهة الخلفية الخاصة بـ Usenet |

سحب الصورة أو إعادة إنشاؤها لا يغيّر أيًا من هذه الملفات.

`data/rclone-cache` هو المجلد الوحيد الذي يكبر. يقوم الـ mount بتنزيل كل ملف يقرأه كاملاً، ويحتفظ به بعد انتهاء التشغيل، حتى **256G** افتراضيًا، لذلك يحتاج مجلد الـ bind إلى مساحة للكاش بالإضافة إلى كل شيء آخر. حدّ العمر 72h لا يحدّه فعليًا، فأي شيء يقرأ المكتبة، بما في ذلك المرور الليلي لخادم الوسائط، يُحسب على أنه لمس الملف.

```bash
du -sh ./data/rclone-cache
```

خفّض الحد في `config.yml` إذا كان قرص الجهاز المضيف لا يتسع لهذا القدر:

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

تغيير المسار على الجهاز المضيف الذي يقف خلف `/config` يعيد تسمية الكاش ويترك النسخة القديمة يتيمة؛ يستعيد zurg المجلدات اليتيمة عند التشغيل التالي ويسجّل المساحة التي حرّرها. راجع [config.md](../reference/config.md#disk-the-mount-uses).

### تهيئة البيئة للتثبيتات غير التفاعلية {#environment-seeding-for-unattended-installs}

ما زالت الصورة تدعم مسار التشغيل الأول القديم. إذا لم يكن هناك ملف `config.yml`، فإن `TOKEN` أو `RD_TOKEN` يزرع الحساب، و`MOUNT_PATH` يفعّل التركيب (mount). تُقرأ هذه المتغيرات فقط أثناء إنشاء الملف، والملف هو الذي يحسم الأمر في كل تشغيل لاحق.

Real-Debrid هو الحساب الوحيد الذي تزرعه الحاوية قيد التشغيل بهذه الطريقة. أما `TORBOX_TOKEN` و`ALLDEBRID_TOKEN` و`PREMIUMIZE_TOKEN` و`DEBRIDLINK_TOKEN` و`OFFCLOUD_TOKEN` و`NNTP_HOST` فيقرأها الأمر `zurg setup`، لذا تسري مفعولها في حاوية الإعداد المنفصلة المذكورة أعلاه، ولا تفعل شيئاً إذا وُضعت في كتلة `environment:` الخاصة بالخدمة.

أمر `setup` التفاعلي أفضل إذا كنت تجلس أمام الطرفية، لأن الرمز لا يدخل ملف compose أبداً. أما زرع المتغيرات البيئية فيبقى مفيداً للأتمتة التي لديها بالفعل مخزن أسرار.

### ترقية تثبيت قام بتركيب `/app` {#upgrading-an-install-that-mounted-app}

كانت مشاريع compose القديمة تربط المسارات `/app/config.yml` و`/app/data` وغيرها بشكل منفصل. لا تزال نقطة الدخول تختار `/app` كلما وجدت هذا الترتيب، لذلك يستمر أي سحب لصورة أحدث في استخدام الإعدادات والذاكرة المؤقتة القديمة.

لاعتماد الترتيب الجديد الذي يستخدم مجلدًا واحدًا، أوقف الحاوية أولًا، ثم انسخ الملف `config.yml` الموجود ومجلد `data/` ومجلدات الحالة الأخرى إلى مجلد واحد على الجهاز المضيف، ثم اربط هذا المجلد بالمسار `/config`.

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

ابدأ بالتشخيص وسجلات الأخطاء الحالية:

```bash
docker compose exec zurg /app/zurg doctor --working-dir /config
docker compose logs --tail=200 zurg
```

### `unknown command "setup"` أو `unknown command "doctor"` {#unknown-command-setup-or-unknown-command-doctor}

الحاوية أقدم من المثبّت المدمج. استخدم `2026.09.04.1449-nightly` أو أي صورة zurg بتاريخ أحدث، ثم أعد إنشاءها:

```bash
docker compose pull zurg
docker compose up -d zurg
```

### `Transport endpoint is not connected`

الـ FUSE mount القديم متقادم:

```bash
sudo umount -l /zurg_mnt/zurg
docker compose restart zurg
```

### جهاز FUSE غير متاح {#fuse-device-is-unavailable}

لحّمّل الوحدة الآن وفي كل إقلاع لاحق:

```bash
sudo modprobe fuse
echo fuse | sudo tee /etc/modules-load.d/fuse.conf
```

ثم تأكّد أن خدمة compose ما زالت تتضمّن `/dev/fuse` و`SYS_ADMIN` وإعداد AppArmor.

### التركيب فارغ {#mount-is-empty}

```bash
docker compose logs zurg 2>&1 | grep -i rclone
docker compose exec zurg ls -la /zurg_mnt/zurg
curl -fsS http://localhost:9999/http/version.txt
curl -fsS http://localhost:9999/ready
findmnt -o TARGET,PROPAGATION /zurg_mnt
```

يجب أن يكون مسار المضيف (host path) عبارة عن bind mount مشترك، وأن يربط ملف compose الأب بالمسار `/zurg_mnt:/zurg_mnt:rshared` كـ volume.

إذا فشل `/ready` مع الخطأ 503، فهذا يعني أن المكتبة ما زالت تُحمَّل، وأن الـ mount سليم. قد تظهر المجلدات فارغة أو تعرض `Input/output error` حتى ينتهي التحميل. انتظر ولا تُعِد تشغيل zurg. إعادة التشغيل تبدأ التحميل من جديد.

### يظهر التركيب مرتين في خرج `mount` {#mount-appears-twice-in-mount-output}

هذا أمر طبيعي. الـ FUSE mount نفسه يظهر داخل الحاوية وفي مساحة أسماء الـ mount على الجهاز المضيف، وذلك لأن الـ propagation يعمل بشكل صحيح.

ما زلت عالقاً؟ اسأل في منتدى **zurg-support** على [Discord](https://discord.com/invite/7u4YjMThXP). صفحة [طلب المساعدة](../../guides/remote-help.md) توضح ما يجب أن تذكره.
