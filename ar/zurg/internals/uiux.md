# تقييم تجربة المستخدم وواجهته لإعدادات الدليل {#directory-configuration-uiux-assessment}

## النطاق والوضع الحالي {#scope-and-current-state}
- الصفحة: `Directory Configuration` على `http://localhost:9999/directories/`.
- الواجهة الحالية: جدول واحد مسطح يعرض المجلدات تحت عناوين مثل "MEDIA" و"RECENT"، وفيه أعمدة لاسم المجلد والترتيب الرقمي وروابط الإجراءات ("Edit" و"Delete").
- السلوك: الضغط على Edit أو Delete ينفّذ إجراءً بسيطاً. لا يوجد تجميع إضافي غير العناوين، ولا توجد شاشة مخصصة لإنشاء المجلدات أو تعديلها بخيارات YAML كاملة.

## أهم الثغرات في تجربة المستخدم {#key-ux-gaps}
- **Information architecture**
  - Groups are visually flattened; users cannot focus on one group at a time.
  - Ordering relies on manual numbers (`group_order`), which is unintuitive and error-prone.
  - No search/filter bar to quickly locate directories.
  - No bulk actions (delete/move) or selection affordances.
- **Creation/editing experience**
  - Edit/add flows do not expose the full YAML schema (general settings, size/file/tag/time filters).
  - No structured layout; fields are not grouped, leading to cognitive overload as options grow.
  - Lacks a nested AND/OR rule builder to mirror YAML's nested filter logic.
  - Tag-related fields (`tags_match_all`, `tags_match_any`) lack discoverability and selection help.
  - No live preview of torrents matching current filter settings.
- **Guidance and validation**
  - Missing tooltips/info icons per field and links to deeper docs (e.g., `tags.md`).
  - No proactive warning when a directory would yield zero torrents or lacks required filters.
  - Regex and other pattern fields lack real-time validation feedback.
  - Deletions happen without confirmation or undo.
- **Accessibility and responsiveness**
  - Contrast and readability not verified against WCAG; icon-only actions may lack labels.
  - Drag-and-drop not available; no keyboard-accessible reordering path.
  - Mobile layout not optimized (table does not adapt to stacked cards; forms may not scroll well).
  - Action affordances rely on text-only links; icons and clear targets are missing.
- **Performance and interaction polish**
  - Search/filter (once added) will need debouncing and pagination/virtualization for large lists.
  - Drag-and-drop (once added) needs persistence and graceful fallback when persistence fails.

## تغييرات الواجهة وتجربة المستخدم الموصى بها {#recommended-uiux-changes}
- **تقديم المجموعات**
  - اعرض كل `group` على المستوى الأعلى (مثل media/recent/example) كبطاقة أو قسم قابل للطي، ولكل منها قائمة خاصة بها.
  - وفّر إجراءات سريعة لكل مجموعة (طي/توسيع، وتحديد جماعي).
- **الترتيب**
  - استبدل عمود الترتيب الرقمي بمقابض سحب لإعادة الترتيب داخل المجموعة، واعرض الترتيب المحسوب عبر تلميح أو شارة مضمّنة.
  - وفّر أزرار تحريك لأعلى/لأسفل للتحكم في الترتيب بلوحة المفاتيح، كبديل لإمكانية الوصول وللأجهزة المحمولة.
- **البحث والإجراءات الجماعية**
  - أضف شريط بحث وتصفية فوق القائمة، مع تأخير معالجة الإدخال.
  - أضف مربعات اختيار للحذف أو النقل الجماعي، مع خيار "select all in group" لتحديد كل عناصر المجموعة.
- **واجهة الإضافة والتعديل**
  - استخدم نافذة منبثقة أو لوحة جانبية بتخطيط مقسّم إلى أقسام: General وSize Filters وFile Filters وTag Filters وTime Filters وAdvanced.
  - أضف أقسامًا فرعية قابلة للطي لتقليل الإرباك، واحفظ حالة التوسيع طوال الجلسة.
- **منشئ القواعد**
  - وفّر منشئًا مرئيًا لمنطق AND وOR يعكس بنية YAML: مجموعات متداخلة، وكبسولات شروط، ومحددات للخاصية والعامل والقيمة (مثل has_episodes، وregex مع matches/does not match).
  - اسمح بتحويل AND إلى OR والعكس في كل عقدة، واعرض معاينة للتعبير الناتج.
