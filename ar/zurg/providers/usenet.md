# Usenet

`type: nzb`

Usenet ليس مزود نوع debrid، بل هو نوع مزود مختلف. لا يوجد API token ولا مكتبة بعيدة. تضع ملفات `.nzb` في مجلد المراقبة (watch directory)، فيحوّل zurg كل ملف منها إلى release. تُجلب المقالات (articles) من خادم الأخبار الخاص بك وتُفكّ شفرتها في اللحظة التي يطلب فيها المشغّل تلك البايتات.

تتناول هذه الصفحة إعداد مزود Usenet وخصائص Docker فقط. كل ما عدا ذلك المتعلق بتشغيل Usenet على zurg موجود في [Usenet مع zurg](../guides/usenet.md). هذا هو الدليل الكامل، ويشرح حسابات الأخبار وملفات NZB والتركيب (mount) وPlex. اقرأه بعد هذه الصفحة.

## إعداده {#configure-it}

لا يوجد `token`. ما يجعل الإدخال صالحاً هو كتلة `nntp` فيها host.

```yaml
zurg: v1
providers:
  - type: nzb
    nntp:
      host: news.example.com
      port: 563
      tls: true
      username: YOUR_USENET_USERNAME
      password: YOUR_USENET_PASSWORD
      connections: 8
      cache_size_mb: 512
mount_path: "/zurg_mnt/zurg"
```

اضبط `connections` على العدد الذي تسمح به خطتك فعلياً. يقرأ zurg بهذا العدد
لأن الاتصال الواحد لا يحمل إلا جزءاً من سرعة الخطة. البث يستهلك كامل المسموح به
بدلاً من جلب مقالة واحدة في كل مرة. تجاوز ما تسمح به الخطة يعني أن الاتصالات ستُرفض.

في التثبيت الجديد داخل الحاوية، سيطلب منك الإعداد كل ذلك.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb
```

في التثبيت غير التفاعلي تأتي كلمة المرور من ملف، ويأتي كل شيء آخر من flags.

```bash
docker compose run --rm zurg setup --non-interactive \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider nzb \
  --nntp-host news.example.com \
  --nntp-username YOUR_USENET_USERNAME \
  --nntp-password-file /config/secrets/nntp \
  --nntp-connections 8
```

القيمة الافتراضية لـ `--nntp-tls` هي true، والقيمة الافتراضية لـ `--nntp-port` هي 563 مع TLS أو 119
بدونه.

في تثبيت يحتوي على `config.yml` مسبقاً، استخدم **Add provider** في
Dashboard على `http://localhost:9999/config/` أو عدّل الملف. أعد التشغيل في الحالتين.

```bash
docker compose restart zurg
```

## المكان الذي تُحفظ فيه ملفات NZB داخل الحاوية {#where-the-nzbs-go-in-a-container}

يبدأ مجلد المراقبة من `nzbs/` بجانب ملف الإعداد. أي إنه `~/zurg/nzbs/` على الجهاز المضيف و`/config/nzbs/` داخل الحاوية. وهما المجلد نفسه، so ضع الملفات من الجهاز المضيف.

```bash
mkdir -p ~/zurg/nzbs
cp /path/to/some.nzb ~/zurg/nzbs/
ls /zurg_mnt/zurg/__all__/
```

بما أن لديك حسابًا واحدًا فقط، فإن مجلد `__nzb__` الخاص به يُستبعد من قائمة الجذر للتركيب (mount)، لذلك ابحث داخل `__all__`. يلتقط زurg مجلد المراقبة كل 15 ثانية تقريبًا. ولأنه يقع داخل الربط `./:/config`، فإنه يبقى محفوظًا عند تنفيذ `docker compose pull` وعند إعادة إنشاء الحاوية، تمامًا like باقي الملفات.

## القواعد الخاصة بهذا النوع {#rules-specific-to-this-type}

