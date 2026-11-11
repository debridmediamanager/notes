# Debrid-Link

`type: debridlink`

يحتوي قائمة السيدboks الخاصة بـ [Debrid-Link](https://debrid-link.com/id/diG1t) على كل الملفات. تحديث المكتبة يتطلب تصفحًا واحدًا متصفحًا للصفحات بدلًا من البحث عن كل إصدار على حدة. وهي الأرخص بين الخدمات السحابية الثلاث من حيث تكلفة المزامنة.

## الحصول على مفتاح API {#get-the-api-key}

سجّل الدخول وافتح [debrid-link.fr/webapp/apikey](https://debrid-link.fr/webapp/apikey). أنشئ مفتاحاً وانسخه.

## إعداده {#configure-it}

```yaml
zurg: v1
providers:
  - type: debridlink
    token: YOUR_DEBRID_LINK_API_KEY
mount_path: "/zurg_mnt/zurg"
```

في تثبيت جديد للحاوية، دع الإعداد يكتبه.

```bash
cd ~/zurg
docker compose run --rm zurg setup \
  --no-service --skip-downloads --mount-path /zurg_mnt/zurg \
  --provider debridlink
```

في تثبيت فيه `config.yml` بالفعل، استخدم **Add provider** في لوحة التحكم على `http://localhost:9999/config/` أو عدّل الملف. أعد التشغيل في الحالتين.

```bash
docker compose restart zurg
```

يقرأ `zurg setup` المتغير `DEBRIDLINK_TOKEN`، أما الخدمة التي تعمل في الخلفية فلا تقرأه.

## بيانات اعتماد واحدة لكل إدخال {#one-credential-per-entry}

يحلّ Debrid-Link كل ملف عبر معرّف يعود إلى حساب القائمة.
ليس هناك مفتاح ثانٍ تنتقل إليه. يُرفض `download_tokens`، وكذلك أي `strm_link_token` يختلف عن `token`. إذا أردت حساباً ثانياً، فأضفه كمدخل آخر بـ`name` خاص به.

```yaml
providers:
  - type: debridlink
    name: dl-main
    token: FIRST_DEBRID_LINK_API_KEY
  - type: debridlink
    name: dl-second
    token: SECOND_DEBRID_LINK_API_KEY
```

## ما الذي يعمل هنا {#what-works-here}

تصفح المكتبة، وقراءة البث، والقراءة عبر إعادة التوجيه، وملفات STRM، وإضافة
ماغنت، ورفع ملفات `.torrent`، والحذف، كلها تعمل. ويحصل الحساب على مجلد
خاص به باسم `__debridlink__`.

## حدود تستحق الانتباه {#limits-worth-knowing}

**20 فتحة نشطة.** هذا هو الحد الأقصى، وzurg يمنع إضافة المزيد بعده.

**8 طلبات API متزامنة.** يتم حل أربعة أجزاء من الأرشيف متعدد الأجزاء في وقت واحد.

**المحتوى ينتهي صلاحيته.** الإصدار الذي اختفى متوقع وليس معطوباً.

**لا يوجد فحص للتخزين المؤقت.** Debrid-Link أوقفت نقطة النهاية هذه، وzurg لا يستخدمها. الإضافة المقتصرة على المخزن المؤقت لا يمكنها أن تتأكد من التوفر إلا من ردّ الإضافة نفسه. لا يستطيع هذا الـ backend الإجابة عن سؤال "هل هذا مخزن مؤقتاً؟" قبل الإضافة.

zurg يربط رموز الأخطاء القادمة من الخدمة بما يجب أن يفعله بعد ذلك.

| الرمز القادم من Debrid-Link | ما يفعله zurg |
|---|---|
| `badToken` or `badSign` | يبلغ عن بيانات اعتماد غير صالحة. أصلح المفتاح. |
| `floodDetected` | يوقف الحساب مؤقتاً لمدة ساعة. |
| `maxTorrent` `maxData` `maxLink` and their `Host` variants | يبلغ عن استنفاد حصة الإضافة أو حركة البيانات اليومية. |
| `serverNotAllowed` `maintenanceHost` `maxTransfer` | يعامل الحساب على أنه غير متاح مؤقتاً. |
| `badId` | يعامل التورنت على أنه غير موجود. |

!!!warning رفض الفيضان يكلّفك ساعة
`floodDetected` يوقف الحساب لمدة ساعة كاملة وليس دقيقة. هذا مقصود. إعادة المحاولة بعد رفض الفيضان هي ما يجلب الرفض التالي. قلّل الطلبات التي كانت تضغط على الخدمة بكثرة قبل أن تعيد تشغيل zurg.
!!!

## تحقّق من أنه يعمل {#check-it-worked}

```bash
curl -fsS -X POST http://localhost:9999/api/providers/debridlink/test
ls /zurg_mnt/zurg/__all__/ | head
```

مع حساب واحد فقط، يتم إخفاء مجلده الخاص من قائمة الجذر في الـ mount،
لذلك يعرض الـ mount نفس الملفات تحت `__all__`.

## عندما تسوء الأمور {#when-it-goes-wrong}

**لا يحدث شيء لمدة ساعة.** هذا رفض بسبب الطوفان. انظر التحذير أعلاه.

**يتم رفض عمليات الـ grab لكن القراءة ما زالت تعمل.** حصة الإضافة أو حصة حركة المرور اليومية نفدت. وتُعاد تعيينها حسب جدول الخدمة الخاص بها.

**الإضافات تنجح ثم تبقى عالقة.** بدون cache endpoint لا توجد طريقة لمعرفة مسبقاً ما إذا كان الـ hash محفوظاً من قبل. أي إضافة غير مخزنة تُنزَّل مثل أي شيء آخر.
