#!/bin/bash

echo "========================================"
echo "   تحقق شامل من إعدادات RadiusDesk"
echo "========================================"

echo ""
echo "🔹 التحقق من إعداد قاعدة بيانات rd"
mysql -u root -e "SHOW DATABASES LIKE 'rd';" | grep rd >/dev/null
if [ $? -eq 0 ]; then
    echo "✅ قاعدة البيانات 'rd' موجودة"
else
    echo "❌ قاعدة البيانات 'rd' غير موجودة"
fi

echo "- التحقق من وجود الجداول الأساسية"
mysql -u root -e "USE rd; SHOW TABLES;" | grep radcheck >/dev/null
if [ $? -eq 0 ]; then
    echo "✅ الجداول الأساسية موجودة (مثال: radcheck)"
else
    echo "❌ الجداول غير موجودة داخل قاعدة بيانات rd"
fi

echo ""
echo "🔹 التحقق من إعداد FreeRADIUS"
echo "- حالة الخدمة:"
systemctl is-active --quiet freeradius && echo "✅ Freeradius يعمل" || echo "❌ Freeradius لا يعمل"

echo "- التأكد من تفعيل وحدة sql"
[ -f /etc/freeradius/3.0/mods-enabled/sql ] && echo "✅ وحدة sql مفعلة" || echo "❌ وحدة sql غير مفعلة"

echo "- فحص إعداد قاعدة البيانات في وحدة sql"
grep -q 'radius_db = "rd"' /etc/freeradius/3.0/mods-enabled/sql && echo "✅ قاعدة البيانات محددة بـ 'rd'" || echo "❌ تحقق من إعدادات sql"

echo ""
echo "🔹 التحقق من ملفات مواقع Freeradius"
for file in default inner-tunnel; do
    echo "- التحقق من وجود sql في $file"
    grep -q '^[^#]*sql' /etc/freeradius/3.0/sites-enabled/$file && echo "✅ sql مفعلة في $file" || echo "❌ sql غير مفعلة في $file"
done

echo ""
echo "🔹 التحقق من ملفات واجهة RadiusDesk"
if [ -d /var/www/html/rdcore ]; then
    echo "✅ مجلد rdcore موجود"
else
    echo "❌ مجلد rdcore مفقود"
fi

if [ -d /var/www/html/rd_mobile ]; then
    echo "✅ مجلد rd_mobile موجود"
else
    echo "❌ مجلد rd_mobile مفقود"
fi

echo ""
echo "🔹 التحقق من صلاحيات ملفات الويب"
WEBUSER="www-data"
find /var/www/html -type d -exec bash -c 'for f; do if [ "$(stat -c %U "$f")" != "$0" ]; then echo "❌ صلاحيات خاطئة على $f"; fi; done' $WEBUSER {} +

echo ""
echo "✅ انتهى الفحص الشامل. راجع أي أخطاء أعلاه قبل ربط Mikrotik."
