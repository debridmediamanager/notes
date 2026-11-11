# أزرار DMM في Safari {#dmm-buttons-in-safari}

DMM-المتصفح الإضافي يضيف زر **DMM🔎** إلى مواقع الأفلام والمسلسلات. يفتح الزر العنوان في DMM. وبجانب روابط magnet يضيف زر **DMM🧲** يقوم بإضافة التورنت إلى مكتبة DMM الخاصة بك.

على Chrome وFirefox ثبّت [إضافة Chrome](https://chromewebstore.google.com/detail/Debrid%20Media%20Manager/oeojlegjfhgefhnbjdnaebgdfkbipghm) أو [إضافة Firefox](https://addons.mozilla.org/en-US/firefox/addon/debrid-media-manager/). أما Safari فيستخدم نفس الكود على شكل [سكربت Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) مع مدير سكربتات.

اختر مديراً واحداً:

| المدير | السعر | يعمل على | تحديث السكربت |
|---|---|---|---|
| [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) | مجاني | Mac وiPhone وiPad | عندما تضغط **Update** في نافذته المنبثقة |
| [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) | 2.99 دولار | Mac وiPhone وiPad | تلقائياً من تلقاء نفسه |

## باستخدام Userscripts {#with-userscripts}

1. ثبّت [Userscripts](https://apps.apple.com/us/app/userscripts/id1463298887) من App Store وافتحه مرة واحدة.
2. فعّل الإضافة:
   - **Mac:** Safari > **Settings** > **Extensions**، ثم ضع علامة على **Userscripts**.
   - **iPhone و iPad:** **Settings** > **Apps** > **Safari** > **Extensions** > **Userscripts**، ثم فعّل **Allow Extension**.
3. اسمح لها بالعمل على كل المواقع. روابط Magnet ممكن تكون في أي موقع، فلازم السكربت يشتغل في كل مكان.
   - **Mac:** في نفس صفحة **Extensions**، اضغط **Edit Websites…** واضبط **When visiting other websites** على **Allow**.
   - **iPhone و iPad:** في شاشة **Userscripts** نفسها، اضبط **All Websites** على **Allow**.
4. في Safari، افتح [ملف سكربت DMM](https://update.greasyfork.org/scripts/463268/Debrid%20Media%20Manager.user.js). هيظهر كنص عادي.
5. افتح نافذة Userscripts المنبثقة: من زر شريط الأدوات على Mac، أو من زر **aA** في شريط العنوان على iPhone. اضغط على زر التثبيت اللي بتظهره وأكد.

عشان تحدّث السكربت بعدين، افتح نافذة Userscripts المنبثقة واضغط **Update** لما تلاقي سكربت DMM في القائمة.

## باستخدام Tampermonkey {#with-tampermonkey}

1. ثبّت [Tampermonkey](https://apps.apple.com/us/app/tampermonkey/id6738342400) من App Store.
2. فعّله ودعه يعمل على كل المواقع، كما في الخطوتين 2 و3 أعلاه، مع استخدام **Tampermonkey** بدلاً من **Userscripts**.
3. في Safari، افتح [صفحة السكربت على Greasy Fork](https://greasyfork.org/en/scripts/463268-debrid-media-manager) وانقر **Install this script**.
4. ستفتح Tampermonkey صفحة التثبيت الخاصة بها. انقر **Install**.

يتحقق Tampermonkey من وجود إصدار جديد مرة واحدة يومياً.

## تحقق من أنه يعمل {#check-it-works}

افتح [Dune: Part Two على Letterboxd](https://letterboxd.com/film/dune-part-two/). يظهر زر **DMM🔎** بلون تركوازي بجانب العنوان، وعند الضغط عليه يفتح الفيلم على DMM.

لا يظهر الزر؟ تحقّق من الأمور التالية:

- تأكد من أن نافذة مدير السكربتات المنبثقة تعرض **Debrid Media Manager** وأن مفتاح التشغيل الخاص به مفعّل.
- تأكد من أن Safari يسمح لمدير السكربتات بالعمل على هذا الموقع. عندما يسألك، اختر **Always Allow on Every Website**.
- تأكد من أن الصفحة اكتمل تحميلها. مواقع مثل TMDB وWikipedia وAniList تُظهر الزر بعد لحظة من اكتمال تحميل الصفحة.
