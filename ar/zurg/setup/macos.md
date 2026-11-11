# دليل macOS {#macos-tutorial}

## خيار سطر واحد {#one-line-option}

يقوم الإعداد الأولي الاختياري للـ sponsor بتثبيت macFUSE عند الحاجة، وتنزيل نسخة Intel أو Apple silicon، وتشغيل
أداة اختيار المزوّد والتشخيصات:

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```

يستخدم تسجيل الدخول عبر المتصفح في GitHub. قد يحتاج macOS مع ذلك إلى موافقتك من **System Settings > Privacy & Security**، وربما إلى إعادة تشغيل للجهاز. تبقى الملفات التنفيذية والإعدادات الموجودة كما هي. تابع أدناه للطريقة اليدوية.

## الخطوة 1: تثبيت macFUSE {#step-1-install-macfuse}

تُتيح لك macFUSE أن يركّب rclone نظام الملفات الافتراضي الخاص بـ zurg كمجلد حقيقي على جهاز Mac.

1. نزّل أحدث ملف `.dmg` من [macfuse.io](https://macfuse.io)
2. افتح ملف `.dmg` وشغّل برنامج التثبيت
3. أثناء التثبيت، سيمنع macOS امتداد النظام. اذهب إلى **System Settings > Privacy & Security**، وانزل للأسفل، ثم اضغط **Allow**
4. **أعد تشغيل جهاز Mac** (ضروري حتى يتحمّل امتداد النواة)

بعد إعادة التشغيل، افتح **Terminal** (اضغط `Cmd + Space` واكتب "Terminal" ثم اضغط Enter)، وتحقّق من أن macOS سيحمّل macFUSE. وهذا هو الفحص نفسه الذي يجريه `zurg setup`:

```bash
/Library/Filesystems/macfuse.fs/Contents/Resources/load_macfuse && echo "macFUSE is ready"
```

إذا لم تظهر الرسالة `macFUSE is ready`، فهذا يعني أن macOS لم يسمح بالامتداد بعد. على أجهزة Apple silicon، فعّل امتدادات النواة من طرف ثالث من وضع Recovery، ثم اسمح بـ macFUSE من **System Settings > Privacy & Security**، وبعدها أعد التشغيل وتحقّق مرة أخرى.

## الخطوة 2: تنزيل zurg {#step-2-download-zurg}

افتح [GitHub Releases](https://github.com/debridmediamanager/zurg/releases) في متصفح مسجّل الدخول فيه إلى حساب GitHub الذي له صلاحية الوصول إلى zurg. خذ أحدث نسخة ليلية، وهي الإصدار التجريبي المسبق الموجود في أعلى القائمة. نزّل ملف zip الخاص بها `darwin-arm64`، أو `darwin-amd64` إذا كان جهازك Intel Mac.

لا تأخذ الإصدار الذي يضع عليه GitHub علامة **Latest**. فهذا هو v1.0.0، وهو أقدم من `zurg setup` ويرد عليه بالخطأ `unknown command`.

النسخ الليلية مخصّصة للداعمين. وقبل أن يحصل حساب GitHub الخاص بك على الصلاحية، ستعرض تلك الصفحة الخطأ 404. ادعم عبر [gatekeeper](https://gatekeeper.debridmediamanager.com/) لتحصل على الصلاحية.

النسخة العامة المجانية هي v1.0.0 من [zurg-public](https://github.com/debridmediamanager/zurg-public/releases). لا تحتوي على `zurg setup`. قم بإعدادها يدوياً كما يشرح [ملف README الخاص بها](https://github.com/debridmediamanager/zurg-public#readme)، بدلاً من اتباع الخطوات أدناه.

ثم فك ضغط الملف.

```bash
mkdir -p ~/zurg && cd ~/zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
```

للتحقق:

```bash
./zurg version
```

## موصى به: دع zurg يُكمل الإعداد {#recommended-let-zurg-finish-the-setup}

من المجلد المستخرج، شغّل:

```bash
./zurg setup
./zurg doctor
```

يسألك `setup` عن المزودين الذين تريد إعدادهم. اختر واحدًا أو أكثر من Real-Debrid وTorBox وAllDebrid وUsenet وPremiumize وDebrid-Link وOffcloud، بالترتيب حسب الأولوية. مثلًا، أدخل `2,4` لاختيار TorBox ثم Usenet. يطلب فقط بيانات الاعتماد التي اخترتها، وينشئ ملف `config.yml` بالصلاحية `0600`، وينزّل rclone (وffprobe، إلا إذا كان موجودًا مسبقًا في PATH لديك)، ويجهّز `/Volumes/Zurg` ويثبّت التشغيل التلقائي.

يختار الأمر LaunchAgent إذا كان المستخدم الحالي لديه نطاق launchd للواجهة الرسومية (GUI). أما على جهاز Mac بدون واجهة رسومية ولا يوجد مستخدم مسجل دخوله إليها، فيثبّت LaunchDaemon على مستوى النظام، ولا يزال يشغّل zurg بصفته المستخدم الحالي. هذا المسار لا يتطلب تسجيل الدخول التلقائي.

يميّز فحص المتطلبات المسبقة بين حزمة macFUSE المثبتة وبين الإضافة (extension) التي يستطيع macOS تحميلها فعليًا. على شرائح Apple silicon، قد يتطلب أول تثبيت لـ macFUSE تغييرًا لمرة واحدة في إعدادات الأمان من Recovery، والموافقة من **System Settings > Privacy & Security**، ثم إعادة تشغيل الجهاز. لا يستطيع أي مثبّت تجاوز هذه التأكيدات.

يمكنك تشغيل setup أكثر من مرة بأمان. يحدّث خدمة launchd المولّدة، لكنه لا يستبدل ملف `config.yml` الموجود.

قبل البث عبر الـ mount، افتح `config.yml` أو Dashboard على العنوان `http://localhost:9999/config/` واضبط كلًا من `--vfs-cache-max-size` و`--vfs-cache-min-free-space` ضمن `rclone_extra_args`. اجعل الحد الأقصى أقل من نصف المساحة الحرة حاليًا على القرص، واحجز على الأقل `20G` باستخدام إعداد الحد الأدنى للمساحة الحرة. ثم شغّل `./zurg service restart`.