- **يُسمح بـ `nzb` مُفعّل واحد فقط.** وجود اثنين سيفحص المجلد نفسه ويكرر كل إصدار. ضع خوادم الأخبار الإضافية تحت `nntp.servers` الخاص بذلك الإدخال الواحد. هناك تخدم المكتبة نفسها بدلاً من نسخة ثانية منها. إدخال `nzb` بجانب إدخال [`torbox_nzb`](torbox-nzb.md) مرفوض للسبب نفسه.
- **`watchlist: true` مرفوض.** خادم الأخبار لا يُسلَّم ملف torrent أبداً.
- **يتم تجاهل `add_torrents`** ويُصدر بدء التشغيل تحذيراً بذلك للسبب نفسه.
- **`download_tokens` و`strm_link_token` لا يفعلان شيئاً.** لا يوجد بيانات اعتماد لتدويرها.
- **اسم المجلد هو `__nzb__`** لأن الاسم يأخذ القيمة الافتراضية من النوع. اضبط `name: usenet` على الإدخال إذا فضلت تصفح `__usenet__`.

## خادم أخبار ثانٍ يستحق أكثر مما يبدو {#a-second-news-server-is-worth-more-than-it-looks}

الاحتفاظ بالمقالات يختلف من مزوّد لآخر. غالباً ما تكون مقالة سقطت من أحد الخوادم ما زالت موجودة على خادم آخر.

بدون حساب ثانٍ، الطريقة الوحيدة لاستعادة مقالة مفقودة هي PAR2، وهذا يعني قراءة **الإصدار كاملاً**. لذلك يُحدث خادم ثانٍ فرقاً كبيراً: الفرق بين جلب مقالة واحدة وإعادة قراءة كل شيء.

تُضاف الحسابات الإضافية ضمن `nntp.servers` لهذا الإدخال، وليس في إدخال `nzb` ثانٍ. تحدد `priority` و`backup` و`backbone` من يُسأل وبأي ترتيب. تُدار القراءات بالسعة المجمّعة للحسابات التي لا تحمل علامة `backup`. يمكنك الاطلاع على الإعداد الكامل وما تفعله كل مفتاح في [Usenet مع zurg](../guides/usenet.md#more-than-one-usenet-provider).

## تحقّق من أنه يعمل {#check-it-worked}

```bash
curl -sS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

مع حساب واحد فقط، يتم استبعاد مجلده الخاص من قائمة الجذر الخاصة بالتركيب (mount)، لذلك يعرض التركيب نفس الملفات تحت `__all__`.

يقوم الفحص هنا بالمصادقة على خادم الأخبار باستخدام اتصال واحد كحد أقصى من المجمع الموجود. لا توجد واجهة برمجية للحساب يمكن الاستعلام عنها.

## عندما تسوء الأمور {#when-it-goes-wrong}

يوجد عرضان يخصان إعداد المزوّد نفسه وليس المكتبة.

**تتقطّع القراءات ويتراجع zurg إلى مقال واحد في كل مرة.** قيمة `pipeline_depth` أعلى مما يتحمله الخادم. يخفّضها zurg بنفسه ويُظهر تحذيراً. اضبطها على `1` صراحةً إذا كان الخادم لا يتعامل مع عدة أوامر في وقت واحد.

**الأداء ضعيف على رابط ذي زمن استجابة عالٍ.** اترك `socket_receive_buffer_kb` غير محدد. المخزن المؤقت المثبَّت هو مخزن يتوقف النواة عن ضبطه تلقائياً. على لينكس، يُبقي هذا نافذة الاستقبال قرب 64 KiB، ويكلّف الحساب معظم سرعته.

أما بقية الأعراض فلها صف في جدول استكشاف الأخطاء في [Usenet مع zurg](../guides/usenet.md#troubleshooting). رفض الاتصالات، والبث البطيء، ومزوّد لا يُطلب منه شيء، وتعديل من Dashboard أسقط `nntp.servers`، كلها مذكورة هناك.
