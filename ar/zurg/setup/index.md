# الإعداد {#setup}

ثبّت الطريقة الأسرع على Linux وmacOS وWindows هي مُثبِّت الملف الثنائي (binary installer). يبقى Docker متاحًا على مضيف Linux عندما تكون الحاوية أنسب. أما Docker Desktop على macOS وWindows فيشغّل الحاويات داخل VM، لذلك لا يمكن أن يظهر الجبل (mount) في Finder أو Explorer، ولا يستطيع rex الوصول إلى zurg. استخدم الملف الثنائي هناك.

## مُثبِّتات بسطر أوامر واحد للراحة {#one-line-convenience-installers}

تقوم برامج التثبيت بتنزيل الإصدار الليلي الخاص بالرعاة. كن راعياً على [gatekeeper](https://gatekeeper.debridmediamanager.com/) أولاً. يمنح ذلك حسابك على GitHub الوصول.

لتثبيت جديد للراعي، اختر الأمر المناسب لجهازك:

+++ Linux و macOS
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.sh | bash
```
+++ Docker على Linux
```bash
curl -fsSL https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install-docker.sh | bash
```
+++ Windows
في PowerShell:
```powershell
irm https://raw.githubusercontent.com/debridmediamanager/zurg-site/main/public/install.ps1 | iex
```
+++

يتحقق برنامج التهيئة من متطلبات النظام، ويسجل الدخول إلى GitHub للتحقق من صلاحية الراعي، ثم ينزل النسخة المناسبة ويشغل أداة اختيار المزود. الملفات التنفيذية والإعدادات الموجودة تبقى كما هي. كل دليل أدناه يشرح أيضاً الطريقة اليدوية الكاملة.

- [Linux](linux.md)
- [Docker](docker.md) (مضيفات Linux)
- [macOS](macos.md)
- [Windows](windows.md)

بعد تثبيت zurg، تشرح صفحة [Providers](../providers/index.md) كيفية ربطه بحساب.
توجد صفحة لكل خدمة فيها بيانات الاعتماد وإدخال `config.yml` وما تفعله تلك الخدمة بشكل مختلف. كُتبت هذه الصفحات لـ Docker. في التثبيت بالملف التنفيذي، يكون إدخال `config.yml` للمزود وخطوات Dashboard هي نفسها، لكن `./zurg service restart` (`.\zurg.exe service restart` على Windows) يحل محل `docker compose restart zurg`، وسطر `docker compose run --rm zurg setup` يصبح `./zurg setup` (`.\zurg.exe setup` على Windows) مع نفس الخيارات، ما عدا `--no-service --skip-downloads --mount-path /zurg_mnt/zurg` الخاصة بالحاوية. وخيار `--…-file` يشير بعد ذلك إلى ملف على جهازك بدلاً من ملف موجود تحت `/config`.