- **محدد الوسوم**
  - اختيار متعدد مع إكمال تلقائي يعتمد على الوسوم المتاحة؛ واعرض أوصاف الوسوم وتلميحاتها وأعدادها عند توفرها.
  - ميّز بوضوح بين `tags_match_all` و`tags_match_any`.
- **المعاينة**
  - أضف "Preview matching torrents" لجلب نتائج عينة وفق حالة الفلتر الحالية، مع عناصر هيكلية أو حالة تحميل، ومعالجة للأخطاء.
- **الإرشادات**
  - أضف تلميحات inline أو أيقونات معلومات لكل حقل، مع روابط لوثائق أعمق عند الحاجة (مثل [tags.md](../reference/tags.md)).
  - اعرض تلميحات سياقية (مثل "Only show largest file" التي توضح الأثر الجانبي للسلوك).
- **التحقق والأمان**
  - امنع الحفظ عند إفراغ الفلاتر المطلوبة أو فشل التحقق، واعرض أخطاء inline.
  - تحقق من صحة regex فورياً على الواجهة، مع تأكيد من الخادم عند الإرسال حتى لا تختلف النتيجتان.
  - احذّر عندما يُنتج الإعداد صفر تورنتات مطابقة (بناءً على المعاينة أو على تقديرات مبسطة).
  - اعرض نافذة تأكيد قبل الحذف، ووفّر شريط تراجع قصيرًا عند الإمكان (حذف ناعم إذا كان مدعومًا).
- **إمكانية الوصول والتصميم المتجاوب**
  - تحقق من تباين الألوان للوحة المختارة، وتأكد من وضوح حالات التركيز وتسميات ARIA للعناصر.
  - تأكد من أن الأقسام القابلة للطي ومقابض السحب والإجراءات تعمل بلوحة المفاتيح.
  - على الأجهزة المحمولة، اعرض المجموعات كبطاقات مكدسة، وتأكد من أن النوافذ والألواح قابلة للتمرير مع رؤوس ثابتة تحتوي على الإجراءات.
  - ارفق الأيقونات بتسميات للإجراءات الأساسية، وتأكد من أن الأزرار التي تحتوي على أيقونات فقط لها أسماء متاحة لقارئات الشاشة.
- **الصقل البصري**
  - استخدم أيقونات متسقة للتعديل والحذف وإعادة الترتيب، وأضف فواصل خفيفة وشرائح (chips) لتوضيح سياق المجموعة أو حالتها.
  - فكّر في تلوين المجموعات لتسهيل التمييز بينها بسرعة، مع الحفاظ على تباين ألوان مقبول.

## التبعيات والافتراضات التي يجب تأكيدها {#dependencies-and-assumptions-to-confirm}
- دعم API لـ: حفظ ترتيب المجموعات، والعمليات الجماعية، وتسلسل AND/OR المتداخل، ومصدر بيانات الوسوم الوصفية، ونقطة نهاية لمعاينة الاستعلام.
- سلوك الحذف: الحذف الناعم مقابل الحذف الصارم، ونافذة التراجع، ومتطلبات التدقيق.
- نموذج الملكية والصلاحيات (إذا كان هناك أكثر من مستخدم) لعرض بيانات آخر تعديل ومنع التعارضات.
- قيود الأداء للمعاينة والبحث؛ استراتيجية الترقيم أو التمرير الافتراضي للمجموعات الكبيرة من البيانات.

## أولويات التنفيذ {#implementation-priorities}
1) أعِد تنظيم القائمة إلى بطاقات أو أقسام قابلة للطيّ مُجمّعة حسب الفئة، وأضِف شريط بحث وتصفية وحوارات تأكيد.
2) أضِف نافذة منبثقة أو لوحة جانبية مقسّمة إلى أقسام للإضافة والتعديل، مع تلميحات (tooltips) وتحقّق أساسي من صحة الإدخال، وأضِف اختيارًا متعدّدًا للوسوم.
3) أضِف السحب والإفلات وإعادة الترتيب بلوحة المفاتيح مع الحفظ الدائم، ونفّذ منشئ قواعد AND/OR.
4) أضِف معاينة للتورنتات المطابقة مع تأخير الطلبات (debounce) ومعالجة الأخطاء.
5) أنهِ إمكانية الوصول (مسارات لوحة المفاتيح وسمات ARIA)، وأضِف تخطيطًا متجاوبًا بالبطاقات المتراصّة فوق بعضها للجوّال.