بقية هذه الصفحة تشرح إعداد الملف والربط مع Plex. الخطوات 3 و4 و5 و7 هي البديل اليدوي، ويمكن تجاهلها بعد أن ينجح `zurg setup`.

## الخطوة 3: إعداد zurg يدويًا {#step-3-configure-zurg-manually}

أنشئ ملف إعدادات يحتوي على رمز API الخاص بك من Real-Debrid:

```bash
cd ~/zurg
cat > config.yml << 'EOF'
# Minimal config - use Dashboard at http://localhost:9999/config/ for more settings
zurg: v1
providers:
  - type: realdebrid
    token: YOUR_RD_API_TOKEN_HERE

rclone_enabled: true
mount_path: /Volumes/Zurg

rclone_extra_args:
  - "--vfs-cache-max-size"
  - "100G"
  - "--vfs-cache-min-free-space"
  - "20G"

directories:
  shows:
    group: media
    group_order: 10
    filters:
      - has_episodes: true
  movies:
    group: media
    group_order: 20
    only_show_the_biggest_file: true
EOF
```

استبدل الرمز التجريبي برمزك الفعلي من [real-debrid.com/apitoken](http://real-debrid.com/?id=20476354):

```bash
sed -i '' "s|YOUR_RD_API_TOKEN_HERE|PASTE_YOUR_TOKEN_HERE|g" ~/zurg/config.yml
```

> **لا تحذف `mount_path`.** سيستخدم rclone المسار `/Volumes/Zurg` على macOS إذا لم تحدده، لكن فحص خادم الوسائط لا يعمل إلا عندما يتم تعيين `mount_path` صراحةً. إذا تركته، فلن يُرسل أي تنبيه إلى Plex لتحديث المكتبة (الخطوة 6).

> **حجم الذاكرة المؤقتة مهم جدًا.** تخزّن ذاكرة VFS المؤقتة أجزاءً من الملفات المبثوثة على قرصك المحلي. إذا امتلأ القرص، سينخفض أداء macOS بشكل كبير، وقد يتوقف Spotlight وPlex بل وحتى النظام نفسه عن الاستجابة. اضبط **الحدّين** دائمًا:
>
> - `--vfs-cache-max-size` — الحد الأقصى الثابت لإجمالي حجم الذاكرة المؤقتة. اضبطه على **50% من المساحة الحرة على قرصك كحد أقصى**. تحقق من ذلك باستخدام `df -h /`.
> - `--vfs-cache-min-free-space` — يوقف التخزين المؤقت عندما تنخفض المساحة الحرة عن هذا الحد. أبقِه عند **20G أو أكثر** كشبكة أمان.
>
> على سبيل المثال، إذا كان لديك قرص سعته 256GB ومساحته الحرة 100GB، فاستخدم `50G` للحد الأقصى للحجم و`20G` للحد الأدنى للمساحة الحرة.

## الخطوة 4: تنزيل المتطلبات يدويًا {#step-4-download-dependencies-manually}

يحتوي zurg على أمر مدمج يقوم بتنزيل rclone وffprobe ويحدّث `config.yml` بمساراتهما:

```bash
cd ~/zurg
./zurg download-requirements
```

أنشئ نقطة التركيب ومجلد السجلات. المجلد `/Volumes` مملوك لـ root، لذا لا يستطيع zurg إنشاء `/Volumes/Zurg` بنفسه. ويجب أن يكون مجلد السجلات موجودًا قبل أن يفتح launchd ملفات المخرجات الخاصة به في الخطوة 7:

```bash
sudo mkdir -p /Volumes/Zurg
sudo chown "$(whoami)" /Volumes/Zurg
mkdir -p ~/zurg/logs
```

راجع [مرجع الإعدادات](../reference/config.md) للاطلاع على جميع الخيارات المتاحة، أو استخدم لوحة Dashboard على الويب عبر `http://localhost:9999/config/` بعد تشغيل zurg.

## الخطوة 5: اختبار zurg يدويًا {#step-5-test-zurg-manually}

قبل إعداد التشغيل التلقائي، تحقّق من أن كل شيء يعمل:

```bash
cd ~/zurg && ./zurg
```

يجب أن ترى مخرجات سجل تُظهر بدء تشغيل zurg، والاتصال بـ Real-Debrid، والتركيب عبر rclone. في نافذة طرفية أخرى، تحقّق من ذلك:

```bash
# Check the HTTP endpoint
curl -s http://localhost:9999/http/version.txt

# Check the mount
ls /Volumes/Zurg/
# Expected: __all__  __downloads__  __unplayable__  movies  shows  version.txt
```

إذا بدا كل شيء سليمًا، أوقف zurg بالضغط على `Ctrl+C`.

## الخطوة 6: تثبيت Plex Media Server {#step-6-install-plex-media-server}

1. نزّل من [plex.tv/media-server-downloads](https://www.plex.tv/media-server-downloads/) واختر **macOS** (Universal)
2. افتح ملف `.dmg` واسحب **Plex Media Server** إلى `/Applications`
3. شغّل Plex Media Server من مجلد Applications (أو من Spotlight: `Cmd + Space` ثم اكتب "Plex Media Server")
4. يفترض أن يفتح متصفحك معالج إعداد Plex. اتبع خطواته لربط الخادم بحسابك
5. **فعّل التشغيل التلقائي:** انقر بزر الفأرة الأيمن على أيقونة Plex في شريط القوائم واختر **Launch at Login**
6. احصل على رمز Plex (Plex token)، وأسهل طريقة هي:
   - افتح أي عنصر وسائط في Plex Web
   - انقر **Get Info** (أو **...** ثم **Get Info**)
   - انقر **View XML**
   - ابحث عن `X-Plex-Token=` في شريط العنوان

أضف رمز Plex إلى إعدادات zurg بتعديل ملف `config.yml`:

```yaml
plex_server_url: http://localhost:32400
plex_token: YOUR_PLEX_TOKEN
```

## الخطوة 7: إعداد التشغيل التلقائي لـ zurg يدويًا {#step-7-set-up-zurg-auto-start-manually}

macOS LaunchAgents تشغّل الخدمات تلقائياً عند تسجيل الدخول. Plex يتولى التشغيل التلقائي بنفسه بالفعل (الخطوة 6)، لذلك نحتاج إلى LaunchAgent لـ zurg فقط.

### LaunchAgent الخاص بـ zurg {#zurg-launchagent}

```bash
cat > ~/Library/LaunchAgents/com.zurg.plist << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.zurg</string>

    <key>ProgramArguments</key>
    <array>
        <string>${HOME}/zurg/zurg</string>
    </array>

    <key>WorkingDirectory</key>
    <string>${HOME}/zurg</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>StandardOutPath</key>
    <string>${HOME}/zurg/logs/launchd-stdout.log</string>

    <key>StandardErrorPath</key>
    <string>${HOME}/zurg/logs/launchd-stderr.log</string>

    <key>ThrottleInterval</key>
    <integer>10</integer>
</dict>
</plist>
PLIST
```

الإعدادات الأساسية:
- **RunAtLoad** — يشغّل zurg تلقائياً عند تسجيل الدخول
- **KeepAlive / SuccessfulExit: false** — إذا توقف zurg بسبب عطل، يعيد launchd تشغيله تلقائياً
- **ThrottleInterval: 10** — ينتظر 10 ثوانٍ بين محاولات إعادة التشغيل

### تحميل LaunchAgent {#load-the-launchagent}

```bash
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

تحقّق من أنه مُسجَّل:

```bash
launchctl list | grep zurg
# Should show com.zurg with a PID
```

## الخطوة 8: إعداد مكتبات Plex {#step-8-configure-plex-libraries}

Now que zurg está en marcha y el montaje está activo:

1. Abre [http://localhost:32400/web](http://localhost:32400/web)
2. Ve a **Settings** (icono de llave inglesa) → **Manage** → **Libraries**
3. Haz clic en **Add Library**

**Añade la biblioteca de películas:**
- Type: **Movies**
- Haz clic en **Browse for media folder**
- Navega hasta `/Volumes/Zurg/movies`
- Haz clic en **Add Library**

**Añade la biblioteca de series:**
- Type: **TV Shows**
- Haz clic en **Browse for media folder**
- Navega hasta `/Volumes/Zurg/shows`
- Haz clic en **Add Library**

**Ajustes recomendados de la biblioteca** (en Edit → Advanced de cada biblioteca):
- Desmarca **Empty trash automatically after every scan**. zurg se encarga del ciclo de vida del contenido.
- Desmarca **Generate video preview thumbnails**. Así ahorras ancho de banda, porque los archivos se transmiten desde Real-Debrid.

## الخطوة 9: التحقق من أن كل شيء يعمل {#step-9-verify-everything-works}

```bash
# 1. zurg is running
curl -s http://localhost:9999/http/version.txt && echo " - zurg is up"

# 2. Mount is active
ls /Volumes/Zurg/movies > /dev/null 2>&1 && echo "Mount is active"

# 3. Plex is running
curl -s -o /dev/null -w "%{http_code}" http://localhost:32400/identity && echo " - Plex is up"

# 4. Processes
ps -eo pid,command | grep -E "[z]urg|[r]clone.*mount|[P]lex Media Server" | head -5

# 5. zurg service (for the manual LaunchAgent from Step 7: launchctl list | grep com.zurg)
cd ~/zurg && ./zurg service status
```

## الخطوة 10: تفعيل تسجيل الدخول التلقائي (اختياري) {#step-10-enable-auto-login-optional}

هذا مطلوب فقط لمسار LaunchAgent اليدوي. يحتاج LaunchAgent إلى أن يسجّل المستخدم الدخول بعد كل إعادة تشغيل. أما المثبّت المدمج فيستخدم LaunchDaemon على جهاز Mac بلا شاشة.

إذا اخترت عمدًا استخدام LaunchAgent اليدوي على خادم بلا شاشة، فَفعّل تسجيل الدخول التلقائي كي يبدأ بدون تدخل:

1. افتح **System Settings**
2. انتقل إلى **Users & Groups**
3. انقر على **Automatic login** واختر حسابك
4. أدخل كلمة المرور الخاصة بك

> **ملاحظة أمنية:** تسجيل الدخول التلقائي يعني أن أي شخص يملك وصولًا فعليًا إلى جهاز Mac يستطيع الوصول إلى حسابك. استخدم هذا فقط على أجهزة موجودة في مكان موثوق.

---

## إدارة الخدمات {#managing-the-services}

لتثبيت أُنشئ عبر `zurg setup`، استخدم الأوامر نفسها على كل المنصات:

```bash
cd ~/zurg
./zurg service status
./zurg service restart
./zurg service stop
./zurg service start
./zurg service uninstall
```

يُزيل `uninstall` التشغيل التلقائي فقط، ويترك الملف التنفيذي والإعدادات والبيانات وملفات السجلات والذاكرة المؤقتة في مكانها. أوامر launchctl أدناه مخصصة لـ LaunchAgent اليدوي من الخطوة 7 (`com.zurg`). أما `zurg setup` فيُسمّي الملف الخاص به `com.zurg.zurg`.

### بدء / إيقاف / إعادة تشغيل {#start--stop--restart}

```bash
# Stop zurg (and its rclone child process)
launchctl stop com.zurg

# Start zurg
launchctl start com.zurg

# Restart zurg
launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### عرض السجلات {#view-logs}

```bash
# zurg logs
tail -50 ~/zurg/logs/zurg.log

# Rclone logs
tail -50 ~/zurg/logs/rclone.log
```

### إعادة التحميل بعد تغيير الإعدادات {#reload-after-config-change}

إذا عدّلت ملف `.plist`:

```bash
launchctl unload ~/Library/LaunchAgents/com.zurg.plist
launchctl load ~/Library/LaunchAgents/com.zurg.plist
```

إذا عدّلت `config.yml`، فقط أعد تشغيل zurg:

```bash
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### تحديث zurg {#update-zurg}

تُحدِّث نسخة الرعاة نفسها بهذا الأمر:

```bash
cd ~/zurg
./zurg update
./zurg service restart
```

يأخذ `update` أحدث نسخة nightly. يحمّلها، ويتحقق من أن الملف الثنائي الجديد يُبلغ عن الإصدار المتوقع، ثم يستبدله بعملية إعادة تسمية (rename)، فلا يُكتب فوق العملية الجارية أبدًا. وإذا كانت النسخة المثبّتة هي الأحدث بالفعل، يُخبرك بذلك ولا يغيّر أي شيء.

يسجّل `update` الدخول إلى GitHub بالحساب الذي استخدمته في التثبيت. ويحتفظ المثبّت بـ GitHub CLI في `~/zurg/bin` لهذا الغرض. إذا قال `update` إنه لم يجد أي بيانات اعتماد لـ GitHub، فمعنى ذلك أن تثبيتك أقدم من هذا التغيير. شغّل تحديث المثبّت مرة واحدة، وبعدها يعمل كل أمر `zurg update` بشكل صحيح. ويمكن للأمر نفسه أيضًا تحديث نسخة قديمة جدًا لا تحتوي على `zurg update`.

```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash -s update
```

يمكنك أيضًا ضبط `GITHUB_TOKEN` بدلًا من ذلك. استخدم classic token مع النطاق `repo` من حساب GitHub الذي له صلاحية الوصول إلى zurg.

للتحديث يدويًا، حمّل ملف zip الجديد `darwin-arm64` (أو `darwin-amd64` على جهاز Mac بمعالج Intel) من [الإصدارات](https://github.com/debridmediamanager/zurg/releases) بالطريقة نفسها كما في الخطوة 2، ثم:

```bash
cd ~/zurg
./zurg service stop && sleep 2     # manual LaunchAgent: launchctl stop com.zurg
rm -f zurg
unzip -o ~/Downloads/zurg-*-darwin-arm64.zip   # on an Intel Mac: zurg-*-darwin-amd64.zip
chmod +x zurg
./zurg service start               # manual LaunchAgent: launchctl start com.zurg
```

احذف الملف الثنائي القديم بدلًا من الكتابة فوقه في مكانه. فإعادة كتابة الملف تُبقي الـ inode نفسه وتُبطل توقيع الكود ad-hoc الخاص به، فيقتل macOS النسخة الجديدة عند التشغيل، والعَرَض هو خروج فوري بدون أي مخرجات إطلاقًا. ولهذا السبب بالذات يستبدل `zurg update` الملف بإعادة التسمية.

## استكشاف الأخطاء وإصلاحها {#troubleshooting}

### "Operation not permitted" عند التركيب {#operation-not-permitted-when-mounting}

macFUSE يحتاج إلى موافقة في System Settings:
1. اذهب إلى **System Settings > Privacy & Security**
2. انزل إلى الأسفل وابحث عن رسالة بخصوص system extension محظور
3. اضغط **Allow**، ثم **reboot**

### يظهر التركيب كـ "not a directory" أو يتوقف {#mount-shows-as-not-a-directory-or-hangs}

قد تكون نقطة التركيب عالقة من تعطل سابق:

```bash
umount -f /Volumes/Zurg 2>/dev/null
diskutil unmount force /Volumes/Zurg 2>/dev/null
cd ~/zurg && ./zurg service restart
# manual LaunchAgent: launchctl stop com.zurg && sleep 2 && launchctl start com.zurg
```

### zurg يعيد التشغيل باستمرار (حلقة تعطل) {#zurg-keeps-restarting-crash-loop}

تحقق من السجلات بحثاً عن الخطأ:

```bash
tail -100 ~/zurg/logs/service-stderr.log   # manual LaunchAgent: launchd-stderr.log
```

الأسباب الشائعة:
- صيغة `config.yml` غير صحيحة. تحقق منها بتشغيل `cd ~/zurg && ./zurg` يدوياً
- انتهت صلاحية رمز Real-Debrid. احصل على رمز جديد من [real-debrid.com/apitoken](http://real-debrid.com/?id=20476410)
- المجلد `/Volumes/Zurg` غير موجود أو ليس مملوكاً لمستخدمك. لا يستطيع zurg إنشاءه، فيفشل مع `ensure mount path: permission denied` (الخطوة 4)
- المنفذ 9999 مستخدم بالفعل. تحقق منه باستخدام `lsof -i :9999`

### macFUSE يتعطل بعد تحديث macOS {#macfuse-breaks-after-macos-update}

قد تُبطل تحديثات macOS الكبيرة أحيانًا امتداد النواة (kernel extension). أعد تثبيت macFUSE:
1. نزّل أحدث إصدار من [macfuse.io](https://macfuse.io)
2. ثبّته
3. وافق على الامتداد من **System Settings > Privacy & Security**
4. أعد تشغيل الجهاز

### كان كل شيء يعمل لكنه توقف بعد إعادة التشغيل {#everything-was-working-but-stopped-after-reboot}

إذا ثبّتَّ LaunchAgent يدويًا ولم يكن تسجيل الدخول التلقائي مفعّلًا، فيجب أن تسجّل الدخول قبل أن يبدأ. يمكنك أن تفعل أحد هذه الأمور:

- فعّل تسجيل الدخول التلقائي (راجع الخطوة 10)
- اتصل عبر SSH؛ فستكون LaunchAgents محمّلة بالفعل بمجرد وجود جلسة المستخدم
- استخدم VNC/Screen Sharing لتسجيل الدخول عن بُعد

أما التثبيت الذي ينشئه `zurg setup` على جهاز Mac بلا شاشة، فيستخدم LaunchDaemon ولا يحتاج إلى تسجيل دخول عبر الواجهة الرسومية. تحقّق من ذلك بتشغيل `cd ~/zurg && ./zurg service status`.

ما زلت عالقًا؟ اسأل في منتدى **zurg-support** على [Discord](https://discord.com/invite/7u4YjMThXP). يشرح [Getting help](../../guides/remote-help.md) ما يجب تضمينه.

## نظرة عامة على البنية {#architecture-overview}

```
launchd (PID 1)

  com.zurg LaunchAgent
    └── ./zurg
          ├── HTTP/WebDAV server (:9999)
          ├── Dashboard UI (:9999/config/)
          ├── Real-Debrid API client
          └── rclone mount (child process)
                └── /Volumes/Zurg/
                      ├── movies/
                      └── shows/

  Plex Media Server (:32400)  — Launch at Login via menu bar
    ├── Movies library  → /Volumes/Zurg/movies
    └── Shows library   → /Volumes/Zurg/shows

  macFUSE kernel extension
    └── Enables FUSE mounts for rclone
```

## مرجع سريع {#quick-reference}

شغّل هذه الأوامر داخل `~/zurg`. سطور `zurg service` مخصصة للتثبيت الذي أنشأه `zurg setup`. أما LaunchAgent اليدوي فيستخدم أوامر launchctl الموجودة في [إدارة الخدمات](#managing-the-services).

| الإجراء | الأمر |
|--------|---------|
| تشغيل zurg | `./zurg service start` |
| إيقاف zurg | `./zurg service stop` |
| إعادة تشغيل zurg | `./zurg service restart` |
| التحقق من التثبيت | `./zurg doctor` |
| إزالة التشغيل التلقائي | `./zurg service uninstall` |
| عرض سجلات zurg | `tail -f ~/zurg/logs/zurg.log` |
| عرض سجلات rclone | `tail -f ~/zurg/logs/rclone.log` |
| التحقق من نقطة التركيب | `ls /Volumes/Zurg/` |
| التحقق من صحة zurg | `curl http://localhost:9999/http/version.txt` |
| التحقق من صحة Plex | `curl http://localhost:32400/identity` |
| لوحة التحكم | `open http://localhost:9999/config/` |
| فرض إلغاء التركيب | `umount -f /Volumes/Zurg` |
