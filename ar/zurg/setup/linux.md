# إعداد الملف الثنائي لـ Linux {#linux-binary-setup}

## خيار سطر واحد {#one-line-option}

يقوم الإعداد الأولي الاختياري للرعاة بتثبيت حزم النظام، وتنزيل نسخة المعالج المناسبة، وتشغيل الإعداد والتشخيص:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

يسجّل الدخول عبر GitHub ويثبّت البرنامج في `~/zurg`. تبقى الملفات التنفيذية والإعدادات الموجودة في مكانها. تابع أدناه لـ
الطريقة اليدوية أو لمسار مخصص.

يستطيع الملف التنفيذي zurg بناء بقية التثبيت بنفسه. يكتب ملف الإعدادات، وينزّل rclone الصحيح (وffprobe، إلا إذا كان موجوداً بالفعل في PATH لديك) الملائم للجهاز، وينشئ نقطة التركيب (mount)، ويسجّل خدمة systemd مفعّلة.

تم التحقق من هذا المسار في 4 September 2026 على خوادم Ubuntu 24.04 نظيفة بمعمارية ARM64 وx86_64.

## 1. تثبيت FUSE 3 {#1-install-fuse-3}

```bash
sudo apt-get update
sudo apt-get install -y fuse3
```

تستخدم توزيعات أخرى حزمة `fuse3` بالاسم نفسه أيضًا: `sudo dnf install fuse3` على Fedora، و`sudo pacman -S fuse3` على Arch، و`sudo zypper install fuse3` على openSUSE.

تأكد من أن المساعد والجهاز موجودان:

```bash
command -v fusermount3
test -c /dev/fuse
```

إذا كان Plex أو Jellyfin أو أي عملية أخرى تعمل بمستخدم Unix مختلف، فعِّل `allow_other` مرة واحدة:

```bash
echo user_allow_other | sudo tee -a /etc/fuse.conf
```

بدون هذا الإعداد يبقى الـ mount يعمل، لكن الحساب الذي يشغّل zurg وحده يستطيع فتحه. يُظهر `zurg doctor` هذا الفرق.

## 2. تنزيل zurg {#2-download-zurg}

