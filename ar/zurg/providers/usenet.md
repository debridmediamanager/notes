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

- **只能启用一个 `nzb` 条目。** 两个条目会扫描同一个目录，导致每个版本都被重复。更多的新闻服务器应放在这一个条目的 `nntp.servers` 下。它们提供的是同一个库，而不是第二份副本。与 [`torbox_nzb`](torbox-nzb.md) 条目并存的 `nzb` 条目同样会因同样的原因被拒绝。
- **`watchlist: true` 会被拒绝。** 新闻服务器永远不会接收种子文件。
- **`add_torrents` 会被忽略**，启动时也会因同样的原因发出警告。
- **`download_tokens` 和 `strm_link_token` 不起作用。** 这里没有需要轮换的凭据。
- **目录名是 `__nzb__`**，因为名称默认与类型相同。如果你更想浏览 `__usenet__`，请在该条目上设置 `name: usenet`。

## خادم أخبار ثانٍ يستحق أكثر مما يبدو {#a-second-news-server-is-worth-more-than-it-looks}

الاحتفاظ بالمقالات يختلف من مزوّد لآخر. غالباً ما تكون مقالة سقطت من أحد الخوادم ما زالت موجودة على خادم آخر.

بدون حساب ثانٍ، الطريقة الوحيدة لاستعادة مقالة مفقودة هي PAR2، وهذا يعني قراءة **الإصدار كاملاً**. لذلك يُحدث خادم ثانٍ فرقاً كبيراً: الفرق بين جلب مقالة واحدة وإعادة قراءة كل شيء.

تُضاف الحسابات الإضافية ضمن `nntp.servers` لهذا الإدخال، وليس في إدخال `nzb` ثانٍ. تحدد `priority` و`backup` و`backbone` من يُسأل وبأي ترتيب. تُدار القراءات بالسعة المجمّعة للحسابات التي لا تحمل علامة `backup`. يمكنك الاطلاع على الإعداد الكامل وما تفعله كل مفتاح في [Usenet مع zurg](../guides/usenet.md#more-than-one-usenet-provider).

## تحقّق من أنه يعمل {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/nzb/test
docker compose logs --tail=100 zurg
ls /zurg_mnt/zurg/__all__/
```

مع حساب واحد فقط، يتم استبعاد مجلده الخاص من قائمة الجذر للتركيب، فيظهر التركيب نفس الملفات تحت `__all__`.

الفحص هنا يتحقق من هوية المستخدم عبر خادم الأخبار باستخدام اتصال واحد على الأكثر من المجمع الموجود. لا توجد واجهة برمجية للحساب يمكن الاستعلام عنها.

## عندما تسوء الأمور {#when-it-goes-wrong}

يوجد عرضان يخصان إعداد المزوّد نفسه وليس المكتبة.

**تتقطّع القراءات ويتراجع zurg إلى مقال واحد في كل مرة.** قيمة `pipeline_depth` أعلى مما يتحمله الخادم. يخفّضها zurg بنفسه ويُظهر تحذيراً. اضبطها على `1` صراحةً إذا كان الخادم لا يتعامل مع عدة أوامر في وقت واحد.

**الأداء ضعيف على رابط ذي زمن استجابة عالٍ.** اترك `socket_receive_buffer_kb` غير محدد. المخزن المؤقت المثبَّت هو مخزن يتوقف النواة عن ضبطه تلقائياً. على لينكس، يُبقي هذا نافذة الاستقبال قرب 64 KiB، ويكلّف الحساب معظم سرعته.

أما بقية الأعراض فلها صف في جدول استكشاف الأخطاء في [Usenet مع zurg](../guides/usenet.md#troubleshooting). رفض الاتصالات، والبث البطيء، ومزوّد لا يُطلب منه شيء، وتعديل من Dashboard أسقط `nntp.servers`، كلها مذكورة هناك.
