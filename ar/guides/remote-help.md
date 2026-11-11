# الحصول على المساعدة في zurg وrex {#getting-help-with-zurg-and-rex}

## اسأل في Discord {#ask-in-discord}

انشر في منتدى [Discord](https://discord.com/invite/7u4YjMThXP) الخاص بالأداة التي تستخدمها: **zurg-support** أو **rex-support** أو **dmm-support**. افتح موضوعًا منفصلًا لكل مشكلة. اذكر ما فعلته، وما كنت تتوقعه، وما حدث فعلًا. وأضف التفاصيل التالية.

**بالنسبة إلى zurg**، انقر على **Export Logs** في لوحة zurg، والصق الروابط التي يعطيها لك. فهو يرفع سجل zurg وملف إعداداته بعد حذف الرموز المميزة وكلمات المرور ومفاتيح API منهما. إذا تعذّر الرفع، فإن **Download Logs** يعطيك الشيء نفسه كملف لترفقه. والصق أيضًا ناتج الأمر `zurg doctor`:

| يعمل zurg كـ | شغّل |
|---|---|
| الملف التنفيذي على Linux أو macOS | `./zurg doctor` داخل مجلد zurg |
| الملف التنفيذي على Windows | `.\zurg.exe doctor` داخل مجلد zurg |
| Docker | `docker compose exec zurg /app/zurg doctor --working-dir /config` |

**بالنسبة إلى rex**، اضغط **Play** مرة واحدة على العنصر الذي يفشل، ثم الصق نهاية سجل rex. يخفي rex رموز Plex في السجل.

| يعمل rex كـ | شغّل |
|---|---|
| خدمة systemd على Linux | `journalctl --user -u rex -n 200 --no-pager` |
| launchd على macOS | `tail -n 200 ~/rex/rex.log` |
| Task Scheduler على Windows | `Get-Content $HOME\rex\rex.log -Tail 200` |
| Docker | `docker compose logs --tail=200 rex` |
| نافذة طرفية | آخر 200 سطر في تلك النافذة |

في السجل الطويل، أهم الأسطر هي الأخطاء والتحذيرات وما قرره rex لكل عملية تشغيل. أضف `| grep -E 'ERROR|WARN|upstream|DECISION'` إلى سطر Linux أو macOS أو Docker لعرض هذه الأسطر فقط. أما على Windows فشغّل `Select-String 'ERROR|WARN|upstream|DECISION' $HOME\rex\rex.log | Select-Object -Last 50`.

## المساعدة عن بُعد للرعاة {#remote-help-for-sponsors}

إذا لم يحلّ الموضوع المشكلة، يمكن لأحد المساعدين أن يكتب في الطرفية الخاصة بك بينما تراقب أنت. **المساعدة عن بُعد لـ zurg وrex متاحة للرعاة ومجانية.** [كن راعيًا على gatekeeper](https://gatekeeper.debridmediamanager.com/). اربط Discord هناك للحصول على رتبة الراعي، ثم اسأل في موضوع الدعم الخاص بك.

تشرح هذه الصفحة طريقة إعداد ذلك باستخدام [upterm](https://github.com/owenthereal/upterm) عبر `upterm.debridmediamanager.com`. تعمل على Linux وmacOS وWindows.

لا تحتاج إلى حساب أو كلمة مرور أو تغيير في الراوتر أو تثبيت مسبق. تقوم الأوامر بتنزيل upterm وتشغيله. راقب كل أمر في الطرفية نفسها. اكتب `exit` لإنهاء الجلسة.

### 1. اختر الجهاز {#1-pick-the-machine}

شغّل upterm على الجهاز الذي يشغّل zurg أو rex. قد يكون هذا خادماً وليس الكمبيوتر أمامك.

| مكان التشغيل | ما الذي تفعله |
|---|---|
| هذا الكمبيوتر | افتح طرفية هنا وانتقل إلى الخطوة 2. |
| خادم سحابي مثل Hetzner أو Oracle أو VPS | ادخل إليه عبر SSH أولاً. ثم استخدم سطر Linux في الخطوة 2 داخل نافذة SSH هذه. |
| NAS أو خادم منزلي مثل Synology أو Unraid | افتح الطرفية الخاصة به. ثم استخدم سطر Linux في الخطوة 2 هناك. |
| Docker | استخدم الجهاز الذي يشغّل Docker وليس الحاوية. |

يمكنك استخدام SSH من Windows أيضاً. يحتوي PowerShell على أمر `ssh` مدمج.

```bash
ssh you@your-server
```

**Synology** يكون SSH متوقفاً افتراضياً. فعّله من Control Panel > Terminal & SNMP > Enable SSH service. ثم سجّل الدخول بحساب مسؤول. استخدم عنوان NAS من جهاز الراوتر أو من Synology Assistant.

إذا ظهرت في الخطوة 2 الرسالة `cannot create directory` على Synology، فشغّل Control Panel > User & Group > Advanced > Enable user home service ثم أعد التشغيل.

**Unraid** فيه طرفية داخل صفحته على الويب. انقر على الأيقونة `>_` في أعلى اليمين.

### 2. ابدأ جلسة {#2-start-a-session}

لصق السطر الخاص بالنظام الذي اخترته في الخطوة 1.

#### Linux وmacOS {#linux-and-macos}

```bash
mkdir -p ~/upterm && cd ~/upterm && curl -fsSL "https://github.com/owenthereal/upterm/releases/latest/download/upterm_$(uname -s | tr A-Z a-z)_$(uname -m | sed 's/x86_64/amd64/;s/aarch64/arm64/;s/armv7l/armv6/').tar.gz" | tar -xz && ./upterm host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

#### Windows

افتح PowerShell. لا يلزم تشغيله كمسؤول.

```powershell
$d = "$env:LOCALAPPDATA\upterm"; New-Item -ItemType Directory -Force $d | Out-Null; Invoke-WebRequest https://github.com/owenthereal/upterm/releases/latest/download/upterm_windows_amd64.tar.gz -OutFile "$d\upterm.tar.gz" -UseBasicParsing; tar -xzf "$d\upterm.tar.gz" -C $d; & "$d\upterm.exe" host --server ssh://upterm.debridmediamanager.com:2222 --accept
```

على لابتوب ARM مثل Surface Pro X، استبدل `amd64` بـ `arm64`.

في المرة الأولى، يسألك upterm إن كنت تريد أن تثق في `upterm.debridmediamanager.com`. اكتب `yes`. يجب أن تكون البصمة التي يعرضها هي هذه.

```
SHA256:r1LtSiydnfetLGxGt8hy+ULyqtN2KgnZSHtRgHzDr58
```

### 3. أرسل سطر SSH إلى المساعد لديك {#3-send-the-ssh-line-to-your-helper}

upterm يطبع بضعة أسطر. انسخ السطر الموجود تحت **SSH**، وهو يبدو هكذا.

```
ssh AbCdEfGhIjKlMnOpQrSt:dXB0ZXJt...@upterm.debridmediamanager.com -p 2222
```

**أرسله في رسالة خاصة.** لا تنشره أبدًا في قناة عامة. أي شخص يملكه يستطيع الكتابة على جهازك.

ثم اترك النافذة مفتوحة ولا تنقر داخلها. على Windows، النقر داخل نافذة PowerShell قد يوقف ما يعمل فيها مؤقتًا حتى تضغط `Esc`. ترى كل ما يكتبه مساعدك في تلك النافذة أثناء كتابته.

### 4. أنهِ الجلسة {#4-end-it}

**اكتب `exit` في تلك النافذة عندما تنتهي.** تنتهي الجلسة ويتوقف الرابط عن العمل فورًا.

إغلاق النافذة لا يكفي، فالجلسة تبقى تعمل. إذا أغلقتها، افتح تيرمينال جديدًا وشغّل `~/upterm/upterm session list` (على ويندوز `& "$env:LOCALAPPDATA\upterm\upterm.exe" session list`)، ثم البرنامج نفسه مع `session stop` والاسم الذي يظهر لك.

للحصول على المساعدة مرة أخرى لاحقًا، الصق السطر من الخطوة 2 من جديد. كل جلسة تحصل على سطر جديد.

## للمساعدين {#for-helpers}

شغّل أمر SSH الذي أُرسل إليك. أي مفتاح SSH يعمل. إذا لم يكن لديك مفتاح، شغّل `ssh-keygen -t ed25519` مرة واحدة أولاً. ستصل إلى الطرفية الخاصة بهم: PowerShell على Windows، والصدفة المعتادة لديهم على Linux وmacOS.

لنسخ ملف، يربك الرمز `:` الموجود في معرّف الجلسة الأمرَ `scp`، لذا مرّره كاسم المستخدم بدلاً من ذلك: `scp -P 2222 -o User=<everything before the @> file upterm.debridmediamanager.com:file`.

اطلب منهم كتابة `exit` عند الانتهاء.