قم بتنزيل أرشيف Linux المناسب من [إصدارات الرعاة](https://github.com/debridmediamanager/zurg/releases). اختر `linux-amd64` لجهاز Intel أو AMD، و`linux-arm64` لجهاز ARM.

خذ أحدث نسخة nightly. وهي الإصدار التجريبي الموجود في أعلى القائمة. لا تأخذ الإصدار الذي يحمل علامة **Latest** على GitHub، فهذا هو v1.0.0. وهو أقدم من `zurg setup` ويرد عليه بـ `unknown command`.

نسخ nightly مخصصة للرعاة فقط. وحتى يصبح حساب GitHub الخاص بك لديه صلاحية الوصول، تعرض تلك الصفحة خطأ 404. ارعَ عبر [gatekeeper](https://gatekeeper.debridmediamanager.com/) لمنحه الوصول. النسخة العامة المجانية هي v1.0.0 من [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). وليس فيها `zurg setup`. قم بإعدادها يدوياً كما يشرح [ملف README الخاص بها](https://github.com/debridmediamanager/zurg-public#readme) بدلاً من اتباع الخطوات أدناه.

فك ضغط الأرشيف داخل المجلد الذي يجب أن يحتوي على التثبيت بأكمله:

```bash
mkdir -p ~/zurg
cd ~/zurg
# Put the downloaded zurg binary here, then:
chmod +x zurg
```

كل ما يحتفظ به zurg يبقى بجانب هذا الملف التنفيذي: `config.yml`، والمساعدات التي يتم تنزيلها، وحالة المكتبة، والسجلات، وذاكرة التخزين المؤقت لـ rclone.

## 3. تشغيل الإعداد {#3-run-setup}

```bash
cd ~/zurg
./zurg setup
```

يسألك الإعداد عن مزودي الخدمة الذين تريد ضبطهم. اختر واحدًا أو أكثر بحسب الأولوية:

```text
  1) Real-Debrid
  2) TorBox
  3) AllDebrid
  4) Usenet (NZB)
  5) Premiumize
  6) Debrid-Link
  7) Offcloud
```

مثلًا، اكتب `2,4` لاختيار TorBox ثم Usenet. يطلب الإعداد بيانات الاعتماد التي اخترتها فقط. بعد ذلك يقوم بالآتي:

1. ينشئ `config.yml` ويتحقق من صحته.
2. يقصر الوصول إلى ملف الإعدادات على مالكه فقط بالوضع `0600`.
3. يحمّل rclone أصلي داخل `bin/`، وكذلك ffprobe ما لم يكن موجودًا بالفعل في PATH لديك.
4. يفعّل تركيب rclone على `/mnt/zurg`.
5. يثبّت خدمة systemd مفعّلة ويشغّلها.

استخدم نقطة تركيب داخل مجلدك الشخصي إذا لم تكن لديك صلاحية لإنشاء `/mnt/zurg`:

```bash
./zurg setup --mount-path "$HOME/zurg-mount"
```

يمكنك تشغيل الإعداد مرة أخرى دون مشكلة. يحدّث الخدمة التي أنشأها، لكنه لا يستبدل ملف `config.yml` الموجود.

### اختيار نطاق systemd {#choosing-the-systemd-scope}

مع مدير systemd للمستخدم يعمل بشكل صحيح، يثبّت الخيار الافتراضي `auto` الملف `~/.config/systemd/user/zurg.service`. وإلا، يثبّت الإعداد الملف `/etc/systemd/system/zurg.service` ويطلب منك sudo تشغيله بصلاحيات المستخدم الحالي.

اختر يدوياً عند الحاجة:

```bash
./zurg setup --service-scope user
./zurg setup --service-scope system --service-user "$USER"
```

لكي تبدأ خدمة المستخدم قبل أول تسجيل دخول بعد إعادة التشغيل، فعّل lingering:

```bash
loginctl show-user "$USER" -p Linger
sudo loginctl enable-linger "$USER"
```

تشغيل الإعداد باسم `root` على خادم يختار خدمة نظام يملكها root.

## 4. التحقق من التثبيت {#4-verify-the-install}

```bash
./zurg doctor
curl -fsS http://127.0.0.1:9999/http/version.txt
ls /mnt/zurg/version.txt
```

يتحقق الأمر `doctor` من الإعدادات وصلاحياتها، ومن الأداتين اللتين تم تنزيلهما، ومن FUSE، ومن وحدة systemd، ومن نقطة HTTP، ومن التركيب الذي يبلغ عنه zurg.

تستغرق مكتبة Real-Debrid الكبيرة وقتاً لبنائها في أول تشغيل. قد تكون الخدمة نشطة بالفعل بينما تنتظر قائمة التركيب الأولى انتهاء ذلك الفحص.

يرد `version.txt` بمجرد أن يعمل zurg. تستمر المكتبة الكبيرة في التحميل بعد ذلك. تظهر مجلداتها فارغة أو كـ `Input/output error` حتى تنتهي. يخبرك `/ready` متى ينتهي ذلك.

```bash
curl -fsS http://127.0.0.1:9999/ready
```

## القرص الذي يستخدمه الـ mount {#disk-the-mount-uses}

يحفظ الـmount نسخة مؤقتة من كل ملف يقرأه داخل `~/zurg/data/rclone-cache`. ويُبقي الملف كاملاً بعد انتهاء التشغيل. إذا تُرك دون تدخل، سيكبر هذا الكاش حتى يصل إلى **256G** ويبقى عند هذا الحجم. ولا يُمسح عند توقف الفيديو. وحد العمر 72h لن ينقذك أيضاً، لأن rclone يعتبر الملف مُستخدَماً كلما قرأه أي شيء، ومهمة الصيانة الليلية في خادم الوسائط تقرأ المكتبة كاملة.

تحقق مما يحتويه.

```bash
du -sh ~/zurg/data/rclone-cache
```

إذا كان 256G أكثر مما يتحمله القرص، فخفّض الحد في `config.yml`.

```yaml
rclone_extra_args:
  - "--vfs-cache-max-size"
  - "50G"
  - "--vfs-cache-min-free-space"
  - "20G"
```

أعد تشغيل zurg بعد ذلك. لتفريغه يدوياً، أوقف zurg أولاً ثم شغّل هذا الأمر.

```bash
rm -rf ~/zurg/data/rclone-cache/vfs/* ~/zurg/data/rclone-cache/vfsMeta/*
```

نقل مجلد zurg يغيّر اسم الكاش ويترك النسخة القديمة في مكانها. يستعيد zurg هذه النسخ عند التشغيل التالي ويسجّل المساحة التي حرّرها. التفاصيل وطريقة تعطيل ذلك موجودة في [مرجع الإعدادات](../reference/config.md#disk-the-mount-uses).

## إدارة zurg {#managing-zurg}

يُرجى تشغيل هذه الأوامر من مجلد zurg:

```bash
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

يزيل الأمر `uninstall` التشغيل التلقائي فقط. يبقى الملف التنفيذي والإعدادات والبيانات والسجلات والذاكرة المؤقتة في مكانها.

لمتابعة السجلات لخدمة مستخدم:

```bash
journalctl --user -u zurg.service -f
```

أما لخدمة النظام:

```bash
sudo journalctl -u zurg.service -f
```

## تحديث zurg {#updating-zurg}

تُستبدل نسخة الرعاة بنفسها:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

يأخذ `update` أحدث نسخة ليلية. يحمّلها، ويتحقق من أن الملف الثنائي الجديد يُبلغ عن الإصدار المتوقع، ثم يستبدله بإعادة التسمية (rename)، فلا تُكتب العملية الجارية فوقها أبدًا. وإذا كانت النسخة المثبتة هي الأحدث بالفعل، يُخبرك بذلك ولا يغيّر أي شيء.

يسجّل `update` الدخول إلى GitHub بالحساب الذي استخدمته للتثبيت. ويحتفظ المثبّت بأداة GitHub CLI في `~/zurg/bin` لهذا الغرض. إذا قال `update` إنه لم يجد بيانات اعتماد GitHub، فتثبيتك أقدم من هذا التغيير. شغّل خيار التحديث في المثبّت مرة واحدة، وسيعمل كل أمر `zurg update` بعد ذلك. ويحدّث الأمر نفسه النسخة القديمة التي لا تحتوي على `zurg update` أيضًا. وهو يستبدل الملف الثنائي فقط ولا يمس أي شيء آخر.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

إذا كان الخادم لا يحتوي على GitHub CLI، يمكنك ضبط `GITHUB_TOKEN` بدلًا من ذلك. استخدم رمزًا كلاسيكيًا (classic token) بالنطاق `repo` من حساب GitHub الذي يملك صلاحية الوصول إلى zurg.

## الإعدادات الموجودة والإعدادات غير التفاعلية {#existing-and-unattended-configs}

لا يستبدل الإعداد أبدًا ملف `config.yml` الموجود. للإعداد بدون تفاعل، كرّر `--provider` وزوّد ملفات الرموز (token-file) المطابقة أو خيارات `--nntp-*`. تعمل متغيرات البيئة `REALDEBRID_TOKEN` و`TORBOX_TOKEN` و`ALLDEBRID_TOKEN` وكذلك متغيرات `NNTP_*` أيضًا. شغّل `./zurg setup --help` لعرض القائمة الكاملة.

راجع [مرجع الإعدادات](../reference/config.md) لمعرفة كل خيار.

لا تزال عالقًا؟ اسأل في منتدى **zurg-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يوضح [الحصول على المساعدة](../../guides/remote-help.md) ما الذي يجب تضمينه.

## انظر أيضًا {#see-also}

- [Docker](docker.md) — إعداد الحاوية وانتشار تركيب FUSE
- [macOS](macos.md) — نفس مثبّت الملف الثنائي مع macFUSE وlaunchd
- [Windows](windows.md) — نفس مثبّت الملف الثنائي مع WinFsp ومهمة مجدولة تفاعلية
