#!/bin/bash

echo "### التحقق من وجود ملف قاعدة البيانات rd.sql..."

# تحديد المسار المتوقع للملف
SQL_FILE=""
if [ -f /var/www/html/cake4/rd_cake/setup/db/rd.sql ]; then
    SQL_FILE="/var/www/html/cake4/rd_cake/setup/db/rd.sql"
elif [ -f /var/www/rdcore/cake4/rd_cake/setup/db/rd.sql ]; then
    SQL_FILE="/var/www/rdcore/cake4/rd_cake/setup/db/rd.sql"
else
    echo "لم يتم العثور على rd.sql في المسارات المعروفة!"
    exit 1
fi

echo "### إعداد المنطقة الزمنية (timezone info)"
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql -u root mysql

echo "### إنشاء قاعدة بيانات rd والمستخدم"
mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS rd;
GRANT ALL PRIVILEGES ON rd.* TO 'rd'@'127.0.0.1' IDENTIFIED BY 'rd';
GRANT ALL PRIVILEGES ON rd.* TO 'rd'@'localhost' IDENTIFIED BY 'rd';
FLUSH PRIVILEGES;
EOF

echo "### استيراد قاعدة البيانات من: $SQL_FILE"
mysql -u root rd < "$SQL_FILE"

echo "### تشغيل patch اختياري (مثال)"
PATCH_FILE="/var/www/rdcore/cake4/rd_cake/setup/db/8.068_add_email_sms_histories.sql"
if [ -f "$PATCH_FILE" ]; then
    mysql -u root rd < "$PATCH_FILE"
    echo "تم تطبيق patch بنجاح: $PATCH_FILE"
else
    echo "لم يتم العثور على patch المحدد، تخطى."
fi

echo "### تنظيف كاش CakePHP"
rm -f /var/www/rdcore/cake4/rd_cake/tmp/cache/models/*

echo "### تم تجهيز قاعدة البيانات بنجاح!"
